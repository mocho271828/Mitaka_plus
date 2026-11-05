#import "AppControllerInternal.h"
#import "SmallBodyOrbitController.h"
#include <stdexcept>

using namespace mitaka;

@implementation AppController (SmallBodyCommands)
- (void)showSmallBodyBrowser:(id)sender {
    (void)sender;
    if (!_smallBodyModel || _loading) return;
    if (!_smallBodyBrowser) {
        _smallBodyBrowser = [[SmallBodyController alloc] init];
        __weak AppController *weakSelf = self;
        _smallBodyBrowser.chooseObject = ^(NSUInteger index, BOOL center) { [weakSelf chooseSmallBody:index center:center]; };
        _smallBodyBrowser.optionsChanged = ^(SmallBodyKind kind, SmallBodyKindDisplayOptions options) {
            [weakSelf setSmallBodyDisplayOptions:options forKind:kind];
        };
        _smallBodyBrowser.displayIdsChanged = ^(const std::vector<SmallBodyId>& ids) { [weakSelf setSmallBodyDisplayIds:ids]; };
        _smallBodyBrowser.orbitSamplingChanged = ^(SmallBodyOrbitSampling sampling) { [weakSelf setSmallBodyOrbitSampling:sampling]; };
        [_smallBodyBrowser setModel:_smallBodyModel snapshot:_smallBodySnapshot];
    }
    [_smallBodyBrowser setDisplayModel:_smallBodyDisplay];
    [_smallBodyBrowser setOrbitSampling:_smallBodyOrbitSampling];
    [self refreshSmallBodyOrbits];
    [_smallBodyBrowser showWindow:nil];
}
- (std::shared_ptr<const SmallBodyDisplayModel>)smallBodyDisplayModel { return _smallBodyDisplay; }
- (void)resetSmallBodyDisplayForCurrentModel {
    _smallBodyOrbits.reset();
    if (!_smallBodyModel) { _smallBodyDisplay.reset(); return; }
    const auto data = std::shared_ptr<const SmallBodyDataset>(_smallBodyModel, &_smallBodyModel->dataset());
    auto next = _smallBodyDisplay ? std::make_shared<SmallBodyDisplayModel>(*_smallBodyDisplay)
                                 : std::make_shared<SmallBodyDisplayModel>(data);
    const auto rebound = next->rebind(data);
    _smallBodyDisplay = std::move(next);
    if (_smallBodyOrbitSampling.sample_count == 0) _smallBodyOrbitSampling = {_jd-182.625, _jd+182.625, 129};
    if (!rebound.removed_ids.empty()) [self showError:[NSString stringWithFormat:
        @"小天体の表示集合から %lu 行を解除しました。元の出典 bytes・種別・原行 ID が一致しないためです。", rebound.removed_ids.size()]];
}
- (void)setSmallBodyDisplayModel:(std::shared_ptr<const SmallBodyDisplayModel>)display {
    if (!_smallBodyModel || !display || display->dataset().get() != &_smallBodyModel->dataset())
        throw std::invalid_argument("small-body display/model mismatch");
    // 過大な要求で設定だけが先に変わることを避ける。原本行は一切切り捨てない。
    (void)small_body_orbit_requested_rows(*_smallBodyModel, *display, _smallBodyOrbitSampling);
    _smallBodyDisplay = std::move(display);
    [_solar setSmallBodyDisplayModel:_smallBodyDisplay];
    [_horizon setSmallBodyDisplayModel:_smallBodyDisplay];
    [_smallBodyBrowser setDisplayModel:_smallBodyDisplay];
    [self refreshSmallBodyOrbits];
}
- (SmallBodyKindDisplayOptions)smallBodyDisplayOptionsForKind:(SmallBodyKind)kind {
    if (!_smallBodyDisplay) return {};
    return _smallBodyDisplay->kind_options(kind);
}
- (void)setSmallBodyDisplayOptions:(SmallBodyKindDisplayOptions)options forKind:(SmallBodyKind)kind {
    if (!_smallBodyDisplay) throw std::logic_error("small-body data is not loaded");
    auto next = std::make_shared<SmallBodyDisplayModel>(*_smallBodyDisplay);
    next->set_kind_options(kind, options);
    [self setSmallBodyDisplayModel:std::move(next)];
}
- (void)setSmallBodyDisplayIds:(const std::vector<SmallBodyId>&)ids {
    if (!_smallBodyDisplay) throw std::logic_error("small-body data is not loaded");
    auto next = std::make_shared<SmallBodyDisplayModel>(*_smallBodyDisplay);
    next->set_selected_ids(ids);
    [self setSmallBodyDisplayModel:std::move(next)];
}
- (void)setSmallBodyOrbitSampling:(SmallBodyOrbitSampling)sampling {
    if (!_smallBodyModel || !_smallBodyDisplay) throw std::logic_error("small-body data is not loaded");
    (void)small_body_orbit_requested_rows(*_smallBodyModel, *_smallBodyDisplay, sampling);
    _smallBodyOrbitSampling = sampling;
    _smallBodyOrbits.reset();
    [_solar setSmallBodyOrbitSnapshot:nullptr];
    [_smallBodyBrowser setOrbitSampling:sampling];
    [self refreshSmallBodyOrbits];
}
- (void)refreshSmallBodyOrbits {
    if (_loading || !_smallBodyModel || !_smallBodyDisplay || _mode.selectedSegment != 1 || ![_solar smallBodiesSceneVisible]) {
        [_smallBodyOrbitController cancel];
        [_smallBodyBrowser setOrbitStatus:@"軌道計算は小天体が表示される 3D 画面で行います。固定 TDB 区間は保持します。"];
        return;
    }
    try {
        const auto rows = small_body_orbit_requested_rows(*_smallBodyModel, *_smallBodyDisplay, _smallBodyOrbitSampling);
        if (rows.empty()) {
            [_smallBodyOrbitController cancel];
            _smallBodyOrbits.reset();
            [_solar setSmallBodyOrbitSnapshot:nullptr];
            [_smallBodyBrowser setOrbitStatus:@"軌道線の要求は 0 行です。種類の「軌道線」を有効にしてください。"];
            return;
        }
        if (!_smallBodyOrbitController) _smallBodyOrbitController = [[SmallBodyOrbitController alloc] init];
        [_smallBodyBrowser setOrbitStatus:[NSString stringWithFormat:@"軌道を計算中: %lu 行 × %lu 標本（上限 %lu 標本）",
            rows.size(), _smallBodyOrbitSampling.sample_count, maximum_small_body_orbit_total_samples]];
        __weak AppController *weakSelf = self;
        [_smallBodyOrbitController requestModel:_smallBodyModel display:_smallBodyDisplay sampling:_smallBodyOrbitSampling
            completion:^(std::shared_ptr<const SmallBodyOrbitSnapshot> result, NSString *error) {
                AppController *controller = weakSelf;
                if (!controller) return;
                if (error) { [controller->_smallBodyBrowser setOrbitStatus:error]; return; }
                if (!result || result->model != controller->_smallBodyModel || result->cancelled) return;
                controller->_smallBodyOrbits = std::move(result);
                [controller->_solar setSmallBodyOrbitSnapshot:controller->_smallBodyOrbits];
                [controller->_smallBodyBrowser setOrbitStatus:[NSString stringWithFormat:
                    @"固定 TDB 区間: %lu 行 × %lu 標本、欠損・未確定 %lu 行。原本は保持し、欠損を跨ぐ線は描きません。",
                    controller->_smallBodyOrbits->requested_count, controller->_smallBodyOrbitSampling.sample_count,
                    controller->_smallBodyOrbits->unresolved_count]];
            }];
    } catch (const std::exception& error) {
        [_smallBodyBrowser setOrbitStatus:[NSString stringWithFormat:@"軌道を更新できません: %s", error.what()]];
    }
}
- (void)invalidateSmallBodyOrbits {
    [_smallBodyOrbitController invalidate];
    _smallBodyOrbitController = nil;
    _smallBodyOrbits.reset();
    [_solar setSmallBodyOrbitSnapshot:nullptr];
}
- (std::shared_ptr<const SmallBodySnapshot>)smallBodySnapshotAtDate:(double)jd {
    if (!_smallBodyModel) return {};
    const NSUInteger index = _solar.selectedSmallBodyIndex;
    const auto selection = index < _smallBodyModel->dataset().records.size() ? std::optional<std::size_t>{index} : std::nullopt;
    const BOOL visible = (_mode.selectedSegment == 1 || _mode.selectedSegment == 2) && _solar.smallBodiesVisible;
    return evaluate_small_body_snapshot(_smallBodyModel, jd, visible, selection);
}
- (void)applySmallBodySnapshot:(std::shared_ptr<const SmallBodySnapshot>)snapshot {
    _smallBodySnapshot = std::move(snapshot);
    [_solar setSmallBodySnapshot:_smallBodySnapshot];
    [_solar setSmallBodyDisplayModel:_smallBodyDisplay];
    [_horizon setSmallBodySnapshot:_smallBodySnapshot];
    [_horizon setSmallBodyDisplayModel:_smallBodyDisplay];
    [_smallBodyBrowser setSnapshot:_smallBodySnapshot];
    [_smallBodyBrowser setDisplayModel:_smallBodyDisplay];
    [self refreshSmallBodyOrbits];
}
- (void)refreshSmallBodies {
    if (!_smallBodyModel || _loading) return;
    try { [self applySmallBodySnapshot:[self smallBodySnapshotAtDate:_jd]]; }
    catch (const std::exception& error) { [self showError:[NSString stringWithFormat:@"小天体の表示を更新できません: %s", error.what()]]; }
}
- (void)toggleSmallBodies:(id)sender {
    (void)sender;
    if (!_smallBodyModel || _loading) return;
    _solar.smallBodiesVisible = !_solar.smallBodiesVisible;
    _horizon.smallBodiesVisible = _solar.smallBodiesVisible;
    if (_mode.selectedSegment != 2) _mode.selectedSegment = 1;
    [self changeMode:nil];
}
- (void)chooseSmallBody:(NSUInteger)index center:(BOOL)center {
    if (!_smallBodyModel || _loading || index >= _smallBodyModel->dataset().records.size()) return;
    [_solar selectSmallBody:index];
    _solar.smallBodiesVisible = YES;
    _horizon.smallBodiesVisible = YES;
    if (_mode.selectedSegment != 2) _mode.selectedSegment = 1;
    [self changeMode:nil];
    if (_mode.selectedSegment == 2) {
        [_horizon selectSmallBody:index];
        if (center) [_horizon focusSelection];
    } else if (center) [_solar focusSelection];
    [self updateEnabled];
}
@end
