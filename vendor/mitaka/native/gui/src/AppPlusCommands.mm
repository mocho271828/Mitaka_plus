#import "AppControllerInternal.h"
#include <stdexcept>

static NSMenuItem *command(NSMenu *menu, NSString *title, SEL action, id target, NSString *key = @"") {
    NSMenuItem *item = [menu addItemWithTitle:title action:action keyEquivalent:key];
    item.target = target;
    return item;
}

static NSMenu *submenu(NSMenu *parent, NSString *title) {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
    NSMenu *menu = [[NSMenu alloc] initWithTitle:title];
    item.submenu = menu;
    [parent addItem:item];
    return menu;
}

@implementation AppController (PlusCommands)
- (void)addPlusMenus:(NSMenu *)menu fileMenu:(NSMenu *)fileMenu {
    [fileMenu addItem:NSMenuItem.separatorItem];
    command(fileMenu, @"表示状態を保存…", @selector(saveSession:), self, @"s");
    command(fileMenu, @"表示状態を開く…", @selector(openSession:), self);
    command(fileMenu, @"ローカル画像・動画・音声を開く…", @selector(openLocalMedia:), self);
    NSMenu *capture = submenu(fileMenu, @"画像を保存");
    for (NSInteger i = 0; i < 3; ++i)
        command(capture, @[@"PNG…", @"JPEG…", @"BMP…"][i], @selector(captureImage:), self).tag = i;
    NSMenu *view = submenu(menu, @"表示");
    command(view, @"視野角を 45° に戻す", @selector(resetViewAngle:), self);
    command(view, @"天体ブラウザ…", @selector(showBrowser:), self, @"f");
    command(view, @"小惑星・彗星ブラウザ…", @selector(showSmallBodyBrowser:), self);
    command(view, @"衛星ブラウザ…", @selector(showSatelliteBrowser:), self);
    command(view, @"探査機ブラウザ…", @selector(showSpacecraftBrowser:), self);
    command(view, @"銀河・球状星団の3D表示…", @selector(showGalaxyBrowser:), self);
    command(view, @"天の川銀河の全景（近似）", @selector(showOurGalaxyOverview:), self);
    command(view, @"旧Plus形式の球状星団・近傍銀河を読み込む", @selector(loadPlusGalaxyCatalogs:), self);
    command(view, @"画像・動画・音声ブラウザ…", @selector(showMediaBrowser:), self);
    command(view, @"太陽系の小天体を表示", @selector(toggleSmallBodies:), self);
    command(view, @"太陽系の衛星を表示", @selector(toggleSatellites:), self);
    command(view, @"太陽系の探査機を表示", @selector(toggleSpacecraft:), self);
    NSMenu *spacecraft = submenu(view, @"探査機の表示");
    NSArray<NSString *> *spacecraftLayers = @[@"位置の点", @"名称", @"原データの軌跡"];
    for (NSUInteger i = 0; i < spacecraftLayers.count; ++i)
        command(spacecraft, spacecraftLayers[i], @selector(toggleSpacecraftDisplay:), self).tag = i;
    command(view, @"観測地点…", @selector(showObserver:), self);
    command(view, @"天体の表示半径倍率…", @selector(showRadiusDisplay:), self);
    command(view, @"ローカル地形を再読込", @selector(reloadTerrain:), self);
    [view addItem:NSMenuItem.separatorItem];
    [self addDisplayMenus:view];
    NSArray<NSString *> *titles = @[@"星座線", @"星座境界", @"星座名", @"NGC・IC", @"SDSS 銀河", @"SDSS QSO", @"星座絵"];
    for (NSUInteger i = 0; i < titles.count; ++i) {
        NSMenuItem *item = command(view, titles[i], @selector(toggleDisplay:), self);
        item.tag = i;
    }
    NSMenu *milkyWay = submenu(view, @"天の川");
    NSArray<NSString *> *backgrounds = @[@"非表示", @"通常", @"明るく", @"赤外線"];
    for (NSUInteger i = 0; i < backgrounds.count; ++i)
        command(milkyWay, backgrounds[i], @selector(selectMilkyWay:), self).tag = i;
    [view addItem:NSMenuItem.separatorItem];
    command(view, @"表示状態を記憶する", @selector(rememberSession:), self);
    command(view, @"表示状態を呼び出す", @selector(restoreSession:), self);
    command(view, @"投影ウィンドウを開く", @selector(showProjection:), self);
    command(view, @"投影ポインタを切り替え", @selector(toggleProjectionPointer:), self);
    command(view, @"投影の暗転を切り替え", @selector(toggleProjectionFade:), self);
    NSMenu *script = submenu(menu, @"スクリプト");
    command(script, @"ローカル Lua を実行…", @selector(runScript:), self);
    command(script, @"信頼したローカルHTML…", @selector(showHtmlBrowser:), self);
    command(script, @"実行を停止", @selector(cancelScript:), self);
    command(script, @"実行ログ", @selector(showScriptConsole:), self);
    [self addTimeMenu:menu];
}
- (void)showRadiusDisplay:(id)sender {
    (void)sender;
    if (!_radiusDisplayController) {
        _radiusDisplayController = [[RadiusDisplayController alloc] init];
        __weak AppController *weakSelf = self;
        _radiusDisplayController.readSettings = ^BOOL(RadiusDisplayOptions *options, RadiusScaleMode *mode, NSString **error) {
            AppController *controller = weakSelf;
            if (!controller) {
                if (error) *error = @"表示半径設定の適用先が終了しました。";
                return NO;
            }
            return [controller readRadiusDisplayOptions:options mode:mode error:error];
        };
        _radiusDisplayController.applySettings = ^BOOL(RadiusDisplayOptions options, RadiusScaleMode mode, NSString **error) {
            AppController *controller = weakSelf;
            if (!controller) {
                if (error) *error = @"表示半径設定の適用先が終了しました。";
                return NO;
            }
            return [controller applyRadiusDisplayOptions:options mode:mode error:error];
        };
    }
    [_radiusDisplayController showWindow:nil];
}
- (void)showBrowser:(id)sender {
    (void)sender;
    if (!_browser) {
        _browser = [[CatalogBrowserController alloc] init];
        __weak AppController *weakSelf = self;
        _browser.chooseObject = ^(CatalogBrowserEntry *object, BOOL center) {
            [weakSelf chooseBrowserEntry:object center:center];
        };
        [self configureConstellationBrowser];
        [self configureStarNameBrowser];
        [self rebuildBrowser];
    }
    [_browser showWindow:nil];
}
- (void)showMediaBrowser:(id)sender {
    (void)sender;
    if (!_mediaBrowser) {
        _mediaBrowser = [[MediaController alloc] init];
        if (_activePath) [_mediaBrowser loadDataDirectory:[NSURL fileURLWithPath:_activePath isDirectory:YES]];
    }
    [_mediaBrowser showWindow:nil];
}
- (void)openLocalMedia:(id)sender {
    [self showMediaBrowser:sender];
    [_mediaBrowser openLocalMedia:sender];
}
- (void)rebuildBrowser {
    if (_browser && _model) {
        [_browser setModel:_model extendedCatalogs:_extendedCatalogs];
    }
}
- (void)chooseBrowserEntry:(CatalogBrowserEntry *)object center:(BOOL)center {
    if (!_model || _loading) return;
    if (object.kind == CatalogObjectPlanet) {
        if (object.identifier < 0 || object.identifier >= (NSInteger)_solarBodies.size()) return;
        NSButton *sender = [[NSButton alloc] init];
        sender.tag = object.identifier;
        if (_mode.selectedSegment != 1 && object.identifier == 3) { _mode.selectedSegment = 1; [self changeMode:nil]; }
        [self selectBody:sender];
        if (center) [self focusSelection:nil];
        return;
    }
    if (object.kind == CatalogObjectConstellation) {
        if (object.identifier >= 0 && object.identifier < (NSInteger)_model->constellations().size())
            [self revealConstellationRow:object.identifier center:center];
        return;
    }
    _mode.selectedSegment = 0;
    [self changeMode:nil];
    if (object.kind == CatalogObjectStar) {
        if ([_sky selectStarHIP:(int32_t)object.identifier] && center) [_sky focusSelection];
        _magnitudeSlider.doubleValue = _sky.magnitudeLimit;
    } else {
        const auto kind = object.kind == CatalogObjectNebula ? SkyCatalogKind::nebula :
            object.kind == CatalogObjectGalaxy ? SkyCatalogKind::galaxy : SkyCatalogKind::quasar;
        [_sky selectDeepSkyKind:kind index:object.identifier];
        if (center) [_sky focusSelection];
    }
    _horizon.magnitudeLimit = _sky.magnitudeLimit;
    [_solar setSurfaceMagnitudeLimit:_sky.magnitudeLimit];
    _magnitudeSlider.doubleValue = _sky.magnitudeLimit;
    _magnitudeLabel.stringValue = [NSString stringWithFormat:@"V 等級 ≤ %.1f", _sky.magnitudeLimit];
    [self refresh];
}
- (void)toggleDisplay:(NSMenuItem *)sender {
    if ((sender.tag >= 0 && sender.tag <= 2) || sender.tag == 6) {
        auto options = [self constellationDisplayOptions];
        if (sender.tag == 0) options.lines = !options.lines;
        else if (sender.tag == 1) options.boundaries = !options.boundaries;
        else if (sender.tag == 2) options.labels = !options.labels;
        else options.illustrations = !options.illustrations;
        [self setConstellationDisplayOptions:options];
        if (_model) [self refresh];
        return;
    }
    switch (sender.tag) {
        case 3: _sky.showsNebulae = !_sky.showsNebulae; break;
        case 4: _sky.showsGalaxies = !_sky.showsGalaxies; break;
        case 5: _sky.showsQuasars = !_sky.showsQuasars; break;
        default: return;
    }
    _mode.selectedSegment = 0;
    [self changeMode:nil];
}
- (void)selectMilkyWay:(NSMenuItem *)sender {
    if (sender.tag < 0 || sender.tag > 3) return;
    [self setMilkyWayMode:static_cast<MilkyWayMode>(sender.tag)];
}
- (BOOL)validateMenuItem:(NSMenuItem *)item {
    if (item.action == @selector(resetViewAngle:))
        return _model && !_loading && _mode.selectedSegment == 2 && !_horizonProjectionTimer &&
            [_horizon viewport].perspective_blend == 0;
    if (item.action == @selector(showRadiusDisplay:)) return _model && !_loading;
    if (item.action == @selector(reloadTerrain:)) return _model && !_loading;
    if (item.action == @selector(showOurGalaxyOverview:)) return [_solar ourGalaxyModel] != nullptr;
    if (item.action == @selector(showGalaxyBrowser:)) return _extendedCatalogs && !_loading;
    if (item.action == @selector(loadPlusGalaxyCatalogs:)) return _extendedCatalogs && !_loading && !_galaxyLoading;
    if (item.action == @selector(toggleMainFullScreen:) || item.action == @selector(showAbout:))
        return [self validateWindowMenuItem:item];
    if (item.action == @selector(togglePlanetDisplay:) || item.action == @selector(selectTerrainAmplification:) || item.action == @selector(toggleStarDisplay:) ||
        item.action == @selector(toggleEarthLayer:) || item.action == @selector(selectAtmosphereMode:) ||
        item.action == @selector(toggleEclipseDisplay:) || item.action == @selector(toggleLandscapeImage:) ||
        item.action == @selector(selectStarMarking:) || item.action == @selector(toggleGridDisplay:) ||
        item.action == @selector(toggleRendererDisplay:) || item.action == @selector(changeStarBrightness:))
        return [self validateDisplayMenuItem:item];
    if (item.action == @selector(toggleSmallBodies:)) {
        item.state = _solar.smallBodiesVisible ? NSControlStateValueOn : NSControlStateValueOff;
        return _smallBodyModel && !_loading;
    }
    if (item.action == @selector(showSmallBodyBrowser:)) return _smallBodyModel && !_loading;
    if (item.action == @selector(showSatelliteBrowser:) || item.action == @selector(toggleSatellites:)) {
        if (item.action == @selector(toggleSatellites:))
            item.state = [self satelliteDisplayOptions].visible ? NSControlStateValueOn : NSControlStateValueOff;
        return _satelliteModel && !_loading;
    }
    if (item.action == @selector(selectMilkyWay:)) {
        item.state = item.tag == static_cast<NSInteger>(_sky.milkyWayMode) ? NSControlStateValueOn : NSControlStateValueOff;
        return _model && !_loading;
    }
    if (item.action == @selector(showSpacecraftBrowser:) || item.action == @selector(toggleSpacecraft:) ||
        item.action == @selector(toggleSpacecraftDisplay:)) {
        if (item.action == @selector(toggleSpacecraft:))
            item.state = _solar.spacecraftVisible ? NSControlStateValueOn : NSControlStateValueOff;
        if (item.action == @selector(toggleSpacecraftDisplay:)) {
            const auto options = _solar.spacecraftDisplayOptions;
            const bool values[] = {options.points, options.labels, options.orbits};
            if (item.tag < 0 || item.tag >= 3) return NO;
            item.state = values[item.tag] ? NSControlStateValueOn : NSControlStateValueOff;
        }
        return _spacecraftModel && !_loading;
    }
    if (item.action == @selector(toggleDisplay:)) {
        const BOOL values[] = {_sky.showsConstellationLines, _sky.showsConstellationBoundaries, _sky.showsConstellationNames,
            _sky.showsNebulae, _sky.showsGalaxies, _sky.showsQuasars, [self constellationDisplayOptions].illustrations};
        if (item.tag >= 0 && item.tag < 7) item.state = values[item.tag] ? NSControlStateValueOn : NSControlStateValueOff;
        return _model && !_loading;
    }
    if (item.action == @selector(showPlusTimeZone:) || item.action == @selector(showCalendar:) || item.action == @selector(setCurrentTime:) ||
        item.action == @selector(stepTime:) || item.action == @selector(selectTimeStep:) ||
        item.action == @selector(toggleClockTracking:) || item.action == @selector(toggleTimeInfo:))
        return [self validateTimeMenuItem:item];
    return YES;
}
@end
