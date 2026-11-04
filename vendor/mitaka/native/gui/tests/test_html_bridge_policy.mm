#include "html_bridge_policy.hpp"

#include <fcntl.h>
#include <iostream>
#include <stdexcept>
#include <sys/stat.h>
#include <unistd.h>

using namespace mitaka::gui;
namespace {
int checks = 0;
void check(bool value, const char *message) {
    ++checks;
    if (!value) throw std::runtime_error(message);
}
template<class Action> void rejects(Action action, const char *message) {
    bool failed = false;
    try { action(); }
    catch (const std::invalid_argument&) { failed = true; }
    catch (const std::runtime_error&) { failed = true; }
    check(failed, message);
}
struct Fixture {
    NSURL *root;
    Fixture() {
        std::string path([NSTemporaryDirectory() stringByAppendingPathComponent:@"mitaka-html-XXXXXX"].fileSystemRepresentation);
        check(mkdtemp(path.data()) != nullptr, "could not create fixture");
        root = [NSURL fileURLWithFileSystemRepresentation:path.c_str() isDirectory:YES relativeToURL:nil];
    }
    ~Fixture() { [NSFileManager.defaultManager removeItemAtURL:root error:nil]; }
    NSURL *url(NSString *name) { return [root URLByAppendingPathComponent:name]; }
    NSURL *file(NSString *name, NSString *text = @"<p>trusted</p>") {
        NSURL *result = url(name);
        check([[text dataUsingEncoding:NSUTF8StringEncoding] writeToURL:result atomically:NO], "fixture write failed");
        return result;
    }
};
HtmlBridgeRequest request(NSURL *url, NSString *script = @"mtkp://Camera.zoom = 0.001; Stars.visible=true;") {
    return {script, url, url, true, true, true, true};
}
void test_file_identity(Fixture& fixture) {
    NSURL *file = fixture.file(@"日本語 panel.html");
    const auto snapshot = read_html_document(file);
    check([snapshot.data isEqualToData:[@"<p>trusted</p>" dataUsingEncoding:NSUTF8StringEncoding]], "snapshot bytes differ from identity read");
    const auto identity = snapshot.identity;
    check(!identity.canonical_path.empty() && identity.inode != 0, "identity missing");
    NSURL *alias = fixture.url(@"alias.htm");
    check(symlink(file.fileSystemRepresentation, alias.fileSystemRepresentation) == 0, "symlink failed");
    check(inspect_html_document(alias).canonical_path == identity.canonical_path, "symlink not canonicalized");
    NSURL *dot = [NSURL fileURLWithPath:[fixture.root.path stringByAppendingString:@"/./日本語 panel.html"]];
    check(inspect_html_document(dot).canonical_path == identity.canonical_path, "dot path not normalized");
    rejects([&] { inspect_html_document(nil); }, "nil accepted");
    rejects([&] { inspect_html_document([NSURL URLWithString:@"https://example.invalid/a.html"]); }, "online accepted");
    rejects([&] { inspect_html_document([NSURL URLWithString:@"file://remote.invalid/a.html"]); }, "file host accepted");
    rejects([&] { inspect_html_document([NSURL URLWithString:[file.absoluteString stringByAppendingString:@"?x=1"]]); }, "query accepted");
    rejects([&] { inspect_html_document([NSURL URLWithString:[file.absoluteString stringByAppendingString:@"#anchor"]]); }, "fragment accepted");
    rejects([&] { inspect_html_document([NSURL URLWithString:[file.absoluteString stringByAppendingString:@"%00.html"]]); }, "NUL path accepted");
    rejects([&] { inspect_html_document(fixture.url(@"missing.html")); }, "missing accepted");
    rejects([&] { inspect_html_document(fixture.file(@"code.lua")); }, "non-HTML extension accepted");
    NSURL *directory = fixture.url(@"directory.html");
    check([NSFileManager.defaultManager createDirectoryAtURL:directory withIntermediateDirectories:NO attributes:nil error:nil], "directory fixture failed");
    rejects([&] { inspect_html_document(directory); }, "directory accepted");
    NSURL *fifo = fixture.url(@"fifo.html");
    check(mkfifo(fifo.fileSystemRepresentation, 0600) == 0, "FIFO fixture failed");
    rejects([&] { inspect_html_document(fifo); }, "FIFO accepted");
    NSURL *large = fixture.file(@"large.html");
    int fd = open(large.fileSystemRepresentation, O_WRONLY);
    check(fd >= 0 && ftruncate(fd, html_document_limit) == 0, "limit fixture failed");
    check(!inspect_html_document(large).canonical_path.empty(), "exact document limit rejected");
    check(ftruncate(fd, static_cast<off_t>(2) * 1024 * 1024 * 1024) == 0, "sparse fixture failed");
    close(fd);
    rejects([&] { inspect_html_document(large); }, "large document accepted");
}
void test_origin_and_navigation(Fixture& fixture) {
    NSURL *file = fixture.file(@"origin.html");
    const auto identity = inspect_html_document(file);
    HtmlBridgePolicy policy;
    check(policy.evaluate(request(file)).disposition == HtmlBridgeDisposition::rejected, "untrusted source ran");
    policy.trust(identity);
    auto result = policy.evaluate(request(file));
    check(result.disposition == HtmlBridgeDisposition::script && result.script == "Camera.zoom = 0.001; Stars.visible=true;", "original example changed");
    for (int flag = 0; flag < 4; ++flag) {
        auto item = request(file);
        if (flag == 0) item.source_main_frame = false;
        if (flag == 1) item.target_main_frame = false;
        if (flag == 2) item.has_target_frame = false;
        if (flag == 3) item.link_activated = false;
        check(policy.evaluate(item).disposition == HtmlBridgeDisposition::rejected, "frame/new window/programmatic call ran");
    }
    NSURL *other = fixture.file(@"other.html");
    for (NSURL *source in @[other, [NSURL URLWithString:@"https://example.invalid/a.html"], [NSURL URLWithString:@"about:blank"]]) {
        policy.trust(identity);
        auto item = request(file);
        item.source_url = source;
        check(policy.evaluate(item).disposition == HtmlBridgeDisposition::rejected && !policy.trusted(), "foreign source retained trust");
    }
    policy.trust(identity);
    auto item = request(file);
    item.document_url = other;
    check(policy.evaluate(item).disposition == HtmlBridgeDisposition::rejected && !policy.trusted(), "different top document accepted");
    for (NSString *destination in @[file.absoluteString, other.absoluteString, @"https://example.invalid/", @"about:blank", @"javascript:void(0)"]) {
        policy.trust(identity);
        check(policy.evaluate(request(file, destination)).disposition == HtmlBridgeDisposition::navigation && !policy.trusted(), "normal navigation retained trust");
        // 遷移先を UI が取り消して旧ページが残っても、失効した承認は復活しない。
        check(policy.evaluate(request(file)).disposition == HtmlBridgeDisposition::rejected, "cancelled navigation resurrected trust");
    }
    policy.trust(identity);
    policy.revoke();
    check(!policy.trusted(), "explicit revoke failed");
}
void test_content_change(Fixture& fixture) {
    NSURL *file = fixture.file(@"changes.html", @"<p>aaaa</p>");
    HtmlBridgePolicy policy;
    const auto identity = inspect_html_document(file);
    policy.trust(identity);
    struct stat original;
    check(stat(file.fileSystemRepresentation, &original) == 0, "stat fixture failed");
    fixture.file(@"changes.html", @"<p>bbbb</p>");
    struct timespec times[] = {original.st_atimespec, original.st_mtimespec};
    check(utimensat(AT_FDCWD, file.fileSystemRepresentation, times, 0) == 0, "mtime restore failed");
    check(inspect_html_document(file).inode == identity.inode, "fixture unexpectedly replaced inode");
    check(policy.evaluate(request(file)).disposition == HtmlBridgeDisposition::rejected && !policy.trusted(), "same-size content edit retained trust");
    policy.trust(inspect_html_document(file));
    NSURL *replacement = fixture.file(@"replacement.html", @"<p>bbbb</p>");
    check(rename(replacement.fileSystemRepresentation, file.fileSystemRepresentation) == 0, "replace failed");
    check(policy.evaluate(request(file)).disposition == HtmlBridgeDisposition::rejected, "replacement inode retained trust");
    NSURL *link = fixture.url(@"moving.html");
    check(symlink(file.fileSystemRepresentation, link.fileSystemRepresentation) == 0, "moving symlink failed");
    policy.trust(inspect_html_document(link));
    check(unlink(link.fileSystemRepresentation) == 0, "unlink failed");
    NSURL *other = fixture.file(@"moving-target.html", @"<p>bbbb</p>");
    check(symlink(other.fileSystemRepresentation, link.fileSystemRepresentation) == 0, "retarget failed");
    check(policy.evaluate(request(link)).disposition == HtmlBridgeDisposition::rejected, "retargeted symlink retained trust");
}
void test_payload(Fixture& fixture) {
    NSURL *file = fixture.file(@"payload.html");
    const auto identity = inspect_html_document(file);
    HtmlBridgePolicy policy;
    for (NSArray<NSString *> *pair in @[
        @[@"mtkp://Time%3AsetTime(2009,7,22,0,30,0);Time.speed=0;", @"Time:setTime(2009,7,22,0,30,0);Time.speed=0;"],
        @[@"MTKP://print('a+b')", @"print('a+b')"],
        @[@"mtkp://print('%2520')", @"print('%20')"],
        @[@"mtkp://print('%E6%97%A5%E6%9C%AC%E8%AA%9E')", @"print('日本語')"],
        @[@"mtkp://dofile('ui/scripts/eclipse_20090722.lua');", @"dofile('ui/scripts/eclipse_20090722.lua');"]]) {
        policy.trust(identity);
        auto result = policy.evaluate(request(file, pair[0]));
        check(result.disposition == HtmlBridgeDisposition::script && result.script == pair[1].UTF8String, "payload changed");
    }
    for (NSString *invalid in @[@"mtkp://", @"mtkp:/print(1)", @"mtkp://%", @"mtkp://%0", @"mtkp://%GG", @"mtkp://%FF", @"mtkp://%C0%AF", @"mtkp://%00"]) {
        policy.trust(identity);
        auto result = policy.evaluate(request(file, invalid));
        check(result.disposition == HtmlBridgeDisposition::rejected && result.script.empty() && !result.error.empty(), "invalid payload accepted");
    }
    NSString *limit = [@"" stringByPaddingToLength:html_script_limit withString:@"x" startingAtIndex:0];
    policy.trust(identity);
    check(policy.evaluate(request(file, [@"mtkp://" stringByAppendingString:limit])).script.size() == html_script_limit, "exact payload limit rejected");
    policy.trust(identity);
    check(policy.evaluate(request(file, [[@"mtkp://" stringByAppendingString:limit] stringByAppendingString:@"x"])).disposition == HtmlBridgeDisposition::rejected, "oversize payload accepted");
    NSString *encoded = [@"" stringByPaddingToLength:html_script_limit * 3 withString:@"%78" startingAtIndex:0];
    policy.trust(identity);
    check(policy.evaluate(request(file, [@"mtkp://" stringByAppendingString:encoded])).script.size() == html_script_limit, "exact encoded limit rejected");
    policy.trust(identity);
    check(policy.evaluate(request(file, [[@"mtkp://" stringByAppendingString:encoded] stringByAppendingString:@"%78"])).disposition == HtmlBridgeDisposition::rejected, "oversize encoded URL accepted");
}
}
int main() {
    @autoreleasepool {
        try {
            Fixture fixture;
            test_file_identity(fixture);
            test_origin_and_navigation(fixture);
            test_content_change(fixture);
            test_payload(fixture);
            std::cout << "html bridge policy: " << checks << " checks passed\n";
            return 0;
        } catch (const std::exception& error) {
            std::cerr << "html bridge policy: " << error.what() << '\n';
            return 1;
        }
    }
}
