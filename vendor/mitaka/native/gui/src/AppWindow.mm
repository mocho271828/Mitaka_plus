#import "AppControllerInternal.h"
static NSTextField *label(NSString *text, CGFloat size) {
    NSTextField *field = [NSTextField labelWithString:text];
    field.font = [NSFont systemFontOfSize:size];
    return field;
}

static NSButton *button(NSString *title, id target, SEL action) {
    return [NSButton buttonWithTitle:title target:target action:action];
}

static NSStackView *stack(NSArray<NSView *> *views, NSUserInterfaceLayoutOrientation orientation) {
    NSStackView *view = [NSStackView stackViewWithViews:views];
    view.orientation = orientation;
    view.spacing = 10;
    view.alignment = orientation == NSUserInterfaceLayoutOrientationVertical ? NSLayoutAttributeLeading : NSLayoutAttributeCenterY;
    return view;
}

@implementation AppController (Window)

- (void)buildMenu {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
    NSMenuItem *appItem = [[NSMenuItem alloc] initWithTitle:@"Mitaka Native" action:nil keyEquivalent:@""];
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"Mitaka Native"];
    NSMenuItem *aboutItem = [appMenu addItemWithTitle:@"Mitaka Native について" action:@selector(showAbout:) keyEquivalent:@""];
    aboutItem.target = self;
    [appMenu addItem:NSMenuItem.separatorItem];
    [appMenu addItemWithTitle:@"Mitaka Native を終了" action:@selector(terminate:) keyEquivalent:@"q"];
    appItem.submenu = appMenu;
    [menu addItem:appItem];
    NSMenuItem *fileItem = [[NSMenuItem alloc] initWithTitle:@"ファイル" action:nil keyEquivalent:@""];
    NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"ファイル"];
    NSMenuItem *openItem = [fileMenu addItemWithTitle:@"データを開く…" action:@selector(openData:) keyEquivalent:@"o"];
    openItem.target = self;
    fileItem.submenu = fileMenu;
    [menu addItem:fileItem];
    NSMenuItem *editItem = [[NSMenuItem alloc] initWithTitle:@"編集" action:nil keyEquivalent:@""];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"編集"];
    [editMenu addItemWithTitle:@"取り消す" action:@selector(undo:) keyEquivalent:@"z"];
    [editMenu addItemWithTitle:@"切り取り" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"コピー" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"ペースト" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"すべてを選択" action:@selector(selectAll:) keyEquivalent:@"a"];
    editItem.submenu = editMenu;
    [menu addItem:editItem];
    [self addPlusMenus:menu fileMenu:fileMenu];
    NSMenuItem *windowItem = [[NSMenuItem alloc] initWithTitle:@"ウィンドウ" action:nil keyEquivalent:@""];
    NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:@"ウィンドウ"];
    NSMenuItem *fullScreenItem = [windowMenu addItemWithTitle:@"主画面を全画面表示"
        action:@selector(toggleMainFullScreen:) keyEquivalent:@"f"];
    fullScreenItem.keyEquivalentModifierMask = NSEventModifierFlagControl | NSEventModifierFlagCommand;
    fullScreenItem.target = self;
    windowItem.submenu = windowMenu;
    [menu addItem:windowItem];
    NSApp.mainMenu = menu;
}

- (void)buildWindow {
    _window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 1280, 800)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable
        backing:NSBackingStoreBuffered defer:NO];
    _window.title = @"Mitaka Native — 星と惑星";
    if (!_smokeTest) [_window setFrameAutosaveName:@"MitakaMainWindow"];
    _window.minSize = NSMakeSize(1100, 850);
    _window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    _window.releasedWhenClosed = NO;
    _window.delegate = self;
    _window.collectionBehavior |= NSWindowCollectionBehaviorFullScreenPrimary;
    _windowPresentation = [[WindowPresentationController alloc] initWithWindow:_window];
    [_window center];

    NSTextField *title = label(@"Mitaka Native", 22);
    title.font = [NSFont systemFontOfSize:22 weight:NSFontWeightSemibold];
    NSTextField *subtitle = label(@"星・惑星・月の公転と自転、地球から目的地への連続飛行", 12);
    subtitle.textColor = NSColor.secondaryLabelColor;
    NSStackView *heading = stack(@[title, subtitle], NSUserInterfaceLayoutOrientationVertical);
    heading.spacing = 3;
    [heading.heightAnchor constraintEqualToConstant:48].active = YES;
    _pathLabel = label(@"データ未選択 — hip.dat / cf96.dat のあるフォルダを開いてください", 12);
    _pathLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [_pathLabel setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    NSStackView *source = stack(@[button(@"データを開く…", self, @selector(openData:)), _pathLabel], NSUserInterfaceLayoutOrientationHorizontal);
    [source.heightAnchor constraintEqualToConstant:28].active = YES;
    _jdField = [NSTextField textFieldWithString:@"2451545.0"];
    _jdField.font = [NSFont monospacedDigitSystemFontOfSize:12 weight:NSFontWeightRegular];
    _jdField.accessibilityLabel = @"暦表時刻のユリウス日";
    _jdField.target = self;
    _jdField.action = @selector(applyDate:);
    [_jdField.widthAnchor constraintEqualToConstant:122].active = YES;
    NSButton *apply = button(@"適用", self, @selector(applyDate:));
    NSButton *previous = button(@"−1日", self, @selector(stepDate:));
    previous.tag = -1;
    NSButton *next = button(@"＋1日", self, @selector(stepDate:));
    next.tag = 1;
    NSButton *previousHour = button(@"−1時間", self, @selector(stepHour:));
    previousHour.tag = -1;
    NSButton *nextHour = button(@"＋1時間", self, @selector(stepHour:));
    nextHour.tag = 1;
    NSButton *reset = button(@"J2000", self, @selector(resetDate:));
    _timeButtons = @[apply, previous, next, previousHour, nextHour, reset];
    _magnitudeLabel = label(@"V 等級 ≤ 6.5", 12);
    [_magnitudeLabel.widthAnchor constraintEqualToConstant:90].active = YES;
    _magnitudeSlider = [NSSlider sliderWithValue:6.5 minValue:0 maxValue:9 target:self action:@selector(changeMagnitude:)];
    _magnitudeSlider.continuous = YES;
    _magnitudeSlider.accessibilityLabel = @"表示する恒星の V 等級上限";
    [_magnitudeSlider.widthAnchor constraintEqualToConstant:135].active = YES;
    NSView *spacer = [[NSView alloc] init];
    NSStackView *controls = stack(@[label(@"JD", 12), _jdField, apply, previous, next,
        previousHour, nextHour, reset, spacer, _magnitudeLabel, _magnitudeSlider], NSUserInterfaceLayoutOrientationHorizontal);
    [controls.heightAnchor constraintEqualToConstant:28].active = YES;
    _dateLabel = label(@"暦表時刻 JD 2451545.0 · 2000-01-01 12:00", 12);
    _dateLabel.textColor = NSColor.secondaryLabelColor;
    [_dateLabel.heightAnchor constraintEqualToConstant:18].active = YES;

    _sky = [[SkyView alloc] initWithFrame:NSZeroRect];
    _horizon = [[HorizonView alloc] initWithFrame:NSZeroRect];
    [_horizon setObserverSite:{_observerLatitude, _observerLongitude}];
    _horizon.hidden = YES;
    _solar = [[SolarSystemView alloc] initWithFrame:NSZeroRect];
    [_solar setHipVisible:_sky.starDisplayOptions.visible];
    [_solar setOurGalaxyVisible:_sky.milkyWayMode != MilkyWayMode::none];
    _sky.hidden = YES;
    _mode = [NSSegmentedControl segmentedControlWithLabels:@[@"全天図", @"太陽系 3D", @"地平図"]
        trackingMode:NSSegmentSwitchTrackingSelectOne target:self action:@selector(changeMode:)];
    _mode.selectedSegment = 1;
    _mode.accessibilityLabel = @"表示モード";
    _cameraButtons = @[button(@"全体", self, @selector(resetCamera:)),
        button(@"内惑星", self, @selector(innerPlanets:)),
        button(@"−", self, @selector(zoomOut:)), button(@"＋", self, @selector(zoomIn:)),
        button(@"選択を中心", self, @selector(focusSelection:)),
        button(@"表面を見る", self, @selector(showSurface:))];
    _cameraButtons[2].accessibilityLabel = @"3D を縮小";
    _cameraButtons[3].accessibilityLabel = @"3D を拡大";
    _cameraLabel = label(@"", 11);
    _cameraLabel.textColor = NSColor.secondaryLabelColor;
    _cameraLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [_cameraLabel setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    NSStackView *viewControls = stack(@[_mode, _cameraButtons[0], _cameraButtons[1],
        _cameraButtons[2], _cameraButtons[3], _cameraButtons[4], _cameraButtons[5], _cameraLabel], NSUserInterfaceLayoutOrientationHorizontal);
    [viewControls.heightAnchor constraintEqualToConstant:28].active = YES;
    _latitudeField = [NSTextField textFieldWithString:@"35.68"];
    _longitudeField = [NSTextField textFieldWithString:@"139.76"];
    _latitudeField.accessibilityLabel = @"着陸地点の緯度（度）";
    _longitudeField.accessibilityLabel = @"着陸地点の東経（度）";
    for (NSTextField *field in @[_latitudeField, _longitudeField])
        [field.widthAnchor constraintEqualToConstant:70].active = YES;
    _travelButtons = @[button(@"地球・月", self, @selector(earthMoon:)),
        button(@"着陸", self, @selector(land:)),
        button(@"離陸", self, @selector(takeOff:)),
        button(@"地球から離陸", self, @selector(takeOffFromEarth:)),
        button(@"移動を停止", self, @selector(stopFlight:)),
        button(@"地平図から離陸", self, @selector(takeOffFromHorizon:)),
        button(@"地平図へ降下", self, @selector(descendToHorizon:))];
    _travelButtons[1].toolTip = @"選択天体の上空へ移動して降下します。ガス惑星は基準面への接近です。";
    _travelButtons[3].toolTip = @"指定した緯度・東経の地球の地表から上昇します。";
    _travelButtons[5].toolTip = @"地平図の観測地点と視線から地球の上空へ移動します。";
    _travelButtons[6].toolTip = @"地球近傍の視点から降下し、地平図へ移ります。ロール付きの視点には対応していません。";
    NSStackView *travelControls = stack(@[_travelButtons[0], label(@"緯度", 12), _latitudeField,
        label(@"東経", 12), _longitudeField, _travelButtons[1], _travelButtons[2],
        _travelButtons[3], _travelButtons[4]], NSUserInterfaceLayoutOrientationHorizontal);
    [travelControls.heightAnchor constraintEqualToConstant:28].active = YES;
    _journeyButton = button(@"選択天体へ飛行", self, @selector(startJourney:));
    _journeyButton.toolTip = @"地表・上空にいる場合は現在地から、それ以外は地球の緯度0°・東経0°から出発します。指定した着陸地点まで約24秒で移動します。";
    _resumeJourneyButton = button(@"現在位置から再航行", self, @selector(resumeJourney:));
    _resumeJourneyButton.toolTip = @"停止した視点から同じ目的地へ、新しい約24秒の経路で再出発します。";
    NSTextField *journeyHint = label(@"約24秒で離陸 → 航行 → 着陸 · 日時の進行は再生速度で設定", 11);
    journeyHint.textColor = NSColor.secondaryLabelColor;
    NSStackView *journeyControls = stack(@[_journeyButton, _resumeJourneyButton, _travelButtons[5], _travelButtons[6], journeyHint], NSUserInterfaceLayoutOrientationHorizontal);
    [journeyControls.heightAnchor constraintEqualToConstant:28].active = YES;
    _selectionLabel = [NSTextField wrappingLabelWithString:@"星や惑星をクリックすると\n座標と明るさ・距離を表示します。"];
    _selectionLabel.font = [NSFont monospacedDigitSystemFontOfSize:12 weight:NSFontWeightRegular];
    [_selectionLabel.heightAnchor constraintEqualToConstant:108].active = YES;
    __weak AppController *weakSelf = self;
    _playback = [[PlaybackController alloc] init];
    _playback.applyDate = ^BOOL(double jd) {
        return [weakSelf updateDate:jd refreshOrbits:NO];
    };
    _playback.stateChanged = ^{ [weakSelf updateEnabled]; };
    _playback.didStop = ^{ [weakSelf refreshOrbits]; };
    [self configurePlayback];
    _horizon.userViewportChange = ^{ [weakSelf stopScriptCameraAnimation]; [weakSelf stopScriptPlaceTransition]; [weakSelf cancelHorizonProjection]; };
    _horizon.selectionChanged = ^(NSString *description) {
        AppController *controller = weakSelf;
        if (!controller) return;
        controller->_horizonSelection = description;
        if (controller->_mode.selectedSegment == 2) controller->_selectionLabel.stringValue = description;
    };
    _sky.viewportChanged = ^{
        AppController *controller = weakSelf;
        if (controller && controller->_model) [controller refresh];
    };
    _sky.selectionChanged = ^(NSString *description) {
        AppController *controller = weakSelf;
        if (!controller) return;
        controller->_skySelection = description;
        if (controller->_mode.selectedSegment == 0) controller->_selectionLabel.stringValue = description;
    };
    _solar.selectionChanged = ^(NSString *description) {
        AppController *controller = weakSelf;
        if (!controller) return;
        controller->_solarSelection = description;
        if (controller->_mode.selectedSegment == 1) controller->_selectionLabel.stringValue = description;
    };
    _solar.cameraChanged = ^(NSString *description) {
        AppController *controller = weakSelf;
        if (controller) controller->_cameraLabel.stringValue = description;
    };
    _solar.navigationChanged = ^{ [weakSelf surfaceNavigationChanged]; };
    _solar.userSurfaceViewChange = ^{ [weakSelf stopScriptCameraAnimation]; [weakSelf stopScriptPlaceTransition]; };
    _solar.overviewVisibilityChanged = ^(BOOL visible) {
        (void)visible;
        [weakSelf refreshSmallBodyOrbits];
    };
    _solar.satelliteSelectionChanged = ^(NSUInteger index) {
        (void)index;
        [weakSelf refreshSatelliteParents];
    };
    _bodyButtons = [NSMutableArray array];
    NSMutableArray<NSView *> *sidebarItems = [NSMutableArray arrayWithObjects:label(@"太陽・惑星・月", 16), nil];
    constexpr Body ids[] = {Body::sun, Body::mercury, Body::venus, Body::earth,
        Body::mars, Body::jupiter, Body::saturn, Body::uranus, Body::neptune, Body::pluto, Body::moon};
    for (NSUInteger index = 0; index < std::size(ids); ++index) {
        NSButton *item = button(bodyName(ids[index]), self, @selector(selectBody:));
        item.tag = index;
        item.alignment = NSTextAlignmentLeft;
        item.font = [NSFont monospacedDigitSystemFontOfSize:12 weight:NSFontWeightRegular];
        [_bodyButtons addObject:item];
        [sidebarItems addObject:item];
    }
    [sidebarItems addObject:_selectionLabel];
    _note = [NSTextField wrappingLabelWithString:@""];
    _note.font = [NSFont systemFontOfSize:11];
    _note.textColor = NSColor.secondaryLabelColor;
    [sidebarItems addObject:_note];
    NSStackView *sidebar = stack(sidebarItems, NSUserInterfaceLayoutOrientationVertical);
    sidebar.spacing = 6;
    [sidebar.widthAnchor constraintEqualToConstant:224].active = YES;
    for (NSView *item in sidebarItems) [item.widthAnchor constraintEqualToAnchor:sidebar.widthAnchor].active = YES;
    NSView *canvas = [[NSView alloc] init];
    for (NSView *view in @[_sky, _solar, _horizon]) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [canvas addSubview:view];
        [NSLayoutConstraint activateConstraints:@[
            [view.leadingAnchor constraintEqualToAnchor:canvas.leadingAnchor],
            [view.trailingAnchor constraintEqualToAnchor:canvas.trailingAnchor],
            [view.topAnchor constraintEqualToAnchor:canvas.topAnchor],
            [view.bottomAnchor constraintEqualToAnchor:canvas.bottomAnchor]]];
    }
    NSStackView *mapRow = stack(@[canvas, sidebar], NSUserInterfaceLayoutOrientationHorizontal);
    mapRow.alignment = NSLayoutAttributeTop;
    mapRow.spacing = 16;
    [canvas.heightAnchor constraintEqualToAnchor:mapRow.heightAnchor].active = YES;
    [canvas.widthAnchor constraintGreaterThanOrEqualToConstant:680].active = YES;
    _status = [NSTextField wrappingLabelWithString:@"データは読み取り専用で利用します。元ファイルの変換・移動・更新は行いません。"];
    _status.font = [NSFont systemFontOfSize:11];
    _status.textColor = NSColor.secondaryLabelColor;
    _status.selectable = YES;
    [_status.heightAnchor constraintEqualToConstant:42].active = YES;
    NSStackView *layout = stack(@[heading, source, controls, _dateLabel, _playback.view, viewControls, travelControls, journeyControls, mapRow, _status], NSUserInterfaceLayoutOrientationVertical);
    layout.translatesAutoresizingMaskIntoConstraints = NO;
    [_window.contentView addSubview:layout];
    for (NSView *row in @[source, controls, _dateLabel, _playback.view, viewControls, travelControls, journeyControls, mapRow, _status]) [row.widthAnchor constraintEqualToAnchor:layout.widthAnchor].active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [layout.leadingAnchor constraintEqualToAnchor:_window.contentView.leadingAnchor constant:20],
        [layout.trailingAnchor constraintEqualToAnchor:_window.contentView.trailingAnchor constant:-20],
        [layout.topAnchor constraintEqualToAnchor:_window.contentView.topAnchor constant:18],
        [layout.bottomAnchor constraintEqualToAnchor:_window.contentView.bottomAnchor constant:-12]
    ]];
    [self changeMode:nil];
}

@end
