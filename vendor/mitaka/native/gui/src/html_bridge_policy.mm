#include "html_bridge_policy.hpp"
#include <CommonCrypto/CommonDigest.h>

#include <algorithm>
#include <cerrno>
#include <cstdlib>
#include <fcntl.h>
#include <stdexcept>
#include <sys/stat.h>
#include <unistd.h>

namespace mitaka::gui {
namespace {
bool same_file(const struct stat& left, const struct stat& right) {
    return left.st_dev == right.st_dev && left.st_ino == right.st_ino &&
        left.st_size == right.st_size &&
        left.st_mtimespec.tv_sec == right.st_mtimespec.tv_sec &&
        left.st_mtimespec.tv_nsec == right.st_mtimespec.tv_nsec &&
        left.st_ctimespec.tv_sec == right.st_ctimespec.tv_sec &&
        left.st_ctimespec.tv_nsec == right.st_ctimespec.tv_nsec;
}

bool same_document(const HtmlDocumentIdentity& left, const HtmlDocumentIdentity& right) {
    return left.canonical_path == right.canonical_path && left.device == right.device &&
        left.inode == right.inode && left.digest == right.digest;
}

HtmlBridgeResult rejected(const char *error) {
    return {HtmlBridgeDisposition::rejected, {}, error};
}

std::string decode_script(NSString *url) {
    if (url.length < 7 || [[url substringToIndex:7] caseInsensitiveCompare:@"mtkp://"] != NSOrderedSame)
        throw std::invalid_argument("Expected mtkp:// followed by Lua source");
    if (url.length > 7 + html_script_limit * 3)
        throw std::invalid_argument("HTML Lua URL exceeds the encoded size limit");
    // URL の host/path へ分解せず、payload だけを UTF-8 として一度復号する。
    NSString *decoded = [url substringFromIndex:7].stringByRemovingPercentEncoding;
    NSData *bytes = [decoded dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    if (!bytes || bytes.length == 0 || bytes.length > html_script_limit)
        throw std::invalid_argument("HTML Lua payload is invalid UTF-8, empty, or exceeds 64 KiB");
    const char *begin = static_cast<const char *>(bytes.bytes);
    if (std::find(begin, begin + bytes.length, '\0') != begin + bytes.length)
        throw std::invalid_argument("HTML Lua payload contains NUL");
    return {begin, bytes.length};
}
}

HtmlDocumentSnapshot read_html_document(NSURL *url) {
    if (!url || !url.isFileURL || url.baseURL || url.host.length || url.user || url.password ||
        url.port || url.query || url.fragment ||
        (![[url.pathExtension lowercaseString] isEqualToString:@"html"] &&
         ![[url.pathExtension lowercaseString] isEqualToString:@"htm"]))
        throw std::invalid_argument("Choose an absolute local HTML file without URL components");
    char *resolved = realpath(url.fileSystemRepresentation, nullptr);
    if (!resolved) throw std::runtime_error("Local HTML file cannot be resolved");
    const std::string path(resolved);
    free(resolved);
    const int fd = open(path.c_str(), O_RDONLY | O_CLOEXEC | O_NONBLOCK | O_NOFOLLOW);
    if (fd < 0) throw std::runtime_error("Local HTML file cannot be opened");
    struct Descriptor { int value; ~Descriptor() { close(value); } } descriptor{fd};
    struct stat before;
    if (fstat(fd, &before) != 0 || !S_ISREG(before.st_mode) || before.st_size < 0 ||
        static_cast<std::uint64_t>(before.st_size) > html_document_limit)
        throw std::invalid_argument("Local HTML must be a regular file no larger than 1 MiB");

    NSMutableData *data = [NSMutableData data];
    CC_SHA256_CTX context;
    CC_SHA256_Init(&context);
    char buffer[16384];
    std::size_t total = 0;
    while (true) {
        const ssize_t count = read(fd, buffer, std::min(sizeof(buffer), html_document_limit + 1 - total));
        if (count == 0) break;
        if (count < 0) {
            if (errno == EINTR) continue;
            throw std::runtime_error("Local HTML file could not be read");
        }
        total += static_cast<std::size_t>(count);
        if (total > html_document_limit)
            throw std::invalid_argument("Local HTML exceeds 1 MiB");
        CC_SHA256_Update(&context, buffer, static_cast<CC_LONG>(count));
        [data appendBytes:buffer length:static_cast<NSUInteger>(count)];
    }
    struct stat after, current;
    if (fstat(fd, &after) != 0 || stat(path.c_str(), &current) != 0 ||
        !same_file(before, after) || !same_file(after, current) ||
        total != static_cast<std::uint64_t>(after.st_size))
        throw std::runtime_error("Local HTML changed while being read");
    HtmlDocumentIdentity result;
    result.canonical_path = path;
    result.device = static_cast<std::uint64_t>(after.st_dev);
    result.inode = static_cast<std::uint64_t>(after.st_ino);
    CC_SHA256_Final(result.digest.data(), &context);
    return {result, [data copy]};
}

HtmlDocumentIdentity inspect_html_document(NSURL *url) {
    return read_html_document(url).identity;
}

void HtmlBridgePolicy::trust(const HtmlDocumentIdentity& document) {
    if (document.canonical_path.empty() || document.canonical_path.front() != '/')
        throw std::invalid_argument("Trusted HTML identity must have an absolute canonical path");
    trusted_ = document;
}

HtmlBridgeResult HtmlBridgePolicy::evaluate(const HtmlBridgeRequest& request) {
    const NSRange separator = [request.url rangeOfString:@":"];
    const bool script_scheme = request.url && separator.location != NSNotFound &&
        [[request.url substringToIndex:separator.location] caseInsensitiveCompare:@"mtkp"] == NSOrderedSame;
    if (!script_scheme) {
        revoke();
        return {HtmlBridgeDisposition::navigation, {}, {}};
    }
    if (!trusted_) return rejected("This HTML document has not been explicitly trusted");
    if (!request.source_main_frame || !request.target_main_frame || !request.has_target_frame ||
        !request.link_activated)
        return rejected("HTML Lua requires an activated link in the trusted main frame");
    try {
        if (!same_document(*trusted_, inspect_html_document(request.source_url)) ||
            !same_document(*trusted_, inspect_html_document(request.document_url))) {
            revoke();
            return rejected("HTML document identity or content changed");
        }
        return {HtmlBridgeDisposition::script, decode_script(request.url), {}};
    } catch (const std::invalid_argument& error) {
        // URLや内容を検証できなければ、同じ画面に見えても承認を引き継がない。
        revoke();
        return rejected(error.what());
    } catch (const std::runtime_error& error) {
        revoke();
        return rejected(error.what());
    }
}
} // namespace mitaka::gui
