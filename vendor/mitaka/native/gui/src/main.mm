#import "AppController.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSString *dataRoot = nil;
        BOOL smokeTest = NO;
        for (int index = 1; index < argc; ++index) {
            if (std::strcmp(argv[index], "--data-root") == 0 && index + 1 < argc) {
                ++index;
                dataRoot = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:argv[index]
                    length:std::strlen(argv[index])];
            } else if (std::strcmp(argv[index], "--smoke-test") == 0) smokeTest = YES;
            else {
                std::fprintf(stderr, "Usage: MitakaNative [--data-root DIRECTORY] [--smoke-test]\n");
                return 2;
            }
        }
        if (!dataRoot) {
            // ビルド済みアプリからリポジトリ内の版固有データを探す。
            NSURL *repository = NSBundle.mainBundle.bundleURL;
            for (int index = 0; index < 4; ++index) repository = repository.URLByDeletingLastPathComponent;
            NSString *candidate = [repository.path stringByAppendingPathComponent:@"resources/mitaka/data"];
            NSFileManager *files = NSFileManager.defaultManager;
            if ([files fileExistsAtPath:[candidate stringByAppendingPathComponent:@"hip.dat"]] &&
                [files fileExistsAtPath:[candidate stringByAppendingPathComponent:@"cf96.dat"]]) dataRoot = candidate;
        }
        if (smokeTest && !dataRoot) {
            std::fprintf(stderr, "--smoke-test requires --data-root DIRECTORY\n");
            return 2;
        }
        if (smokeTest) {
            // ログをリダイレクトしても、完了した段階をその場で確認できるようにする。
            std::setvbuf(stdout, nullptr, _IOLBF, 0);
            // 初期読込も含めて監視する。メインスレッド停止時にも失敗を通知する。
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 300LL * NSEC_PER_SEC),
                dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
                    std::fprintf(stderr, "AppKit smoke timed out after 300 seconds\n");
                    std::fflush(stderr);
                    std::_Exit(EXIT_FAILURE);
                });
        }
        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        AppController *controller = [[AppController alloc] initWithDataRoot:dataRoot smokeTest:smokeTest];
        app.delegate = controller;
        [app run];
    }
    return 0;
}
