#import <Foundation/Foundation.h>
#import "ScriptController.h"
#include "script_object_identity.hpp"
#include <stdexcept>
#include <string>
using namespace mitaka;
using namespace mitaka::gui;
static void require(bool ok, const char *reason) { if (!ok) throw std::runtime_error(reason); }
int main(int argc, const char *argv[]) {
    @autoreleasepool {
        try {
            require(argc == 2, "helper path required");
            __block SmallBodyDataset bodies;
            SmallBodyRecord asteroid; asteroid.kind = SmallBodyKind::asteroid; asteroid.number = 1; asteroid.name_bytes = "Ceres";
            SmallBodyRecord comet; comet.kind = SmallBodyKind::comet; comet.name_bytes = "星";
            SmallBodyRecord longComet; longComet.kind = SmallBodyKind::comet; longComet.name_bytes = std::string(4089, 'x');
            SmallBodyRecord overlong; overlong.kind = SmallBodyKind::comet; overlong.name_bytes = std::string(4090, 'x');
            bodies.records = {asteroid, comet, longComet, overlong};
            __block SpacecraftDataset ships;
            SpacecraftDefinition ship; ship.fields.push_back({"KEY", "voyager", 0, 0, 0, {}});
            ship.fields.push_back({"NAME", "Voyager", 0, 0, 0, "default"});
            ship.fields.push_back({"NAME", "Duplicate", 0, 0, 0, "ja"});
            ships.definitions.push_back(ship);
            SpacecraftDefinition twin; twin.fields.push_back({"KEY", "twin", 0, 0, 0, {}});
            twin.fields.push_back({"NAME", "Duplicate", 0, 0, 0, "ja"});
            ships.definitions.push_back(twin);
            __block ScriptSnapshot state;
            __block std::optional<std::size_t> bodyIndex, shipIndex;
            __block std::string previousBody, previousShip;
            ScriptController *controller = [[ScriptController alloc] initWithHelperURL:[NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]]];
            controller.snapshot = ^ScriptSnapshot {
                ScriptSnapshot result = state;
                if (bodyIndex) result.target = smallBodySnapshotTarget(&bodies, *bodyIndex, bodyIndex, previousBody);
                else if (shipIndex) result.target = spacecraftSnapshotTarget(&ships, *shipIndex, shipIndex, previousShip);
                return result;
            };
            controller.applyAction = ^BOOL(const ScriptAction& action, NSString **error) {
                if (action.kind != ScriptActionKind::select_target) { *error = @"Unexpected action"; return NO; }
                try {
                    if (const auto index = resolveScriptSmallBody(action.text, bodies)) {
                        bodyIndex = *index; shipIndex.reset(); previousBody = action.text;
                    } else if (action.text.compare(0, 11, "Spacecraft.") == 0) {
                        shipIndex = resolveScriptSpacecraft(action.text, ships); bodyIndex.reset(); previousShip = action.text;
                    } else throw std::invalid_argument("unsupported target");
                    return YES;
                } catch (const std::invalid_argument& e) { *error = [NSString stringWithUTF8String:e.what()]; return NO; }
            };
            __block bool finished = false, succeeded = false;
            __block NSString *failure = nil;
            controller.completion = ^(BOOL ok, NSString *message) { succeeded = ok; failure = message; finished = true; };
            NSError *error = nil;
            NSString *source = @R"lua(
                Camera.target='Asteroids.1'; assert(Camera.target=='Asteroids.1')
                Camera.target='Spacecraft.voyager'; assert(Camera.target=='Spacecraft.voyager')
                Camera.target='Spacecraft.Voyager'; assert(Camera.target=='Spacecraft.Voyager')
                Camera.target='Comet.星'; assert(Camera.target=='Comet.星')
                local large='Comet.'..string.rep('x', 4089)
                Camera.target=large; assert(Camera.target==large and #Camera.target==4095)
                local ok=pcall(function() Camera.target='Spacecraft.unknown' end); assert(not ok)
                assert(Camera.target==large)
                local ambiguous=pcall(function() Camera.target='Spacecraft.Duplicate' end); assert(not ambiguous)
                assert(Camera.target==large)
                local tooLong=pcall(function() Camera.target='Comet.'..string.rep('x',4090) end); assert(not tooLong)
                assert(Camera.target==large)
            )lua";
            require([controller runSource:source error:&error], error ? error.localizedDescription.UTF8String : "launch failed");
            const auto deadline = [NSDate dateWithTimeIntervalSinceNow:10];
            while (!finished && deadline.timeIntervalSinceNow > 0)
                [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];
            require(finished, "timeout"); require(succeeded, failure ? failure.UTF8String : "script failed");
            std::puts("Lua target integration passed"); return 0;
        } catch (const std::exception& e) { std::fprintf(stderr, "%s\n", e.what()); return 1; }
    }
}
