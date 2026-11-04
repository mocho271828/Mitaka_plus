#import "AppControllerInternal.h"
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <stdexcept>

namespace {
NSView *smallBodyControl(NSView *root, bool (^matches)(NSView *)) {
    if (matches(root)) return root;
    for (NSView *child in root.subviews)
        if (NSView *found = smallBodyControl(child, matches)) return found;
    return nil;
}
bool sameSmallBodyPosition(mitaka::Vec3 a, mitaka::Vec3 b) {
    return std::hypot(a.x-b.x, a.y-b.y, a.z-b.z) < 1e-11;
}
}

@implementation AppController (SmallBodySmokeTests)
- (void)runSmallBodySmokeTestWithCompletion:(void (^)(void))completion {
    const auto checks = std::make_shared<unsigned>(0);
    const auto require = [checks](bool condition, const char *message) {
        ++*checks;
        if (!condition) throw std::runtime_error(message);
    };
    require(_smallBodyModel && _smallBodySnapshot && _smallBodySnapshot->model == _smallBodyModel,
            "small-body source and snapshot were not loaded together");
    const SessionState saved = [self sessionState];
    const auto source = _smallBodyModel;
    const auto selected = _solar.selectedSmallBodyIndex;
    const BOOL browserVisible = _smallBodyBrowser.window.isVisible;
    const auto rowCount = source->dataset().records.size();
    [self showSmallBodyBrowser:nil];
    NSView *root = _smallBodyBrowser.window.contentView;
    NSSearchField *search = (NSSearchField *)smallBodyControl(root, ^bool(NSView *view) {
        return [view isKindOfClass:NSSearchField.class];
    });
    NSPopUpButton *kind = (NSPopUpButton *)smallBodyControl(root, ^bool(NSView *view) {
        return [view isKindOfClass:NSPopUpButton.class];
    });
    NSTableView *table = (NSTableView *)smallBodyControl(root, ^bool(NSView *view) {
        return [view isKindOfClass:NSTableView.class];
    });
    NSTextField *count = (NSTextField *)smallBodyControl(root, ^bool(NSView *view) {
        return [view.accessibilityIdentifier isEqualToString:@"small-body-result-count"];
    });
    NSButton *choose = (NSButton *)smallBodyControl(root, ^bool(NSView *view) {
        return [view isKindOfClass:NSButton.class] && [((NSButton *)view).title isEqualToString:@"選択・診断を表示"];
    });
    require(search && kind && table && count && choose, "small-body application browser controls are missing");
    search.stringValue = @"";
    [kind selectItemAtIndex:0];
    require([search sendAction:search.action to:search.target], "small-body search action was not dispatched");
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:5];
    // メインキュー内で待機すると検索完了の反映を妨げるため、run loopへ制御を返す。
    [NSTimer scheduledTimerWithTimeInterval:0.01 repeats:YES block:^(NSTimer *timer) {
    if ([count.stringValue containsString:@"検索中"] && deadline.timeIntervalSinceNow > 0) return;
    [timer invalidate];
    try {
    require([count.stringValue containsString:[NSString stringWithFormat:@"該当 %zu 件", rowCount]] &&
            table.numberOfRows == static_cast<NSInteger>(std::min(rowCount, std::size_t{500})),
            "small-body browser did not search every original row with a bounded page");
    if (rowCount) {
        [table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        require(choose.enabled && [choose sendAction:choose.action to:choose.target],
                "small-body browser selection callback was not dispatched");
        require(_mode.selectedSegment == 1 && _solar.selectedSmallBodyIndex == 0 &&
                _solar.selectedBodyIndex == NSNotFound && _smallBodySnapshot->evaluated_all,
                "small-body browser selection did not reach the solar view");
        require([_selectionLabel.stringValue containsString:[NSString stringWithUTF8String:source->title(0).c_str()]] &&
                !_travelButtons[1].enabled && !_journeyButton.enabled,
                "small-body selection lost its diagnosis or enabled unsupported surface travel");
    } else require(!choose.enabled, "empty local small-body dataset enabled row selection");

    _solar.smallBodiesVisible = YES;
    _mode.selectedSegment = 1;
    [self changeMode:nil];
    require(_smallBodySnapshot->evaluated_all && _smallBodySnapshot->positions.size() == rowCount,
            "small-body display dropped original rows from its snapshot");
    std::optional<std::size_t> positioned, unresolved;
    for (std::size_t index = 0; index < rowCount; ++index) {
        if (_smallBodySnapshot->positions[index] && !positioned) positioned = index;
        if (!_smallBodySnapshot->positions[index] && !unresolved) unresolved = index;
    }
    if (positioned) {
        [self chooseSmallBody:*positioned center:YES];
        require(sameSmallBodyPosition([_solar cameraState].target, *_smallBodySnapshot->positions[*positioned]) &&
                _solar.visibleSmallBodyCount > 0, "small-body focus disagrees with the core heliocentric position");
        const auto range = _model->time_range();
        const double nextDate = _jd < range.second ? std::min(_jd + 0.25, range.second) : range.first;
        require([self updateDate:nextDate refreshOrbits:NO] && _smallBodySnapshot->julian_date == _jd &&
                _horizon.julianDate == _jd && _smallBodySnapshot->positions.size() == rowCount,
                "small-body date update disagrees with the shared scene date");
        require(_solar.selectedSmallBodyIndex == *positioned && _smallBodySnapshot->positions[*positioned] &&
                sameSmallBodyPosition([_solar cameraState].target, *_smallBodySnapshot->positions[*positioned]),
                "small-body following camera did not update at the new date");
    }
    if (unresolved) {
        const auto camera = [_solar cameraState];
        [self chooseSmallBody:*unresolved center:YES];
        const auto after = [_solar cameraState];
        require(_solar.selectedSmallBodyIndex == *unresolved && sameSmallBodyPosition(camera.target, after.target) &&
                camera.distance_au == after.distance_au && camera.yaw_deg == after.yaw_deg && camera.pitch_deg == after.pitch_deg,
                "unresolved small-body focus changed the existing camera");
        require([_selectionLabel.stringValue containsString:@"位置を表示できません"],
                "unresolved small-body selection did not expose its diagnosis");
    }
    const auto beforeInvalid = _solar.selectedSmallBodyIndex;
    [self chooseSmallBody:rowCount center:YES];
    require(_solar.selectedSmallBodyIndex == beforeInvalid, "invalid small-body selection changed the application state");
    [self toggleSmallBodies:nil];
    require(!_solar.smallBodiesVisible && !_smallBodySnapshot->evaluated_all &&
            _smallBodySnapshot->positioned_count <= 1 && _solar.visibleSmallBodyCount == 0,
            "hidden small bodies retained full catalog evaluation or drawing");
    [self toggleSmallBodies:nil];
    require(_solar.smallBodiesVisible && _smallBodySnapshot->evaluated_all &&
            _smallBodyModel == source && source->dataset().records.size() == rowCount,
            "small-body display toggle replaced or truncated the source catalog");

    require([self applySessionState:saved], "small-body smoke could not restore the previous session");
    if (selected < rowCount) [_solar selectSmallBody:selected];
    [self refreshSmallBodies];
    require(encode_session_state([self sessionState]) == encode_session_state(saved) &&
            _solar.selectedSmallBodyIndex == selected, "small-body smoke changed the original application state");
    if (!browserVisible) [_smallBodyBrowser close];
    std::printf("Small-body AppKit smoke passed: %u checks; source_rows=%zu evaluable=%zu focus=%s diagnosis=%s\n",
        *checks, rowCount, source->evaluable_indices().size(), positioned ? "tested" : "no-local-position",
        unresolved ? "tested" : "no-unresolved-row");
    completion();
    } catch (const std::exception& error) {
        std::fprintf(stderr, "Small-body AppKit smoke failed: %s (search=%s, displayed_rows=%ld)\n",
            error.what(), count.stringValue.UTF8String, static_cast<long>(table.numberOfRows));
        std::exit(EXIT_FAILURE);
    }
    }];
}
@end
