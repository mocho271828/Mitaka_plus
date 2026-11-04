#import "AppControllerInternal.h"
#include <stdexcept>

@implementation AppController (ScriptingTime)
- (void)fillScriptTimeSnapshot:(ScriptSnapshot&)state {
    state.julian_date = _jd;
    state.rate_seconds_per_second = _playback.simulationRate;
    state.playing = _playback.playing;
    state.clock_tracking = _playback.clockTracking;
    state.time_info = [self timeInfoVisible];
    state.plus_time = [_playback plusTimeState];
    state.plus_time_zone = [_playback plusTimeZone];
}

- (BOOL)applyScriptTimeAction:(const ScriptAction&)action error:(NSString **)error {
    try {
        if (!_model || _loading) throw std::logic_error("Time: astronomical data is unavailable");
        switch (action.kind) {
            case ScriptActionKind::set_time_step:
            case ScriptActionKind::set_time_step_value:
            case ScriptActionKind::set_time_speed:
            case ScriptActionKind::previous_time_step:
            case ScriptActionKind::next_time_step: {
                auto state = [_playback plusTimeState];
                if (action.kind == ScriptActionKind::set_time_step) {
                    if (!std::isfinite(action.number) || action.number != std::floor(action.number) ||
                        action.number < 0 || action.number > 11)
                        throw std::invalid_argument("Invalid Time step");
                    state.step.select(static_cast<PlusTimeStep>(static_cast<int>(action.number)));
                } else if (action.kind == ScriptActionKind::set_time_step_value) state.step.set_value_days(action.number);
                else if (action.kind == ScriptActionKind::set_time_speed) state.speed = plus_time_speed(action.number);
                else if (action.kind == ScriptActionKind::previous_time_step) state.step.previous();
                else state.step.next();
                if (action.kind == ScriptActionKind::set_time_speed)
                    return [_playback setPlusTimeState:state error:error];
                return [_playback setPlusTimeStep:state.step error:error];
            }
            case ScriptActionKind::step_time_forward:
            case ScriptActionKind::step_time_rewind: {
                const double date = [_playback plusTimeState].step.stepped_julian_date(_jd,
                    action.kind == ScriptActionKind::step_time_forward ? 1 : -1);
                (void)_model->bodies(date);
                if (![self setDate:date]) throw std::runtime_error("date update failed");
                return YES;
            }
            case ScriptActionKind::set_date:
                // 手動日時と同じ入口を使う。範囲外入力では再生や補間を停止しない。
                (void)_model->bodies(action.number);
                if (![self setDate:action.number]) throw std::runtime_error("date update failed");
                return YES;
            case ScriptActionKind::set_time_animation_jd:
            case ScriptActionKind::set_time_animation_calendar:
                (void)_model->bodies(action.number);
                return [_playback animateToJulianDate:action.number duration:action.duration_seconds
                    curve:action.enabled ? PlusTimeAnimationCurve::half_cosine : PlusTimeAnimationCurve::linear
                    sameTargetPolicy:action.kind == ScriptActionKind::set_time_animation_jd ?
                        PlusTimeAnimationSameTarget::preserve : PlusTimeAnimationSameTarget::replace error:error];
            case ScriptActionKind::set_rate:
                [_playback setSimulationRate:action.number];
                [_playback play];
                return YES;
            case ScriptActionKind::stop: [_playback pause]; return YES;
            case ScriptActionKind::set_clock_tracking:
                if (![_playback setClockTracking:action.enabled])
                    throw std::runtime_error("Time: cannot start clock tracking");
                return YES;
            case ScriptActionKind::set_time_info: [self setTimeInfoVisible:action.enabled]; return YES;
            default: throw std::invalid_argument("Unsupported Time action");
        }
    } catch (const std::exception& failure) {
        if (error) *error = [NSString stringWithUTF8String:failure.what()];
        return NO;
    }
}
@end
