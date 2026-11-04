#import "AppControllerInternal.h"
#include "satellite_scene.hpp"
#include <stdexcept>

@implementation AppController (SatelliteCommands)
- (void)showSatelliteBrowser:(id)sender {
    (void)sender;
    if (!_satelliteModel || _loading) return;
    if (!_satelliteBrowser) {
        _satelliteBrowser = [[SatelliteController alloc] init];
        __weak AppController *weakSelf = self;
        _satelliteBrowser.chooseObject = ^(NSUInteger index, BOOL center) {
            [weakSelf chooseSatellite:index center:center];
        };
        _satelliteBrowser.changeDisplayOptions = ^(SatelliteDisplayOptions options) {
            [weakSelf setSatelliteDisplayOptions:options];
        };
        _satelliteBrowser.changeDisplaySelection = ^(const std::vector<mitaka::SatelliteRecordId>& ids) {
            [weakSelf setSatelliteDisplaySelectedIds:ids];
        };
        [_satelliteBrowser setModel:_satelliteModel snapshot:_satelliteSnapshot];
    }
    [_satelliteBrowser setDisplayModel:_satelliteDisplay];
    [_satelliteBrowser setOrbitGeometry:[_solar satelliteOrbitGeometry]];
    [_satelliteBrowser showWindow:nil];
}
- (std::shared_ptr<const SatelliteSnapshot>)satelliteSnapshotAtDate:(double)jd {
    if (!_satelliteModel || !_model) return {};
    return evaluate_satellite_snapshot(_satelliteModel, _model->ephemeris(), jd);
}
- (void)applySatelliteSnapshot:(std::shared_ptr<const SatelliteSnapshot>)snapshot {
    std::shared_ptr<const SatelliteDisplayModel> display = _satelliteDisplay;
    if (snapshot && snapshot->model) {
        auto model = std::shared_ptr<const mitaka::SatelliteModel>(snapshot->model, &snapshot->model->model());
        if (!display) display = std::make_shared<SatelliteDisplayModel>(model);
        else if (display->model() != model) {
            auto replacement = std::make_shared<SatelliteDisplayModel>(*display);
            replacement->rebind(model);
            display = std::move(replacement);
        }
    } else display.reset();
    [_solar setSatelliteSnapshot:snapshot];
    _satelliteSnapshot = std::move(snapshot);
    _satelliteDisplay = std::move(display);
    [_solar setSatelliteDisplayModel:_satelliteDisplay];
    [_satelliteBrowser setSnapshot:_satelliteSnapshot];
    [_satelliteBrowser setDisplayModel:_satelliteDisplay];
    [_satelliteBrowser setOrbitGeometry:[_solar satelliteOrbitGeometry]];
}
- (SatelliteDisplayOptions)satelliteDisplayOptions {
    return _satelliteDisplay ? _satelliteDisplay->options() : SatelliteDisplayOptions{};
}
- (void)setSatelliteDisplayOptions:(SatelliteDisplayOptions)options {
    if (!_satelliteDisplay) throw std::invalid_argument("satellite display model is unavailable");
    auto display = std::make_shared<SatelliteDisplayModel>(*_satelliteDisplay);
    display->set_options(options);
    [_solar setSatelliteDisplayModel:display];
    _satelliteDisplay = std::move(display);
    [_satelliteBrowser setDisplayModel:_satelliteDisplay];
    [self updateEnabled];
}
- (void)setSatelliteDisplaySelectedIds:(const std::vector<mitaka::SatelliteRecordId>&)ids {
    if (!_satelliteDisplay) throw std::invalid_argument("satellite display model is unavailable");
    auto display = std::make_shared<SatelliteDisplayModel>(*_satelliteDisplay);
    display->set_selected_ids(ids);
    [_solar setSatelliteDisplayModel:display];
    _satelliteDisplay = std::move(display);
    [_satelliteBrowser setDisplayModel:_satelliteDisplay];
    [self updateEnabled];
}
- (void)toggleSatellites:(id)sender {
    (void)sender;
    if (!_satelliteModel || _loading) return;
    auto options = [self satelliteDisplayOptions];
    options.visible = !options.visible;
    [self setSatelliteDisplayOptions:options];
    _mode.selectedSegment = 1;
    [self changeMode:nil];
}
- (void)chooseSatellite:(NSUInteger)index center:(BOOL)center {
    if (!_satelliteModel || _loading || index >= _satelliteModel->model().records().size()) return;
    [_solar selectSatellite:index];
    auto options = [self satelliteDisplayOptions];
    options.visible = true;
    [self setSatelliteDisplayOptions:options];
    _mode.selectedSegment = 1;
    [self changeMode:nil];
    if (center) [_solar focusSelection];
    [self updateEnabled];
}
- (void)refreshSatelliteParents {
    const NSUInteger index = _solar.selectedSatelliteIndex;
    if (!_model || !_satelliteModel || !_satelliteSnapshot || _loading ||
        _satelliteSnapshot->julian_date != _jd) return;
    const auto source = index < _satelliteModel->model().records().size()
        ? std::optional<std::string>{_satelliteModel->source(index)} : std::nullopt;
    // 一覧・画面クリックの両方で、選んだ衛星と同じ出典の親補正を使う。
    _solarBodies = apply_satellite_parent_positions(_model->solar_bodies(_jd),
        *_satelliteSnapshot, source);
    [_solar setBodies:_solarBodies];
    [self refreshBodyButtons];
}
@end
