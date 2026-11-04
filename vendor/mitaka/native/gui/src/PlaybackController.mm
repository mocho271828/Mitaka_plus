#import "PlaybackController.h"
#include "playback_clock.hpp"
#include <array>
#include <chrono>
#include <cmath>
#include <exception>
#include <stdexcept>

using mitaka::gui::PlaybackClock;
using mitaka::gui::PlaybackEvent;

namespace {
constexpr std::array<double, 6> rates{{1, 60, 3600, 86400, 864000, 2592000}};
double monotonicSeconds() {
    return std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
}
}

@interface PlaybackController ()
- (void)updateControls;
- (void)updateRateSelection;
- (void)finishWithMessage:(NSString *)message;
- (BOOL)sampleAtTime:(double)now;
- (BOOL)sampleSystemClock;
- (BOOL)sampleAnimationAtTime:(double)now;
- (double)monotonicTime;
- (void)startTimer;
- (void)suspendClockTracking;
- (void)resumeClockTracking;
@end

@implementation PlaybackController {
    NSStackView *_view;
    NSButton *_playButton;
    NSSegmentedControl *_directionControl;
    NSPopUpButton *_rateButton;
    NSTextField *_stateLabel;
    NSTimer *_timer;
    PlaybackClock _clock;
    mitaka::gui::PlusTimeState _plusTimeState;
    std::optional<mitaka::gui::PlusTimeZone> _plusTimeZone;
    mitaka::gui::PlusTimeAnimation _timeAnimation;
    double _animationLastSeconds;
    double _nativeRate;
    BOOL _plusPlayback;
    std::pair<double, double> _range;
    double _jd;
    BOOL _playing, _enabled, _invalidated, _sampling;
    BOOL _clockTracking, _sleeping, _hidden;
    double (^_unixTimeProvider)(void);
    NSUInteger _stateRevision;
    NSString *_pendingStopMessage;
}

- (instancetype)init {
    return [self initWithUnixTimeProvider:^double { return NSDate.date.timeIntervalSince1970; }];
}

- (instancetype)initWithUnixTimeProvider:(double (^)(void))provider {
    if (!provider) return nil;
    if ((self = [super init])) {
        _unixTimeProvider = [provider copy];
        _jd = 2451545.0;
        _nativeRate = 3600;
        _playButton = [NSButton buttonWithTitle:@"再生" target:self action:@selector(togglePlayback:)];
        _playButton.accessibilityLabel = @"時刻を再生・一時停止";
        [_playButton.widthAnchor constraintEqualToConstant:82].active = YES;
        _directionControl = [NSSegmentedControl segmentedControlWithLabels:@[@"逆方向", @"順方向"]
            trackingMode:NSSegmentSwitchTrackingSelectOne target:self action:@selector(changeDirection:)];
        _directionControl.accessibilityLabel = @"時刻の再生方向";
        _rateButton = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
        [_rateButton addItemsWithTitles:@[@"1 秒（実時間）", @"1 分", @"1 時間", @"1 日", @"10 日", @"30 日"]];
        for (NSUInteger index = 0; index < rates.size(); ++index)
            [_rateButton itemAtIndex:index].representedObject = @(rates[index]);
        _rateButton.target = self;
        _rateButton.action = @selector(changeRate:);
        _rateButton.accessibilityLabel = @"実時間 1 秒あたりに進む暦表時刻";
        _rateButton.toolTip = @"実時間 1 秒あたりに進む暦表時刻";
        NSTextField *rateLabel = [NSTextField labelWithString:@"実時間 1 秒 →"];
        rateLabel.font = [NSFont systemFontOfSize:12];
        _stateLabel = [NSTextField labelWithString:@"データ未選択"];
        _stateLabel.font = [NSFont systemFontOfSize:11];
        _stateLabel.textColor = NSColor.secondaryLabelColor;
        _stateLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [_stateLabel setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow
            forOrientation:NSLayoutConstraintOrientationHorizontal];
        _view = [NSStackView stackViewWithViews:@[_playButton, _directionControl, rateLabel, _rateButton, _stateLabel]];
        _view.orientation = NSUserInterfaceLayoutOrientationHorizontal;
        _view.alignment = NSLayoutAttributeCenterY;
        _view.spacing = 10;
        [self updateRateSelection];
        [self updateControls];
    }
    return self;
}

- (NSView *)view { return _view; }
- (BOOL)playing { return _playing; }
- (BOOL)clockTracking { return _clockTracking; }
- (BOOL)timeAnimating { return _timeAnimation.active(); }
- (double)monotonicTime { return monotonicSeconds(); }
- (std::optional<mitaka::gui::PlusTimeZone>)plusTimeZone { return _plusTimeZone; }
- (void)setPlusTimeZone:(std::optional<mitaka::gui::PlusTimeZone>)zone { _plusTimeZone = zone; }
- (double)julianDate { return _jd; }
- (double)simulationRate { return _nativeRate; }
- (mitaka::gui::PlusTimeState)plusTimeState { return _plusTimeState; }

- (BOOL)setPlusTimeStep:(const mitaka::gui::PlusTimeStepState&)step error:(NSString **)error {
    try {
        if (_invalidated || _sampling) throw std::logic_error("Plus time: controller is not available");
        auto state = _plusTimeState;
        state.step = step;
        const double rate = mitaka::gui::plus_time_rate(state);
        if (_plusPlayback && _playing) {
            const double now = [self monotonicTime];
            PlaybackClock candidate;
            candidate.set_plus_rate(rate);
            candidate.start(_jd, _range, now);
            if (!_timeAnimation.active()) {
                if (![self sampleAtTime:now]) throw std::runtime_error("Plus time: playback stopped during update");
                candidate.stop();
                candidate.start(_jd, _range, now);
            }
            _clock = candidate;
        }
        _plusTimeState = state;
        ++_stateRevision;
        if (self.stateChanged) self.stateChanged();
        return YES;
    } catch (const std::exception& failure) {
        if (error) *error = [NSString stringWithUTF8String:failure.what()];
        return NO;
    }
}

- (BOOL)setPlusTimeState:(const mitaka::gui::PlusTimeState&)state error:(NSString **)error {
    try {
        const double rate = mitaka::gui::plus_time_rate(state);
        if (_invalidated || _sampling) throw std::logic_error("Plus time: controller is not available");
        const double now = [self monotonicTime];
        PlaybackClock candidate;
        candidate.set_plus_rate(rate);
        if (state.speed != 0) {
            if (!_enabled || _sleeping || _hidden) throw std::logic_error("Plus time: playback is unavailable");
            candidate.start(_jd, _range, now);
        }
        // 入力と開始条件を検証し終えるまで、現在の再生・時計追従には触れない。
        if (state.speed == 0) {
            const BOOL animating = _timeAnimation.active();
            if (animating) {
                _clock.stop();
                _clock.set_rate(_nativeRate);
                _playing = NO;
                _plusPlayback = NO;
                _clockTracking = NO;
                _stateLabel.stringValue = @"日時を補間中";
            } else [self pause];
            _plusTimeState = state;
            [self updateControls];
            if (animating) {
                ++_stateRevision;
                if (self.stateChanged) self.stateChanged();
            }
            return YES;
        }
        if (_playing && !_timeAnimation.active()) {
            if (![self sampleAtTime:now]) throw std::runtime_error("Plus time: playback stopped during update");
            candidate.stop();
            candidate.start(_jd, _range, now);
        }
        _clock = candidate;
        _plusTimeState = state;
        _plusPlayback = YES;
        _playing = YES;
        _clockTracking = NO;
        ++_stateRevision;
        _stateLabel.stringValue = [NSString stringWithFormat:@"Lua 再生中（%d step/秒）", state.speed];
        [self startTimer];
        [self updateRateSelection];
        [self updateControls];
        if (self.stateChanged) self.stateChanged();
        return YES;
    } catch (const std::exception& failure) {
        if (error) *error = [NSString stringWithUTF8String:failure.what()];
        return NO;
    }
}

- (BOOL)animateToJulianDate:(double)jd duration:(double)duration
    curve:(mitaka::gui::PlusTimeAnimationCurve)curve
    sameTargetPolicy:(mitaka::gui::PlusTimeAnimationSameTarget)policy error:(NSString **)error {
    try {
        if (_invalidated || _sampling || !_enabled || _sleeping || _hidden)
            throw std::logic_error("Plus time animation: controller is unavailable");
        if (!std::isfinite(_range.first) || !std::isfinite(_range.second) || _range.first >= _range.second ||
            !std::isfinite(jd) || jd < _range.first || jd > _range.second ||
            !std::isfinite(_jd) || _jd < _range.first || _jd > _range.second)
            throw std::out_of_range("Plus time animation: date is outside the available range");
        const double now = [self monotonicTime];
        auto candidate = _timeAnimation;
        if (!candidate.start(_jd, jd, duration, now, curve, policy)) return YES;
        _timeAnimation = candidate;
        _animationLastSeconds = now;
        if (policy == mitaka::gui::PlusTimeAnimationSameTarget::replace) _clockTracking = NO;
        ++_stateRevision;
        _stateLabel.stringValue = @"日時を補間中";
        [self startTimer];
        [self updateControls];
        if (self.stateChanged) self.stateChanged();
        return YES;
    } catch (const std::exception& failure) {
        if (error) *error = [NSString stringWithUTF8String:failure.what()];
        return NO;
    }
}

- (BOOL)sampleAnimationAtTime:(double)now {
    if (!_timeAnimation.active() || _sampling) return NO;
    _sampling = YES;
    NSString *stopMessage = nil;
    BOOL stateChanged = NO;
    try {
        // 原版の補間式とは別に、既存 native 再生と同じ中断境界を適用する。
        if (!std::isfinite(now) || now < _animationLastSeconds || now - _animationLastSeconds > 1.0) {
            stopMessage = @"更新が中断したため一時停止";
        } else {
            const auto sample = _timeAnimation.sample(now);
            const BOOL changed = sample->julian_date != _jd;
            if (changed && (!self.applyDate || !self.applyDate(sample->julian_date))) {
                stopMessage = @"表示の更新に失敗して停止";
            } else {
                _jd = sample->julian_date;
                _animationLastSeconds = now;
                if (changed && _clockTracking) { _clockTracking = NO; stateChanged = YES; }
                // 補間中も Lua speed は保持する。1 tick の描画は一度だけにし、
                // 通常時計は受理した JD から再開できる位置へ移す。
                if (_playing) {
                    _clock.stop();
                    if ((_clock.rate() > 0 && _jd == _range.second) ||
                        (_clock.rate() < 0 && _jd == _range.first)) {
                        stopMessage = @"暦表の端点に到達して停止";
                    } else _clock.start(_jd, _range, now);
                }
                if (sample->remove_after_dispatch) {
                    _timeAnimation.cancel();
                    stateChanged = YES;
                }
            }
        }
    } catch (const std::exception& failure) {
        NSLog(@"日時補間の更新に失敗: %s", failure.what());
        stopMessage = @"表示の更新に失敗して停止";
    }
    _sampling = NO;
    if (_pendingStopMessage && !stopMessage) stopMessage = _pendingStopMessage;
    if (stopMessage) { [self finishWithMessage:stopMessage]; return NO; }
    if (stateChanged) {
        const NSUInteger revision = ++_stateRevision;
        if (!_timeAnimation.active()) {
            _stateLabel.stringValue = _playing ? @"再生中" : _clockTracking ? @"時計追従中（現在 UTC）" : @"一時停止";
            [self startTimer];
        }
        [self updateControls];
        if (self.stateChanged) self.stateChanged();
        if (_stateRevision == revision && !_playing && !_clockTracking && !_timeAnimation.active() && self.didStop)
            self.didStop();
    }
    return _timeAnimation.active() || _playing || _clockTracking;
}

- (void)updateControls {
    const BOOL valid = _enabled && !_invalidated && std::isfinite(_jd)
        && std::isfinite(_range.first) && std::isfinite(_range.second)
        && _range.first < _range.second && _jd >= _range.first && _jd <= _range.second;
    const BOOL canAdvance = _clock.rate() > 0 ? _jd < _range.second : _jd > _range.first;
    const BOOL active = _playing || _clockTracking || _timeAnimation.active();
    _playButton.enabled = active || (valid && canAdvance && !_sleeping && !_hidden);
    _playButton.title = active ? @"一時停止" : @"再生";
    _rateButton.enabled = valid;
    _directionControl.enabled = valid;
}

- (void)updateRateSelection {
    _directionControl.selectedSegment = _nativeRate < 0 ? 0 : 1;
    const double magnitude = std::abs(_nativeRate);
    // 通常の六段階以外をプログラムから指定した場合も、実際の速度を表示する。
    while (_rateButton.numberOfItems > static_cast<NSInteger>(rates.size()))
        [_rateButton removeItemAtIndex:_rateButton.numberOfItems - 1];
    for (NSUInteger index = 0; index < rates.size(); ++index) {
        if (magnitude == rates[index]) {
            [_rateButton selectItemAtIndex:index];
            return;
        }
    }
    [_rateButton addItemWithTitle:[NSString stringWithFormat:@"%.6g 秒", magnitude]];
    _rateButton.lastItem.representedObject = @(magnitude);
    [_rateButton selectItemAtIndex:_rateButton.numberOfItems - 1];
}

- (void)configureWithJulianDate:(double)jd range:(std::pair<double, double>)range enabled:(BOOL)enabled {
    if (_sampling || _invalidated) return;
    if (_playing || _clockTracking || _timeAnimation.active()) [self interruptWithMessage:@"一時停止"];
    _jd = jd;
    _range = range;
    _enabled = enabled;
    ++_stateRevision;
    const BOOL valid = std::isfinite(jd) && std::isfinite(range.first) && std::isfinite(range.second)
        && range.first < range.second && jd >= range.first && jd <= range.second;
    _stateLabel.stringValue = !enabled ? @"再生できるデータを選択してください"
        : !valid ? @"再生可能な日時の範囲外です"
        : jd == range.second && _clock.rate() > 0 ? @"暦表の終端に到達しています"
        : jd == range.first && _clock.rate() < 0 ? @"暦表の先頭に到達しています" : @"一時停止";
    [self updateControls];
}

- (void)play {
    if ((_clockTracking || _timeAnimation.active()) && !_sampling) [self finishWithMessage:@"再生へ切り替え"];
    if (_playing || _sampling || !_enabled || _invalidated || _sleeping || _hidden) return;
    if (std::isfinite(_jd) && ((_clock.rate() > 0 && _jd == _range.second) ||
                              (_clock.rate() < 0 && _jd == _range.first))) {
        _stateLabel.stringValue = _clock.rate() > 0 ? @"暦表の終端に到達しています" : @"暦表の先頭に到達しています";
        [self updateControls];
        return;
    }
    try {
        _clock.start(_jd, _range, [self monotonicTime]);
    } catch (const std::exception& error) {
        NSLog(@"再生を開始できません: %s", error.what());
        _stateLabel.stringValue = @"再生可能な日時の範囲外です";
        [self updateControls];
        return;
    }
    _playing = YES;
    ++_stateRevision;
    _stateLabel.stringValue = _clock.rate() < 0 ? @"逆再生中" : @"再生中";
    [self startTimer];
    [self updateControls];
    if (self.stateChanged) self.stateChanged();
}

- (void)startTimer {
    [_timer invalidate];
    _timer = nil;
    if (_invalidated || _sleeping || _hidden || (!_playing && !_clockTracking && !_timeAnimation.active())) return;
    __weak PlaybackController *weakSelf = self;
    _timer = [NSTimer timerWithTimeInterval:1.0 / 30.0 repeats:YES block:^(NSTimer *timer) {
        (void)timer;
        PlaybackController *controller = weakSelf;
        if (controller.timeAnimating) [controller sampleAnimationAtTime:[controller monotonicTime]];
        else if (controller.clockTracking) [controller sampleSystemClock];
        else if (controller) [controller sampleAtTime:[controller monotonicTime]];
    }];
    _timer.tolerance = 1.0 / 300.0;
    [NSRunLoop.mainRunLoop addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)playForward {
    [self setSimulationRate:std::abs(_nativeRate)];
    [self play];
}

- (void)playBackward {
    [self setSimulationRate:-std::abs(_nativeRate)];
    [self play];
}

- (void)playRealtime {
    [self setSimulationRate:1];
    [self play];
}

- (void)finishWithMessage:(NSString *)message {
    const BOOL wasActive = _playing || _clockTracking || _timeAnimation.active();
    _timeAnimation.cancel();
    _clock.stop();
    _clock.set_rate(_nativeRate);
    _plusTimeState.speed = 0;
    _plusPlayback = NO;
    _playing = NO;
    _clockTracking = NO;
    [_timer invalidate];
    _timer = nil;
    _pendingStopMessage = nil;
    const NSUInteger revision = ++_stateRevision;
    _stateLabel.stringValue = message;
    [self updateControls];
    if (!wasActive) return;
    if (self.stateChanged) self.stateChanged();
    // stateChangedで再生条件が変わった場合、古い停止の通知を重ねない。
    if (_stateRevision == revision && !_playing && !_clockTracking && !_timeAnimation.active() && self.didStop) self.didStop();
}

- (BOOL)sampleAtTime:(double)now {
    if (_timeAnimation.active()) return [self sampleAnimationAtTime:now];
    if (!_playing || _sampling) return NO;
    _sampling = YES;
    NSString *stopMessage = nil;
    try {
        const auto sample = _clock.sample(now);
        if (sample.event == PlaybackEvent::interrupted) {
            stopMessage = @"更新が中断したため一時停止";
        } else if (sample.julian_date != _jd && (!self.applyDate || !self.applyDate(sample.julian_date))) {
            stopMessage = @"表示の更新に失敗して停止";
        } else {
            _jd = sample.julian_date;
            if (sample.event == PlaybackEvent::end_of_range)
                stopMessage = _clock.rate() < 0 ? @"暦表の先頭に到達して停止" : @"暦表の終端に到達して停止";
        }
    } catch (const std::exception& error) {
        NSLog(@"再生時刻の更新に失敗: %s", error.what());
        stopMessage = @"表示の更新に失敗して停止";
    }
    _sampling = NO;
    // applyDate中の中断は、その反映結果が確定してから停止通知する。
    if (_pendingStopMessage && !stopMessage) stopMessage = _pendingStopMessage;
    if (stopMessage) [self finishWithMessage:stopMessage];
    return stopMessage == nil && _playing;
}

- (BOOL)setClockTracking:(BOOL)enabled {
    if (_invalidated || _sampling) return NO;
    if (!enabled) { if (_clockTracking) [self pause]; return YES; }
    if (_clockTracking && !_timeAnimation.active()) return YES;
    if (!_enabled || !std::isfinite(_range.first) || !std::isfinite(_range.second) ||
        _range.first >= _range.second) return NO;
    if (_playing || _timeAnimation.active()) [self finishWithMessage:@"時計追従へ切り替え"];
    if (_invalidated || !_enabled) return NO;
    _clockTracking = YES;
    ++_stateRevision;
    if (![self sampleSystemClock]) return NO;
    _stateLabel.stringValue = _sleeping || _hidden ? @"時計追従（復帰待ち）" : @"時計追従中（現在 UTC）";
    [self startTimer];
    [self updateControls];
    if (self.stateChanged) self.stateChanged();
    return _clockTracking;
}

- (BOOL)sampleSystemClock {
    if (!_clockTracking || _sampling) return NO;
    if (_sleeping || _hidden) return YES;
    _sampling = YES;
    NSString *stopMessage = nil;
    try {
        // システム時計は積算せず毎回読む。手動の時計修正や復帰後の時刻にも追従する。
        const double candidate = _unixTimeProvider() / 86400.0 + 2440587.5;
        if (!std::isfinite(candidate) || candidate < _range.first || candidate > _range.second) {
            stopMessage = @"現在 UTC が暦表範囲外のため時計追従を停止";
        } else if (candidate != _jd && (!self.applyDate || !self.applyDate(candidate))) {
            stopMessage = @"表示の更新に失敗して時計追従を停止";
        } else {
            _jd = candidate;
        }
    } catch (const std::exception& error) {
        NSLog(@"時計追従の更新に失敗: %s", error.what());
        stopMessage = @"表示の更新に失敗して時計追従を停止";
    }
    _sampling = NO;
    if (_pendingStopMessage && !stopMessage) stopMessage = _pendingStopMessage;
    if (stopMessage) [self finishWithMessage:stopMessage];
    return stopMessage == nil && _clockTracking;
}

- (void)suspendClockTracking {
    if (_timeAnimation.active()) {
        [self interruptWithMessage:@"ウィンドウ非表示・スリープのため一時停止"];
    } else if (_clockTracking) {
        [_timer invalidate];
        _timer = nil;
        _stateLabel.stringValue = @"時計追従（復帰待ち）";
        [self updateControls];
    } else {
        [self interruptWithMessage:@"ウィンドウ非表示・スリープのため一時停止"];
    }
}

- (void)resumeClockTracking {
    if (_clockTracking && !_sleeping && !_hidden && [self sampleSystemClock]) {
        _stateLabel.stringValue = @"時計追従中（現在 UTC）";
        [self startTimer];
    }
    [self updateControls];
}

- (void)suspendForSystemSleep { _sleeping = YES; [self suspendClockTracking]; }
- (void)resumeAfterSystemSleep { _sleeping = NO; [self resumeClockTracking]; }
- (void)suspendForHiddenWindow { _hidden = YES; [self suspendClockTracking]; }
- (void)resumeAfterHiddenWindow { _hidden = NO; [self resumeClockTracking]; }

- (void)pause {
    if (_sampling) {
        _pendingStopMessage = @"一時停止";
        return;
    }
    if (_timeAnimation.active()) {
        [self sampleAnimationAtTime:[self monotonicTime]];
        if (_timeAnimation.active() || _playing || _clockTracking) [self finishWithMessage:@"一時停止"];
        return;
    }
    if (_clockTracking) { [self interruptWithMessage:@"時計追従を解除"]; return; }
    if (_playing && [self sampleAtTime:[self monotonicTime]]) [self finishWithMessage:@"一時停止"];
}

- (void)interruptWithMessage:(NSString *)message {
    NSString *reason = message.length ? message : @"一時停止";
    if (_sampling) {
        _pendingStopMessage = [reason copy];
        return;
    }
    [self finishWithMessage:reason];
}

- (void)setSimulationRate:(double)rate {
    if (_invalidated || _sampling) return;
    try {
        PlaybackClock validation;
        validation.set_rate(rate);
        if (_clockTracking || _timeAnimation.active()) [self finishWithMessage:@"速度設定へ切り替え"];
        if (!_plusPlayback && _nativeRate == rate) return;
        const double now = [self monotonicTime];
        const BOOL resume = _playing && [self sampleAtTime:now];
        if (_playing && !resume) return;
        _clock.stop();
        _clock.set_rate(rate);
        _nativeRate = rate;
        _plusTimeState.speed = 0;
        _plusPlayback = NO;
        if (resume) _clock.start(_jd, _range, now);
        [self updateRateSelection];
        _stateLabel.stringValue = _playing ? (_clock.rate() < 0 ? @"逆再生中" : @"再生中")
            : _jd == _range.second && _clock.rate() > 0 ? @"暦表の終端に到達しています"
            : _jd == _range.first && _clock.rate() < 0 ? @"暦表の先頭に到達しています" : @"一時停止";
        [self updateControls];
    } catch (const std::exception& error) {
        NSLog(@"再生速度を変更できません: %s", error.what());
        if (_playing && !_clock.is_playing()) [self finishWithMessage:@"再生速度を変更できず停止"];
        [self updateRateSelection];
    }
}

- (void)togglePlayback:(id)sender {
    (void)sender;
    if (_playing || _clockTracking || _timeAnimation.active()) [self pause]; else [self play];
}

- (void)changeRate:(NSPopUpButton *)sender {
    const double magnitude = [sender.selectedItem.representedObject doubleValue];
    [self setSimulationRate:_nativeRate < 0 ? -magnitude : magnitude];
}

- (void)changeDirection:(NSSegmentedControl *)sender {
    const double magnitude = std::abs(_nativeRate);
    [self setSimulationRate:sender.selectedSegment == 0 ? -magnitude : magnitude];
}

- (void)invalidate {
    _invalidated = YES;
    _enabled = NO;
    [_timer invalidate];
    _timer = nil;
    [self interruptWithMessage:@"停止"];
    [self updateControls];
}

- (void)dealloc { [_timer invalidate]; }
@end
