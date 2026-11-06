#pragma once

#import <AppKit/AppKit.h>
#include <utility>
#include "plus_time_playback.hpp"
#include "plus_time_calendar.hpp"
#include "plus_time_animation.hpp"
#include <optional>

// 操作・コールバックはいずれもメインスレッドで実行する。
@interface PlaybackController : NSObject
@property(nonatomic, readonly) NSView *view;
@property(nonatomic, readonly) BOOL playing;
@property(nonatomic, readonly) BOOL clockTracking;
@property(nonatomic, readonly) BOOL timeAnimating;
@property(nonatomic, readonly) double julianDate;
// 実時間 1 秒あたりの暦表秒。負数は逆再生、絶対値は [1,2592000]。
@property(nonatomic, readonly) double simulationRate;
// Lua 専用の step / 日単位 value / int32 speed。native 速度設定とは独立する。
- (mitaka::gui::PlusTimeState)plusTimeState;
// 全候補を検証してから変更する。非零 speed は専用速度で連続再生する。
- (BOOL)setPlusTimeState:(const mitaka::gui::PlusTimeState&)state error:(NSString **)error;
// step の変更は speed setter と異なり、時計追従や通常再生を解除しない。
- (BOOL)setPlusTimeStep:(const mitaka::gui::PlusTimeStepState&)step error:(NSString **)error;
// 原版 CRT の固定時差を明示設定する。未指定と UTC (0 秒) を区別する。
- (std::optional<mitaka::gui::PlusTimeZone>)plusTimeZone;
- (void)setPlusTimeZone:(std::optional<mitaka::gui::PlusTimeZone>)zone;
// JD 指定は preserve、暦指定は replace を使う。暦指定だけ開始時に時計追従を解除する。
- (BOOL)animateToJulianDate:(double)jd duration:(double)duration
    curve:(mitaka::gui::PlusTimeAnimationCurve)curve
    sameTargetPolicy:(mitaka::gui::PlusTimeAnimationSameTarget)policy error:(NSString **)error;
// 同期的に表示を更新し、成功時だけ YES を返す。
@property(nonatomic, copy) BOOL (^applyDate)(double jd);
@property(nonatomic, copy) void (^stateChanged)(void);
@property(nonatomic, copy) void (^didStop)(void);

// 通常 init は NSDate を使う。注入する時計も Unix epoch からの秒を返す。
- (instancetype)initWithUnixTimeProvider:(double (^)(void))provider;
- (BOOL)setClockTracking:(BOOL)enabled;
- (void)suspendForSystemSleep;
- (void)resumeAfterSystemSleep;
- (void)suspendForHiddenWindow;
- (void)resumeAfterHiddenWindow;

// 停止中の日時変更・データ切り替え時に呼ぶ。enabled=NO なら範囲検証を要求しない。
- (void)configureWithJulianDate:(double)jd range:(std::pair<double, double>)range enabled:(BOOL)enabled;
- (void)play;
- (void)playForward;
- (void)playBackward;
// 現在の表示日時を基準に、順方向の 1 倍速で再生する。システム日時への移動はしない。
- (void)playRealtime;
- (void)pause;
// 中断時は新しい日時を計算せず、最後に反映できた表示時刻を保持する。
- (void)interruptWithMessage:(NSString *)message;
// 再入による新しい操作が優先された場合や無効値では NO。
- (BOOL)setSimulationRate:(double)rate;
// 破棄前に呼ぶと、以降の再生操作を無効にする。
- (void)invalidate;
@end
