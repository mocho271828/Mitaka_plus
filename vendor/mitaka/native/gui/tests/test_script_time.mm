#import <Foundation/Foundation.h>
#import "ScriptController.h"
#include "plus_time_calendar.hpp"
#include <cmath>
#include <cstdio>
#include <stdexcept>
#include <string>
#include <vector>

using namespace mitaka::gui;
namespace {
int checks = 0;
void check(bool condition, const std::string& message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
struct Outcome { bool succeeded = false; std::string message; };
Outcome run(ScriptController *controller, NSString *source) {
    __block bool finished = false;
    __block Outcome result;
    controller.completion = ^(BOOL succeeded, NSString *message) {
        result = {static_cast<bool>(succeeded), message.UTF8String}; finished = true;
    };
    NSError *error = nil;
    check([controller runSource:source error:&error], error ? error.localizedDescription.UTF8String : "launch Time fixture");
    const auto deadline = [NSDate dateWithTimeIntervalSinceNow:10];
    while (!finished && deadline.timeIntervalSinceNow > 0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];
    if (!finished) [controller cancel];
    check(finished && !controller.running, "Time fixture completes and releases worker");
    return result;
}
void succeeds(ScriptController *controller, NSString *source) {
    const auto result = run(controller, source);
    check(result.succeeded, "Lua Time fixture: " + result.message);
}
void fails(ScriptController *controller, NSString *source, const char *fragment = nullptr) {
    const auto result = run(controller, source);
    check(!result.succeeded, "Lua Time fixture must fail");
    if (fragment) check(result.message.find(fragment) != std::string::npos, "Lua Time error: " + result.message);
}
bool near(double a, double b) { return std::abs(a - b) < 1e-8; }
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        try {
            check(argc == 2, "pass MitakaScript helper path");
            ScriptController *controller = [[ScriptController alloc] initWithHelperURL:
                [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]]];
            __block ScriptSnapshot state;
            __block std::vector<ScriptAction> actions;
            __block bool reject = false;
            state.plus_time_zone = PlusTimeZone(-32400);
            controller.snapshot = ^{ return state; };
            controller.applyAction = ^BOOL(const ScriptAction& action, NSString **error) {
                if (reject) { *error = @"Time host rejection"; return NO; }
                actions.push_back(action);
                if (action.kind == ScriptActionKind::set_date) {
                    state.julian_date = action.number;
                    state.clock_tracking = false;
                }
                return YES;
            };

            succeeds(controller, @R"lua(
                assert(select('#', Time:setLocalTime(2000,1,2,3,4,5)) == 0)
                assert(select('#', Time:getLocalTime()) == 6)
                local y,m,d,h,n,s = Time:getLocalTime()
                assert(y==2000 and m==1 and d==2 and h==3 and n==4)
                assert(s==Time.localSecond and s==Time:getLocalSec())
                assert(Time.localMin==Time.localMinute and Time:getLocalMin()==Time:getLocalMinute())
            )lua");
            check(near(state.julian_date, plus_local_julian_date({2000,1,2,3,4,5}, *state.plus_time_zone)), "local calendar sends UTC target");

            // 整数秒へ丸める既存 UTC getter と、切り捨てる新 getter を分離して確認する。
            state.julian_date = mitaka::julian_date({2001,1,31,12,34,12.75});
            state.plus_time_zone = PlusTimeZone(0);
            succeeds(controller, @R"lua(
                local _,_,_,_,_,utc = Time:getTime()
                local _,_,_,_,_,localSec = Time:getLocalTime()
                assert(utc==13 and localSec==12)
                assert(Time:getTimeString()=='2001,1,31,12,34,12')
            )lua");
            actions.clear(); state.clock_tracking = true;
            succeeds(controller, @R"lua(
                Time.localYear=Time.localYear
                assert(select('#',Time:setLocalYear(Time:getLocalYear()))==0)
                Time.localMinute=Time.localMin
                Time:setLocalMin(Time:getLocalMinute())
            )lua");
            check(actions.empty() && state.clock_tracking, "same component preserves tracking without apply");
            succeeds(controller, @"Time:setLocalSecond(Time:getLocalSecond())");
            check(actions.size() == 1 && !state.clock_tracking, "integer second replaces fractional second");
            check(near(state.julian_date, mitaka::julian_date({2001,1,31,12,34,12})), "second setter truncates original fraction");

            for (int second = 0; second < 60; ++second) {
                state.plus_time_zone = PlusTimeZone(-32400);
                state.julian_date = plus_local_julian_date({2000,1,2,3,4,static_cast<double>(second)}, *state.plus_time_zone);
                actions.clear(); state.clock_tracking = true;
                succeeds(controller, @R"lua(
                    Time.localYear=Time.localYear; Time.localMonth=Time.localMonth
                    Time.localDay=Time.localDay; Time.localHour=Time.localHour
                    Time.localMinute=Time.localMinute; Time.localSecond=Time.localSecond
                )lua");
                check(actions.empty() && state.clock_tracking,
                      "integer calendar getter/setter roundtrip must not interrupt tracking second " + std::to_string(second));
            }
            state.plus_time_zone = PlusTimeZone(0);

            struct ComponentCase { const char *suffix; int value; PlusTimeComponent component; };
            const ComponentCase components[] = {
                {"Year",2004,PlusTimeComponent::year}, {"Month",2,PlusTimeComponent::month},
                {"Day",0,PlusTimeComponent::day}, {"Hour",24,PlusTimeComponent::hour},
                {"Min",61,PlusTimeComponent::minute}, {"Minute",62,PlusTimeComponent::minute},
                {"Sec",10,PlusTimeComponent::second}, {"Second",11,PlusTimeComponent::second}
            };
            for (const auto& test : components) {
                const double initial = mitaka::julian_date({2001,1,31,12,34,12.75});
                const double expected = *plus_local_component_julian_date(initial, *state.plus_time_zone, test.component, test.value);
                for (bool property : {false, true}) {
                    state.julian_date = initial; actions.clear();
                    NSString *source = property ? [NSString stringWithFormat:@"Time.local%s=%d", test.suffix, test.value] :
                        [NSString stringWithFormat:@"assert(select('#',Time:setLocal%s(%d))==0)", test.suffix, test.value];
                    succeeds(controller, source);
                    check(actions.size() == 1 && near(state.julian_date, expected), std::string("component route: ") + test.suffix);
                    succeeds(controller, [NSString stringWithFormat:@"assert(Time.local%s==Time:getLocal%s())", test.suffix, test.suffix]);
                }
            }
            state.julian_date = mitaka::julian_date({2001,1,31,12,34,12.75});
            succeeds(controller, @"Time:setLocalMonth(2)");
            const auto rollover = mitaka::gregorian_date_time(state.julian_date);
            check(rollover.month == 3 && rollover.day == 3 && std::abs(rollover.second - 12.75) < 0.001,
                  "month rollover preserves subsecond value");

            succeeds(controller, @R"lua(
                local text='0x7d0,01,02,03,04,05suffix'..string.rep('x',9000)..string.char(255)
                assert(select('#',Time:setTimeString(text))==1)
                assert(Time:setTimeString(text)==text)
                assert(select('#',Time.getTimeString())==1)
            )lua");
            check(near(state.julian_date, plus_julian_date({2000,1,2,3,4,5})), "string parses calendar and preserves full raw argument");
            state.plus_time_zone = PlusTimeZone(-32400); actions.clear();
            succeeds(controller, @R"lua(
                assert(select('#',Time:setTimeTo(2000,1,2,3,4,5,2))==0)
                Time.setLocalTimeTo(2000,1,2,3,4,5,-2,false)
                Time:setJDTo(2451545.25,0,true)
                Time.setJDTo(Time.JD,1,false)
            )lua");
            check(actions.size() == 4, "all animation calls dispatch to host");
            check(actions[0].kind == ScriptActionKind::set_time_animation_calendar && actions[0].enabled &&
                  actions[0].duration_seconds == 2 && near(actions[0].number, plus_julian_date({2000,1,2,3,4,5})), "UTC animation target and default curve");
            check(actions[1].kind == ScriptActionKind::set_time_animation_calendar && !actions[1].enabled &&
                  actions[1].duration_seconds == -2 && near(actions[1].number, plus_local_julian_date({2000,1,2,3,4,5}, *state.plus_time_zone)), "local animation target and signed duration");
            check(actions[2].kind == ScriptActionKind::set_time_animation_jd && actions[2].number == 2451545.25 &&
                  actions[2].duration_seconds == 0 && actions[2].enabled, "JD animation zero duration");
            check(actions[3].kind == ScriptActionKind::set_time_animation_jd && actions[3].number == state.julian_date &&
                  !actions[3].enabled, "same JD reaches host to preserve numeric animation semantics");

            const NSArray<NSString *> *invalid = @[
                @"Time:setLocalTime(2000,1,2,3,4)", @"Time:setLocalTime(2000,1,2,3,4,5,6)",
                @"Time:setLocalTime(2000,1,2,3,4,5.5)", @"Time:setLocalTime('2000',1,2,3,4,5)",
                @"Time:setLocalTime(2000,128,2,3,4,5)", @"Time:setLocalTime(-4713,1,2,3,4,5)",
                @"Time:getLocalTime(1)", @"Time:getLocalYear(1)", @"Time:setLocalSecond()",
                @"Time:setLocalYear(2000,1)", @"Time.localMinute=1.5", @"Time:setLocalYear(2147483648)",
                @"Time:setLocalMonth(128)", @"Time:setLocalHour(Camera,1)",
                @"Time.getLocalSecond(Stars)", @"Time.setLocalTime(Stars,2000,1,2,3,4,5)",
                @"Time:setTimeString(2000)", @"Time:setTimeString('2000,1,2,3,4')",
                @"Time:setTimeString('2000,1,2,3,4,5'..string.char(0))", @"Time:setTimeString('2000,1,2,3,4,2147483648')",
                @"Time:setTimeString('2000,1,2,3,4,5',1)", @"Time:getTimeString(1)",
                @"Time:setTimeTo(2000,1,2,3,4,5)", @"Time:setTimeTo(2000,1,2,3,4,5,1,nil)",
                @"Time:setTimeTo(2000,1,2,3,4,5,1,1)", @"Time:setLocalTimeTo(2000,1,2,3,4,5,0/0)",
                @"Time:setJDTo(2451545)", @"Time:setJDTo(2451545,math.huge)",
                @"Time:setJDTo(2451545,1,'false')", @"Time:setJDTo(2451545,1,false,1)",
                @"Time:setJDTo(1e20,1)", @"Time:setJDTo({},1)", @"Time.setJDTo(Camera,2451545,1)"
            ];
            for (NSString *source in invalid) {
                actions.clear(); const double before = state.julian_date;
                fails(controller, source);
                check(actions.empty() && state.julian_date == before, "invalid Time input does not apply");
            }
            state.plus_time_zone.reset(); actions.clear();
            for (NSString *source in @[@"Time:getLocalTime()", @"Time:setLocalTime(2000,1,1,0,0,0)",
                @"return Time.localYear", @"Time:setLocalMin(1)", @"Time:setLocalTimeTo(2000,1,1,0,0,0,1)"])
                fails(controller, source, "explicit CRT time zone");
            check(actions.empty(), "missing explicit zone rejects every local action");
            succeeds(controller, @"Time:setTimeString('2000,1,1,0,0,0'); Time:getTimeString(); Time:setTimeTo(2000,1,1,0,0,0,1); Time:setJDTo(2451545,1)");
            reject = true;
            for (NSString *source in @[@"Time:setTimeString('2001,1,1,0,0,0')", @"Time:setJDTo(2451546,1)",
                @"Time:setTimeTo(2001,1,1,0,0,0,1)"])
                fails(controller, source, "Time host rejection");
            state.plus_time_zone = PlusTimeZone(0);
            fails(controller, @"Time:setLocalYear(2001)", "Time host rejection");
            [controller invalidate];
            std::printf("script Time checks passed: %d\n", checks);
            return 0;
        } catch (const std::exception& error) {
            std::fprintf(stderr, "script Time failure: %s\n", error.what()); return 1;
        }
    }
}
