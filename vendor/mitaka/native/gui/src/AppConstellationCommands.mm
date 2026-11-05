#import "AppControllerInternal.h"
#include <algorithm>

@implementation AppController (ConstellationCommands)
- (ConstellationDisplayOptions)constellationDisplayOptions { return _sky.constellationDisplayOptions; }
- (void)setConstellationDisplayOptions:(const ConstellationDisplayOptions&)options {
    if (_model) {
        ConstellationDisplayModel validated(_model->constellations());
        validated.set_options(options);
    }
    _sky.constellationDisplayOptions = options;
    _horizon.constellationDisplayOptions = options;
    _solar.surfaceConstellationDisplayOptions = options;
    [_browser refreshConstellationVisibility];
    [NSApp.mainMenu update];
}
- (void)setConstellationMembership:(const std::vector<std::string>&)ids visible:(BOOL)visible {
    if (!_model) return;
    ConstellationDisplayModel next(_model->constellations());
    next.set_options([self constellationDisplayOptions]);
    next.set_visible(ids, visible);
    [self setConstellationDisplayOptions:next.options()];
}
- (void)setAllConstellationsVisible:(BOOL)visible {
    if (!_model) return;
    ConstellationDisplayModel next(_model->constellations());
    next.set_options([self constellationDisplayOptions]);
    next.set_all_visible(visible);
    [self setConstellationDisplayOptions:next.options()];
}
- (ConstellationDisplayRebind)rebindConstellationDisplay {
    if (!_model) return {};
    ConstellationDisplayModel next(_model->constellations());
    auto options = [self constellationDisplayOptions];
    ConstellationDisplayRebind report;
    for (auto item = options.exceptions.begin(); item != options.exceptions.end();) {
        if (next.abbreviations().count(*item)) ++item;
        else { report.removed_exceptions.push_back(*item); item = options.exceptions.erase(item); }
    }
    [self setConstellationDisplayOptions:options];
    return report;
}
- (void)configureConstellationBrowser {
    __weak AppController *weakSelf = self;
    _browser.constellationVisible = ^BOOL(NSUInteger row) {
        AppController *controller = weakSelf;
        if (!controller || !controller->_model || row >= controller->_model->constellations().size()) return NO;
        const auto options = [controller constellationDisplayOptions];
        const auto& abbreviation = controller->_model->constellations()[row].abbreviation;
        return options.default_visible != (options.exceptions.count(abbreviation) != 0);
    };
    _browser.setConstellationVisible = ^(NSUInteger row, BOOL visible) {
        AppController *controller = weakSelf;
        if (!controller || !controller->_model || row >= controller->_model->constellations().size()) return;
        [controller setConstellationMembership:{controller->_model->constellations()[row].abbreviation} visible:visible];
    };
    _browser.setAllConstellationsVisible = ^(BOOL visible) { [weakSelf setAllConstellationsVisible:visible]; };
    [_browser refreshConstellationVisibility];
}
- (void)revealConstellationRow:(NSUInteger)row center:(BOOL)center {
    if (!_model || row >= _model->constellations().size()) return;
    const auto& record = _model->constellations()[row];
    ConstellationDisplayModel next(_model->constellations());
    auto options = [self constellationDisplayOptions];
    options.lines = options.labels = true;
    next.set_options(options);
    next.set_visible({record.abbreviation}, true);
    [self setConstellationDisplayOptions:next.options()];
    if (_mode.selectedSegment == 2) {
        if (center) {
            const mitaka::ObservationFrame frame(_horizon.observerSite, _horizon.julianDate);
            const auto point = frame.to_horizontal({record.right_ascension_degrees, record.declination_degrees});
            [self stopScriptCameraAnimation];
            [_horizon setViewport:{point.azimuth_deg, point.altitude_deg, std::max(3.0, _horizon.viewport.zoom)}];
        }
    } else {
        _mode.selectedSegment = 0;
        [self changeMode:nil];
        if (center) [_sky setViewport:{record.right_ascension_degrees, record.declination_degrees,
            std::max(3.0, _sky.viewport.zoom)}];
    }
    [self refresh];
}
@end
