#import <AppKit/AppKit.h>

@interface AppController : NSObject <NSApplicationDelegate, NSWindowDelegate>
- (instancetype)initWithDataRoot:(NSString *)path smokeTest:(BOOL)smokeTest;
@end
