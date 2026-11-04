#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>
#include <stdio.h>

int main(void) {
    @autoreleasepool {
        NSArray *readers = CFBridgingRelease(CGImageSourceCopyTypeIdentifiers());
        NSArray *writers = CFBridgingRelease(CGImageDestinationCopyTypeIdentifiers());
        for (NSString *type in @[@"public.jpeg", @"public.png", @"com.microsoft.bmp", @"com.truevision.tga-image"])
            printf("%s reader=%s writer=%s\n", type.UTF8String,
                [readers containsObject:type] ? "YES" : "NO", [writers containsObject:type] ? "YES" : "NO");
    }
    return 0;
}
