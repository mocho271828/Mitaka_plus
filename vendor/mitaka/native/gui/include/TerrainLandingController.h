#import <Foundation/Foundation.h>
#include "terrain_landing.hpp"

typedef void (^TerrainLandingCompletion)(mitaka::gui::TerrainLandingResult result, NSString *error);

// Main-thread interface. A new request supersedes the running and pending requests.
@interface TerrainLandingController : NSObject
- (void)requestLanding:(mitaka::gui::TerrainLandingRequest)request completion:(TerrainLandingCompletion)completion;
- (void)cancel;
- (void)invalidate;
@end
