#import "gui_file_io.h"
#include "session_state.hpp"

#include <algorithm>
#include <cerrno>
#include <cstdlib>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>

namespace {
NSError *fileError(NSString *description) {
    return [NSError errorWithDomain:@"Mitaka.FileIO" code:1
        userInfo:@{NSLocalizedDescriptionKey: description}];
}

NSURL *canonicalURL(NSURL *url) {
    if (!url.isFileURL) return nil;
    NSURL *resolved = url.URLByResolvingSymlinksInPath;
    char *path = realpath(resolved.fileSystemRepresentation, nullptr);
    if (path) {
        NSURL *result = [NSURL fileURLWithFileSystemRepresentation:path isDirectory:NO relativeToURL:nil];
        free(path);
        return result;
    }
    // 保存先が未作成でも、親の実体と大文字小文字を確定できる場合だけ受け付ける。
    struct stat info;
    if (lstat(resolved.fileSystemRepresentation, &info) == 0 || errno != ENOENT) return nil;
    path = realpath(resolved.URLByDeletingLastPathComponent.fileSystemRepresentation, nullptr);
    if (!path) return nil;
    NSURL *parent = [NSURL fileURLWithFileSystemRepresentation:path isDirectory:YES relativeToURL:nil];
    free(path);
    return [parent URLByAppendingPathComponent:resolved.lastPathComponent];
}

bool containsFile(NSURL *directory, NSString *relative) {
    return [NSFileManager.defaultManager fileExistsAtPath:[directory URLByAppendingPathComponent:relative].path];
}
}

NSData *boundedSessionData(NSURL *url, NSError **error) {
    if (error) *error = nil;
    if (!url.isFileURL) {
        if (error) *error = fileError(@"ローカルの状態ファイルを選択してください。");
        return nil;
    }
    // FIFOなどの選択でもUIを待たせず、同じfdを検査・上限付き読み込みに使う。
    const int fd = open(url.fileSystemRepresentation, O_RDONLY | O_NONBLOCK | O_CLOEXEC);
    if (fd < 0) {
        if (error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
        return nil;
    }
    struct Descriptor { int value; ~Descriptor() { close(value); } } descriptor{fd};
    struct stat info;
    if (fstat(fd, &info) != 0 || !S_ISREG(info.st_mode)) {
        if (error) *error = fileError(@"通常の状態ファイルを選択してください。");
        return nil;
    }
    NSMutableData *data = [NSMutableData data];
    constexpr std::size_t limit = mitaka::gui::maximum_session_state_bytes;
    char buffer[65536];
    while (data.length <= limit) {
        const ssize_t count = read(fd, buffer, std::min(sizeof(buffer), limit + 1 - data.length));
        if (count == 0) return data;
        if (count < 0) {
            if (errno == EINTR) continue;
            if (error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
            return nil;
        }
        [data appendBytes:buffer length:static_cast<NSUInteger>(count)];
    }
    if (error) *error = fileError(@"状態ファイルは1MiB以下にしてください。");
    return nil;
}

BOOL canWriteUserOutput(NSURL *url, NSArray<NSURL *> *protectedRoots) {
    NSURL *destination = canonicalURL(url);
    if (!destination) return NO;
    for (NSURL *root in protectedRoots) {
        NSURL *canonical = canonicalURL(root);
        if (!canonical) return NO;
        if ([canonical.path isEqualToString:@"/"] ||
            [destination.path isEqualToString:canonical.path] ||
            [destination.path hasPrefix:[canonical.path stringByAppendingString:@"/"]]) return NO;
    }
    for (NSURL *ancestor = destination.URLByDeletingLastPathComponent;
         ancestor.path.length > 1; ancestor = ancestor.URLByDeletingLastPathComponent) {
        if ([ancestor.pathExtension.lowercaseString isEqualToString:@"app"] ||
            containsFile(ancestor, @"Contents/Info.plist") ||
            (containsFile(ancestor, @"data/hip.dat") && containsFile(ancestor, @"data/cf96.dat")) ||
            (containsFile(ancestor, @"hip.dat") && containsFile(ancestor, @"cf96.dat"))) return NO;
        NSString *name = ancestor.lastPathComponent.lowercaseString;
        if (([name isEqualToString:@"official"] || [name isEqualToString:@"reference"]) &&
            [ancestor.URLByDeletingLastPathComponent.lastPathComponent.lowercaseString isEqualToString:@"sources"])
            return NO;
    }
    return YES;
}
