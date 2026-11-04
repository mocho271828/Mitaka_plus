#import "AppControllerInternal.h"
#include <limits>
#include <stdexcept>

@implementation AppController (StarNameCommands)
- (const std::set<std::int32_t>&)selectedStarNameHIPs {
    static const std::set<std::int32_t> empty;
    return _starNameSelection ? _starNameSelection->selected_hips() : empty;
}
- (void)setSelectedStarNameHIPs:(const std::set<std::int32_t>&)hips {
    if (!_starNameSelection) throw std::invalid_argument("star name catalog is not loaded");
    _starNameSelection->set_selection(hips);
    [_sky setSelectedStarNameHIPs:hips];
    [_horizon setSelectedStarNameHIPs:hips];
    [_browser refreshConstellationVisibility];
}
- (void)setStarNameMembership:(const std::vector<std::int32_t>&)hips selected:(BOOL)selected {
    if (!_starNameSelection) throw std::invalid_argument("star name catalog is not loaded");
    auto next = *_starNameSelection;
    next.set_selected(hips, selected);
    [self setSelectedStarNameHIPs:next.selected_hips()];
}
- (void)setAllStarNamesSelected:(BOOL)selected {
    if (!_starNameSelection) return;
    [self setSelectedStarNameHIPs:selected ? _starNameSelection->known_hips() : std::set<std::int32_t>{}];
}
- (void)rebindStarNameSelection {
    if (!_extendedCatalogs) return;
    if (_starNameSelection) {
        const auto report = _starNameSelection->rebind(_extendedCatalogs->star_names);
        if (!report.removed_selected_hips.empty())
            _sky.toolTip = [NSString stringWithFormat:@"再読込で消失した恒星名の選択を %zu 件解除しました。",
                report.removed_selected_hips.size()];
    } else _starNameSelection = std::make_unique<StarNameSelection>(_extendedCatalogs->star_names);
    [self setSelectedStarNameHIPs:_starNameSelection->selected_hips()];
}
- (void)configureStarNameBrowser {
    __weak AppController *weakSelf = self;
    _browser.starNameSelectable = ^BOOL(NSInteger hip) {
        AppController *controller = weakSelf;
        return controller && controller->_starNameSelection && hip > 0 &&
            hip <= std::numeric_limits<std::int32_t>::max() &&
            controller->_starNameSelection->known_hips().count(static_cast<std::int32_t>(hip)) != 0;
    };
    _browser.starNameSelected = ^BOOL(NSInteger hip) {
        AppController *controller = weakSelf;
        return controller && controller->_starNameSelection && hip > 0 &&
            hip <= std::numeric_limits<std::int32_t>::max() &&
            controller->_starNameSelection->membership(static_cast<std::int32_t>(hip));
    };
    _browser.setStarNameSelected = ^(NSInteger hip, BOOL selected) {
        AppController *controller = weakSelf;
        if (!controller || controller->_loading || !controller->_browser.starNameSelectable(hip)) return;
        [controller setStarNameMembership:{static_cast<std::int32_t>(hip)} selected:selected];
    };
    _browser.setAllStarNamesSelected = ^(BOOL selected) {
        AppController *controller = weakSelf;
        if (controller && !controller->_loading) [controller setAllStarNamesSelected:selected];
    };
    [_browser refreshConstellationVisibility];
}
@end
