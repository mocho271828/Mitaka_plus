#pragma once

#import <AppKit/AppKit.h>
#include <utility>
#include "plus_time_playback.hpp"

// 操作・コールバックはいずれもメインスレッドで実行する。
@interface PlaybackController : NSObject
@property(nonatomic, readonly) NSView *view;
@property(nonatomic, readonly) BOOL playing;
@property(nonatomic, readonly) BOOL clockTracking;
@property(nonatomic, readonly) double julianDate;
// 実時間 1 秒あたりの暦表秒。負数は逆再生、絶対値は [1,2592000]。
@property(nonatomic, readonly) double simulationRate;
// Lua 専用の step / 日単位 value / int32 speed。native 速度設定とは独立する。
- (mitaka::gui::PlusTimeState)plusTimeState;
// 全候補を検証してから変更する。非零 speed は専用速度で連続再生する。
- (BOOL)setPlusTimeState:(const mitaka::gui::PlusTimeState&)state error:(NSString **)error;
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
- (void)setSimulationRate:(double)rate;
// 破棄前に呼ぶと、以降の再生操作を無効にする。
- (void)invalidate;
@end
