#import "gui_file_io.h"
#include "session_state.hpp"

#include <fcntl.h>
#include <iostream>
#include <stdexcept>
#include <sys/stat.h>
#include <unistd.h>

namespace {
int checks = 0;
void check(bool condition, const char *message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}

struct Fixture {
    NSURL *root;
    Fixture() {
        NSString *pattern = [NSTemporaryDirectory() stringByAppendingPathComponent:@"mitaka-file-io-XXXXXX"];
        std::string path(pattern.fileSystemRepresentation);
        check(mkdtemp(path.data()) != nullptr, "could not create test directory");
        root = [NSURL fileURLWithFileSystemRepresentation:path.c_str() isDirectory:YES relativeToURL:nil];
    }
    ~Fixture() { [NSFileManager.defaultManager removeItemAtURL:root error:nil]; }
    NSURL *url(NSString *path) { return [root URLByAppendingPathComponent:path]; }
    NSURL *directory(NSString *path) {
        NSURL *result = url(path);
        check([NSFileManager.defaultManager createDirectoryAtURL:result withIntermediateDirectories:YES
            attributes:nil error:nil], "could not create fixture directory");
        return result;
    }
    NSURL *file(NSString *path, NSUInteger size = 0) {
        directory(path.stringByDeletingLastPathComponent);
        NSURL *result = url(path);
        check([[NSMutableData dataWithLength:size] writeToURL:result atomically:NO], "could not create fixture file");
        return result;
    }
    void link(NSString *path, NSURL *target) {
        check(symlink(target.fileSystemRepresentation, url(path).fileSystemRepresentation) == 0,
              "could not create fixture symlink");
    }
};

void test_bounded_read(Fixture& fixture) {
    using mitaka::gui::maximum_session_state_bytes;
    NSError *error = nil;
    NSURL *url = fixture.file(@"session.json", maximum_session_state_bytes);
    NSData *data = boundedSessionData(url, &error);
    check(data.length == maximum_session_state_bytes && !error, "exact 1 MiB file was rejected");
    const int fd = open(url.fileSystemRepresentation, O_WRONLY);
    check(fd >= 0, "could not open fixture for resizing");
    check(ftruncate(fd, maximum_session_state_bytes + 1) == 0, "could not resize fixture");
    check(!boundedSessionData(url, &error) && error, "1 MiB+1 file was accepted");
    // サイズの事前検査に依存せず、実readの確保量が巨大な入力でも有界であることを確認する。
    check(ftruncate(fd, static_cast<off_t>(2) * 1024 * 1024 * 1024) == 0, "could not create sparse fixture");
    close(fd);
    check(!boundedSessionData(url, &error) && error, "large sparse file was accepted");
    url = fixture.file(@"empty.json");
    check(boundedSessionData(url, &error) != nil && !error, "empty regular file read failed");
    check(!boundedSessionData(fixture.root, &error) && error, "directory was accepted");
    check(!boundedSessionData(fixture.url(@"missing.json"), &error) && error, "missing file was accepted");
    check(!boundedSessionData([NSURL URLWithString:@"https://example.invalid/session.json"], &error) && error,
          "remote URL was accepted");
    NSURL *fifo = fixture.url(@"pipe.json");
    check(mkfifo(fifo.fileSystemRepresentation, 0600) == 0, "could not create FIFO fixture");
    check(!boundedSessionData(fifo, &error) && error, "FIFO was accepted or blocked");
}

void test_output_guard(Fixture& fixture) {
    NSURL *protectedRoot = fixture.directory(@"selected/source");
    NSArray<NSURL *> *roots = @[protectedRoot];
    check(canWriteUserOutput(fixture.url(@"result.json"), roots), "ordinary external output was rejected");
    check(!canWriteUserOutput(fixture.url(@"result.json"), @[[NSURL fileURLWithPath:@"/"]]),
          "filesystem root protection was bypassed");
    check(!canWriteUserOutput(fixture.url(@"selected/source/result.json"), roots), "selected source accepted output");
    fixture.directory(@"selected/source-sibling");
    check(canWriteUserOutput(fixture.url(@"selected/source-sibling/result.json"), roots), "prefix sibling rejected");
    fixture.link(@"link-to-source", protectedRoot);
    check(!canWriteUserOutput(fixture.url(@"link-to-source/result.json"), roots), "symlink into source accepted");
    NSURL *original = fixture.file(@"selected/source/image.png");
    fixture.link(@"linked-image.png", original);
    check(!canWriteUserOutput(fixture.url(@"linked-image.png"), roots), "symlink to source file accepted");
    check(!canWriteUserOutput(fixture.url(@"selected/source/../source/result.json"), roots), "dot traversal into source accepted");
    if ([NSFileManager.defaultManager fileExistsAtPath:fixture.url(@"SELECTED/SOURCE").path])
        check(!canWriteUserOutput(fixture.url(@"SELECTED/SOURCE/result.json"), roots), "case alias into source accepted");
    check(!canWriteUserOutput(fixture.url(@"missing-parent/result.json"), roots), "unresolved parent accepted");
    check(!canWriteUserOutput([NSURL URLWithString:@"https://example.invalid/result.json"], roots), "remote output accepted");

    // 選択中の原本とは別の、拡張子なしWine bundle・裸のMitaka配置も保護する。
    fixture.file(@"other-plus/Contents/Info.plist");
    fixture.directory(@"other-plus/Contents/Resources");
    check(!canWriteUserOutput(fixture.url(@"other-plus/Contents/Resources/image.png"), roots),
          "inactive original bundle accepted output");
    fixture.directory(@"other.app/assets");
    check(!canWriteUserOutput(fixture.url(@"other.app/assets/image.png"), roots), "app bundle accepted output");
    fixture.file(@"other-data/data/hip.dat");
    fixture.file(@"other-data/data/cf96.dat");
    fixture.directory(@"other-data/textures");
    check(!canWriteUserOutput(fixture.url(@"other-data/textures/image.png"), roots), "inactive data source accepted output");
    fixture.link(@"link-to-other", fixture.url(@"other-data"));
    check(!canWriteUserOutput(fixture.url(@"link-to-other/textures/image.png"), roots), "symlink to inactive data source accepted");
    for (NSString *path in @[@"sources/official", @"sources/reference"]) {
        fixture.directory(path);
        check(!canWriteUserOutput(fixture.url([path stringByAppendingPathComponent:@"image.png"]), roots),
              "preserved source tree accepted output");
    }
}
}

int main() {
    @autoreleasepool {
        try {
            Fixture fixture;
            test_bounded_read(fixture);
            test_output_guard(fixture);
            std::cout << "GUI file I/O: " << checks << " checks passed\n";
            return 0;
        } catch (const std::exception& error) {
            std::cerr << "GUI file I/O: " << error.what() << '\n';
            return 1;
        }
    }
}
