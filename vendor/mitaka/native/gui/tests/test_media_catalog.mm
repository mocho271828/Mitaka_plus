#include "media_catalog.hpp"
#import <Foundation/Foundation.h>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <sys/stat.h>
#include <unistd.h>

using namespace mitaka::gui;
namespace fs = std::filesystem;
namespace {
std::size_t checks = 0;
void check(bool value, const char *message) { ++checks; if (!value) throw std::runtime_error(message); }
struct Fixture {
    fs::path root;
    Fixture() {
        char name[] = "/tmp/mitaka-media-model-XXXXXX";
        const char *path = mkdtemp(name);
        if (!path) throw std::runtime_error("mkdtemp failed");
        root = path; fs::create_directory(root / "data"); fs::create_directory(root / "media"); fs::create_directory(root / "images");
    }
    ~Fixture() { std::error_code ignored; fs::remove_all(root, ignored); }
    void write(const fs::path& path, const std::string& value) { std::ofstream out(root / path, std::ios::binary); out << value; }
    void cp932(const fs::path& path, NSString *value) {
        NSData *data = [value dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese) allowLossyConversion:NO];
        check(data != nil, "fixture CP932 conversion");
        write(path, std::string(static_cast<const char *>(data.bytes), data.length));
    }
    MediaCatalog load() { return load_media_catalog(root / "data"); }
};
void registrations() {
    Fixture f;
    check(f.load().entries.empty(), "optional missing registry");
    f.cp932("media/images.dat", @"x.mvp x.mvp I 日本語 {日本語|にほんご}\r\n");
    f.write("media/images_list.dat", "x.mvp x.mvp I 日本語 {日本語|にほんご}\r\n");
    f.cp932("media/x.mvp", @".\\images\\missing.png\r\n.\\images\\ソ.png\r\n");
    f.write("images/ソ.png", "test");
    auto catalog = f.load();
    check(catalog.entries.size() == 1, "UTF8 CP932 duplicate not collapsed");
    const auto& entry = catalog.entries.front();
    check(entry.menu_title == "日本語" && entry.display_title == "{日本語|にほんご}", "title or ruby modified");
    check(entry.media_paths.size() == 2, "mvp paths dropped");
    check(entry.resolved_path && entry.resolved_path->filename() == "ソ.png", "last controller path or CP932 backslash corrupted");
    check(entry.diagnostics.empty(), "valid registration diagnosed");
    check(load_media_catalog(fs::path((f.root / "data").string() + "/")).entries.size() == 1, "trailing slash root");
    f.write("media/images_list.dat", "x.mvp x.mvp I 日本語 {日本語|にほんご}\r\nx.mvp x.mvp P 追加 追加\r\nx.mvp x.mvp P 追加 追加\r\n");
    catalog = f.load();
    check(catalog.entries.size() == 3 && !catalog.diagnostics.empty(), "secondary additions or repeated rows dropped");
    check(catalog.entries[1].raw_type == "P" && catalog.entries[1].kind == MediaKind::unknown, "unknown P interpreted");
    check(catalog.entries[1].resolved_path && !catalog.entries[1].diagnostics.empty(), "unknown entry discarded");
    f.write("media/movies.dat", "x.mvp x.mvp M 動画 動画\n");
    f.write("media/audio.dat", "x.mvp x.mvp A 音 音\n");
    catalog = f.load();
    check(catalog.entries.size() == 5 && catalog.entries[3].kind == MediaKind::movie && catalog.entries[4].kind == MediaKind::audio, "movie audio registry");
}
void unresolved() {
    Fixture f;
    f.write("media/images.dat", "x.mvp x.mvp I item title\nmalformed\n");
    f.write("media/x.mvp", ".\\images\\IMAGE.png\n"); f.write("images/image.png", "test");
    auto c = f.load();
    check(c.entries.size() == 2, "malformed entry dropped");
    check(!c.entries[0].resolved_path && !c.entries[0].diagnostics.empty(), "case mismatch silently resolved");
    check(!c.entries[1].diagnostics.empty(), "malformed entry not diagnosed");
    for (const auto *path : {"https://example.invalid/a.png", "C:\\data\\a.png", "../a.png", "/tmp/a.png", "\\\\server\\a.png", ""}) {
        f.write("media/x.mvp", path); c = f.load();
        check(!c.entries[0].resolved_path && !c.entries[0].diagnostics.empty(), "external missing or empty reference accepted");
    }
    f.write("media/x.mvp", ".\\images\\escape.png\n");
    fs::create_symlink("/etc/hosts", f.root / "images/escape.png");
    check(!f.load().entries[0].resolved_path, "symlink escape accepted");
    f.write("media/x.mvp", ".\\images\\directory\n"); fs::create_directory(f.root / "images/directory");
    check(!f.load().entries[0].resolved_path, "directory accepted as media");
    f.write("media/x.mvp", std::string(65537, 'x'));
    check(!f.load().entries[0].resolved_path, "oversize descriptor accepted");
    f.write("media/images.dat", std::string("x\0x", 3));
    c = f.load(); check(c.entries.empty() && !c.diagnostics.empty(), "NUL registry accepted");
    f.write("media/images.dat", std::string(1024 * 1024 + 1, 'x'));
    check(!f.load().diagnostics.empty(), "oversize registry accepted");
    fs::remove(f.root / "media/images.dat");
    check(mkfifo((f.root / "media/images.dat").c_str(), 0600) == 0, "mkfifo fixture");
    check(!f.load().diagnostics.empty(), "FIFO accepted");
}
void classification() {
    for (const auto *name : {"a.JPG", "a.jpeg", "a.PnG"}) check(media_kind_for_extension(name) == MediaKind::image, "image kind");
    for (const auto *name : {"a.mp4", "a.MOV", "a.m4v", "a.avi"}) check(media_kind_for_extension(name) == MediaKind::movie, "movie kind");
    for (const auto *name : {"a.mp3", "a.wav", "a.AIFF", "a.m4a"}) check(media_kind_for_extension(name) == MediaKind::audio, "audio kind");
    for (const auto *name : {"a.m3u8", "a.url", "a.exe", "a", "a.pptx"}) check(media_kind_for_extension(name) == MediaKind::unknown, "unknown kind");
}
}
int main(int argc, char **argv) {
    @autoreleasepool {
        try {
            registrations(); unresolved(); classification();
            if (argc == 2) {
                const auto catalog = load_media_catalog(argv[1]);
                check(catalog.diagnostics.empty(), "real registry diagnostic");
                // 通常版では media 登録自体が任意であり、空の結果も有効。
                std::size_t unresolved_count = 0;
                for (const auto& entry : catalog.entries) { check(!entry.menu_title.empty(), "real title missing"); if (!entry.resolved_path) ++unresolved_count; }
                std::cout << "local entries=" << catalog.entries.size() << " unresolved=" << unresolved_count << '\n';
            }
            std::cout << "media_catalog: " << checks << " checks passed\n"; return 0;
        } catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
    }
}
