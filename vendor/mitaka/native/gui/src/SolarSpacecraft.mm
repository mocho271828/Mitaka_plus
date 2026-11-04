#import "SolarSystemViewInternal.h"
#import "SpacecraftRenderer.h"
#include <algorithm>
#include <cmath>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;

@implementation SolarSystemView (Spacecraft)
- (BOOL)spacecraftVisible { return _spacecraftVisible; }
- (void)setSpacecraftVisible:(BOOL)visible { _spacecraftVisible = visible; self.needsDisplay = YES; }
- (SpacecraftDisplayOptions)spacecraftDisplayOptions { return _spacecraftDisplayOptions; }
- (void)setSpacecraftDisplayOptions:(SpacecraftDisplayOptions)options {
    _spacecraftDisplayOptions = options;
    self.needsDisplay = YES;
}
- (NSUInteger)selectedSpacecraftIndex { return !_selection && _spacecraftSelection ? *_spacecraftSelection : NSNotFound; }
- (BOOL)spacecraftSceneVisible {
    return _spacecraftVisible && _spacecraftSnapshot && !_earthMoonMode && !_surfacePreview && !_surfaceActive && !_journeyActive;
}
- (NSUInteger)visibleSpacecraftCount {
    return [self spacecraftSceneVisible] ? visible_spacecraft(*_spacecraftSnapshot, _camera, [self mapRect], _spacecraftDisplayOptions).size() : 0;
}
- (void)setSpacecraftSnapshot:(std::shared_ptr<const SpacecraftSnapshot>)snapshot {
    if (snapshot) {
        if (!snapshot->model || snapshot->positions.size() != snapshot->model->model().dataset().definitions.size() ||
            snapshot->evaluations.size() != snapshot->positions.size())
            throw std::invalid_argument("spacecraft snapshot does not match its dataset");
        if (!std::isfinite(snapshot->julian_date)) throw std::invalid_argument("spacecraft snapshot Julian date must be finite");
        for (const auto& position : snapshot->positions)
            if (position && (!std::isfinite(position->x) || !std::isfinite(position->y) || !std::isfinite(position->z)))
                throw std::invalid_argument("spacecraft snapshot position must be finite");
    }
    const BOOL wasSelected = !_selection && _spacecraftSelection.has_value();
    if (!snapshot || !_spacecraftSnapshot || snapshot->model != _spacecraftSnapshot->model) {
        if (_spacecraftSelection && !_selection) _following = NO;
        _spacecraftSelection.reset();
    }
    _spacecraftSnapshot = std::move(snapshot);
    if (wasSelected || (!_selection && _spacecraftSelection)) {
        [self updateTrackedCamera];
        [self notifySelection];
        [self notifyCamera];
    }
    self.needsDisplay = YES;
}
- (void)selectSpacecraft:(NSUInteger)index {
    if (!_spacecraftSnapshot || index >= _spacecraftSnapshot->positions.size()) return;
    _selection.reset();
    _smallBodySelection.reset();
    _satelliteSelection.reset();
    _spacecraftSelection = index;
    _following = NO;
    [self notifySelection];
    [self notifyCamera];
    self.needsDisplay = YES;
}
- (NSString *)spacecraftSelectionDescription {
    if (!_spacecraftSnapshot || !_spacecraftSelection) return @"探査機のデータがありません。";
    const auto text = spacecraft_description(*_spacecraftSnapshot->model, *_spacecraftSelection, _spacecraftSnapshot.get());
    return [[NSString alloc] initWithBytes:text.data() length:text.size() encoding:NSUTF8StringEncoding];
}
- (void)focusSpacecraftSelection {
    if (!_spacecraftSnapshot || !_spacecraftSelection) return;
    const auto position = spacecraft_scene_position(*_spacecraftSnapshot, *_spacecraftSelection);
    if (!position) {
        [self notifySelection];
        if (self.cameraChanged) self.cameraChanged(@"選択した探査機は位置を評価できないため、現在の視点を維持します。");
        return;
    }
    [self leaveNavigation];
    _camera.target = *position;
    _camera.frame.reset();
    _camera.distance_au = std::max(0.05, _camera.distance_au);
    _following = YES;
    _spacecraftVisible = YES;
    [self notifyCamera];
    self.needsDisplay = YES;
}
- (BOOL)rejectSpacecraftSurfaceNavigation {
    if (self.selectedSpacecraftIndex == NSNotFound) return NO;
    if (self.cameraChanged) self.cameraChanged(@"探査機は軌跡上の位置を表示します。表面観察・着陸・連続飛行の対象にはできません。");
    return YES;
}
@end
