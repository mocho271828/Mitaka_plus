#import "AppControllerInternal.h"
#include <cstdio>
#include <cstdlib>
#include <stdexcept>

namespace {
enum class GalaxySmokePhase { cancel, data_generation, failure, partial_failure, invalidate, success };
struct GalaxySmokeState {
    unsigned checks = 0;
    std::shared_ptr<const GalaxySpatialModel> original =
        std::make_shared<const GalaxySpatialModel>(std::vector<GalaxySpatialSource>{});
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

@interface AppController (GalaxySmokePrivate)
- (void)runGalaxySmokePhase:(GalaxySmokePhase)phase state:(std::shared_ptr<GalaxySmokeState>)state
    completion:(void (^)(void))completion;
@end

@implementation AppController (GalaxySmokeTests)
- (void)runGalaxySmokeTestWithCompletion:(void (^)(void))completion {
    try {
        auto state = std::make_shared<GalaxySmokeState>();
        state->require(NSThread.isMainThread, "host smoke must run on the main thread");
        // 実際のホストと controller を使うが、利用者の状態や原本は試験へ渡さない。
        // Plus 読込を無効にした空 SDSS はファイル I/O を行わない。
        AppController *probe = [[AppController alloc] initWithDataRoot:nil smokeTest:YES];
        probe->_extendedCatalogs = std::make_shared<const ExtendedCatalogs>();
        probe->_galaxyBrowser = [[GalaxyController alloc] init];
        probe->_galaxyModel = state->original;
        probe->_galaxyUsesPlusCatalogs = YES;
        probe->_galaxyDiagnostics = @"retained galaxy source";
        [probe->_galaxyBrowser setModel:state->original diagnostics:probe->_galaxyDiagnostics];
        state->require(!probe->_galaxyBrowser.window.isVisible, "fixture window became visible");
        probe->_activePath = @"/mitaka-galaxy-smoke-memory-only";
        [probe prepareGalaxyForDataRoot:probe->_activePath];
        state->require(probe->_galaxyModel == state->original && probe->_galaxyUsesPlusCatalogs &&
            [probe->_galaxyBrowser.galaxyView model] == state->original,
            "same-root data reload discarded the displayed galaxy");
        [probe prepareGalaxyForDataRoot:@"/another-galaxy-root"];
        state->require(!probe->_galaxyModel && !probe->_galaxyUsesPlusCatalogs &&
            ![probe->_galaxyBrowser.galaxyView model], "changed root retained another root's galaxy");
        probe->_galaxyModel = state->original;
        probe->_galaxyUsesPlusCatalogs = YES;
        probe->_galaxyDiagnostics = @"retained galaxy source";
        [probe->_galaxyBrowser setModel:state->original diagnostics:probe->_galaxyDiagnostics];
        [probe runGalaxySmokePhase:GalaxySmokePhase::cancel state:state completion:completion];
    } catch (const std::exception& error) {
        failGalaxySmoke(error.what());
    }
}

- (void)runGalaxySmokePhase:(GalaxySmokePhase)phase state:(std::shared_ptr<GalaxySmokeState>)state
    completion:(void (^)(void))completion {
    try {
        _activePath = phase == GalaxySmokePhase::failure ? @"" :
            phase == GalaxySmokePhase::partial_failure ? @"/dev/null" : @"/mitaka-galaxy-smoke-memory-only";
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
                    !_galaxyModel && !_galaxyUsesPlusCatalogs && ![_galaxyBrowser.galaxyView model],
                    "invalidate did not clear host and view while cancelling the job");
                break;
            case GalaxySmokePhase::failure:
            case GalaxySmokePhase::partial_failure:
            case GalaxySmokePhase::success:
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
                            [_galaxyBrowser.galaxyView model] == state->original,
                            "late result replaced the retained host/view model or diagnostics");
                        break;
                    case GalaxySmokePhase::failure:
                        state->require(_galaxyModel == state->original && _galaxyUsesPlusCatalogs &&
                            [_galaxyBrowser.galaxyView model] == state->original &&
                            [_galaxyDiagnostics containsString:@"銀河の読込に失敗"],
                            "failed load discarded the previous model or hid its diagnostic");
                        break;
                    case GalaxySmokePhase::partial_failure:
                        state->require(_galaxyModel == state->original && _galaxyUsesPlusCatalogs &&
                            [_galaxyBrowser.galaxyView model] == state->original &&
                            [_galaxyDiagnostics containsString:@"銀河の再読込に失敗"] &&
                            [_galaxyDiagnostics containsString:@"globular_cluster.dat"] &&
                            [_galaxyDiagnostics containsString:@"NBG.dat"],
                            "partial Plus reload discarded the previous model or hid failed sources");
                        break;
                    case GalaxySmokePhase::invalidate:
                        state->require(!_galaxyModel && !_galaxyUsesPlusCatalogs &&
                            ![_galaxyBrowser.galaxyView model] && [_galaxyDiagnostics isEqualToString:@"データ未読込"],
                            "late result restored an invalidated model");
                        break;
                    case GalaxySmokePhase::success:
                        state->require(_galaxyModel && _galaxyModel != state->original &&
                            _galaxyModel->size() == 0 && _galaxyModel->sources().size() == 2 &&
                            !_galaxyUsesPlusCatalogs && _galaxyDiagnostics.length == 0 &&
                            [_galaxyBrowser.galaxyView model] == _galaxyModel,
                            "successful job did not publish the new SDSS model to its controller");
                        for (std::size_t source = 0; source < _galaxyModel->sources().size(); ++source)
                            state->require(_galaxyModel->source_path(source).parent_path() ==
                                std::filesystem::path(_activePath.fileSystemRepresentation),
                                "successful model retained another data root");
                        [self invalidateGalaxy];
                        state->require(!_galaxyBrowser.window.isVisible, "host smoke opened its fixture window");
                        std::printf("Galaxy host smoke passed: %u checks; cancel/data-generation/failure/partial-failure/invalidate/success\n",
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
