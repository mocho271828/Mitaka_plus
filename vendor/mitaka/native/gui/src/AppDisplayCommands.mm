#import "AppControllerInternal.h"
#include <array>
#include <stdexcept>

namespace {
constexpr std::array<bool PlanetDisplayOptions::*, 4> planetFlags{{
    &PlanetDisplayOptions::visible, &PlanetDisplayOptions::labels,
    &PlanetDisplayOptions::orbits, &PlanetDisplayOptions::axes}};
constexpr std::array<bool EclipseDisplayOptions::*, 4> eclipseFlags{{
    &EclipseDisplayOptions::shadows, &EclipseDisplayOptions::shadow_borders,
    &EclipseDisplayOptions::shadow_umbra, &EclipseDisplayOptions::shadow_penumbra}};
constexpr std::array<bool StarDisplayOptions::*, 6> starFlags{{
    &StarDisplayOptions::visible, &StarDisplayOptions::proper_names, &StarDisplayOptions::bayer_labels,
    &StarDisplayOptions::flamsteed_labels, &StarDisplayOptions::hip_labels,
    &StarDisplayOptions::selected_proper_names_only}};
constexpr std::array<bool GridDisplayOptions::*, 6> gridFlags{{
    &GridDisplayOptions::equatorial, &GridDisplayOptions::ecliptic, &GridDisplayOptions::galactic,
    &GridDisplayOptions::horizontal, &GridDisplayOptions::circle_scales, &GridDisplayOptions::square_scales}};
constexpr std::array<bool RendererDisplayOptions::*, 4> rendererFlags{{
    &RendererDisplayOptions::antialias, &RendererDisplayOptions::point_smoothing,
    &RendererDisplayOptions::line_smoothing, &RendererDisplayOptions::text_smoothing}};

NSMenu *displaySubmenu(NSMenu *parent, NSString *title, NSArray<NSString *> *titles, SEL action, id target) {
    NSMenuItem *group = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
    group.submenu = [[NSMenu alloc] initWithTitle:title];
    [parent addItem:group];
    for (NSUInteger index = 0; index < titles.count; ++index) {
        NSMenuItem *item = [group.submenu addItemWithTitle:titles[index] action:action keyEquivalent:@""];
        item.target = target;
        item.tag = index;
    }
    return group.submenu;
}

template <class Options, std::size_t Count>
bool toggleOption(Options& options, const std::array<bool Options::*, Count>& flags, NSInteger tag) {
    if (tag < 0 || static_cast<std::size_t>(tag) >= Count) return false;
    bool& value = options.*flags[tag];
    value = !value;
    return true;
}

template <class Options, std::size_t Count>
bool checkOption(NSMenuItem *item, const Options& options, const std::array<bool Options::*, Count>& flags) {
    if (item.tag < 0 || static_cast<std::size_t>(item.tag) >= Count) return false;
    item.state = options.*flags[item.tag] ? NSControlStateValueOn : NSControlStateValueOff;
    return true;
}
}

@implementation AppController (DisplayCommands)
- (void)reloadTerrain:(id)sender {
    (void)sender;
    if (_model && !_loading) [_solar reloadTerrain];
}
- (void)setMilkyWayMode:(MilkyWayMode)mode {
    switch (mode) {
        case MilkyWayMode::none: case MilkyWayMode::normal:
        case MilkyWayMode::bright: case MilkyWayMode::infrared: break;
        default: throw std::invalid_argument("invalid Milky Way mode");
    }
    _sky.milkyWayMode = mode;
    _horizon.milkyWayMode = mode;
    _solar.surfaceMilkyWayMode = mode;
    [_solar setOurGalaxyVisible:mode != MilkyWayMode::none];
    [NSApp.mainMenu update];
}
- (PlanetDisplayOptions)planetDisplayOptions { return _solar.planetDisplayOptions; }
- (TerrainAmplification)terrainAmplification { return _solar.terrainAmplification; }
- (void)setTerrainAmplification:(TerrainAmplification)value {
    _solar.terrainAmplification = value;
    [NSApp.mainMenu update];
}
- (void)setPlanetDisplayOptions:(const PlanetDisplayOptions&)options {
    _sky.planetDisplayOptions = options;
    _horizon.planetDisplayOptions = options;
    _solar.planetDisplayOptions = options;
    [NSApp.mainMenu update];
}
- (StarDisplayOptions)starDisplayOptions { return _sky.starDisplayOptions; }
- (EarthLayerOptions)earthLayerOptions { return _solar.earthLayerOptions; }
- (void)setEarthLayerOptions:(const EarthLayerOptions&)options {
    _solar.earthLayerOptions = options;
    [NSApp.mainMenu update];
}
- (AtmosphereDisplayOptions)atmosphereDisplayOptions { return _solar.atmosphereDisplayOptions; }
- (EclipseDisplayOptions)eclipseDisplayOptions { return _solar.eclipseDisplayOptions; }
- (void)setEclipseDisplayOptions:(const EclipseDisplayOptions&)options {
    _solar.eclipseDisplayOptions = options;
    [NSApp.mainMenu update];
}
- (void)setAtmosphereDisplayOptions:(const AtmosphereDisplayOptions&)options {
    validate_atmosphere_display(options);
    _solar.atmosphereDisplayOptions = options;
    [NSApp.mainMenu update];
}
- (void)setStarDisplayOptions:(const StarDisplayOptions&)options {
    validate_star_display(options);
    _sky.starDisplayOptions = options;
    _horizon.starDisplayOptions = options;
    [_solar setSurfaceStarDisplayOptions:options];
    [_solar setHipVisible:options.visible];
    if (_model && !_loading) [self refresh];
    [NSApp.mainMenu update];
}
- (GridDisplayOptions)gridDisplayOptions { return _sky.gridDisplayOptions; }
- (void)setGridDisplayOptions:(const GridDisplayOptions&)options {
    _sky.gridDisplayOptions = options;
    _horizon.gridDisplayOptions = options;
    _solar.gridDisplayOptions = options;
    [NSApp.mainMenu update];
}
- (void)addDisplayMenus:(NSMenu *)menu {
    NSMenu *planets = displaySubmenu(menu, @"惑星・月", @[@"表示", @"名前", @"軌道", @"自転軸"],
                   @selector(togglePlanetDisplay:), self);
    displaySubmenu(planets, @"地形の高さ", @[@"1 倍", @"2 倍", @"5 倍", @"10 倍", @"20 倍"],
                   @selector(selectTerrainAmplification:), self);
    NSMenu *earth = displaySubmenu(planets, @"地球", @[@"雲", @"夜景を強調"], @selector(toggleEarthLayer:), self);
    NSMenuItem *landscape = [earth addItemWithTitle:@"地平の風景画像" action:@selector(toggleLandscapeImage:) keyEquivalent:@""];
    landscape.target = self;
    displaySubmenu(planets, @"大気", @[@"なし", @"単一散乱", @"多重散乱"], @selector(selectAtmosphereMode:), self);
    displaySubmenu(planets, @"食と影", @[@"天体表面の影", @"影の境界", @"本影の円錐", @"半影の円錐"], @selector(toggleEclipseDisplay:), self);
    NSMenu *stars = displaySubmenu(menu, @"恒星", @[@"表示", @"固有名", @"バイエル符号", @"フラムスティード番号", @"HIP 番号", @"選んだ固有名のみ"],
                                  @selector(toggleStarDisplay:), self);
    displaySubmenu(stars, @"マーク", @[@"なし", @"連星", @"系外惑星のある恒星"],
                   @selector(selectStarMarking:), self);
    displaySubmenu(stars, @"明るさ", @[@"明るくする", @"暗くする", @"初期値に戻す"],
                   @selector(changeStarBrightness:), self);
    displaySubmenu(menu, @"座標線・距離目盛", @[@"赤道座標", @"黄道", @"銀河座標", @"地平座標", @"円形の距離目盛", @"方眼の距離目盛"],
                   @selector(toggleGridDisplay:), self);
    NSMenu *renderer = displaySubmenu(menu, @"描画品質", @[@"アンチエイリアス", @"点を滑らかに描画", @"線を滑らかに描画", @"文字を滑らかに描画"],
                   @selector(toggleRendererDisplay:), self);
    [renderer addItem:NSMenuItem.separatorItem];
    NSMenuItem *settings = [renderer addItemWithTitle:@"描画品質の設定…" action:@selector(showRendererOptions:) keyEquivalent:@""];
    settings.target = self;
}
- (void)showRendererOptions:(id)sender {
    (void)sender;
    if (!_rendererOptionsController) {
        _rendererOptionsController = [RendererOptionsController new];
        __weak AppController *weakSelf = self;
        _rendererOptionsController.readSettings = ^BOOL(RendererDisplayOptions *options, NSString **error) {
            AppController *controller = weakSelf;
            if (!controller || !controller->_model || controller->_loading) {
                if (error) *error = @"天文データを読み込んでから描画品質を変更してください。";
                return NO;
            }
            *options = [controller rendererDisplayOptions];
            return YES;
        };
        _rendererOptionsController.applySettings = ^BOOL(RendererDisplayOptions options, NSString **error) {
            AppController *controller = weakSelf;
            if (!controller || !controller->_model || controller->_loading) {
                if (error) *error = @"天文データを読み込んでから描画品質を変更してください。";
                return NO;
            }
            [controller setRendererDisplayOptions:options];
            return YES;
        };
    }
    [_rendererOptionsController showWindow:nil];
}
- (RendererDisplayOptions)rendererDisplayOptions { return _sky.rendererDisplayOptions; }
- (void)setRendererDisplayOptions:(const RendererDisplayOptions&)options {
    _sky.rendererDisplayOptions = options;
    _horizon.rendererDisplayOptions = options;
    _solar.rendererDisplayOptions = options;
    [_galaxyBrowser setRendererDisplayOptions:options];
    [_rendererOptionsController synchronizeOptions:options];
    [NSApp.mainMenu update];
}
- (void)toggleRendererDisplay:(NSMenuItem *)sender {
    auto options = [self rendererDisplayOptions];
    if (toggleOption(options, rendererFlags, sender.tag)) [self setRendererDisplayOptions:options];
}
- (void)togglePlanetDisplay:(NSMenuItem *)sender {
    auto options = [self planetDisplayOptions];
    if (toggleOption(options, planetFlags, sender.tag)) [self setPlanetDisplayOptions:options];
}
- (void)selectTerrainAmplification:(NSMenuItem *)sender {
    if (sender.tag < 0 || sender.tag > 4) return;
    [self setTerrainAmplification:static_cast<TerrainAmplification>(sender.tag + 1)];
}
- (void)toggleEclipseDisplay:(NSMenuItem *)sender {
    auto options = [self eclipseDisplayOptions];
    if (toggleOption(options, eclipseFlags, sender.tag)) [self setEclipseDisplayOptions:options];
}
- (void)toggleStarDisplay:(NSMenuItem *)sender {
    auto options = [self starDisplayOptions];
    if (toggleOption(options, starFlags, sender.tag)) [self setStarDisplayOptions:options];
}
- (void)toggleEarthLayer:(NSMenuItem *)sender {
    auto options = [self earthLayerOptions];
    if (sender.tag == 0) options.clouds = !options.clouds;
    else if (sender.tag == 1) options.city_lights = !options.city_lights;
    else return;
    [self setEarthLayerOptions:options];
}
- (void)toggleLandscapeImage:(NSMenuItem *)sender {
    (void)sender;
    _horizon.showsLandscapeImage = !_horizon.showsLandscapeImage;
    [NSApp.mainMenu update];
}
- (void)selectAtmosphereMode:(NSMenuItem *)sender {
    if (sender.tag < 0 || sender.tag > 2) return;
    auto options = [self atmosphereDisplayOptions];
    options.mode = static_cast<AtmosphereMode>(sender.tag);
    [self setAtmosphereDisplayOptions:options];
}
- (void)selectStarMarking:(NSMenuItem *)sender {
    if (sender.tag < 0 || sender.tag > 2) return;
    auto options = [self starDisplayOptions];
    options.marking = static_cast<StarMarking>(sender.tag);
    [self setStarDisplayOptions:options];
}
- (void)toggleGridDisplay:(NSMenuItem *)sender {
    auto options = [self gridDisplayOptions];
    if (toggleOption(options, gridFlags, sender.tag)) [self setGridDisplayOptions:options];
}
- (BOOL)validateDisplayMenuItem:(NSMenuItem *)item {
    bool valid = false;
    if (item.action == @selector(togglePlanetDisplay:))
        valid = checkOption(item, [self planetDisplayOptions], planetFlags);
    else if (item.action == @selector(selectTerrainAmplification:)) {
        valid = item.tag >= 0 && item.tag <= 4;
        item.state = valid && item.tag + 1 == static_cast<NSInteger>([self terrainAmplification])
            ? NSControlStateValueOn : NSControlStateValueOff;
    }
    else if (item.action == @selector(toggleEclipseDisplay:))
        valid = checkOption(item, [self eclipseDisplayOptions], eclipseFlags);
    else if (item.action == @selector(toggleEarthLayer:)) {
        const auto options = [self earthLayerOptions];
        valid = item.tag == 0 || item.tag == 1;
        item.state = (item.tag == 0 ? options.clouds : options.city_lights)
            ? NSControlStateValueOn : NSControlStateValueOff;
    } else if (item.action == @selector(toggleLandscapeImage:)) {
        valid = true;
        item.state = _horizon.showsLandscapeImage ? NSControlStateValueOn : NSControlStateValueOff;
    } else if (item.action == @selector(selectAtmosphereMode:)) {
        valid = item.tag >= 0 && item.tag <= 2;
        item.state = item.tag == static_cast<NSInteger>([self atmosphereDisplayOptions].mode)
            ? NSControlStateValueOn : NSControlStateValueOff;
    }
    else if (item.action == @selector(toggleStarDisplay:))
        valid = checkOption(item, [self starDisplayOptions], starFlags);
    else if (item.action == @selector(toggleGridDisplay:))
        valid = checkOption(item, [self gridDisplayOptions], gridFlags);
    else if (item.action == @selector(toggleRendererDisplay:))
        valid = checkOption(item, [self rendererDisplayOptions], rendererFlags);
    else if (item.action == @selector(changeStarBrightness:))
        valid = item.tag >= 0 && item.tag <= 2;
    else if (item.action == @selector(selectStarMarking:)) {
        item.state = item.tag == static_cast<NSInteger>([self starDisplayOptions].marking)
            ? NSControlStateValueOn : NSControlStateValueOff;
        valid = item.tag >= 0 && item.tag <= 2;
    }
    return valid && _model && !_loading;
}
@end
