#import "SolarSystemViewInternal.h"
#import "SmallBodyRenderer.h"
#include <algorithm>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;

@implementation SolarSystemView (SmallBodies)
- (std::shared_ptr<const SmallBodyDisplayModel>)smallBodyDisplayModel { return _smallBodyDisplay; }
- (BOOL)smallBodiesVisible { return _smallBodiesVisible; }
- (void)setSmallBodiesVisible:(BOOL)visible { _smallBodiesVisible = visible; self.needsDisplay = YES; }
- (NSUInteger)selectedSmallBodyIndex { return !_selection && _smallBodySelection ? *_smallBodySelection : NSNotFound; }
- (BOOL)smallBodiesSceneVisible {
    return _smallBodiesVisible && _smallBodySnapshot && _smallBodyDisplay && !_earthMoonMode && !_surfacePreview && !_surfaceActive && !_journeyActive;
}
- (NSUInteger)visibleSmallBodyCount {
    return [self smallBodiesSceneVisible] ? visible_small_bodies(*_smallBodySnapshot, *_smallBodyDisplay, _camera, [self mapRect]).size() : 0;
}
- (void)setSmallBodySnapshot:(std::shared_ptr<const SmallBodySnapshot>)snapshot {
    if (snapshot && (!snapshot->model || snapshot->positions.size() != snapshot->model->dataset().records.size()))
        throw std::invalid_argument("small-body snapshot does not match its dataset");
    auto nextDisplay = _smallBodyDisplay;
    // 元データと異なる設定・軌道を次の描画へ持ち越さない。
    if (!snapshot || !_smallBodyDisplay || _smallBodyDisplay->dataset().get() != &snapshot->model->dataset()) {
        nextDisplay = snapshot ? std::make_shared<SmallBodyDisplayModel>(
            std::shared_ptr<const SmallBodyDataset>(snapshot->model, &snapshot->model->dataset())) : nullptr;
    }
    const BOOL wasSelected = !_selection && _smallBodySelection.has_value();
    if (!snapshot || !_smallBodySnapshot || snapshot->model != _smallBodySnapshot->model) {
        if (_smallBodySelection && !_selection) _following = NO;
        _smallBodySelection.reset();
    }
    if (nextDisplay != _smallBodyDisplay) _smallBodyOrbits.reset();
    _smallBodyDisplay = std::move(nextDisplay);
    _smallBodySnapshot = std::move(snapshot);
    if (wasSelected || (!_selection && _smallBodySelection)) {
        [self updateTrackedCamera];
        [self notifySelection];
        [self notifyCamera];
    }
    self.needsDisplay = YES;
}
- (void)setSmallBodyDisplayModel:(std::shared_ptr<const SmallBodyDisplayModel>)display {
    if (display && _smallBodySnapshot && display->dataset().get() != &_smallBodySnapshot->model->dataset())
        throw std::invalid_argument("small-body display/model mismatch");
    _smallBodyDisplay = std::move(display);
    self.needsDisplay = YES;
}
- (void)setSmallBodyOrbitSnapshot:(std::shared_ptr<const SmallBodyOrbitSnapshot>)snapshot {
    if (snapshot && (!_smallBodySnapshot || snapshot->model != _smallBodySnapshot->model
        || snapshot->paths.size() != _smallBodySnapshot->positions.size()
        || snapshot->minor_planet_paths.size() != _smallBodySnapshot->positions.size() || snapshot->cancelled))
        throw std::invalid_argument("small-body orbit snapshot/model mismatch");
    _smallBodyOrbits = std::move(snapshot);
    self.needsDisplay = YES;
}
- (void)selectSmallBody:(NSUInteger)index {
    if (!_smallBodySnapshot || index >= _smallBodySnapshot->positions.size()) return;
    [self clearGalaxySelection];
    _selection.reset();
    _smallBodySelection = index;
    _satelliteSelection.reset();
    _spacecraftSelection.reset();
    // 評価不能の行を選んだだけでカメラや既存の航行状態を変えない。
    _following = NO;
    [self notifySelection];
    [self notifyCamera];
    self.needsDisplay = YES;
}
- (NSString *)smallBodySelectionDescription {
    if (!_smallBodySnapshot || !_smallBodySelection) return @"小天体のデータがありません。";
    const auto text = small_body_description(*_smallBodySnapshot->model, *_smallBodySelection, _smallBodySnapshot.get());
    return [[NSString alloc] initWithBytes:text.data() length:text.size() encoding:NSUTF8StringEncoding];
}
- (void)focusSmallBodySelection {
    if (!_smallBodySnapshot || !_smallBodySelection) return;
    const auto& position = _smallBodySnapshot->positions[*_smallBodySelection];
    if (!position) {
        [self notifySelection];
        if (self.cameraChanged) self.cameraChanged(@"選択した小天体は位置を評価できないため、現在の視点を維持します。");
        return;
    }
    [self leaveNavigation];
    _camera.target = *position;
    _camera.frame.reset();
    _camera.distance_au = std::max(0.05, _camera.distance_au);
    _following = YES;
    _smallBodiesVisible = YES;
    [self notifyCamera];
    self.needsDisplay = YES;
}
- (BOOL)rejectSmallBodySurfaceNavigation {
    if (self.selectedSmallBodyIndex == NSNotFound) return NO;
    if (self.cameraChanged) self.cameraChanged(@"小天体の半径・表面モデルは未定義のため、表面観察・着陸・連続飛行の対象にはできません。");
    return YES;
}
@end
