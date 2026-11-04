#import "AppController.h"
#include <cstdio>
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
        if (smokeTest && !dataRoot) {
            std::fprintf(stderr, "--smoke-test requires --data-root DIRECTORY\n");
            return 2;
        }
        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        AppController *controller = [[AppController alloc] initWithDataRoot:dataRoot smokeTest:smokeTest];
        app.delegate = controller;
        [app run];
    }
    return 0;
}
