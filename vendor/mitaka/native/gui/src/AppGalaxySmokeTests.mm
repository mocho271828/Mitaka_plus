#import "AppControllerInternal.h"
#import "SolarSystemViewInternal.h"
#include "shared_camera.hpp"
#include "our_galaxy_navigation.hpp"
#include "mitaka/our_galaxy_model.hpp"
#include <cstdio>
#include <cstdlib>
#include <stdexcept>

namespace {
enum class GalaxySmokePhase { cancel, data_generation, failure, partial_failure, invalidate, success, corrupt, no_browser };
struct GalaxySmokeState {
    unsigned checks = 0;
    std::shared_ptr<const GalaxySpatialModel> original =
        std::make_shared<const GalaxySpatialModel>(std::vector<GalaxySpatialSource>{});
    std::shared_ptr<const mitaka::OurGalaxyModel> originalOur = std::make_shared<const mitaka::OurGalaxyModel>();
    NSString *corruptDirectory = nil;
    void require(bool condition, const char *message) {
        ++checks;
        if (!condition) throw std::runtime_error(message);
    }
};
[[noreturn]] void failGalaxySmoke(const char *message) {
    std::fprintf(stderr, "Galaxy host smoke failed: %s\n", message);
    std::exit(EXIT_FAILURE);
}
void afterGalaxyJob(std::weak_ptr<std::atomic_bool> lifetime, void (^completion)(void)) {
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:10];
    // token は worker と main callback の両方が所有する。解放を待つことで、
    // 取消後の遅延 callback を固定秒数の待機で見逃さない。
    [NSTimer scheduledTimerWithTimeInterval:0.01 repeats:YES block:^(NSTimer *timer) {
        if (!lifetime.expired()) {
            if (deadline.timeIntervalSinceNow > 0) return;
            [timer invalidate];
            failGalaxySmoke("worker/main callback did not release its cancellation token");
        }
        [timer invalidate];
        completion();
    }];
}
}

@interface GalaxyModelProbeView : SolarSystemView
- (std::shared_ptr<const GalaxySpatialModel>)receivedGalaxyModel;
- (std::shared_ptr<const mitaka::OurGalaxyModel>)receivedOurGalaxyModel;
@end

@implementation GalaxyModelProbeView {
    std::shared_ptr<const GalaxySpatialModel> _receivedGalaxyModel;
    std::shared_ptr<const mitaka::OurGalaxyModel> _receivedOurGalaxyModel;
}
- (void)setGalaxyModel:(std::shared_ptr<const GalaxySpatialModel>)model { _receivedGalaxyModel = std::move(model); }
- (std::shared_ptr<const GalaxySpatialModel>)receivedGalaxyModel { return _receivedGalaxyModel; }
- (void)setOurGalaxyModel:(std::shared_ptr<const mitaka::OurGalaxyModel>)model { _receivedOurGalaxyModel = std::move(model); }
- (std::shared_ptr<const mitaka::OurGalaxyModel>)receivedOurGalaxyModel { return _receivedOurGalaxyModel; }
@end

@interface AppController (GalaxySmokePrivate)
- (void)runGalaxySmokePhase:(GalaxySmokePhase)phase state:(std::shared_ptr<GalaxySmokeState>)state
    completion:(void (^)(void))completion;
@end

@implementation AppController (GalaxySmokeTests)
- (void)runGalaxySmokeTestWithCompletion:(void (^)(void))completion {
    try {
        auto state = std::make_shared<GalaxySmokeState>();
        state->require(NSThread.isMainThread, "host smoke must run on the main thread");
        state->corruptDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
        NSError *fixtureError = nil;
        state->require([[NSFileManager defaultManager] createDirectoryAtPath:state->corruptDirectory
            withIntermediateDirectories:NO attributes:nil error:&fixtureError], "could not create corrupt fixture");
        state->require([@"invalid" writeToFile:[state->corruptDirectory stringByAppendingPathComponent:@"ourgalaxy_model.dat"]
            atomically:YES encoding:NSUTF8StringEncoding error:&fixtureError], "could not write corrupt fixture");
        // 実際のホストと controller を使うが、利用者の状態や原本は試験へ渡さない。
        // Plus 読込を無効にした空 SDSS はファイル I/O を行わない。
        AppController *probe = [[AppController alloc] initWithDataRoot:nil smokeTest:YES];
        probe->_solar = [[GalaxyModelProbeView alloc] initWithFrame:NSZeroRect];
        probe->_extendedCatalogs = std::make_shared<const ExtendedCatalogs>();
        probe->_galaxyBrowser = [[GalaxyController alloc] init];
        probe->_galaxyModel = state->original;
        probe->_galaxyUsesPlusCatalogs = YES;
        probe->_galaxyDiagnostics = @"retained galaxy source";
        [probe->_galaxyBrowser setModel:state->original diagnostics:probe->_galaxyDiagnostics];
        [probe->_solar setGalaxyModel:state->original];
        [probe->_solar setOurGalaxyModel:state->originalOur];
        state->require(!probe->_galaxyBrowser.window.isVisible, "fixture window became visible");
        probe->_activePath = @"/mitaka-galaxy-smoke-memory-only";
        [probe prepareGalaxyForDataRoot:probe->_activePath];
        state->require(probe->_galaxyModel == state->original && probe->_galaxyUsesPlusCatalogs &&
            [probe->_galaxyBrowser.galaxyView model] == state->original &&
            [(GalaxyModelProbeView *)probe->_solar receivedGalaxyModel] == state->original,
            "same-root data reload discarded the displayed galaxy");
        [probe prepareGalaxyForDataRoot:@"/another-galaxy-root"];
        state->require(!probe->_galaxyModel && !probe->_galaxyUsesPlusCatalogs &&
            ![probe->_galaxyBrowser.galaxyView model] &&
            ![(GalaxyModelProbeView *)probe->_solar receivedGalaxyModel] &&
            ![(GalaxyModelProbeView *)probe->_solar receivedOurGalaxyModel], "changed root retained another root's galaxy");
        probe->_galaxyModel = state->original;
        probe->_galaxyUsesPlusCatalogs = YES;
        probe->_galaxyDiagnostics = @"retained galaxy source";
        [probe->_galaxyBrowser setModel:state->original diagnostics:probe->_galaxyDiagnostics];
        [probe->_solar setGalaxyModel:state->original];
        [probe->_solar setOurGalaxyModel:state->originalOur];
        [probe runGalaxySmokePhase:GalaxySmokePhase::cancel state:state completion:completion];
    } catch (const std::exception& error) {
        failGalaxySmoke(error.what());
    }
}

- (void)runGalaxySmokePhase:(GalaxySmokePhase)phase state:(std::shared_ptr<GalaxySmokeState>)state
    completion:(void (^)(void))completion {
    try {
        if (phase == GalaxySmokePhase::no_browser) _galaxyBrowser = nil;
        if (phase == GalaxySmokePhase::success) [_solar setOurGalaxyModel:state->originalOur];
        const auto previousModel = _galaxyModel;
        _activePath = phase == GalaxySmokePhase::failure ? @"" :
            phase == GalaxySmokePhase::partial_failure ? @"/dev/null" :
            phase == GalaxySmokePhase::corrupt ? state->corruptDirectory : @"/mitaka-galaxy-smoke-memory-only";
        const NSUInteger previousGalaxyGeneration = _galaxyGeneration;
        const NSUInteger previousDataGeneration = _loadGeneration;
        [self loadGalaxyIncludingPlus:phase == GalaxySmokePhase::partial_failure];
        state->require(_galaxyLoading && _galaxyCancellation && !_galaxyCancellation->load(),
            "host did not start a cancellable galaxy job");
        state->require(_galaxyGeneration > previousGalaxyGeneration && _loadGeneration == previousDataGeneration,
            "galaxy load changed the wrong generation");
        const auto token = _galaxyCancellation;
        const std::weak_ptr<std::atomic_bool> lifetime = token;
        switch (phase) {
            case GalaxySmokePhase::cancel:
                [self cancelGalaxyLoading];
                state->require(token->load() && !_galaxyCancellation && !_galaxyLoading &&
                    _loadGeneration == previousDataGeneration, "cancel did not stop only galaxy loading");
                state->require(_galaxyModel == state->original && _galaxyUsesPlusCatalogs &&
                    [_galaxyDiagnostics isEqualToString:@"retained galaxy source"] &&
                    [_galaxyBrowser.galaxyView model] == state->original,
                    "cancel discarded the displayed source or its explicit Plus choice");
                break;
            case GalaxySmokePhase::data_generation:
                // cancel と銀河世代の判定を通過する結果でも、data 世代だけで拒否する。
                ++_loadGeneration;
                _galaxyCancellation.reset();
                _galaxyLoading = NO;
                state->require(!token->load() && _galaxyGeneration == previousGalaxyGeneration + 1,
                    "data-generation fixture accidentally cancelled the galaxy job");
                break;
            case GalaxySmokePhase::invalidate:
                [self invalidateGalaxy];
                state->require(token->load() && !_galaxyCancellation && !_galaxyLoading &&
                    !_galaxyModel && !_galaxyUsesPlusCatalogs && ![_galaxyBrowser.galaxyView model] &&
                    ![(GalaxyModelProbeView *)_solar receivedOurGalaxyModel],
                    "invalidate did not clear host and view while cancelling the job");
                break;
            case GalaxySmokePhase::failure:
            case GalaxySmokePhase::partial_failure:
            case GalaxySmokePhase::success:
            case GalaxySmokePhase::corrupt:
            case GalaxySmokePhase::no_browser:
                break;
        }
        afterGalaxyJob(lifetime, ^{
            try {
                state->require(!_galaxyLoading && !_galaxyCancellation,
                    "completed or rejected job retained active loading state");
                switch (phase) {
                    case GalaxySmokePhase::cancel:
                    case GalaxySmokePhase::data_generation:
                        state->require(_galaxyModel == state->original && _galaxyUsesPlusCatalogs &&
                            [_galaxyDiagnostics isEqualToString:@"retained galaxy source"] &&
                            [_galaxyBrowser.galaxyView model] == state->original &&
                            [(GalaxyModelProbeView *)_solar receivedGalaxyModel] == state->original,
                            "late result replaced the retained host/view model or diagnostics");
                        break;
                    case GalaxySmokePhase::failure:
                        state->require(_galaxyModel == state->original && _galaxyUsesPlusCatalogs &&
                            [_galaxyBrowser.galaxyView model] == state->original &&
                            [(GalaxyModelProbeView *)_solar receivedGalaxyModel] == state->original &&
                            [_galaxyDiagnostics containsString:@"銀河の読込に失敗"],
                            "failed load discarded the previous model or hid its diagnostic");
                        break;
                    case GalaxySmokePhase::partial_failure:
                        state->require(_galaxyModel == state->original && _galaxyUsesPlusCatalogs &&
                            [_galaxyBrowser.galaxyView model] == state->original &&
                            [(GalaxyModelProbeView *)_solar receivedGalaxyModel] == state->original &&
                            [_galaxyDiagnostics containsString:@"銀河の再読込に失敗"] &&
                            [_galaxyDiagnostics containsString:@"globular_cluster.dat"] &&
                            [_galaxyDiagnostics containsString:@"NBG.dat"],
                            "partial Plus reload discarded the previous model or hid failed sources");
                        break;
                    case GalaxySmokePhase::invalidate:
                        state->require(!_galaxyModel && !_galaxyUsesPlusCatalogs &&
                            ![_galaxyBrowser.galaxyView model] && ![(GalaxyModelProbeView *)_solar receivedGalaxyModel] &&
                            [_galaxyDiagnostics isEqualToString:@"データ未読込"],
                            "late result restored an invalidated model");
                        break;
                    case GalaxySmokePhase::success:
                        // 欠損した OurGalaxy は SDSS の公開を妨げない。
                        state->require(_galaxyModel && _galaxyModel != state->original &&
                            _galaxyModel->size() == 0 && _galaxyModel->sources().size() == 2 &&
                            !_galaxyUsesPlusCatalogs && [_galaxyDiagnostics containsString:@"ourgalaxy_model.dat"] &&
                            [_galaxyBrowser.galaxyView model] == _galaxyModel &&
                            [(GalaxyModelProbeView *)_solar receivedGalaxyModel] == _galaxyModel &&
                            [(GalaxyModelProbeView *)_solar receivedOurGalaxyModel] == state->originalOur,
                            "missing OurGalaxy blocked SDSS or discarded the prior model");
                        for (std::size_t source = 0; source < _galaxyModel->sources().size(); ++source)
                            state->require(_galaxyModel->source_path(source).parent_path() ==
                                std::filesystem::path(_activePath.fileSystemRepresentation),
                                "successful model retained another data root");
                        state->require(!_galaxyBrowser.window.isVisible, "host smoke opened its fixture window");
                        break;
                    case GalaxySmokePhase::corrupt:
                        state->require(_galaxyModel && _galaxyModel != previousModel &&
                            [_galaxyDiagnostics containsString:@"ourgalaxy_model.dat"] &&
                            [_galaxyBrowser.galaxyView model] == _galaxyModel &&
                            [(GalaxyModelProbeView *)_solar receivedGalaxyModel] == _galaxyModel &&
                            [(GalaxyModelProbeView *)_solar receivedOurGalaxyModel] == state->originalOur,
                            "corrupt OurGalaxy blocked valid SDSS, hid diagnostic or discarded the prior model");
                        break;
                    case GalaxySmokePhase::no_browser:
                        state->require(!_galaxyBrowser && _galaxyModel && _galaxyModel != previousModel &&
                            [(GalaxyModelProbeView *)_solar receivedGalaxyModel] == _galaxyModel,
                            "successful load without a browser did not publish to the solar view");
                        [self invalidateGalaxy];
                        NSError *cleanupError = nil;
                        state->require([[NSFileManager defaultManager] removeItemAtPath:state->corruptDirectory error:&cleanupError],
                            "could not remove corrupt fixture");
                        std::printf("Galaxy host smoke passed: %u checks; cancel/data-generation/failure/partial-failure/invalidate/success/no-browser\n",
                            state->checks);
                        completion();
                        return;
                }
                [self runGalaxySmokePhase:static_cast<GalaxySmokePhase>(static_cast<int>(phase) + 1)
                    state:state completion:completion];
            } catch (const std::exception& error) {
                failGalaxySmoke(error.what());
            }
        });
    } catch (const std::exception& error) {
        failGalaxySmoke(error.what());
    }
}
@end


namespace {
struct SolarGalaxySmokeState {
    int phase = 0;
    GalaxySpatialRecordId expected{};
    NativeEclipticPositionPc position{};
    SolarCamera latest{};
    std::shared_ptr<const GalaxySpatialModel> model;
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:90];
};
bool solarGalaxyVectorMatches(mitaka::Vec3 a, mitaka::Vec3 b) {
    return a.x == b.x && a.y == b.y && a.z == b.z;
}
bool solarGalaxyFrameMatches(const std::optional<SolarCameraBasis>& a, const std::optional<SolarCameraBasis>& b) {
    if (a.has_value() != b.has_value()) return false;
    return !a || (solarGalaxyVectorMatches(a->right, b->right) && solarGalaxyVectorMatches(a->up, b->up) &&
                  solarGalaxyVectorMatches(a->outward, b->outward));
}
bool solarGalaxyCameraMatches(const GalaxyCameraPc& displayed, const SolarCamera& solar) {
    const auto expected = galaxy_camera_from_shared(shared_camera_from_solar(solar));
    return solarGalaxyFrameMatches(displayed.frame, expected.frame) && displayed.target.x_pc == expected.target.x_pc && displayed.target.y_pc == expected.target.y_pc &&
        displayed.target.z_pc == expected.target.z_pc && displayed.distance_pc == expected.distance_pc &&
        displayed.yaw_deg == expected.yaw_deg && displayed.pitch_deg == expected.pitch_deg;
}
}

@implementation AppController (SolarGalaxySmokeTests)
- (void)runSolarGalaxySmokeTestWithCompletion:(void (^)(void))completion {
    auto state = std::make_shared<SolarGalaxySmokeState>();
    [NSTimer scheduledTimerWithTimeInterval:0.02 repeats:YES block:^(NSTimer *timer) {
        try {
            if (state->deadline.timeIntervalSinceNow <= 0)
                failGalaxySmoke("solar/galaxy integration timed out");
            if (state->phase == 0) {
                if (self->_galaxyLoading) return;
                if (!self->_galaxyModel || self->_galaxyModel->size() == 0) {
                    [timer invalidate];
                    std::printf("Solar/galaxy AppKit smoke skipped: real SDSS model unavailable\n");
                    completion();
                    return;
                }
                state->model = self->_galaxyModel;
                bool found = false;
                for (std::size_t i = 0; i < state->model->size(); ++i) {
                    const auto row = state->model->row(state->model->record_id(i));
                    if (row.position && (row.id.family == GalaxySpatialFamily::sdss_galaxy ||
                                         row.id.family == GalaxySpatialFamily::sdss_quasar)) {
                        state->expected = row.id;
                        state->position = *row.position;
                        found = true;
                        break;
                    }
                }
                if (!found) failGalaxySmoke("SDSS has no positioned source");
                self->_mode.selectedSegment = 1;
                [self changeMode:nil];
                [self->_window.contentView layoutSubtreeIfNeeded];
                NSString *ourPath = [self->_activePath stringByAppendingPathComponent:@"ourgalaxy_model.dat"];
                if ([[NSFileManager defaultManager] fileExistsAtPath:ourPath]) {
                    if (![self->_solar ourGalaxyModel]) failGalaxySmoke("real OurGalaxy model was not loaded");
                    [self setMilkyWayMode:MilkyWayMode::normal];
                    auto camera = [self->_solar cameraState];
                    camera.target = {0, 0, 0};
                    camera.distance_au = 20000 * astronomical_units_per_parsec;
                    camera.frame.reset();
                    [self->_solar setCameraState:camera];
                    [self->_solar displayIfNeeded];
                    state->phase = 10;
                    return;
                }
                std::printf("Solar/galaxy AppKit smoke: OurGalaxy data unavailable, draw check skipped\n");
                state->phase = 10;
            }
            if (state->phase == 10) {
                if ([self->_solar ourGalaxyModel]) {
                    [self->_solar displayIfNeeded];
                    const auto diag = [self->_solar galaxyOverlayDiagnostics];
                    if (diag.display != GalaxyOverlayDisplay::complete) return;
                    if (!diag.displayed || !solarGalaxyCameraMatches(diag.displayed->camera, [self->_solar cameraState]) ||
                        diag.our_galaxy_drawn == 0)
                        failGalaxySmoke("real OurGalaxy was not rendered with the current solar camera");
                    [self showOurGalaxyOverview:nil];
                    const auto center = our_galaxy_center({{0, 0, 0}});
                    const auto overview = [self->_solar cameraState];
                    if (![self->_solar isOurGalaxySelected] ||
                        overview.target.x != center.x_pc * astronomical_units_per_parsec ||
                        overview.target.y != center.y_pc * astronomical_units_per_parsec ||
                        overview.target.z != center.z_pc * astronomical_units_per_parsec)
                        failGalaxySmoke("OurGalaxy overview did not select and center the galaxy");
                    [self->_solar focusSelection];
                    if (!solarGalaxyVectorMatches(overview.target, [self->_solar cameraState].target))
                        failGalaxySmoke("OurGalaxy focus did not preserve the center");
                    [self->_solar setGalaxyModel:nullptr];
                    if (![self->_solar isOurGalaxySelected] ||
                        ![[self->_solar cameraStateDescription] containsString:@"選択天体を追従"] ||
                        !solarGalaxyVectorMatches(overview.target, [self->_solar cameraState].target))
                        failGalaxySmoke("SDSS replacement lost OurGalaxy selection or tracking");
                    [self->_solar setGalaxyModel:state->model];
                    const auto milkyWayMode = self->_sky.milkyWayMode;
                    [self setMilkyWayMode:MilkyWayMode::none];
                    if ([self->_solar isOurGalaxySelected] ||
                        [[self->_solar cameraStateDescription] containsString:@"選択天体を追従"])
                        failGalaxySmoke("hiding OurGalaxy retained its selection or tracking");
                    [self showOurGalaxyOverview:nil];
                    if ([self->_solar isOurGalaxySelected])
                        failGalaxySmoke("hidden OurGalaxy overview was selectable");
                    [self setMilkyWayMode:milkyWayMode];
                }
                const auto hip = [self->_solar hipModel];
                if (hip && !hip->points.empty()) {
                    const auto position = hip->points.front().position;
                    auto camera = [self->_solar cameraState];
                    camera.target = {position.x_pc * astronomical_units_per_parsec,
                                     position.y_pc * astronomical_units_per_parsec,
                                     position.z_pc * astronomical_units_per_parsec};
                    camera.distance_au = astronomical_units_per_parsec;
                    camera.frame.reset();
                    [self->_solar setCameraState:camera];
                    [self->_solar displayIfNeeded];
                    state->phase = 11;
                    return;
                }
                state->phase = 12;
            }
            if (state->phase == 11) {
                [self->_solar displayIfNeeded];
                const auto diag = [self->_solar galaxyOverlayDiagnostics];
                if (diag.display != GalaxyOverlayDisplay::complete) return;
                if (!diag.displayed || !solarGalaxyCameraMatches(diag.displayed->camera, [self->_solar cameraState]) ||
                    !diag.hip_drawn) failGalaxySmoke("HIP was not rendered with the current solar camera");
                const NSRect map = [self->_solar mapRect];
                [self->_solar pickBodyAtPoint:NSMakePoint(NSMidX(map), NSMidY(map))];
                state->phase = 111;
                return;
            }
            if (state->phase == 111) {
                const auto selected = [self->_solar selectedHipIndex];
                if (!selected) return;
                if (*selected != 0) failGalaxySmoke("HIP click did not select the displayed star");
                const auto before = [self->_solar cameraState];
                [self->_solar focusSelection];
                const auto after = [self->_solar cameraState];
                if (before.distance_au != after.distance_au || !solarGalaxyFrameMatches(before.frame, after.frame) ||
                    ![[self->_solar cameraStateDescription] containsString:@"選択天体を追従"])
                    failGalaxySmoke("HIP focus changed orientation or did not enable tracking");
                [self->_solar setGalaxyModel:nullptr];
                if ([self->_solar selectedHipIndex] != selected ||
                    ![[self->_solar cameraStateDescription] containsString:@"選択天体を追従"] ||
                    !solarGalaxyVectorMatches(after.target, [self->_solar cameraState].target))
                    failGalaxySmoke("SDSS replacement lost HIP selection or tracking");
                [self->_solar setGalaxyModel:state->model];
                if ([self->_solar selectedHipIndex] != selected ||
                    ![[self->_solar cameraStateDescription] containsString:@"選択天体を追従"])
                    failGalaxySmoke("SDSS restore lost HIP selection or tracking");
                // 地球付近で以前の表示下限を往復し、地表カメラの最小距離でも同じ恒星が描かれる。
                const auto star = [self->_solar hipModel]->points.front().position;
                const double x = star.x_pc - 1.0 / astronomical_units_per_parsec;
                const double y = star.y_pc, z = star.z_pc;
                auto closeCamera = [self->_solar cameraState];
                closeCamera.target = {1, 0, 0};
                closeCamera.distance_au = 1;
                closeCamera.frame.reset();
                closeCamera.yaw_deg = std::atan2(-y, -x) * 180 / std::acos(-1);
                closeCamera.pitch_deg = std::atan2(-z, std::hypot(x, y)) * 180 / std::acos(-1);
                closeCamera.frame = solar_camera_basis(closeCamera);
                for (const double distance : {0.207, 0.205, 0.207, minimum_shared_distance_au}) {
                    closeCamera.distance_au = distance;
                    [self->_solar setCameraState:closeCamera];
                    [self->_solar displayIfNeeded];
                    const auto nearDiag = [self->_solar galaxyOverlayDiagnostics];
                    if (nearDiag.display == GalaxyOverlayDisplay::none || !nearDiag.displayed || !nearDiag.hip_drawn ||
                        !solarGalaxyCameraMatches(nearDiag.displayed->camera, closeCamera))
                        failGalaxySmoke("HIP disappeared near the old 0.206 AU boundary or minimum distance");
                }
                // 恒星の表示設定は同じ 3D レイヤーにも届き、選択と追尾を解除する。
                auto stars = [self starDisplayOptions];
                const bool starsVisible = stars.visible;
                [self->_solar focusSelection];
                stars.visible = false;
                [self setStarDisplayOptions:stars];
                if ([self->_solar selectedHipIndex] ||
                    [[self->_solar cameraStateDescription] containsString:@"選択天体を追従"])
                    failGalaxySmoke("hiding HIP retained its selection or tracking");
                stars.visible = starsVisible;
                [self setStarDisplayOptions:stars];
                state->phase = 12;
            }
            if (state->phase == 12) {
                auto camera = [self->_solar cameraState];
                camera.target = {state->position.x_pc * astronomical_units_per_parsec,
                                 state->position.y_pc * astronomical_units_per_parsec,
                                 state->position.z_pc * astronomical_units_per_parsec};
                camera.distance_au = astronomical_units_per_parsec;
                auto framed = camera;
                framed.yaw_deg = 12;
                framed.pitch_deg = 20;
                framed.frame.reset();
                camera.frame = solar_camera_basis(framed);
                [self->_solar setCameraState:camera];
                [self->_solar displayIfNeeded];
                state->phase = 1;
                return;
            }
            if (state->phase == 1) {
                [self->_solar displayIfNeeded];
                const auto diag = [self->_solar galaxyOverlayDiagnostics];
                if (diag.display != GalaxyOverlayDisplay::complete) return;
                if (!diag.displayed || !solarGalaxyCameraMatches(diag.displayed->camera, [self->_solar cameraState]) ||
                    diag.displayed_drawn == 0)
                    failGalaxySmoke("real SDSS was not rendered with the current solar camera");
                const NSRect map = [self->_solar mapRect];
                const GalaxyProjector projector(diag.displayed->camera, map.size.width, map.size.height);
                const auto projected = projector.project(state->position);
                if (!projected || !projector.contains(*projected)) failGalaxySmoke("SDSS point not in map");
                [self->_solar pickBodyAtPoint:NSMakePoint(map.origin.x + projected->x, map.origin.y + projected->y)];
                state->phase = 2;
                return;
            }
            if (state->phase == 2) {
                const auto selected = [self->_solar selectedGalaxyRecord];
                if (!selected) return;
                if (!(*selected == state->expected)) failGalaxySmoke("selection did not use the displayed SDSS position");
                const auto beforeFocus = [self->_solar cameraState];
                [self->_solar focusSelection];
                const auto afterFocus = [self->_solar cameraState];
                if (!beforeFocus.frame || !solarGalaxyFrameMatches(beforeFocus.frame, afterFocus.frame) ||
                    beforeFocus.distance_au != afterFocus.distance_au)
                    failGalaxySmoke("SDSS focus changed the camera frame or distance");
                const auto target = afterFocus.target;
                const auto position = state->model->row(*selected).position;
                if (!position || target.x != position->x_pc * astronomical_units_per_parsec ||
                    target.y != position->y_pc * astronomical_units_per_parsec ||
                    target.z != position->z_pc * astronomical_units_per_parsec)
                    failGalaxySmoke("SDSS selection focus did not follow the selected position");
                if (![[self->_solar cameraStateDescription] containsString:@"選択天体を追従"])
                    failGalaxySmoke("SDSS focus did not enable tracking");
                const double savedJD = self->_jd;
                const auto range = self->_model->time_range();
                const double laterJD = savedJD < range.second ? std::min(savedJD + 0.01, range.second) : range.first;
                if (![self setDate:laterJD] || ![self setDate:savedJD])
                    failGalaxySmoke("could not change date while tracking SDSS");
                for (int i = 0; i < 23; ++i) {
                    [self->_solar zoomIn];
                    [self->_solar displayIfNeeded];
                }
                if ([self->_solar cameraState].distance_au >= 1000)
                    failGalaxySmoke("zoom could not approach below 1000 AU");
                bool overThousand = false, overParsec = false, underThousand = false, underParsec = false;
                for (int i = 0; i < 24; ++i) {
                    [self->_solar zoomOut];
                    const auto distance = [self->_solar cameraState].distance_au;
                    overThousand |= distance > 1000;
                    overParsec |= distance > astronomical_units_per_parsec;
                    [self->_solar displayIfNeeded];
                }
                for (int i = 0; i < 24; ++i) {
                    [self->_solar zoomIn];
                    const auto distance = [self->_solar cameraState].distance_au;
                    underParsec |= distance < astronomical_units_per_parsec;
                    underThousand |= distance < 1000;
                    [self->_solar displayIfNeeded];
                }
                const auto followed = [self->_solar cameraState].target;
                if (!overThousand || !overParsec || !underThousand || !underParsec)
                    failGalaxySmoke("zoom did not cross 1000 AU and 1 pc in both directions");
                if (followed.x != target.x || followed.y != target.y || followed.z != target.z ||
                    ![[self->_solar cameraStateDescription] containsString:@"選択天体を追従"])
                    failGalaxySmoke("zoom or date change lost the selected SDSS tracking target");
                // 最新入力の描画収束を、途中の完了画像と区別して待つ。
                [self->_solar zoomOut];
                [self->_solar orbitByX:11 y:-7];
                [self->_solar displayIfNeeded];
                state->latest = [self->_solar cameraState];
                state->phase = 3;
                return;
            }
            [self->_solar displayIfNeeded];
            const auto diag = [self->_solar galaxyOverlayDiagnostics];
            if (diag.display != GalaxyOverlayDisplay::complete || !diag.displayed ||
                !solarGalaxyCameraMatches(diag.displayed->camera, state->latest)) return;
            if (diag.displayed_drawn == 0) failGalaxySmoke("latest SDSS frame contained no rendered sources");
            [self->_solar focusSelection];
            [self->_solar setGalaxyModel:state->model];
            if (![self->_solar selectedGalaxyRecord] ||
                ![[self->_solar cameraStateDescription] containsString:@"選択天体を追従"])
                failGalaxySmoke("unchanged SDSS model lost selection or tracking");
            [self->_solar setGalaxyModel:nullptr];
            if ([self->_solar selectedGalaxyRecord] ||
                [[self->_solar cameraStateDescription] containsString:@"選択天体を追従"])
                failGalaxySmoke("replaced SDSS model retained stale selection or tracking");
            [self->_solar setGalaxyModel:state->model];
            [timer invalidate];
            [self->_solar resetCamera];
            std::printf("Solar/galaxy AppKit smoke passed: real OurGalaxy and HIP draw when available, real SDSS draw, selection/focus, 1000 AU and 1 pc zoom round trip, latest frame\n");
            completion();
        } catch (const std::exception& error) { failGalaxySmoke(error.what()); }
    }];
}
@end
