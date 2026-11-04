#pragma once
#import <Foundation/Foundation.h>

// 全操作と callback はメインスレッド。表示値は App の共通設定にだけ保持する。
@interface StarBrightnessController : NSObject
@property(nonatomic, readonly) BOOL animating;
@property(nonatomic, copy) BOOL (^applyValue)(float value);
@property(nonatomic, copy) void (^didFail)(NSString *message);
- (instancetype)initWithMonotonicTimeProvider:(double (^)(void))provider;
- (BOOL)animateFrom:(float)current to:(double)target duration:(double)seconds error:(NSString **)error;
// 取消しは target を適用せず、最後に表示された値を残す。
- (void)cancel;
- (void)invalidate;
@end
