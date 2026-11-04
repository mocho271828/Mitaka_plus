#import "AppControllerInternal.h"
#include <array>
#include <stdexcept>

namespace {
NSMenuItem *timeCommand(NSMenu *menu, NSString *title, SEL action, id target) {
    NSMenuItem *item = [menu addItemWithTitle:title action:action keyEquivalent:@""];
    item.target = target;
    return item;
}
NSMenu *timeSubmenu(NSMenu *parent, NSString *title) {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
    item.submenu = [[NSMenu alloc] initWithTitle:title];
    [parent addItem:item];
    return item.submenu;
}
NSString *offsetTitle(int minutes) {
    return [NSString stringWithFormat:@"UTC%c%02d:%02d", minutes < 0 ? '-' : '+',
        std::abs(minutes) / 60, std::abs(minutes) % 60];
}
NSStackView *timeRow(NSString *title, NSView *control) {
    NSTextField *label = [NSTextField labelWithString:title];
    [label.widthAnchor constraintEqualToConstant:160].active = YES;
    [control.widthAnchor constraintEqualToConstant:200].active = YES;
    NSStackView *row = [NSStackView stackViewWithViews:@[label, control]];
    row.spacing = 10;
    return row;
}
NSString *calendarNumber(double value, bool integer) {
    // 数値 setter のロケール依存の桁区切りを避け、入力側の厳密な POSIX 解釈と揃える。
    return [[NSString alloc] initWithFormat:integer ? @"%.0f" : @"%.6f"
        locale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"], value];
}
double fieldNumber(NSTextField *field, bool integer) {
    NSScanner *scanner = [NSScanner scannerWithString:field.stringValue];
    scanner.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    double value = 0;
    if (![scanner scanDouble:&value] || !scanner.isAtEnd || !std::isfinite(value) ||
        std::abs(value) > 10000000 || (integer && std::trunc(value) != value))
        throw std::invalid_argument("calendar: enter finite numbers; all fields except seconds require integers");
    return value;
}
}

@implementation AppController (TimeCommands)
- (void)addTimeMenu:(NSMenu *)menu {
    NSMenu *time = timeSubmenu(menu, @"時刻");
    timeCommand(time, @"カレンダー・固定時差…", @selector(showCalendar:), self);
    timeCommand(time, @"現在 UTC を一度適用", @selector(setCurrentTime:), self);
    timeCommand(time, @"現在 UTC に継続追従", @selector(toggleClockTracking:), self);
    timeCommand(time, @"日時情報を表示", @selector(toggleTimeInfo:), self);
    [time addItem:NSMenuItem.separatorItem];
    timeCommand(time, @"順方向に再生", @selector(playForward), _playback);
    timeCommand(time, @"逆方向に再生", @selector(playBackward), _playback);
    timeCommand(time, @"表示日時から 1 倍速再生", @selector(playRealtime), _playback);
    timeCommand(time, @"一時停止・時計追従を解除", @selector(pause), _playback);
    [time addItem:NSMenuItem.separatorItem];
    timeCommand(time, @"1 ステップ戻す", @selector(stepTime:), self).tag = -1;
    timeCommand(time, @"1 ステップ進める", @selector(stepTime:), self).tag = 1;
    NSMenu *steps = timeSubmenu(time, @"ステップ単位");
    NSArray<NSString *> *titles = @[@"10 秒", @"1 分", @"10 分", @"1 時間", @"1 日", @"1 週間",
        @"1 暦月", @"1 暦年", @"10 暦年", @"100 暦年", @"任意の秒数…"];
    for (NSUInteger i = 0; i < titles.count; ++i)
        timeCommand(steps, titles[i], @selector(selectTimeStep:), self).tag = i;
}

- (void)showCalendar:(id)sender {
    (void)sender;
    if (!_model || _loading) return;
    if (!_calendarWindow) {
        _calendarWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 730, 500)
            styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:NO];
        _calendarWindow.title = @"カレンダー・固定 UTC 時差";
        _calendarWindow.releasedWhenClosed = NO;
        _calendarWindow.appearance = _window.appearance;
        NSMutableArray<NSTextField *> *fields = [NSMutableArray array];
        NSMutableArray<NSView *> *rows = [NSMutableArray array];
        for (NSString *title in @[@"年（年 0 は紀元前 1 年）", @"月", @"日", @"時", @"分", @"秒"]) {
            NSTextField *field = [NSTextField textFieldWithString:@""];
            field.accessibilityLabel = title;
            if (fields.count < 3)
                [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(calendarFieldChanged:)
                    name:NSControlTextDidChangeNotification object:field];
            [fields addObject:field];
            [rows addObject:timeRow(title, field)];
        }
        _calendarFields = fields;
        _calendarOffsetPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
        _calendarOffsetPopup.accessibilityLabel = @"固定 UTC 時差";
        for (int minutes = -840; minutes <= 840; minutes += 15) {
            [_calendarOffsetPopup addItemWithTitle:offsetTitle(minutes)];
            _calendarOffsetPopup.lastItem.representedObject = @(minutes);
        }
        _customTimeStepField = [NSTextField textFieldWithString:@""];
        _customTimeStepField.accessibilityLabel = @"任意ステップの秒数";
        [rows addObject:timeRow(@"固定 UTC 時差", _calendarOffsetPopup)];
        [rows addObject:timeRow(@"任意ステップ（秒）", _customTimeStepField)];
        NSTextField *help = [NSTextField wrappingLabelWithString:
            @"先発グレゴリオ暦。月・年ステップは移動先の月末に日を収めます。任意ステップは 1〜2592000 秒です。固定時差は夏時間に追従しません。入力日時を UTC 相当の JD として暦表に渡す近似で、UT1・TT・TDB の補正と閏秒は含みません。"];
        help.textColor = NSColor.secondaryLabelColor;
        help.font = [NSFont systemFontOfSize:11];
        [rows addObject:help];
        [rows addObject:[NSButton buttonWithTitle:@"日時と設定を適用" target:self action:@selector(applyCalendar:)]];
        NSStackView *form = [NSStackView stackViewWithViews:rows];
        form.orientation = NSUserInterfaceLayoutOrientationVertical;
        form.alignment = NSLayoutAttributeLeading;
        form.spacing = 10;
        _calendarPreviousButton = [NSButton buttonWithTitle:@"‹" target:self action:@selector(moveCalendarMonth:)];
        _calendarPreviousButton.tag = -1;
        _calendarPreviousButton.accessibilityLabel = @"前の月";
        _calendarNextButton = [NSButton buttonWithTitle:@"›" target:self action:@selector(moveCalendarMonth:)];
        _calendarNextButton.tag = 1;
        _calendarNextButton.accessibilityLabel = @"次の月";
        _calendarMonthLabel = [NSTextField labelWithString:@""];
        _calendarMonthLabel.alignment = NSTextAlignmentCenter;
        [_calendarMonthLabel.widthAnchor constraintEqualToConstant:196].active = YES;
        for (NSButton *button in @[_calendarPreviousButton, _calendarNextButton])
            [button.widthAnchor constraintEqualToConstant:32].active = YES;
        NSStackView *monthHeader = [NSStackView stackViewWithViews:@[
            _calendarPreviousButton, _calendarMonthLabel, _calendarNextButton]];
        monthHeader.spacing = 8;
        NSMutableArray<NSView *> *monthRows = [NSMutableArray arrayWithObject:monthHeader];
        NSMutableArray<NSView *> *weekdays = [NSMutableArray array];
        for (NSString *weekday in @[@"日", @"月", @"火", @"水", @"木", @"金", @"土"]) {
            NSTextField *label = [NSTextField labelWithString:weekday];
            label.alignment = NSTextAlignmentCenter;
            label.textColor = NSColor.secondaryLabelColor;
            [label.widthAnchor constraintEqualToConstant:36].active = YES;
            [weekdays addObject:label];
        }
        NSStackView *weekdayRow = [NSStackView stackViewWithViews:weekdays];
        weekdayRow.spacing = 4;
        [monthRows addObject:weekdayRow];
        NSMutableArray<NSButton *> *days = [NSMutableArray array];
        for (NSUInteger week = 0; week < 6; ++week) {
            NSMutableArray<NSView *> *buttons = [NSMutableArray array];
            for (NSUInteger column = 0; column < 7; ++column) {
                NSButton *button = [NSButton buttonWithTitle:@"" target:self action:@selector(selectCalendarDay:)];
                [button setButtonType:NSButtonTypePushOnPushOff];
                button.bezelStyle = NSBezelStyleRegularSquare;
                [button.widthAnchor constraintEqualToConstant:36].active = YES;
                [button.heightAnchor constraintEqualToConstant:28].active = YES;
                [buttons addObject:button];
                [days addObject:button];
            }
            NSStackView *weekRow = [NSStackView stackViewWithViews:buttons];
            weekRow.spacing = 4;
            [monthRows addObject:weekRow];
        }
        _calendarDayButtons = days;
        NSTextField *calendarHint = [NSTextField wrappingLabelWithString:
            @"年月・日を選び、右の日時と固定時差を確認して適用してください。月移動では日を移動先の月末に収めます。"];
        calendarHint.font = [NSFont systemFontOfSize:11];
        calendarHint.textColor = NSColor.secondaryLabelColor;
        [calendarHint.widthAnchor constraintEqualToConstant:276].active = YES;
        [monthRows addObject:calendarHint];
        NSStackView *month = [NSStackView stackViewWithViews:monthRows];
        month.orientation = NSUserInterfaceLayoutOrientationVertical;
        month.alignment = NSLayoutAttributeLeading;
        month.spacing = 8;
        NSStackView *layout = [NSStackView stackViewWithViews:@[month, form]];
        layout.alignment = NSLayoutAttributeTop;
        layout.spacing = 24;
        layout.translatesAutoresizingMaskIntoConstraints = NO;
        [_calendarWindow.contentView addSubview:layout];
        [NSLayoutConstraint activateConstraints:@[
            [layout.leadingAnchor constraintEqualToAnchor:_calendarWindow.contentView.leadingAnchor constant:20],
            [layout.trailingAnchor constraintEqualToAnchor:_calendarWindow.contentView.trailingAnchor constant:-20],
            [layout.topAnchor constraintEqualToAnchor:_calendarWindow.contentView.topAnchor constant:20],
            [help.widthAnchor constraintEqualToAnchor:form.widthAnchor]]];
        [_calendarWindow center];
    }
    const auto date = calendar_at_offset(_jd, _timeSettings.utc_offset_minutes);
    const std::array<double, 6> values{{double(date.year), double(date.month), double(date.day),
        double(date.hour), double(date.minute), date.second}};
    for (NSUInteger i = 0; i < values.size(); ++i)
        _calendarFields[i].stringValue = calendarNumber(values[i], i != 5);
    NSInteger selected = [_calendarOffsetPopup indexOfItemWithRepresentedObject:@(_timeSettings.utc_offset_minutes)];
    // 状態ファイルが保持する整数分の時差も、15 分刻みの選択肢に丸めず表示する。
    if (selected < 0) {
        [_calendarOffsetPopup addItemWithTitle:offsetTitle(_timeSettings.utc_offset_minutes)];
        _calendarOffsetPopup.lastItem.representedObject = @(_timeSettings.utc_offset_minutes);
        selected = _calendarOffsetPopup.numberOfItems - 1;
    }
    [_calendarOffsetPopup selectItemAtIndex:selected];
    _customTimeStepField.stringValue = calendarNumber(_timeSettings.custom_seconds, true);
    [self refreshCalendarGrid];
    [_calendarWindow makeKeyAndOrderFront:nil];
}

- (void)refreshCalendarGrid {
    if (!_calendarWindow) return;
    std::optional<CalendarMonth> month;
    int selectedDay = 0;
    try { month = calendar_month(int(fieldNumber(_calendarFields[0], true)), int(fieldNumber(_calendarFields[1], true))); }
    catch (const std::exception&) { /* 入力途中の年月は変更せず、グリッドだけを無効にする。 */ }
    if (month) {
        try {
            selectedDay = int(fieldNumber(_calendarFields[2], true));
            (void)mitaka::julian_date({month->year, month->month, selectedDay, 12, 0, 0});
        } catch (const std::exception&) { selectedDay = 0; }
    }
    _calendarMonthLabel.stringValue = month ? [NSString stringWithFormat:@"%d 年 %d 月", month->year, month->month] : @"年月を確認してください";
    _calendarPreviousButton.enabled = month && month->previous_enabled && selectedDay;
    _calendarNextButton.enabled = month && month->next_enabled && selectedDay;
    for (NSUInteger index = 0; index < _calendarDayButtons.count; ++index) {
        NSButton *button = _calendarDayButtons[index];
        const int day = month ? month->days[index] : 0;
        button.tag = day;
        button.enabled = day != 0;
        button.transparent = day == 0;
        button.title = day ? [NSString stringWithFormat:@"%d", day] : @"";
        button.state = day && day == selectedDay ? NSControlStateValueOn : NSControlStateValueOff;
        button.accessibilityLabel = day ? [NSString stringWithFormat:@"%d 年 %d 月 %d 日", month->year, month->month, day] : @"";
    }
}

- (void)calendarFieldChanged:(id)sender {
    (void)sender;
    [self refreshCalendarGrid];
}

- (void)selectCalendarDay:(NSButton *)sender {
    if (!sender.enabled || ![_calendarDayButtons containsObject:sender]) return;
    _calendarFields[2].stringValue = calendarNumber(sender.tag, true);
    [self refreshCalendarGrid];
}

- (void)moveCalendarMonth:(NSButton *)sender {
    if (!sender.enabled || (sender != _calendarPreviousButton && sender != _calendarNextButton)) return;
    try {
        const double draft = mitaka::julian_date({int(fieldNumber(_calendarFields[0], true)),
            int(fieldNumber(_calendarFields[1], true)), int(fieldNumber(_calendarFields[2], true)), 12, 0, 0});
        const auto next = mitaka::gregorian_date_time(step_julian_date(draft, {TimeStep::month, 3600, 0}, int(sender.tag)));
        _calendarFields[0].stringValue = calendarNumber(next.year, true);
        _calendarFields[1].stringValue = calendarNumber(next.month, true);
        _calendarFields[2].stringValue = calendarNumber(next.day, true);
    } catch (const std::exception&) { /* 無効な入力の修正は利用者に委ね、時刻と秒の入力文字列を保つ。 */ }
    [self refreshCalendarGrid];
}

- (BOOL)timeInfoVisible { return _timeInfoVisible; }
- (void)setTimeInfoVisible:(BOOL)visible {
    _timeInfoVisible = visible;
    _dateLabel.hidden = !visible;
    _horizon.showsTimeInfo = visible;
    _solar.showsTimeInfo = visible;
}
- (void)toggleTimeInfo:(id)sender {
    (void)sender;
    [self setTimeInfoVisible:!_timeInfoVisible];
}

- (void)applyCalendar:(id)sender {
    (void)sender;
    if (!_model || _loading || !_calendarWindow) return;
    [_playback interruptWithMessage:@"日時操作により一時停止"];
    try {
        std::array<double, 6> values{};
        for (NSUInteger i = 0; i < values.size(); ++i) values[i] = fieldNumber(_calendarFields[i], i != 5);
        TimeSettings settings = _timeSettings;
        settings.utc_offset_minutes = [_calendarOffsetPopup.selectedItem.representedObject intValue];
        settings.custom_seconds = static_cast<int>(fieldNumber(_customTimeStepField, true));
        validate_time_settings(settings);
        const double jd = julian_date_at_offset({int(values[0]), int(values[1]), int(values[2]),
            int(values[3]), int(values[4]), values[5]}, settings.utc_offset_minutes);
        if ([self setDate:jd]) {
            _timeSettings = settings;
            [self refresh];
            [_calendarWindow close];
        }
    } catch (const std::exception& error) {
        [self showError:[NSString stringWithFormat:@"カレンダーを適用できません: %s", error.what()]];
    }
}

- (void)setCurrentTime:(id)sender {
    (void)sender;
    [self setDate:NSDate.date.timeIntervalSince1970 / 86400.0 + 2440587.5];
}

- (void)stepTime:(NSMenuItem *)sender {
    if (!_model || _loading) return;
    [_playback interruptWithMessage:@"日時操作により一時停止"];
    try { [self setDate:step_julian_date(_jd, _timeSettings, static_cast<int>(sender.tag))]; }
    catch (const std::exception& error) {
        [self showError:[NSString stringWithFormat:@"時刻を移動できません: %s", error.what()]];
    }
}

- (void)selectTimeStep:(NSMenuItem *)sender {
    if (!_model || _loading || sender.tag < 0 || sender.tag > static_cast<NSInteger>(TimeStep::custom)) return;
    TimeSettings settings = _timeSettings;
    settings.step = static_cast<TimeStep>(sender.tag);
    if (settings.step == TimeStep::custom) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"任意ステップの秒数";
        alert.informativeText = @"1 ステップで移動する秒数を 1〜2592000 の整数で指定してください。";
        NSTextField *field = [NSTextField textFieldWithString:calendarNumber(settings.custom_seconds, true)];
        field.frame = NSMakeRect(0, 0, 240, 24);
        alert.accessoryView = field;
        [alert addButtonWithTitle:@"適用"];
        [alert addButtonWithTitle:@"キャンセル"];
        [alert.window makeFirstResponder:field];
        if ([alert runModal] != NSAlertFirstButtonReturn) return;
        try {
            settings.custom_seconds = static_cast<int>(fieldNumber(field, true));
            validate_time_settings(settings);
        } catch (const std::exception& error) {
            [self showError:[NSString stringWithFormat:@"ステップを適用できません: %s", error.what()]];
            return;
        }
    }
    _timeSettings = settings;
}

- (void)toggleClockTracking:(id)sender {
    (void)sender;
    if (!_model || _loading) return;
    [_solar interruptFlight];
    const BOOL enabled = !_playback.clockTracking;
    if (![_playback setClockTracking:enabled] && enabled)
        [self showError:@"現在 UTC への追従を開始できません。暦表の有効範囲と時刻表示を確認してください。"];
    else if (enabled)
        [self refreshOrbits];
}

- (BOOL)validateTimeMenuItem:(NSMenuItem *)item {
    if (item.action == @selector(toggleTimeInfo:)) {
        item.state = _timeInfoVisible ? NSControlStateValueOn : NSControlStateValueOff;
        return YES;
    }
    if (item.action == @selector(selectTimeStep:)) {
        item.state = item.tag == static_cast<NSInteger>(_timeSettings.step) ? NSControlStateValueOn : NSControlStateValueOff;
        if (item.tag == static_cast<NSInteger>(TimeStep::custom))
            item.title = [NSString stringWithFormat:@"任意（%d 秒）…", _timeSettings.custom_seconds];
    } else if (item.action == @selector(toggleClockTracking:))
        item.state = _playback.clockTracking ? NSControlStateValueOn : NSControlStateValueOff;
    return _model && !_loading;
}

- (NSString *)timeDisplayDescription {
    if (!_model) return @"データを選択してください";
    const auto date = displayDate(_jd + _timeSettings.utc_offset_minutes / 1440.0);
    return [NSString stringWithFormat:@"暦表時刻 JD %.6f · %04d-%02d-%02d %02d:%02d %@ 相当（固定時差・時系補正なし）",
        _jd, date.year, date.month, date.day, date.hour, date.minute, offsetTitle(_timeSettings.utc_offset_minutes)];
}
@end
