#import "AppControllerInternal.h"
#import "SolarSystemViewInternal.h"
#include "galaxy_spatial_load.hpp"
#include "mitaka/our_galaxy_model.hpp"

namespace {
NSString *diagnosticText(const std::vector<std::string>& diagnostics) {
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    for (const auto& diagnostic : diagnostics) {
        NSString *line = [[NSString alloc] initWithBytes:diagnostic.data() length:diagnostic.size()
            encoding:NSUTF8StringEncoding];
        [lines addObject:line ? line : @"診断にUTF-8以外の文字が含まれています。"];
    }
    return [lines componentsJoinedByString:@"\n"];
}
}

@interface AppController (GalaxyStatusPresentation)
- (void)refreshPresentation;
@end

@implementation AppController (GalaxyCommands)
- (void)prepareGalaxyForDataRoot:(NSString *)path {
    // 同じ出典の再読込中は旧モデルを維持する。別出典の表示は混在させない。
    if (_activePath && [_activePath isEqualToString:path]) [self cancelGalaxyLoading];
    else [self invalidateGalaxy];
}
- (void)showOurGalaxyOverview:(id)sender {
    (void)sender;
    if (![_solar ourGalaxyModel]) return;
    if (_mode.selectedSegment != 1) { _mode.selectedSegment = 1; [self changeMode:nil]; }
    [_solar showOurGalaxyOverview];
}
- (void)showGalaxyBrowser:(id)sender {
    if (!_extendedCatalogs || _loading) return;
    if (!_galaxyBrowser) {
        _galaxyBrowser = [[GalaxyController alloc] init];
        __weak AppController *weakSelf = self;
        _galaxyBrowser.visibilityChanged = ^(GalaxySpatialVisibility visibility) {
            AppController *controller = weakSelf;
            if (controller) [controller->_solar setGalaxyVisibility:visibility];
        };
        [_galaxyBrowser setRendererDisplayOptions:[self rendererDisplayOptions]];
        [_galaxyBrowser setModel:_galaxyModel diagnostics:_galaxyDiagnostics ? _galaxyDiagnostics : @""];
    }
    [_galaxyBrowser showWindow:sender];
    if (!_galaxyModel && !_galaxyLoading) [self loadGalaxyIncludingPlus:NO];
}
- (void)loadPlusGalaxyCatalogs:(id)sender {
    if (!_extendedCatalogs || _loading || _galaxyLoading) return;
    // この操作を選んだ場合だけ、同名の通常版ファイルとは異なるPlus形式として読む。
    (void)sender;
    [self loadGalaxyIncludingPlus:YES showMainWhenReady:YES];
}
- (void)loadGalaxyIncludingPlus:(BOOL)includePlus {
    [self loadGalaxyIncludingPlus:includePlus showMainWhenReady:NO];
}
- (void)loadGalaxyIncludingPlus:(BOOL)includePlus showMainWhenReady:(BOOL)showMainWhenReady {
    if (!_extendedCatalogs || !_activePath || _loading) return;
    if (_galaxyCancellation) _galaxyCancellation->store(true);
    const auto cancellation = std::make_shared<std::atomic_bool>(false);
    _galaxyCancellation = cancellation;
    _galaxyLoading = YES;
    const NSUInteger generation = ++_galaxyGeneration, dataGeneration = _loadGeneration;
    const NSUInteger modeGeneration = _modeGeneration;
    const NSInteger initialMode = _mode.selectedSegment;
    const auto catalogs = _extendedCatalogs;
    // NSString は空文字を fileSystemRepresentation に変換できない。
    // 空の出典はローダー側でエラーにし、表示中のモデルを保持する。
    const std::filesystem::path directory = _activePath.length
        ? std::filesystem::path(_activePath.fileSystemRepresentation) : std::filesystem::path{};
    NSString *progress = includePlus ? @"SDSSと、選択フォルダの旧Plus形式を読み込み中…"
                                    : @"読み込み済みSDSSから3D位置を計算中…";
    [_galaxyBrowser setModel:_galaxyModel diagnostics:progress];
    if (_model && !_loading) [self refreshPresentation];
    __weak AppController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        GalaxySpatialLoadResult result;
        std::shared_ptr<const mitaka::OurGalaxyModel> ourGalaxy;
        NSString *failure = nil;
        try {
            result = load_galaxy_spatial_model(directory, *catalogs, includePlus, {},
                [cancellation] { return cancellation->load(); });
            if (!result.cancelled && !cancellation->load()) {
                try {
                    ourGalaxy = std::make_shared<const mitaka::OurGalaxyModel>(
                        mitaka::load_our_galaxy_model(directory / "ourgalaxy_model.dat"));
                } catch (const mitaka::CatalogError& error) {
                    result.diagnostics.push_back(error.what());
                }
            }
        } catch (const std::exception& error) {
            failure = [NSString stringWithFormat:@"銀河の読込に失敗: %s", error.what()];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            AppController *controller = weakSelf;
            if (!controller || cancellation->load() || generation != controller->_galaxyGeneration ||
                dataGeneration != controller->_loadGeneration) return;
            controller->_galaxyLoading = NO;
            controller->_galaxyCancellation.reset();
            if (result.cancelled) return;
            if (failure) {
                controller->_galaxyDiagnostics = failure;
            } else if (result.plus_source_failed && controller->_galaxyModel) {
                controller->_galaxyDiagnostics = [@"銀河の再読込に失敗したため、直前のモデルを表示しています。\n"
                    stringByAppendingString:diagnosticText(result.diagnostics)];
            } else {
                controller->_galaxyModel = result.model;
                controller->_galaxyUsesPlusCatalogs = includePlus;
                controller->_galaxyDiagnostics = diagnosticText(result.diagnostics);
                [controller->_solar setGalaxyModel:controller->_galaxyModel];
                if (ourGalaxy) [controller->_solar setOurGalaxyModel:ourGalaxy];
                // 読込中にモード変更された場合は、後着した結果で操作を覆さない。
                if (showMainWhenReady && !result.plus_source_failed && initialMode != 1 &&
                    controller->_modeGeneration == modeGeneration && controller->_mode.selectedSegment == initialMode) {
                    controller->_mode.selectedSegment = 1;
                    [controller changeMode:nil];
                    [controller->_solar showGalaxyCatalogOverview];
                }
            }
            [controller->_galaxyBrowser setModel:controller->_galaxyModel diagnostics:controller->_galaxyDiagnostics];
            if (controller->_model && !controller->_loading) [controller refreshPresentation];
            [NSApp.mainMenu update];
        });
    });
}
- (void)cancelGalaxyLoading {
    ++_galaxyGeneration;
    if (_galaxyCancellation) _galaxyCancellation->store(true);
    _galaxyCancellation.reset();
    _galaxyLoading = NO;
    [_galaxyBrowser setModel:_galaxyModel diagnostics:_galaxyDiagnostics ? _galaxyDiagnostics : @""];
    if (_model && !_loading) [self refreshPresentation];
}
- (void)invalidateGalaxy {
    [self cancelGalaxyLoading];
    _galaxyModel.reset();
    _galaxyUsesPlusCatalogs = NO;
    _galaxyDiagnostics = @"データ未読込";
    [_solar setGalaxyModel:nullptr];
    [_solar setOurGalaxyModel:nullptr];
    [_galaxyBrowser invalidate];
    [_galaxyBrowser setModel:nullptr diagnostics:_galaxyDiagnostics];
    if (_model && !_loading) [self refreshPresentation];
}
@end
