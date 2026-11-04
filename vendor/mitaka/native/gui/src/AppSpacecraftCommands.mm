#import "AppControllerInternal.h"

@implementation AppController (SpacecraftCommands)
- (void)showSpacecraftBrowser:(id)sender {
    (void)sender;
    if (!_spacecraftModel || _loading) return;
    if (!_spacecraftBrowser) {
        _spacecraftBrowser = [[SpacecraftController alloc] init];
        __weak AppController *weakSelf = self;
        _spacecraftBrowser.chooseObject = ^(NSUInteger index, BOOL center) {
            [weakSelf chooseSpacecraft:index center:center];
        };
        [_spacecraftBrowser setModel:_spacecraftModel snapshot:_spacecraftSnapshot];
    }
    [_spacecraftBrowser showWindow:nil];
}
- (std::shared_ptr<const SpacecraftSnapshot>)spacecraftSnapshotAtDate:(double)jd {
    if (!_spacecraftModel) return {};
    return evaluate_spacecraft_snapshot(_spacecraftModel, jd);
}
- (void)applySpacecraftSnapshot:(std::shared_ptr<const SpacecraftSnapshot>)snapshot {
    _spacecraftSnapshot = std::move(snapshot);
    [_solar setSpacecraftSnapshot:_spacecraftSnapshot];
    [_spacecraftBrowser setSnapshot:_spacecraftSnapshot];
}
- (void)toggleSpacecraft:(id)sender {
    (void)sender;
    if (!_spacecraftModel || _loading) return;
    _solar.spacecraftVisible = !_solar.spacecraftVisible;
    _mode.selectedSegment = 1;
    [self changeMode:nil];
}
- (void)toggleSpacecraftDisplay:(NSMenuItem *)sender {
    if (!_spacecraftModel || _loading) return;
    auto options = _solar.spacecraftDisplayOptions;
    switch (sender.tag) {
        case 0: options.points = !options.points; break;
        case 1: options.labels = !options.labels; break;
        case 2: options.orbits = !options.orbits; break;
        default: return;
    }
    _solar.spacecraftDisplayOptions = options;
}
- (void)chooseSpacecraft:(NSUInteger)index center:(BOOL)center {
    if (!_spacecraftModel || _loading || index >= _spacecraftModel->model().dataset().definitions.size()) return;
    [_solar selectSpacecraft:index];
    _solar.spacecraftVisible = YES;
    _mode.selectedSegment = 1;
    [self changeMode:nil];
    if (center) [_solar focusSelection];
    [self updateEnabled];
}
@end
