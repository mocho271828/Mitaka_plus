#import "RadiusDisplayController.h"
#include <array>
#include <cmath>
#include <cstdio>
#include <limits>
#include <stdexcept>

using namespace mitaka::gui;
namespace {
int checks = 0;
void check(bool condition, const char *message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
bool same(const RadiusDisplayOptions& a, const RadiusDisplayOptions& b) {
    return a.space_planet == b.space_planet && a.space_sun == b.space_sun &&
        a.planetarium_planet == b.planetarium_planet && a.planetarium_sun_moon == b.planetarium_sun_moon;
}
}

int main() {
    @autoreleasepool {
        try {
            RadiusDisplayController *controller = [[RadiusDisplayController alloc] init];
            NSString *error = nil;
            check(!controller.isWindowLoaded, "construction does not create a window");
            check(![controller reloadSettingsWithError:&error] && error.length, "missing read callback is an error");
            NSArray<NSString *> *valid = @[@"500", @"1", @"20", @"1"];
            check(![controller applyFieldValues:valid mode:1 error:&error] && error.length, "missing apply callback is an error");
            __block RadiusDisplayOptions state{1, 2, 3, 4};
            __block RadiusScaleMode stateMode = RadiusScaleMode::keep_orbit;
            __block NSUInteger reads = 0, writes = 0;
            controller.readSettings = ^BOOL(RadiusDisplayOptions *options, RadiusScaleMode *mode, NSString **) {
                ++reads;
                *options = state; *mode = stateMode; return YES;
            };
            controller.applySettings = ^BOOL(RadiusDisplayOptions options, RadiusScaleMode mode, NSString **) {
                ++writes; state = options; stateMode = mode; return YES;
            };
            check([controller reloadSettingsWithError:&error] && !error, "latest host snapshot is accepted");
            check(reads == 1 && writes == 0, "reload only reads");
            check([controller applyFieldValues:valid mode:1 error:&error] && !error, "valid four values apply");
            check(writes == 1 && same(state, {500, 1, 20, 1}) && stateMode == RadiusScaleMode::keep_orbit,
                "binary order is retained in one host callback");
            check([controller applyFieldValues:@[@" 1.5 ", @"2e1", @"+3", @".5"] mode:0 error:&error],
                "decimal exponent plus and surrounding whitespace are accepted");
            check(writes == 2 && same(state, {1.5f, 20, 3, .5f}) && stateMode == RadiusScaleMode::keep_radius,
                "keep radius mode is passed to host without camera emulation");
            const RadiusDisplayOptions retained = state;
            const NSUInteger count = writes;
            NSArray<NSString *> *invalid = @[@"", @" ", @"0", @"-1", @"NaN", @"Infinity", @"1e1000",
                @"1e-1000", @"1e40", @"1e-50", @"2x", @"1 2", @"1,000", @"2.3.4", @"1\0x"];
            for (NSUInteger index = 0; index < 4; ++index) {
                for (NSString *input in invalid) {
                    NSMutableArray<NSString *> *values = [valid mutableCopy]; values[index] = input;
                    check(![controller applyFieldValues:values mode:1 error:&error] && error.length,
                        "invalid numeric input rejects before host call");
                    check(writes == count && same(state, retained) && stateMode == RadiusScaleMode::keep_radius,
                        "invalid field leaves all host values unchanged");
                }
            }
            NSString *longInput = [@"1" stringByPaddingToLength:129 withString:@"0" startingAtIndex:0];
            check(![controller applyFieldValues:@[longInput, @"1", @"1", @"1"] mode:0 error:&error], "input size is bounded");
            for (NSArray<NSString *> *values in @[@[], @[@"1"], @[@"1", @"2", @"3"], @[@"1", @"2", @"3", @"4", @"5"]])
                check(![controller applyFieldValues:values mode:1 error:&error], "arity is exact");
            for (NSInteger mode : {-1, 2, 100})
                check(![controller applyFieldValues:valid mode:mode error:&error], "unknown mode is rejected");
            check(writes == count, "all structural errors avoid host calls");
            NSArray<NSString *> *extremes = @[
                [NSString stringWithFormat:@"%.17g", static_cast<double>(std::numeric_limits<float>::max())],
                [NSString stringWithFormat:@"%.17g", static_cast<double>(std::numeric_limits<float>::denorm_min())], @"1", @"1"];
            check([controller applyFieldValues:extremes mode:1 error:&error], "finite float endpoints are accepted");
            check(state.space_planet == std::numeric_limits<float>::max() &&
                state.space_sun == std::numeric_limits<float>::denorm_min(), "endpoint float values survive parsing");
            check([controller reloadSettingsWithError:&error] && reads == 2, "reload reads current values again");
            state.space_planet = 0;
            check(![controller reloadSettingsWithError:&error] && error.length, "invalid host options are rejected");
            state.space_planet = 1; stateMode = static_cast<RadiusScaleMode>(2);
            check(![controller reloadSettingsWithError:&error] && error.length, "invalid host mode is rejected");
            stateMode = RadiusScaleMode::keep_orbit;
            const RadiusDisplayOptions beforeFailure = state;
            controller.applySettings = ^BOOL(RadiusDisplayOptions, RadiusScaleMode, NSString **failure) {
                ++writes; *failure = @"camera guard rejected"; return NO;
            };
            check(![controller applyFieldValues:valid mode:0 error:&error] && [error isEqualToString:@"camera guard rejected"],
                "host camera refusal is preserved");
            check(same(state, beforeFailure) && stateMode == RadiusScaleMode::keep_orbit, "host refusal does not emulate application");
            __weak RadiusDisplayController *weakController = controller;
            __block BOOL nestedApply = YES, nestedRead = YES;
            controller.applySettings = ^BOOL(RadiusDisplayOptions, RadiusScaleMode, NSString **) {
                ++writes;
                nestedApply = [weakController applyFieldValues:valid mode:1 error:nullptr];
                nestedRead = [weakController reloadSettingsWithError:nullptr];
                return YES;
            };
            const NSUInteger beforeReentry = writes;
            check([controller applyFieldValues:valid mode:1 error:&error], "outer host operation succeeds");
            check(!nestedApply && !nestedRead && writes == beforeReentry + 1, "callback reentry is refused");
            __block BOOL backgroundApply = YES, backgroundRead = YES;
            dispatch_semaphore_t finished = dispatch_semaphore_create(0);
            dispatch_async(dispatch_queue_create("org.mitaka.radius-test", DISPATCH_QUEUE_SERIAL), ^{
                @autoreleasepool {
                    backgroundApply = [controller applyFieldValues:valid mode:1 error:nullptr];
                    backgroundRead = [controller reloadSettingsWithError:nullptr];
                    dispatch_semaphore_signal(finished);
                }
            });
            check(dispatch_semaphore_wait(finished, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC)) == 0,
                "background rejection finishes within budget");
            check(!backgroundApply && !backgroundRead && writes == beforeReentry + 1, "off-main operations do not invoke host");
            check(!controller.isWindowLoaded, "validation and callback tests never create a window");
            std::printf("radius display controller: %d checks passed (no window)\n", checks);
        } catch (const std::exception& exception) {
            std::fprintf(stderr, "radius display controller test failed: %s\n", exception.what()); return 1;
        }
    }
    return 0;
}
