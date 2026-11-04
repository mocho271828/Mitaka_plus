#include "media_catalog.hpp"
#import <Foundation/Foundation.h>
#include <algorithm>
#include <array>
#include <cctype>
#include <cstdint>
#include <fcntl.h>
#include <map>
#include <sstream>
#include <stdexcept>
#include <sys/stat.h>
#include <unistd.h>

namespace mitaka::gui {
namespace {
namespace fs = std::filesystem;
constexpr std::size_t registry_limit = 1024 * 1024;
constexpr std::size_t descriptor_limit = 64 * 1024;

struct Descriptor {
    int fd;
    ~Descriptor() { if (fd >= 0) close(fd); }
};

std::string read_text(const fs::path& path, std::size_t limit) {
    Descriptor file{open(path.c_str(), O_RDONLY | O_NONBLOCK | O_CLOEXEC)};
    struct stat info{};
    if (file.fd < 0 || fstat(file.fd, &info) != 0 || !S_ISREG(info.st_mode))
        throw std::runtime_error("通常ファイルを読み込めません");
    if (info.st_size < 0 || static_cast<std::uint64_t>(info.st_size) > limit)
        throw std::runtime_error("登録ファイルの容量上限を超えています");
    std::string bytes;
    std::array<char, 4096> buffer{};
    for (;;) {
        const auto count = read(file.fd, buffer.data(), buffer.size());
        if (count < 0) throw std::runtime_error("登録ファイルの読み取りに失敗しました");
        if (!count) break;
        if (bytes.size() + static_cast<std::size_t>(count) > limit)
            throw std::runtime_error("登録ファイルの容量上限を超えています");
        bytes.append(buffer.data(), static_cast<std::size_t>(count));
    }
    if (bytes.find('\0') != std::string::npos) throw std::runtime_error("NULを含む登録ファイルです");
    NSString *decoded = [[NSString alloc] initWithBytes:bytes.data() length:bytes.size() encoding:NSUTF8StringEncoding];
    if (!decoded) decoded = [[NSString alloc] initWithBytes:bytes.data() length:bytes.size()
        encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese)];
    if (!decoded) throw std::runtime_error("UTF-8 / CP932として読み込めません");
    std::string result(decoded.UTF8String);
    if (result.compare(0, 3, "\xef\xbb\xbf") == 0) result.erase(0, 3);
    return result;
}

std::string trim(std::string text) {
    const auto first = text.find_first_not_of(" \t\r\n");
    if (first == std::string::npos) return {};
    return text.substr(first, text.find_last_not_of(" \t\r\n") - first + 1);
}

bool same_name(const fs::path& a, const fs::path& b) {
    NSString *left = [[NSString alloc] initWithBytes:a.native().data() length:a.native().size() encoding:NSUTF8StringEncoding];
    NSString *right = [[NSString alloc] initWithBytes:b.native().data() length:b.native().size() encoding:NSUTF8StringEncoding];
    // macOSの分解Unicodeだけを同値化し、大文字小文字や説明付きの改名は推測しない。
    return left && right && [left.precomposedStringWithCanonicalMapping isEqualToString:right.precomposedStringWithCanonicalMapping];
}

fs::path relative_file(const fs::path& root, std::string raw) {
    std::replace(raw.begin(), raw.end(), '\\', '/');
    const fs::path relative(raw);
    if (raw.empty() || relative.is_absolute() || raw.find(':') != std::string::npos)
        throw std::runtime_error("外部URL・絶対パスはファイル選択で明示的に割り当ててください");
    fs::path candidate = root;
    for (const auto& component : relative) {
        if (component == ".") continue;
        if (component == "..") throw std::runtime_error("親フォルダへの参照は自動解決しません");
        bool found = false;
        for (const auto& item : fs::directory_iterator(candidate)) {
            if (same_name(item.path().filename(), component)) { candidate = item.path(); found = true; break; }
        }
        if (!found) throw std::runtime_error("登録と完全一致するファイル名がありません");
    }
    const auto canonical_root = fs::canonical(root);
    const auto canonical_path = fs::canonical(candidate);
    const auto inside = canonical_path.lexically_relative(canonical_root);
    if (inside.empty() || *inside.begin() == "..") throw std::runtime_error("登録フォルダ外への参照は自動解決しません");
    if (!fs::is_regular_file(canonical_path)) throw std::runtime_error("参照先が通常ファイルではありません");
    return candidate;
}

void resolve(MediaEntry& entry, const fs::path& root) {
    try {
        const auto descriptor = relative_file(root / "media", entry.descriptor);
        std::istringstream input(read_text(descriptor, descriptor_limit));
        std::string line;
        while (std::getline(input, line)) {
            line = trim(std::move(line));
            if (!line.empty()) entry.media_paths.push_back(std::move(line));
        }
        if (entry.media_paths.empty()) throw std::runtime_error("mvpに参照先がありません");
        entry.resolved_path = relative_file(root, entry.media_paths.back());
    } catch (const std::exception& error) {
        entry.diagnostics.push_back(error.what());
    }
}

using Occurrences = std::map<std::string, std::size_t>;
Occurrences read_registry(MediaCatalog& result, const fs::path& root, const char *name,
                          Occurrences previous = {}) {
    Occurrences seen;
    const auto registry = root / "media" / name;
    std::error_code error;
    if (!fs::exists(registry, error)) {
        if (error) result.diagnostics.push_back(registry.filename().string() + ": " + error.message());
        return seen;
    }
    try {
        std::istringstream input(read_text(registry, registry_limit));
        std::string line;
        std::size_t number = 0;
        while (std::getline(input, line)) {
            ++number;
            line = trim(std::move(line));
            if (line.empty() || line.front() == '#') continue;
            ++seen[line];
            if (previous[line]) { --previous[line]; continue; }
            MediaEntry entry;
            entry.registry = registry; entry.line = number;
            std::istringstream fields(line);
            std::string extra;
            if (!(fields >> entry.descriptor >> entry.secondary_descriptor >> entry.raw_type >> entry.menu_title >> entry.display_title) || (fields >> extra)) {
                entry.menu_title = "形式未解決: " + line;
                entry.diagnostics.push_back("登録は空白区切りの5列が必要です");
            } else {
                if (entry.raw_type == "I") entry.kind = MediaKind::image;
                else if (entry.raw_type == "M") entry.kind = MediaKind::movie;
                else if (entry.raw_type == "A") entry.kind = MediaKind::audio;
                else entry.diagnostics.push_back("旧type " + entry.raw_type + " の表示仕様は未確定です");
                resolve(entry, root);
            }
            result.entries.push_back(std::move(entry));
        }
    } catch (const std::exception& exception) {
        result.diagnostics.push_back(registry.filename().string() + ": " + exception.what());
    }
    return seen;
}
} // namespace

MediaCatalog load_media_catalog(const std::filesystem::path& data_directory) {
    MediaCatalog result;
    auto data = data_directory;
    while (!data.empty() && data.filename().empty() && data != data.root_path()) data = data.parent_path();
    const auto root = data.parent_path();
    // 公開仕様にない両登録の優先規則を推測せず、完全一致した行だけ相殺する。
    // 副登録に独自追加があれば残し、同一ファイル内の重複も勝手に削除しない。
    auto primary = read_registry(result, root, "images.dat");
    const auto secondary = read_registry(result, root, "images_list.dat", primary);
    if (!primary.empty() && !secondary.empty() && primary != secondary)
        result.diagnostics.push_back("images.dat / images_list.datが異なります。完全一致行を除き両方を保持しました");
    read_registry(result, root, "movies.dat");
    read_registry(result, root, "audio.dat");
    return result;
}

MediaKind media_kind_for_extension(const std::filesystem::path& path) {
    auto extension = path.extension().string();
    std::transform(extension.begin(), extension.end(), extension.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    if (extension == ".jpg" || extension == ".jpeg" || extension == ".png") return MediaKind::image;
    for (const auto *value : {".mov", ".mp4", ".m4v", ".avi", ".wmv", ".mpg", ".mpeg"})
        if (extension == value) return MediaKind::movie;
    for (const auto *value : {".mp3", ".wav", ".m4a", ".aif", ".aiff", ".caf", ".flac", ".aac", ".ogg", ".wma"})
        if (extension == value) return MediaKind::audio;
    return MediaKind::unknown;
}
} // namespace mitaka::gui
