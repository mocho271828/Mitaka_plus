#import "SolarSystemViewInternal.h"
#import "SatelliteRenderer.h"
#include <algorithm>
#include <cmath>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;

@implementation SolarSystemView (Satellites)
- (NSUInteger)selectedSatelliteIndex { return !_selection && _satelliteSelection ? *_satelliteSelection : NSNotFound; }
- (BOOL)satellitesSceneVisible {
    return _satelliteSnapshot && _satelliteDisplay && _satelliteDisplay->options().visible && !_earthMoonMode && !_surfacePreview && !_surfaceActive && !_journeyActive;
}
- (NSUInteger)visibleSatelliteCount {
    return [self satellitesSceneVisible] ? visible_satellites(*_satelliteSnapshot, _camera, [self mapRect], _satelliteDisplay.get()).size() : 0;
}
- (std::shared_ptr<const SatelliteDisplayModel>)satelliteDisplayModel { return _satelliteDisplay; }
- (std::shared_ptr<const SatelliteOrbitGeometry>)satelliteOrbitGeometry { return _satelliteOrbits; }
- (void)setSatelliteDisplayModel:(std::shared_ptr<const SatelliteDisplayModel>)display {
    if (display && (!_satelliteSnapshot || display->model().get() != &_satelliteSnapshot->model->model()))
        throw std::invalid_argument("satellite display does not match its snapshot");
    _satelliteDisplay = std::move(display);
    self.needsDisplay = YES;
}
- (void)setSatelliteSnapshot:(std::shared_ptr<const SatelliteSnapshot>)snapshot {
    if (snapshot) {
        if (!snapshot->model || snapshot->positions.size() != snapshot->model->model().records().size())
            throw std::invalid_argument("satellite snapshot does not match its dataset");
        if (!std::isfinite(snapshot->julian_date)) throw std::invalid_argument("satellite snapshot Julian date must be finite");
        for (const auto& position : snapshot->positions)
            if (position && (!std::isfinite(position->x) || !std::isfinite(position->y) || !std::isfinite(position->z)))
                throw std::invalid_argument("satellite snapshot position must be finite");
    }
    const auto orbits = snapshot ? satellite_orbit_geometry(snapshot) : nullptr;
    auto display = _satelliteDisplay;
    if (!snapshot) display.reset();
    else if (!display || display->model().get() != &snapshot->model->model()) {
        const auto model = std::shared_ptr<const SatelliteModel>(snapshot->model, &snapshot->model->model());
        display = std::make_shared<SatelliteDisplayModel>(model);
    }
    const BOOL wasSelected = !_selection && _satelliteSelection.has_value();
    if (!snapshot || !_satelliteSnapshot || snapshot->model != _satelliteSnapshot->model) {
        if (_satelliteSelection && !_selection) _following = NO;
        _satelliteSelection.reset();
    }
    _satelliteSnapshot = std::move(snapshot);
    _satelliteDisplay = std::move(display);
    _satelliteOrbits = orbits;
    if (wasSelected || (!_selection && _satelliteSelection)) {
        [self updateTrackedCamera];
        [self notifySelection];
        [self notifyCamera];
    }
    self.needsDisplay = YES;
}
- (void)selectSatellite:(NSUInteger)index {
    if (!_satelliteSnapshot || index >= _satelliteSnapshot->positions.size()) return;
    _selection.reset();
    _smallBodySelection.reset();
    _spacecraftSelection.reset();
    _satelliteSelection = index;
    // 未評価行も一覧で選べる。選択だけでは視点や既存の航行状態を変えない。
    _following = NO;
    [self notifySelection];
    [self notifyCamera];
    self.needsDisplay = YES;
}
- (NSString *)satelliteSelectionDescription {
    if (!_satelliteSnapshot || !_satelliteSelection) return @"衛星のデータがありません。";
    const auto text = satellite_description(*_satelliteSnapshot->model, *_satelliteSelection, _satelliteSnapshot.get());
    return [[NSString alloc] initWithBytes:text.data() length:text.size() encoding:NSUTF8StringEncoding];
}
- (void)focusSatelliteSelection {
    if (!_satelliteSnapshot || !_satelliteSelection) return;
    const auto& position = _satelliteSnapshot->positions[*_satelliteSelection];
    if (!position) {
        [self notifySelection];
        if (self.cameraChanged) self.cameraChanged(@"選択した衛星は位置を評価できないため、現在の視点を維持します。");
        return;
    }
    [self leaveNavigation];
    _camera.target = *position;
    _camera.frame.reset();
    _camera.distance_au = std::max(0.05, _camera.distance_au);
    _following = YES;
    [self notifyCamera];
    self.needsDisplay = YES;
}
- (BOOL)rejectSatelliteSurfaceNavigation {
    if (self.selectedSatelliteIndex == NSNotFound) return NO;
    if (self.cameraChanged) self.cameraChanged(@"追加衛星の表面描画・表面航行は未対応のため、表面観察・着陸・連続飛行の対象にはできません。");
    return YES;
}
@end
