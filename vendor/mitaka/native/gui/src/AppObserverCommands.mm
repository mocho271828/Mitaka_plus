#import "AppControllerInternal.h"

namespace {
NSString *placeName(const mitaka::PlaceRecord& place) {
    NSString *name = [[NSString alloc] initWithBytes:place.name_bytes.data() length:place.name_bytes.size()
        encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese)];
    return name ? name : @"名称を解読できません（CP932）";
}

NSString *sourceText(const std::string& text) {
    NSString *value = [[NSString alloc] initWithBytes:text.data() length:text.size() encoding:NSUTF8StringEncoding];
    return value ? value : @"UTF-8 で表示できない情報があります";
}

NSStackView *observerRow(NSString *title, NSView *control) {
    NSTextField *label = [NSTextField labelWithString:title];
    [label.widthAnchor constraintEqualToConstant:150].active = YES;
    NSStackView *row = [NSStackView stackViewWithViews:@[label, control]];
    row.spacing = 10;
    [control.widthAnchor constraintEqualToConstant:420].active = YES;
    return row;
}
}

@implementation AppController (ObserverCommands)
- (void)showObserver:(id)sender {
    (void)sender;
    if (!_model || _loading) return;
    if (!_observerWindow) {
        _observerWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 640, 360)
            styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:NO];
        _observerWindow.title = @"地平図の観測地点";
        _observerWindow.releasedWhenClosed = NO;
        _observerWindow.appearance = _window.appearance;
        _observerPlacesPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
        _observerPlacesPopup.target = self;
        _observerPlacesPopup.action = @selector(chooseObserverPlace:);
        _observerLatitudeField = [NSTextField textFieldWithString:@""];
        _observerLongitudeField = [NSTextField textFieldWithString:@""];
        _observerCatalogStatus = [NSTextField wrappingLabelWithString:@""];
        _observerCatalogStatus.selectable = YES;
        _observerApplyButton = [NSButton buttonWithTitle:@"地平図に適用" target:self action:@selector(applyObserver:)];
        NSTextField *help = [NSTextField wrappingLabelWithString:
            @"北緯・東経が正です。選択地点の経度は −180〜180° に換算して表示します。登録地点の風景を適用し、座標を編集すると既定風景へ戻ります。地球以外の地点、大気差・地心視差・時系補正は未対応です。"];
        NSStackView *layout = [NSStackView stackViewWithViews:@[
            observerRow(@"ローカルの地点", _observerPlacesPopup),
            observerRow(@"緯度（−90〜90°）", _observerLatitudeField),
            observerRow(@"東経（−180〜180°）", _observerLongitudeField),
            help, _observerCatalogStatus, _observerApplyButton]];
        layout.orientation = NSUserInterfaceLayoutOrientationVertical;
        layout.alignment = NSLayoutAttributeLeading;
        layout.spacing = 12;
        layout.translatesAutoresizingMaskIntoConstraints = NO;
        [_observerWindow.contentView addSubview:layout];
        [NSLayoutConstraint activateConstraints:@[
            [layout.leadingAnchor constraintEqualToAnchor:_observerWindow.contentView.leadingAnchor constant:20],
            [layout.trailingAnchor constraintEqualToAnchor:_observerWindow.contentView.trailingAnchor constant:-20],
            [layout.topAnchor constraintEqualToAnchor:_observerWindow.contentView.topAnchor constant:20],
            [help.widthAnchor constraintEqualToAnchor:layout.widthAnchor],
            [_observerCatalogStatus.widthAnchor constraintEqualToAnchor:layout.widthAnchor]]];
        [_observerWindow center];
    }
    [self rebuildObserverPlaces];
    _observerLatitudeField.stringValue = [NSString stringWithFormat:@"%.12g", _observerLatitude];
    _observerLongitudeField.stringValue = [NSString stringWithFormat:@"%.12g", _observerLongitude];
    [_observerWindow makeKeyAndOrderFront:nil];
}

- (void)rebuildObserverPlaces {
    if (!_observerWindow) return;
    [_observerPlacesPopup removeAllItems];
    [_observerPlacesPopup addItemWithTitle:@"緯度・東経を手入力"];
    NSMutableString *status = [NSMutableString string];
    if (_observerPlaces) {
        for (const auto& place : _observerPlaces->places) {
            NSString *title = [NSString stringWithFormat:@"%@ — %@%@", placeName(place), sourceText(place.target_name),
                observer_place_is_earth(place) ? @"" : @"（未解決または地球以外・適用未対応）"];
            // 同じ表示名でも別IDを選べるよう、NSMenuItemを独立して追加する。
            [_observerPlacesPopup.menu addItem:[[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""]];
        }
        [status appendFormat:@"ローカル地点 %zu 件（全出典の読込定義 %zu 件）。",
            _observerPlaces->places.size(), _observerPlaces->source_place_count];
        if (_observerPlaces->selected_source) {
            const auto& source = _observerPlaces->sources.at(*_observerPlaces->selected_source);
            [status appendFormat:@"採用元: %@。独自地点ファイルが存在するときは、その定義だけを使用します。",
                sourceText(source.path.filename().string())];
        }
        if (!_observerPlaces->missing_files.empty()) {
            [status appendString:@"\n任意ファイルなし: "];
            for (std::size_t i = 0; i < _observerPlaces->missing_files.size(); ++i) {
                if (i) [status appendString:@", "];
                [status appendString:sourceText(_observerPlaces->missing_files[i])];
            }
            [status appendString:@"。手入力は利用できます。"];
        }
        for (const auto& warning : _observerPlaces->warnings)
            [status appendFormat:@"\n読込エラー: %@", sourceText(warning)];
    } else [status appendString:@"地点カタログは未読込です。緯度・東経の手入力を利用できます。"];
    _observerCatalogStatus.stringValue = status;
    _observerCatalogStatus.toolTip = status;
    _observerCatalogStatus.textColor = _observerPlaces && !_observerPlaces->warnings.empty()
        ? NSColor.systemOrangeColor : NSColor.secondaryLabelColor;
    [_observerPlacesPopup selectItemAtIndex:0];
    if (_observerPlaces) {
        const auto& identifier = [_horizon observerPlaceIdentifier];
        for (std::size_t index = 0; index < _observerPlaces->places.size(); ++index) {
            const auto& place = _observerPlaces->places[index];
            if (place.target_name == identifier && observer_place_matches(place, _observerLatitude, _observerLongitude)) {
                [_observerPlacesPopup selectItemAtIndex:index + 1];
                break;
            }
        }
    }
    _observerLatitudeField.enabled = _observerLongitudeField.enabled = YES;
    _observerApplyButton.enabled = YES;
}

- (void)chooseObserverPlace:(NSPopUpButton *)sender {
    const NSInteger index = sender.indexOfSelectedItem - 1;
    const bool selected = _observerPlaces && index >= 0 && static_cast<std::size_t>(index) < _observerPlaces->places.size();
    const bool earth = !selected || observer_place_is_earth(_observerPlaces->places[index]);
    _observerLatitudeField.enabled = _observerLongitudeField.enabled = earth;
    _observerApplyButton.enabled = earth;
    if (selected) {
        const auto& place = _observerPlaces->places[index];
        _observerLatitudeField.stringValue = [NSString stringWithFormat:@"%.12g", place.latitude_degrees];
        _observerLongitudeField.stringValue = [NSString stringWithFormat:@"%.12g", std::remainder(place.longitude_degrees, 360.0)];
    }
    _observerApplyButton.toolTip = earth ? nil : @"この地点は対象が未解決または地球以外です。地平図と登録地点を使う3D着陸への適用は未対応です。";
}

- (void)applyObserver:(id)sender {
    (void)sender;
    if (!_model || _loading) return;
    [self stopScriptPlaceTransition];
    const NSInteger index = _observerPlacesPopup.indexOfSelectedItem - 1;
    if (_observerPlaces && index >= 0 && static_cast<std::size_t>(index) < _observerPlaces->places.size() &&
        !observer_place_is_earth(_observerPlaces->places[index])) {
        [self showError:@"未解決または地球以外の登録地点は、地平図と3D着陸への適用に未対応です。地球上の地点または手入力を選んでください。"];
        return;
    }
    double lat = 0, lon = 0;
    NSScanner *a = [NSScanner scannerWithString:_observerLatitudeField.stringValue];
    NSScanner *b = [NSScanner scannerWithString:_observerLongitudeField.stringValue];
    a.locale = b.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    if (![a scanDouble:&lat] || !a.isAtEnd || ![b scanDouble:&lon] || !b.isAtEnd
        || !std::isfinite(lat) || !std::isfinite(lon) || std::abs(lat) > 90 || std::abs(lon) > 180) {
        [self showError:@"観測地点の緯度・東経が範囲外、または数値ではありません。"];
        return;
    }
    _observerLatitude = lat;
    _observerLongitude = lon;
    [_horizon setObserverSite:{lat, lon}];
    std::string identifier;
    if (_observerPlaces && index >= 0 && static_cast<std::size_t>(index) < _observerPlaces->places.size()) {
        const auto& place = _observerPlaces->places[index];
        if (observer_place_matches(place, lat, lon)) identifier = place.target_name;
    }
    [_horizon setObserverPlaceIdentifier:identifier];
    [_sky setObservationSite:{lat, lon} julianDate:_jd];
    _mode.selectedSegment = 2;
    [self changeMode:nil];
    [_observerWindow close];
}
@end
