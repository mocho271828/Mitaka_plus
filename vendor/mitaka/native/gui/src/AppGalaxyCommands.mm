#import "AppControllerInternal.h"
#include "galaxy_spatial_load.hpp"

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

@implementation AppController (GalaxyCommands)
- (void)prepareGalaxyForDataRoot:(NSString *)path {
    // 同じ出典の再読込中は旧モデルを維持する。別出典の表示は混在させない。
    if (_activePath && [_activePath isEqualToString:path]) [self cancelGalaxyLoading];
    else [self invalidateGalaxy];
}
- (void)showGalaxyBrowser:(id)sender {
    if (!_extendedCatalogs || _loading) return;
    if (!_galaxyBrowser) {
        _galaxyBrowser = [[GalaxyController alloc] init];
        [_galaxyBrowser setRendererDisplayOptions:[self rendererDisplayOptions]];
        [_galaxyBrowser setModel:_galaxyModel diagnostics:_galaxyDiagnostics ? _galaxyDiagnostics : @""];
    }
    [_galaxyBrowser showWindow:sender];
    if (!_galaxyModel && !_galaxyLoading) [self loadGalaxyIncludingPlus:NO];
}
- (void)loadPlusGalaxyCatalogs:(id)sender {
    if (!_extendedCatalogs || _loading || _galaxyLoading) return;
    // この操作を選んだ場合だけ、同名の通常版ファイルとは異なるPlus形式として読む。
    [self loadGalaxyIncludingPlus:YES];
    [self showGalaxyBrowser:sender];
}
- (void)loadGalaxyIncludingPlus:(BOOL)includePlus {
    if (!_extendedCatalogs || !_activePath || _loading) return;
    if (_galaxyCancellation) _galaxyCancellation->store(true);
    const auto cancellation = std::make_shared<std::atomic_bool>(false);
    _galaxyCancellation = cancellation;
    _galaxyLoading = YES;
    const NSUInteger generation = ++_galaxyGeneration, dataGeneration = _loadGeneration;
    const auto catalogs = _extendedCatalogs;
    // NSString は空文字を fileSystemRepresentation に変換できない。
    // 空の出典はローダー側でエラーにし、表示中のモデルを保持する。
    const std::filesystem::path directory = _activePath.length
        ? std::filesystem::path(_activePath.fileSystemRepresentation) : std::filesystem::path{};
    NSString *progress = includePlus ? @"SDSSと、選択フォルダの旧Plus形式を読み込み中…"
                                    : @"読み込み済みSDSSから3D位置を計算中…";
    [_galaxyBrowser setModel:_galaxyModel diagnostics:progress];
    __weak AppController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        GalaxySpatialLoadResult result;
        NSString *failure = nil;
        try {
            result = load_galaxy_spatial_model(directory, *catalogs, includePlus, {},
                [cancellation] { return cancellation->load(); });
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
            }
            [controller->_galaxyBrowser setModel:controller->_galaxyModel diagnostics:controller->_galaxyDiagnostics];
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
}
- (void)invalidateGalaxy {
    [self cancelGalaxyLoading];
    _galaxyModel.reset();
    _galaxyUsesPlusCatalogs = NO;
    _galaxyDiagnostics = @"データ未読込";
    [_galaxyBrowser invalidate];
    [_galaxyBrowser setModel:nullptr diagnostics:_galaxyDiagnostics];
}
@end
