#import <Foundation/Foundation.h>
#import "ScriptController.h"
#include "script_transport.hpp"
#include "star_brightness.hpp"
#include "mitaka/astronomy.hpp"
#include <lua.hpp>
#include <algorithm>
#include <array>
#include <chrono>
#include <charconv>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <limits>
#include <memory>
#include <stdexcept>
#include <string>
#include <string_view>
#include <thread>
#include <utility>
#include <unistd.h>

using namespace mitaka::gui;
namespace {
constexpr double auPerParsec = 648000.0 / 3.14159265358979323846;
constexpr std::size_t memoryLimit = 64 * 1024 * 1024;
constexpr std::array<const char *, 12> stepNames{"STEP_SEC", "STEP_10SEC", "STEP_MIN", "STEP_10MIN",
    "STEP_HOUR", "STEP_DAY", "STEP_WEEK", "STEP_MONTH", "STEP_YEAR", "STEP_10YEAR", "STEP_100YEAR", "STEP_VALUE"};
struct Context {
    std::size_t allocated = 0;
    std::size_t instructions = 0;
    std::chrono::steady_clock::time_point started = std::chrono::steady_clock::now();
};
struct Reply {
    enum Type { empty, number, boolean, text, calendar, radius_scale, euler, function, original_argument } type = empty;
    double values[6]{};
    bool flag = false;
    int method = 0;
    int stack_index = 0;
    char string[4096]{};
};
enum Object { timeObject = 1, cameraObject, constellationObject, starsObject, galaxiesObject, guiObject,
              milkyWayObject, planetsObject, gridsObject, rendererObject, asteroidsObject, tnobjectsObject, cometsObject, satellitesObject, placesObject };
enum Method { setTime = 1, getTime, stopTime, stepForward, stepRewind, currentTime,
              previousStep, nextStep, printText, waitSeconds, saveImageDialog, toggleFullScreen, aboutDialog,
              brightenStars, darkenStars, defaultStarBrightness, animateStarBrightness,
              selectStarNames, deselectStarNames, isStarNameSelected, toggleAtmosphere,
              setTimeString, getTimeString, setLocalTime, getLocalTime, setTimeTo, setLocalTimeTo, setJDTo,
              getLocalComponentBase = 40, setLocalComponentBase = 50,
              setRadiusScale = 60, getRadiusScale, setRadiusScaleMode, getRadiusScaleMode, lookTarget, animateAzimuth, animateAltitude,
              setModeTo, toggleMode, toggleModeTo, forceMode, getOrient, getEuler, setOrient, setEuler, addEuler,
              setOrientTo, setEulerTo, addEulerTo, animateLookTarget, animateTarget, animateZoom, animateZoomLog, toggleFlagBase = 100 };
struct LocalTimeBinding {
    const char *property;
    const char *getter;
    const char *setter;
    PlusTimeComponent component;
};
constexpr LocalTimeBinding localTimeBindings[] = {
    {"localYear", "getLocalYear", "setLocalYear", PlusTimeComponent::year},
    {"localMonth", "getLocalMonth", "setLocalMonth", PlusTimeComponent::month},
    {"localDay", "getLocalDay", "setLocalDay", PlusTimeComponent::day},
    {"localHour", "getLocalHour", "setLocalHour", PlusTimeComponent::hour},
    {"localMin", "getLocalMin", "setLocalMin", PlusTimeComponent::minute},
    {"localMinute", "getLocalMinute", "setLocalMinute", PlusTimeComponent::minute},
    {"localSec", "getLocalSec", "setLocalSec", PlusTimeComponent::second},
    {"localSecond", "getLocalSecond", "setLocalSecond", PlusTimeComponent::second}
};
struct BooleanBinding {
    Object object;
    const char *property;
    const char *toggle;
    NSString *snapshot_key;
    ScriptActionKind action;
    bool writable = true;
};
// alias は同一の snapshot/action を共有し、GUI 側で変わった状態も毎回読み出す。
const BooleanBinding booleanBindings[] = {
    {asteroidsObject, "visible", "toggle", @"asteroids_visible", ScriptActionKind::set_asteroids_visible},
    {asteroidsObject, "labels", "toggleLabels", @"asteroids_labels", ScriptActionKind::set_asteroids_labels},
    {asteroidsObject, "orbits", "toggleOrbits", @"asteroids_orbits", ScriptActionKind::set_asteroids_orbits},
    {asteroidsObject, "selectedOnly", "toggleSelectedOnly", @"asteroids_selectedOnly", ScriptActionKind::set_asteroids_selected_only},
    {tnobjectsObject, "visible", "toggle", @"tnobjects_visible", ScriptActionKind::set_tnobjects_visible},
    {tnobjectsObject, "labels", "toggleLabels", @"tnobjects_labels", ScriptActionKind::set_tnobjects_labels},
    {tnobjectsObject, "orbits", "toggleOrbits", @"tnobjects_orbits", ScriptActionKind::set_tnobjects_orbits},
    {tnobjectsObject, "selectedOnly", "toggleSelectedOnly", @"tnobjects_selectedOnly", ScriptActionKind::set_tnobjects_selected_only},
    {cometsObject, "visible", "toggle", @"comets_visible", ScriptActionKind::set_comets_visible},
    {cometsObject, "labels", "toggleLabels", @"comets_labels", ScriptActionKind::set_comets_labels},
    {cometsObject, "orbits", "toggleOrbits", @"comets_orbits", ScriptActionKind::set_comets_orbits},
    {cometsObject, "selectedOnly", "toggleSelectedOnly", @"comets_selectedOnly", ScriptActionKind::set_comets_selected_only},
    {satellitesObject, "visible", "toggle", @"satellites_visible", ScriptActionKind::set_satellites_visible},
    {satellitesObject, "labels", "toggleLabels", @"satellites_labels", ScriptActionKind::set_satellites_labels},
    {satellitesObject, "orbits", "toggleOrbits", @"satellites_orbits", ScriptActionKind::set_satellites_orbits},
    {satellitesObject, "selectedOnly", "toggleSelectedOnly", @"satellites_selectedOnly", ScriptActionKind::set_satellites_selected_only},
    {timeObject, "realtime", "toggleRealtime", @"realtime", ScriptActionKind::set_clock_tracking},
    {timeObject, "timeInfo", "toggleTimeInfo", @"timeInfo", ScriptActionKind::set_time_info},
    {constellationObject, "lines", "toggleLines", @"lines", ScriptActionKind::set_constellation_lines},
    {constellationObject, "bounds", "toggleBounds", @"bounds", ScriptActionKind::set_constellation_boundaries},
    {constellationObject, "labels", "toggleLabels", @"labels", ScriptActionKind::set_constellation_labels},
    {constellationObject, "illusts", "toggleIllusts", @"illusts", ScriptActionKind::set_constellation_illustrations},
    {starsObject, "labels", "toggleLabels", @"starLabels", ScriptActionKind::set_star_labels},
    {starsObject, "selectedLabels", "toggleSelectedLabels", @"selectedStarLabels", ScriptActionKind::set_selected_star_labels},
    {starsObject, "visible", "toggle", @"starsVisible", ScriptActionKind::set_stars_visible},
    {starsObject, "bayerLabels", "toggleBayerLabels", @"bayerLabels", ScriptActionKind::set_bayer_labels},
    {starsObject, "flamsteedLabels", "toggleFlamsteedLabels", @"flamsteedLabels", ScriptActionKind::set_flamsteed_labels},
    {starsObject, "hipLabels", "toggleHipLabels", @"hipLabels", ScriptActionKind::set_hip_labels},
    {planetsObject, "visible", "toggle", @"planetsVisible", ScriptActionKind::set_planets_visible},
    {planetsObject, "labels", "toggleLabels", @"planetLabels", ScriptActionKind::set_planet_labels},
    {planetsObject, "orbits", "toggleOrbits", @"planetOrbits", ScriptActionKind::set_planet_orbits},
    {planetsObject, "axes", "toggleAxes", @"planetAxes", ScriptActionKind::set_planet_axes},
    {planetsObject, "clouds", "toggleClouds", @"earthClouds", ScriptActionKind::set_earth_clouds},
    {planetsObject, "cityLights", "toggleCityLights", @"earthCityLights", ScriptActionKind::set_earth_city_lights},
    {planetsObject, "shadows", "toggleShadows", @"shadows", ScriptActionKind::set_shadows},
    {planetsObject, "shadowBorders", "toggleShadowBorders", @"shadowBorders", ScriptActionKind::set_shadow_borders},
    {planetsObject, "shadowUmbra", "toggleShadowUmbra", @"shadowUmbra", ScriptActionKind::set_shadow_umbra},
    {planetsObject, "shadowPenumbra", "toggleShadowPenumbra", @"shadowPenumbra", ScriptActionKind::set_shadow_penumbra},
    {placesObject, "landscape", "toggleLandscape", @"landscape", ScriptActionKind::set_landscape},
    {gridsObject, "equatorial", "toggleEquatorial", @"equatorial", ScriptActionKind::set_equatorial_grid},
    {gridsObject, "ecliptic", "toggleEcliptic", @"ecliptic", ScriptActionKind::set_ecliptic_grid},
    {gridsObject, "galactic", "toggleGalactic", @"galactic", ScriptActionKind::set_galactic_grid},
    {gridsObject, "horizontal", "toggleHorizontal", @"horizontal", ScriptActionKind::set_horizontal_grid},
    {gridsObject, "circleScales", "toggleCircleScales", @"circleScales", ScriptActionKind::set_circle_scales},
    {gridsObject, "squareScales", "toggleSquareScales", @"squareScales", ScriptActionKind::set_square_scales},
    {rendererObject, "antialias", "toggleAntialias", @"antialias", ScriptActionKind::set_antialias},
    {rendererObject, "pointSmooth", "togglePointSmooth", @"pointSmooth", ScriptActionKind::set_point_smoothing},
    {rendererObject, "lineSmooth", "toggleLineSmooth", @"lineSmooth", ScriptActionKind::set_line_smoothing},
    {rendererObject, "textSmooth", "toggleTextSmooth", @"textSmooth", ScriptActionKind::set_text_smoothing},
    {galaxiesObject, "NGCs", "toggleNGCs", @"nebulae", ScriptActionKind::set_nebulae},
    {galaxiesObject, "distantGalaxies", "toggleDistantGalaxies", @"galaxies", ScriptActionKind::set_distant_galaxies},
    {galaxiesObject, "SDSS", "toggleSDSS", @"galaxies", ScriptActionKind::set_distant_galaxies},
    {galaxiesObject, "quasars", "toggleQuasars", @"quasars", ScriptActionKind::set_quasars},
    {galaxiesObject, "QSOs", "toggleQSOs", @"quasars", ScriptActionKind::set_quasars},
    {guiObject, "targetBrowser", "toggleTargetBrowser", @"targetBrowser", ScriptActionKind::set_target_browser},
    {guiObject, "timeSetting", "toggleTimeSetting", @"timeSetting", ScriptActionKind::set_time_setting},
    {guiObject, "placeSetting", "togglePlaceSetting", @"placeSetting", ScriptActionKind::set_place_setting},
    {guiObject, "scriptOutput", "toggleScriptOutput", @"scriptOutput", ScriptActionKind::set_script_output},
    // 同梱 GUI で確認できた読出しと toggle だけを公開し、不明な setter を補わない。
    {guiObject, "dualScreen", "toggleDualScreen", @"dualScreen", ScriptActionKind::set_dual_screen, false}
};
constexpr const char *hostMetatable = "Mitaka.HostObject";

NSDictionary *request(NSDictionary *message) {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:message options:0 error:&error];
    if (!data) throw std::runtime_error(error.localizedDescription.UTF8String);
    write_script_frame(STDIN_FILENO, std::string(static_cast<const char *>(data.bytes), data.length));
    const auto text = read_script_frame(STDIN_FILENO);
    id value = [NSJSONSerialization JSONObjectWithData:[NSData dataWithBytes:text.data() length:text.size()] options:0 error:nil];
    if (![value isKindOfClass:NSDictionary.class] || ![value[@"ok"] isKindOfClass:NSNumber.class])
        throw std::runtime_error("Invalid host response");
    if (![value[@"ok"] boolValue]) {
        NSString *failure = [value[@"error"] isKindOfClass:NSString.class] ? value[@"error"] : @"Host rejected script action";
        throw std::runtime_error(failure.UTF8String);
    }
    return value;
}
void apply(ScriptActionKind kind, double number = 0, bool flag = false, const char *text = "", double duration = 0,
           const std::vector<std::int32_t>& hips = {}, NSArray<NSNumber *> *radiusScale = @[], NSArray<NSNumber *> *orientation = @[]) {
    NSString *value = [NSString stringWithUTF8String:text];
    if (!value) throw std::invalid_argument("Host names must be UTF-8");
    NSMutableArray<NSNumber *> *identifiers = [NSMutableArray arrayWithCapacity:hips.size()];
    for (const auto hip : hips) [identifiers addObject:@(hip)];
    request(@{@"op":@"apply", @"kind":@(static_cast<int>(kind)), @"number":@(number),
        @"enabled":@(flag), @"text":value, @"duration":@(duration), @"hips":identifiers,
        @"radiusScale":radiusScale, @"orientation":orientation});
}
NSDictionary *snapshot() { return request(@{@"op":@"snapshot"}); }
Context& context(lua_State *state) { return **static_cast<Context **>(lua_getextraspace(state)); }
double numberAt(lua_State *state, int index, bool integer = false) {
    if (lua_type(state, index) != LUA_TNUMBER) throw std::invalid_argument("Expected a number");
    const double value = lua_tonumber(state, index);
    if (!std::isfinite(value) || (integer && (value != std::floor(value) || value < -10000000 || value > 10000000)))
        throw std::invalid_argument("Expected a finite value in range");
    return value;
}
int timeIntegerAt(lua_State *state, int index) {
    const double value = numberAt(state, index);
    if (value != std::trunc(value) || value < std::numeric_limits<std::int32_t>::min() ||
        value > std::numeric_limits<std::int32_t>::max())
        throw std::invalid_argument("Time requires an int32 integer");
    return static_cast<int>(value);
}
const char *textAt(lua_State *state, int index) {
    if (lua_type(state, index) != LUA_TSTRING) throw std::invalid_argument("Expected a string");
    std::size_t length = 0;
    const char *value = lua_tolstring(state, index, &length);
    if (length > 4095 || std::strlen(value) != length) throw std::invalid_argument("Invalid string length");
    return value;
}
bool booleanAt(lua_State *state, int index) {
    if (lua_type(state, index) != LUA_TBOOLEAN) throw std::invalid_argument("Expected a boolean");
    return lua_toboolean(state, index);
}
std::int32_t starHIP(const std::string_view text) {
    std::int32_t hip = 0;
    if (text.empty() || !std::all_of(text.begin(), text.end(), [](char c) { return c >= '0' && c <= '9'; }))
        throw std::invalid_argument("HIP must be a positive decimal integer");
    const auto result = std::from_chars(text.data(), text.data() + text.size(), hip);
    if (result.ec != std::errc{} || result.ptr != text.data() + text.size() || hip <= 0)
        throw std::invalid_argument("HIP must fit a positive 32-bit integer");
    return hip;
}
std::vector<std::int32_t> starHIPList(const std::string_view text) {
    std::vector<std::int32_t> hips;
    std::size_t start = 0;
    while (start < text.size()) {
        start = text.find_first_not_of(' ', start);
        if (start == std::string_view::npos) break;
        const auto end = text.find(' ', start);
        hips.push_back(starHIP(text.substr(start, end == std::string_view::npos ? end : end - start)));
        if (end == std::string_view::npos) break;
        start = end + 1;
    }
    if (hips.empty()) throw std::invalid_argument("Expected at least one HIP");
    return hips;
}
Reply numeric(double value) { Reply result; result.type = Reply::number; result.values[0] = value; return result; }
Reply boolean(bool value) { Reply result; result.type = Reply::boolean; result.flag = value; return result; }
Reply method(int value) { Reply result; result.type = Reply::function; result.method = value; return result; }
Reply textReply(NSString *value) {
    if (![value isKindOfClass:NSString.class]) throw std::runtime_error("Invalid host text");
    Reply result; result.type = Reply::text;
    std::snprintf(result.string, sizeof(result.string), "%s", value.UTF8String);
    return result;
}
mitaka::GregorianDateTime calendar(double jd) {
    // JD の丸め誤差で整数秒が 59.99999 になるため、日付境界も含めて秒単位へ丸める。
    const double seconds = std::round((jd + 0.5) * 86400.0);
    const double day = std::floor(seconds / 86400.0);
    auto date = mitaka::gregorian_date_time(day - 0.5);
    const int withinDay = static_cast<int>(seconds - day * 86400.0);
    date.hour = withinDay / 3600;
    date.minute = withinDay % 3600 / 60;
    date.second = withinDay % 60;
    return date;
}
Reply calendarReply(const mitaka::GregorianDateTime& date) {
    Reply result; result.type = Reply::calendar;
    result.values[0] = date.year; result.values[1] = date.month; result.values[2] = date.day;
    result.values[3] = date.hour; result.values[4] = date.minute; result.values[5] = date.second;
    return result;
}
PlusTimeZone timeZone(NSDictionary *current) {
    id value = current[@"plusTimeZoneWestSeconds"];
    if (value == NSNull.null) throw std::invalid_argument("Local Time requires an explicit CRT time zone");
    if (![value isKindOfClass:NSNumber.class] || CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID())
        throw std::runtime_error("Invalid host CRT time zone");
    const double seconds = [value doubleValue];
    if (!std::isfinite(seconds) || seconds != std::trunc(seconds) ||
        seconds < std::numeric_limits<std::int32_t>::min() || seconds > std::numeric_limits<std::int32_t>::max())
        throw std::runtime_error("Invalid host CRT time zone");
    return PlusTimeZone(static_cast<std::int32_t>(seconds));
}
double localComponent(NSDictionary *current, PlusTimeComponent component) {
    const auto date = plus_local_time([current[@"jd"] doubleValue], timeZone(current));
    switch (component) {
        case PlusTimeComponent::year: return date.year;
        case PlusTimeComponent::month: return date.month;
        case PlusTimeComponent::day: return date.day;
        case PlusTimeComponent::hour: return date.hour;
        case PlusTimeComponent::minute: return date.minute;
        case PlusTimeComponent::second: return date.second;
    }
    throw std::logic_error("Unknown local Time component");
}
void setLocalComponent(PlusTimeComponent component, std::int32_t value) {
    NSDictionary *current = snapshot();
    const auto jd = plus_local_component_julian_date([current[@"jd"] doubleValue], timeZone(current), component, value);
    // 同じ成分の指定は補間や実時計追従を取り消さない。
    if (jd) apply(ScriptActionKind::set_date, *jd);
}
mitaka::GregorianDateTime calendarArguments(lua_State *state, int offset) {
    return {timeIntegerAt(state, offset+1), timeIntegerAt(state, offset+2),
        timeIntegerAt(state, offset+3), timeIntegerAt(state, offset+4),
        timeIntegerAt(state, offset+5), static_cast<double>(timeIntegerAt(state, offset+6))};
}
int objectAt(lua_State *state) {
    const auto *object = static_cast<int *>(luaL_testudata(state, 1, hostMetatable));
    if (!object || lua_rawlen(state, 1) != sizeof(int)) throw std::invalid_argument("Expected a Mitaka host object");
    return *object;
}

Reply readProperty(int object, const std::string& key) {
    if (object == milkyWayObject && key == "type") return textReply(snapshot()[@"milkyWay"]);
    if (object == starsObject && key == "markingType") return textReply(snapshot()[@"starMarking"]);
    if (object == planetsObject && key == "atmosphere") return numeric([snapshot()[@"atmosphereMode"] intValue]);
    if (object == planetsObject && key == "topoAmplification") return numeric([snapshot()[@"topoAmplification"] intValue]);
    if (object == planetsObject && key == "scaleMode") return numeric([snapshot()[@"radiusScaleMode"] intValue]);
    if (object == planetsObject && key == "setScale") return method(setRadiusScale);
    if (object == planetsObject && key == "getScale") return method(getRadiusScale);
    if (object == planetsObject && key == "setScaleMode") return method(setRadiusScaleMode);
    if (object == planetsObject && key == "getScaleMode") return method(getRadiusScaleMode);
    if (object == planetsObject && key == "toggleAtmosphere") return method(toggleAtmosphere);
    if (object == starsObject) {
        if (key == "brightness") return numeric([snapshot()[@"starBrightness"] doubleValue]);
        if (key == "brighten") return method(brightenStars);
        if (key == "darken") return method(darkenStars);
        if (key == "defaultBrightness") return method(defaultStarBrightness);
        if (key == "setBrightnessTo") return method(animateStarBrightness);
        if (key == "select") return method(selectStarNames);
        if (key == "deselect") return method(deselectStarNames);
        if (key == "isSelected") return method(isStarNameSelected);
    }
    for (std::size_t i = 0; i < std::size(booleanBindings); ++i) {
        const auto& binding = booleanBindings[i];
        if (binding.object != object) continue;
        if (key == binding.toggle) return method(toggleFlagBase + static_cast<int>(i));
        if (key == binding.property) return boolean([snapshot()[binding.snapshot_key] boolValue]);
    }
    if (object == timeObject) {
        if (key == "setTime") return method(setTime);
        if (key == "getTime") return method(getTime);
        if (key == "stop") return method(stopTime);
        if (key == "forward") return method(stepForward);
        if (key == "rewind") return method(stepRewind);
        if (key == "setCurrent") return method(currentTime);
        if (key == "prevStep") return method(previousStep);
        if (key == "nextStep") return method(nextStep);
        if (key == "setTimeString") return method(setTimeString);
        if (key == "getTimeString") return method(getTimeString);
        if (key == "setLocalTime") return method(setLocalTime);
        if (key == "getLocalTime") return method(getLocalTime);
        if (key == "setTimeTo") return method(setTimeTo);
        if (key == "setLocalTimeTo") return method(setLocalTimeTo);
        if (key == "setJDTo") return method(setJDTo);
        for (std::size_t i = 0; i < std::size(localTimeBindings); ++i) {
            const auto& binding = localTimeBindings[i];
            if (key == binding.getter) return method(getLocalComponentBase + static_cast<int>(i));
            if (key == binding.setter) return method(setLocalComponentBase + static_cast<int>(i));
            if (key == binding.property) return numeric(localComponent(snapshot(), binding.component));
        }
        NSDictionary *current = snapshot();
        if (key == "step") return numeric([current[@"timeStep"] intValue]);
        if (key == "stepValue") return numeric([current[@"timeStepValue"] doubleValue]);
        if (key == "JD") return numeric([current[@"jd"] doubleValue]);
        if (key == "speed") return numeric([current[@"timeSpeed"] intValue]);
        const auto date = calendar([current[@"jd"] doubleValue]);
        if (key == "year") return numeric(date.year);
        if (key == "month") return numeric(date.month);
        if (key == "day") return numeric(date.day);
        if (key == "hour") return numeric(date.hour);
        if (key == "minute" || key == "min") return numeric(date.minute);
        if (key == "second" || key == "sec") return numeric(date.second);
    } else if (object == cameraObject) {
        if (key == "look") return method(lookTarget);
        if (key == "lookTo") return method(animateLookTarget);
        if (key == "setTargetTo") return method(animateTarget);
        if (key == "setZoomTo") return method(animateZoom);
        if (key == "setZoomLogTo") return method(animateZoomLog);
        if (key == "setAzimuthTo") return method(animateAzimuth);
        if (key == "setAltitudeTo") return method(animateAltitude);
        if (key == "setModeTo") return method(setModeTo);
        if (key == "toggleMode") return method(toggleMode);
        if (key == "toggleModeTo") return method(toggleModeTo);
        if (key == "forceMode") return method(forceMode);
        if (key == "getOrient") return method(getOrient);
        if (key == "getEuler") return method(getEuler);
        if (key == "setOrient") return method(setOrient);
        if (key == "setEuler") return method(setEuler);
        if (key == "addEuler") return method(addEuler);
        if (key == "setOrientTo") return method(setOrientTo);
        if (key == "setEulerTo") return method(setEulerTo);
        if (key == "addEulerTo") return method(addEulerTo);
        NSDictionary *current = snapshot();
        if (key == "mode") {
            if (current[@"cameraMode"] == NSNull.null) throw std::runtime_error("Camera.mode is unavailable in the sky view");
            return numeric([current[@"cameraMode"] intValue]);
        }
        if (key == "modeDuration") return numeric([current[@"cameraModeDuration"] doubleValue]);
        if (key == "zoomMode") return numeric([current[@"cameraZoomMode"] intValue]);
        if (key == "duration") {
            if (current[@"cameraDuration"] == NSNull.null) throw std::runtime_error("Camera.duration is not set");
            return numeric([current[@"cameraDuration"] doubleValue]);
        }
        if (key == "zoom") return numeric([current[@"distance"] doubleValue] / auPerParsec);
        if (key == "azimuth") return numeric([current[@"azimuth"] doubleValue]);
        if (key == "altitude") return numeric([current[@"altitude"] doubleValue]);
        if (key == "target") return textReply(current[@"target"]);
    } else if (object == guiObject) {
        if (key == "saveImageDialog") return method(saveImageDialog);
        if (key == "fullScreen") return boolean([snapshot()[@"fullScreen"] boolValue]);
        if (key == "toggleFullScreen") return method(toggleFullScreen);
        if (key == "aboutDialog") return method(aboutDialog);
    }
    throw std::invalid_argument("Unsupported host property: " + key);
}
void writeProperty(lua_State *state, int object, const std::string& key) {
    if (object == planetsObject && key == "scaleMode") {
        const double value = numberAt(state, 3);
        if (value != 0 && value != 1) throw std::invalid_argument("Invalid Planets.scaleMode");
        apply(ScriptActionKind::set_radius_scale_mode, value); return;
    }
    if (object == planetsObject && key == "topoAmplification") {
        const auto value = terrain_amplification_from_lua(numberAt(state, 3));
        apply(ScriptActionKind::set_terrain_amplification, static_cast<int>(value)); return;
    }
    if (object == planetsObject && key == "atmosphere") {
        const double value = numberAt(state, 3, true);
        if (value < 0 || value > 2) throw std::invalid_argument("Unsupported Planets.atmosphere mode");
        apply(ScriptActionKind::set_atmosphere_mode, value); return;
    }
    if (object == starsObject && key == "brightness") {
        apply(ScriptActionKind::set_star_brightness, checked_star_brightness(numberAt(state, 3))); return;
    }
    if (object == milkyWayObject && key == "type") {
        const std::string value = textAt(state, 3);
        if (value != "None" && value != "Normal" && value != "Bright" && value != "Infrared")
            throw std::invalid_argument("Unsupported Milkyway.type: " + value);
        apply(ScriptActionKind::set_milky_way_type, 0, false, value.c_str()); return;
    }
    if (object == starsObject && key == "markingType") {
        const std::string value = textAt(state, 3);
        if (value != "None" && value != "Binary" && value != "ExoPlanets")
            throw std::invalid_argument("Unsupported Stars.markingType: " + value);
        apply(ScriptActionKind::set_star_marking, 0, false, value.c_str()); return;
    }
    for (const auto& binding : booleanBindings) {
        if (binding.object != object || key != binding.property) continue;
        if (!binding.writable) throw std::invalid_argument("Unsupported property assignment: " + key);
        apply(binding.action, 0, booleanAt(state, 3));
        return;
    }
    if (object == guiObject && key == "fullScreen") {
        apply(ScriptActionKind::set_full_screen, 0, booleanAt(state, 3)); return;
    }
    if (object == timeObject) {
        if (key == "JD") { apply(ScriptActionKind::set_date, numberAt(state, 3)); return; }
        if (key == "speed") { apply(ScriptActionKind::set_time_speed, plus_time_speed(numberAt(state, 3))); return; }
        if (key == "step") {
            const double value = numberAt(state, 3, true);
            if (value < 0 || value > 11) throw std::invalid_argument("Unsupported time step");
            apply(ScriptActionKind::set_time_step, value); return;
        }
        if (key == "stepValue") {
            apply(ScriptActionKind::set_time_step_value, numberAt(state, 3)); return;
        }
        for (const auto& binding : localTimeBindings) {
            if (key == binding.property) {
                setLocalComponent(binding.component, timeIntegerAt(state, 3)); return;
            }
        }
        auto date = calendar([snapshot()[@"jd"] doubleValue]);
        const int value = timeIntegerAt(state, 3);
        if (key == "year") date.year = value;
        else if (key == "month") date.month = value;
        else if (key == "day") date.day = value;
        else if (key == "hour") date.hour = value;
        else if (key == "minute" || key == "min") date.minute = value;
        else if (key == "second" || key == "sec") date.second = value;
        else throw std::invalid_argument("Unsupported Time property: " + key);
        apply(ScriptActionKind::set_date, plus_julian_date(date)); return;
    }
    if (object == cameraObject && key == "duration") {
        const double duration = numberAt(state, 3);
        if (duration < 0) throw std::invalid_argument("Camera.duration must be nonnegative");
        apply(ScriptActionKind::set_camera_duration, duration); return;
    }
    if (object == cameraObject && key == "modeDuration") {
        const double duration = numberAt(state, 3);
        if (duration < 0) throw std::invalid_argument("Camera.modeDuration must be nonnegative");
        apply(ScriptActionKind::set_camera_mode_duration, duration); return;
    }
    if (object == cameraObject && key == "mode") {
        const double mode = numberAt(state, 3);
        if (mode != 0 && mode != 1) throw std::invalid_argument("Invalid Camera.mode");
        apply(ScriptActionKind::set_camera_mode, mode); return;
    }
    if (object == cameraObject && key == "zoomMode") {
        const double mode = numberAt(state, 3);
        if (mode != 0 && mode != 1 && mode != 2) throw std::invalid_argument("Invalid Camera.zoomMode");
        apply(ScriptActionKind::set_camera_zoom_mode, mode); return;
    }
    if (object == cameraObject && key == "zoom") {
        const double distance = numberAt(state, 3) * auPerParsec;
        if (!std::isfinite(distance) || distance <= 0) throw std::invalid_argument("Camera.zoom must be positive");
        apply(ScriptActionKind::set_camera_distance, distance); return;
    }
    if (object == cameraObject && key == "target") { apply(ScriptActionKind::select_target, 0, false, textAt(state, 3)); return; }
    if (object == cameraObject && key == "azimuth") {
        apply(ScriptActionKind::set_camera_azimuth, numberAt(state, 3)); return;
    }
    if (object == cameraObject && key == "altitude") {
        apply(ScriptActionKind::set_camera_altitude, numberAt(state, 3)); return;
    }
    throw std::invalid_argument("Unsupported host property: " + key);
}
Reply invokeExtendedTime(lua_State *state, int operation, int offset) {
    if (offset && objectAt(state) != timeObject) throw std::invalid_argument("Expected Time receiver");
    const int count = lua_gettop(state) - offset;
    const bool componentGetter = operation >= getLocalComponentBase &&
        operation < getLocalComponentBase + static_cast<int>(std::size(localTimeBindings));
    const bool componentSetter = operation >= setLocalComponentBase &&
        operation < setLocalComponentBase + static_cast<int>(std::size(localTimeBindings));
    if (componentGetter || componentSetter) {
        if (count != (componentSetter ? 1 : 0)) throw std::invalid_argument("Invalid local Time component argument count");
        const auto component = localTimeBindings[operation - (componentSetter ? setLocalComponentBase : getLocalComponentBase)].component;
        if (componentGetter) return numeric(localComponent(snapshot(), component));
        setLocalComponent(component, timeIntegerAt(state, offset + 1));
    } else if (operation == setTimeString) {
        if (count != 1 || lua_type(state, offset + 1) != LUA_TSTRING)
            throw std::invalid_argument("Time:setTimeString requires one string");
        std::size_t length = 0;
        const char *text = lua_tolstring(state, offset + 1, &length);
        apply(ScriptActionKind::set_date, plus_julian_date_from_string({text, length}));
        // Lua stack の元値を返し、長い接尾辞や元の表記を固定長 reply へ切り詰めない。
        Reply result; result.type = Reply::original_argument; result.stack_index = offset + 1; return result;
    } else if (operation == getTimeString || operation == getLocalTime) {
        if (count != 0) throw std::invalid_argument("Time getter requires no arguments");
        NSDictionary *current = snapshot();
        const double jd = [current[@"jd"] doubleValue];
        if (operation == getLocalTime) return calendarReply(plus_local_time(jd, timeZone(current)));
        return textReply([NSString stringWithUTF8String:plus_time_string(jd).c_str()]);
    } else if (operation == setLocalTime) {
        if (count != 6) throw std::invalid_argument("Time:setLocalTime requires six integers");
        const auto date = calendarArguments(state, offset);
        apply(ScriptActionKind::set_date, plus_local_julian_date(date, timeZone(snapshot())));
    } else {
        const bool numericTarget = operation == setJDTo;
        const int required = numericTarget ? 2 : 7;
        if (count != required && count != required + 1)
            throw std::invalid_argument("Time animation requires a target, duration and optional boolean curve");
        const double duration = numberAt(state, offset + required);
        const bool halfCosine = count == required ? true : booleanAt(state, offset + required + 1);
        double target;
        if (numericTarget) {
            target = numberAt(state, offset + 1);
            (void)mitaka::gregorian_date_time(target);
        } else {
            const auto date = calendarArguments(state, offset);
            target = operation == setLocalTimeTo ? plus_local_julian_date(date, timeZone(snapshot())) : plus_julian_date(date);
        }
        apply(numericTarget ? ScriptActionKind::set_time_animation_jd : ScriptActionKind::set_time_animation_calendar,
            target, halfCosine, "", duration);
    }
    return {};
}
Reply invoke(lua_State *state, int operation) {
    const int offset = lua_type(state, 1) == LUA_TUSERDATA ? 1 : 0;
    if ((operation >= setTimeString && operation <= setJDTo) ||
        (operation >= getLocalComponentBase && operation < getLocalComponentBase + static_cast<int>(std::size(localTimeBindings))) ||
        (operation >= setLocalComponentBase && operation < setLocalComponentBase + static_cast<int>(std::size(localTimeBindings))))
        return invokeExtendedTime(state, operation, offset);
    if (operation >= setTime && operation <= nextStep) {
        if (offset && objectAt(state) != timeObject) throw std::invalid_argument("Expected Time receiver");
        if (operation != setTime && lua_gettop(state) != offset)
            throw std::invalid_argument("Time method requires no arguments");
    }
    if (operation >= getOrient && operation <= addEulerTo) {
        if (offset && objectAt(state) != cameraObject) throw std::invalid_argument("Expected Camera receiver");
        const int count = lua_gettop(state) - offset;
        if (operation == getOrient || operation == getEuler) {
            if (count != 0) throw std::invalid_argument("Camera orientation getter takes no arguments");
            const bool quaternion = operation == getOrient;
            NSArray *values = snapshot()[quaternion ? @"cameraOrientation" : @"cameraEuler"];
            const NSUInteger size = quaternion ? 4 : 3;
            if (![values isKindOfClass:NSArray.class] || values.count != size)
                throw std::runtime_error("Camera orientation is unavailable in this view");
            Reply result; result.type = quaternion ? Reply::radius_scale : Reply::euler;
            for (NSUInteger i = 0; i < size; ++i) result.values[i] = [values[i] doubleValue];
            return result;
        }
        const bool quaternion = operation == setOrient || operation == setOrientTo;
        const bool animated = operation == setOrientTo || operation == setEulerTo || operation == addEulerTo;
        const int required = quaternion ? 4 : 3;
        if (count < required || count > required + (animated ? 2 : 0))
            throw std::invalid_argument("Invalid Camera orientation arguments");
        NSMutableArray<NSNumber *> *values = [NSMutableArray arrayWithCapacity:required];
        for (int i = 1; i <= required; ++i) [values addObject:@(numberAt(state, offset + i))];
        double duration = 0;
        if (animated) {
            if (count > required) duration = numberAt(state, offset + required + 1);
            else {
                id value = snapshot()[@"cameraDuration"];
                if (value == NSNull.null) throw std::invalid_argument("Camera.duration is not set");
                duration = [value doubleValue];
            }
        }
        if (duration < 0) throw std::invalid_argument("Camera orientation duration must be nonnegative");
        const bool smooth = count > required + 1 ? booleanAt(state, offset + required + 2) : true;
        ScriptActionKind kind = operation == setOrient ? ScriptActionKind::set_camera_orientation :
            operation == setEuler ? ScriptActionKind::set_camera_euler : operation == addEuler ? ScriptActionKind::add_camera_euler :
            operation == setOrientTo ? ScriptActionKind::animate_camera_orientation :
            operation == setEulerTo ? ScriptActionKind::animate_camera_euler : ScriptActionKind::animate_add_camera_euler;
        apply(kind, 0, smooth, "", duration, {}, @[], values);
    } else if (operation == setModeTo || operation == toggleMode || operation == toggleModeTo || operation == forceMode) {
        if (offset && objectAt(state) != cameraObject) throw std::invalid_argument("Expected Camera receiver");
        const int count = lua_gettop(state) - offset;
        const bool toggle = operation == toggleMode || operation == toggleModeTo;
        if ((operation == forceMode && count != 1) || (operation == setModeTo && (count < 1 || count > 2)) ||
            (toggle && count > (operation == toggleMode ? 0 : 1)))
            throw std::invalid_argument("Invalid Camera mode arguments");
        NSDictionary *current = snapshot();
        double mode;
        if (toggle) {
            if (current[@"cameraMode"] == NSNull.null) throw std::invalid_argument("Camera.mode is unavailable in the sky view");
            mode = 1 - [current[@"cameraMode"] intValue];
        } else mode = numberAt(state, offset + 1);
        if (mode != 0 && mode != 1) throw std::invalid_argument("Invalid Camera.mode");
        const int durationIndex = offset + (toggle ? 1 : 2);
        const double duration = operation == toggleMode || operation == forceMode ? 0 : (count >= (toggle ? 1 : 2) ? numberAt(state, durationIndex) : [current[@"cameraModeDuration"] doubleValue]);
        if (duration < 0) throw std::invalid_argument("Camera mode duration must be nonnegative");
        apply(ScriptActionKind::set_camera_mode, mode, operation == forceMode, "", duration);
    } else if (operation == animateZoom || operation == animateZoomLog) {
        if (offset && objectAt(state) != cameraObject) throw std::invalid_argument("Expected Camera receiver");
        const int count = lua_gettop(state) - offset;
        if (count < 1 || count > 2) throw std::invalid_argument("Camera zoom animation requires a target and optional duration");
        const double distance = numberAt(state, offset + 1) * auPerParsec;
        if (!std::isfinite(distance) || distance <= 0) throw std::invalid_argument("Camera.zoom must be positive");
        double duration;
        if (count == 2) duration = numberAt(state, offset + 2);
        else {
            id value = snapshot()[@"cameraDuration"];
            if (value == NSNull.null) throw std::invalid_argument("Camera.duration must be set when duration is omitted");
            duration = [value doubleValue];
        }
        if (duration < 0) throw std::invalid_argument("Camera animation duration must be nonnegative");
        apply(ScriptActionKind::animate_camera_zoom, distance, operation == animateZoomLog, "", duration);
    } else if (operation == animateAzimuth || operation == animateAltitude) {
        if (offset && objectAt(state) != cameraObject) throw std::invalid_argument("Expected Camera receiver");
        const int count = lua_gettop(state) - offset;
        if (count < 1 || count > 3) throw std::invalid_argument("Camera animation requires a target and optional duration and smooth");
        const double target = numberAt(state, offset + 1);
        double duration;
        if (count >= 2) duration = numberAt(state, offset + 2);
        else {
            id value = snapshot()[@"cameraDuration"];
            if (value == NSNull.null) throw std::invalid_argument("Camera.duration must be set when duration is omitted");
            duration = [value doubleValue];
        }
        if (duration < 0) throw std::invalid_argument("Camera animation duration must be nonnegative");
        const bool smooth = count == 3 ? booleanAt(state, offset + 3) : true;
        apply(operation == animateAzimuth ? ScriptActionKind::animate_camera_azimuth : ScriptActionKind::animate_camera_altitude,
              target, smooth, "", duration);
    } else if (operation == animateTarget) {
        if (offset && objectAt(state) != cameraObject) throw std::invalid_argument("Expected Camera receiver");
        const int count = lua_gettop(state) - offset;
        if (count < 1 || count > 2) throw std::invalid_argument("Camera:setTargetTo requires a target and optional duration");
        double duration;
        if (count == 2) duration = numberAt(state, offset + 2);
        else {
            id value = snapshot()[@"cameraDuration"];
            if (value == NSNull.null) throw std::invalid_argument("Camera.duration is not set");
            duration = [value doubleValue];
        }
        if (duration < 0) throw std::invalid_argument("Camera target duration must be nonnegative");
        apply(ScriptActionKind::select_target, 0, true, textAt(state, offset + 1), duration);
    } else if (operation == lookTarget || operation == animateLookTarget) {
        if (offset && objectAt(state) != cameraObject) throw std::invalid_argument("Expected Camera receiver");
        const int count = lua_gettop(state) - offset;
        const bool animated = operation == animateLookTarget;
        if (count < 1 || count > (animated ? 2 : 1))
            throw std::invalid_argument("Camera:look requires a target and optional animation duration");
        double duration = 0;
        if (animated) {
            if (count == 2) duration = numberAt(state, offset + 2);
            else {
                id value = snapshot()[@"cameraDuration"];
                if (value == NSNull.null) throw std::invalid_argument("Camera.duration is not set");
                duration = [value doubleValue];
            }
            if (duration < 0) throw std::invalid_argument("Camera look duration must be nonnegative");
        }
        apply(ScriptActionKind::look_target, 0, animated, textAt(state, offset + 1), duration);
    } else if (operation == setRadiusScale || operation == getRadiusScale ||
        operation == setRadiusScaleMode || operation == getRadiusScaleMode) {
        if (offset && objectAt(state) != planetsObject) throw std::invalid_argument("Expected Planets receiver");
        const int count = lua_gettop(state) - offset;
        if (operation == setRadiusScale) {
            if (count != 4) throw std::invalid_argument("Planets:setScale requires four numbers");
            const auto options = checked_radius_display_options(numberAt(state, offset + 1), numberAt(state, offset + 2),
                numberAt(state, offset + 3), numberAt(state, offset + 4));
            apply(ScriptActionKind::set_radius_scale, 0, false, "", 0, {},
                @[@(options.space_planet), @(options.space_sun), @(options.planetarium_planet), @(options.planetarium_sun_moon)]);
        } else if (operation == getRadiusScale) {
            if (count != 0) throw std::invalid_argument("Planets:getScale requires no arguments");
            NSArray *scales = snapshot()[@"radiusScale"];
            if (![scales isKindOfClass:NSArray.class] || scales.count != 4)
                throw std::runtime_error("Invalid host radius scale");
            Reply result; result.type = Reply::radius_scale;
            for (NSUInteger i = 0; i < 4; ++i) result.values[i] = [scales[i] doubleValue];
            return result;
        } else if (operation == setRadiusScaleMode) {
            if (count != 1) throw std::invalid_argument("Planets:setScaleMode requires one number");
            const double value = numberAt(state, offset + 1);
            if (value != 0 && value != 1) throw std::invalid_argument("Invalid Planets.scaleMode");
            apply(ScriptActionKind::set_radius_scale_mode, value);
        } else {
            if (count != 0) throw std::invalid_argument("Planets:getScaleMode requires no arguments");
            return numeric([snapshot()[@"radiusScaleMode"] intValue]);
        }
    } else if (operation >= toggleFlagBase && operation < toggleFlagBase + static_cast<int>(std::size(booleanBindings))) {
        if (lua_gettop(state) != offset) throw std::invalid_argument("toggle requires no arguments");
        const auto& binding = booleanBindings[operation - toggleFlagBase];
        if (offset && objectAt(state) != binding.object) throw std::invalid_argument("Unexpected toggle receiver");
        apply(binding.action, 0, ![snapshot()[binding.snapshot_key] boolValue]);
    } else if (operation == saveImageDialog || operation == toggleFullScreen || operation == aboutDialog) {
        if (lua_gettop(state) != offset) throw std::invalid_argument("GUI method requires no arguments");
        if (offset && objectAt(state) != guiObject) throw std::invalid_argument("Expected GUI receiver");
        // 全画面の実表示と遷移先は一致しない場合があるため、toggle の判断をウィンドウ側へ渡す。
        apply(operation == saveImageDialog ? ScriptActionKind::save_image_dialog :
            operation == toggleFullScreen ? ScriptActionKind::toggle_full_screen : ScriptActionKind::show_about);
    } else if (operation == brightenStars || operation == darkenStars || operation == defaultStarBrightness ||
               operation == animateStarBrightness) {
        if (offset && objectAt(state) != starsObject) throw std::invalid_argument("Expected Stars receiver");
        if (operation == animateStarBrightness) {
            if (lua_gettop(state) != offset + 2)
                throw std::invalid_argument("Stars:setBrightnessTo requires brightness and duration");
            const float target = checked_star_brightness(numberAt(state, offset + 1));
            const double duration = numberAt(state, offset + 2);
            if (duration < 0) throw std::invalid_argument("Star brightness duration must be nonnegative");
            apply(ScriptActionKind::animate_star_brightness, target, false, "", duration);
        } else {
            if (lua_gettop(state) != offset) throw std::invalid_argument("Stars method requires no arguments");
            apply(operation == brightenStars ? ScriptActionKind::brighten_stars :
                operation == darkenStars ? ScriptActionKind::darken_stars : ScriptActionKind::default_star_brightness);
        }
    } else if (operation == selectStarNames || operation == deselectStarNames || operation == isStarNameSelected) {
        if (offset && objectAt(state) != starsObject) throw std::invalid_argument("Expected Stars receiver");
        if (lua_gettop(state) != offset + 1) throw std::invalid_argument("Stars selection requires one string");
        const std::string_view text = textAt(state, offset + 1);
        if (operation == isStarNameSelected) {
            const auto hip = starHIP(text);
            return boolean([snapshot()[@"selectedStarNames"] containsObject:@(hip)]);
        }
        if (text == "All") apply(ScriptActionKind::set_all_star_names_selected, 0, operation == selectStarNames);
        else apply(ScriptActionKind::set_star_name_membership, 0, operation == selectStarNames, "", 0, starHIPList(text));
    } else if (operation == toggleAtmosphere) {
        if (lua_gettop(state) != offset) throw std::invalid_argument("toggleAtmosphere requires no arguments");
        if (offset && objectAt(state) != planetsObject) throw std::invalid_argument("Expected Planets receiver");
        apply(ScriptActionKind::set_atmosphere_mode, ([snapshot()[@"atmosphereMode"] intValue] + 1) % 3);
    } else if (operation == setTime) {
        if (lua_gettop(state) != offset + 6) throw std::invalid_argument("Time:setTime requires six integers");
        apply(ScriptActionKind::set_date, plus_julian_date(calendarArguments(state, offset)));
    } else if (operation == getTime) {
        return calendarReply(calendar([snapshot()[@"jd"] doubleValue]));
    } else if (operation == stopTime) apply(ScriptActionKind::stop);
    else if (operation == stepForward || operation == stepRewind)
        apply(operation == stepForward ? ScriptActionKind::step_time_forward : ScriptActionKind::step_time_rewind);
    else if (operation == currentTime)
        apply(ScriptActionKind::set_date, std::floor(NSDate.date.timeIntervalSince1970) / 86400.0 + 2440587.5);
    else if (operation == previousStep || operation == nextStep) {
        apply(operation == previousStep ? ScriptActionKind::previous_time_step : ScriptActionKind::next_time_step);
    } else if (operation == waitSeconds) {
        if (lua_gettop(state) != 1) throw std::invalid_argument("waitTime requires one number");
        const double seconds = numberAt(state, 1);
        if (seconds < 0) throw std::invalid_argument("waitTime must be non-negative");
        const auto elapsed = std::chrono::duration<double>(std::chrono::steady_clock::now() - context(state).started).count();
        if (seconds + elapsed > 110) throw std::invalid_argument("Script execution budget exceeded");
        std::this_thread::sleep_for(std::chrono::duration<double>(seconds));
    } else if (operation == printText) {
        std::string output;
        for (int i=1; i<=lua_gettop(state); ++i) {
            if (i > 1) output += '\t';
            switch (lua_type(state, i)) {
                case LUA_TSTRING: { std::size_t size; const char *value = lua_tolstring(state, i, &size); output.append(value, std::min<std::size_t>(size, 8192)); break; }
                case LUA_TNUMBER: output += std::to_string(lua_tonumber(state, i)); break;
                case LUA_TBOOLEAN: output += lua_toboolean(state, i) ? "true" : "false"; break;
                case LUA_TNIL: output += "nil"; break;
                default: output += lua_typename(state, lua_type(state, i)); break;
            }
            if (output.size() > 8192) { output.resize(8192); break; }
        }
        NSString *text = [[NSString alloc] initWithBytes:output.data() length:output.size() encoding:NSUTF8StringEncoding];
        request(@{@"op":@"log", @"text":text ? text : @"[non-UTF-8 output]"});
    }
    return {};
}
int callMethod(lua_State *state);
int pushReply(lua_State *state, const Reply& result) {
    switch (result.type) {
        case Reply::empty: return 0;
        case Reply::number: lua_pushnumber(state, result.values[0]); return 1;
        case Reply::boolean: lua_pushboolean(state, result.flag); return 1;
        case Reply::text: lua_pushstring(state, result.string); return 1;
        case Reply::calendar: for (double value : result.values) lua_pushinteger(state, static_cast<lua_Integer>(value)); return 6;
        case Reply::radius_scale: for (int i = 0; i < 4; ++i) lua_pushnumber(state, result.values[i]); return 4;
        case Reply::euler: for (int i = 0; i < 3; ++i) lua_pushnumber(state, result.values[i]); return 3;
        case Reply::function: lua_pushinteger(state, result.method); lua_pushcclosure(state, callMethod, 1); return 1;
        case Reply::original_argument: lua_pushvalue(state, result.stack_index); return 1;
    }
    return 0;
}
// Lua の longjmp が C++ / Objective-C の所有オブジェクトを飛び越えないよう、結果を POD にしてからスタックへ渡す。
int callMethod(lua_State *state) {
    Reply result; char failure[4096]{};
    try { @autoreleasepool { result = invoke(state, static_cast<int>(lua_tointeger(state, lua_upvalueindex(1)))); } }
    catch (const std::exception& error) { std::snprintf(failure, sizeof(failure), "%s", error.what()); }
    if (failure[0]) return luaL_error(state, "%s", failure);
    return pushReply(state, result);
}
int indexProperty(lua_State *state) {
    Reply result; char failure[4096]{};
    try { @autoreleasepool {
        result = readProperty(objectAt(state), textAt(state, 2));
    } } catch (const std::exception& error) { std::snprintf(failure, sizeof(failure), "%s", error.what()); }
    if (failure[0]) return luaL_error(state, "%s", failure);
    return pushReply(state, result);
}
int newIndexProperty(lua_State *state) {
    char failure[4096]{};
    try { @autoreleasepool {
        writeProperty(state, objectAt(state), textAt(state, 2));
    } } catch (const std::exception& error) { std::snprintf(failure, sizeof(failure), "%s", error.what()); }
    if (failure[0]) return luaL_error(state, "%s", failure);
    return 0;
}
void installObject(lua_State *state, const char *name, int object) {
    auto *value = static_cast<int *>(lua_newuserdatauv(state, sizeof(int), 0)); *value = object;
    luaL_newmetatable(state, hostMetatable);
    lua_pushcfunction(state, indexProperty); lua_setfield(state, -2, "__index");
    lua_pushcfunction(state, newIndexProperty); lua_setfield(state, -2, "__newindex");
    lua_pushliteral(state, "Mitaka host object"); lua_setfield(state, -2, "__metatable");
    lua_setmetatable(state, -2); lua_setglobal(state, name);
}
void instructionHook(lua_State *state, lua_Debug *) {
    auto& runtime = context(state);
    runtime.instructions += 1000;
    if (runtime.instructions > 10000000 || std::chrono::steady_clock::now() - runtime.started > std::chrono::seconds(110))
        luaL_error(state, "Script execution budget exceeded");
}
void *allocate(void *opaque, void *pointer, std::size_t oldSize, std::size_t newSize) {
    auto& runtime = *static_cast<Context *>(opaque);
    if (!pointer) oldSize = 0;
    if (!newSize) { std::free(pointer); runtime.allocated -= oldSize; return nullptr; }
    if (newSize > memoryLimit || runtime.allocated - oldSize > memoryLimit - newSize) return nullptr;
    void *result = std::realloc(pointer, newSize);
    if (result) runtime.allocated = runtime.allocated - oldSize + newSize;
    return result;
}
void install(lua_State *state) {
    luaL_openlibs(state);
    installObject(state, "Time", timeObject); installObject(state, "Camera", cameraObject); installObject(state, "Constels", constellationObject);
    installObject(state, "Stars", starsObject); installObject(state, "Galaxies", galaxiesObject); installObject(state, "GUI", guiObject);
    installObject(state, "Milkyway", milkyWayObject); installObject(state, "Planets", planetsObject); installObject(state, "Grids", gridsObject);
    installObject(state, "Renderer", rendererObject);
    installObject(state, "Asteroids", asteroidsObject); installObject(state, "TNObjects", tnobjectsObject);
    installObject(state, "Comets", cometsObject); installObject(state, "Satellites", satellitesObject);
    installObject(state, "Places", placesObject);
    lua_pushinteger(state, printText); lua_pushcclosure(state, callMethod, 1); lua_setglobal(state, "print");
    lua_pushinteger(state, waitSeconds); lua_pushcclosure(state, callMethod, 1); lua_setglobal(state, "waitTime");
    lua_newtable(state);
    for (std::size_t i=0; i<stepNames.size(); ++i) {
        lua_pushinteger(state, i); lua_setfield(state, -2, stepNames[i]);
        lua_pushinteger(state, i); lua_setglobal(state, stepNames[i]);
    }
    for (const auto& unit : std::array<std::pair<const char *, double>, 3>{{{"UNIT_AU", 1.0 / auPerParsec}, {"UNIT_KM", 1.0 / (auPerParsec * 149597870.7)}, {"UNIT_LY", 63241.07708426628 / auPerParsec}}}) {
        lua_pushnumber(state, unit.second); lua_setfield(state, -2, unit.first);
        lua_pushnumber(state, unit.second); lua_setglobal(state, unit.first);
    }
    const std::array<const char *, 3> atmosphereNames{"ATMOS_NONE", "ATMOS_SINGLE", "ATMOS_MULTIPLE"};
    for (std::size_t i = 0; i < atmosphereNames.size(); ++i) {
        lua_pushinteger(state, i); lua_setfield(state, -2, atmosphereNames[i]);
    }
    lua_pushinteger(state, 0); lua_setfield(state, -2, "KEEP_RADIUS");
    lua_pushinteger(state, 1); lua_setfield(state, -2, "KEEP_ORBIT");
    lua_pushinteger(state, 0); lua_setfield(state, -2, "PLANETARIUM");
    lua_pushinteger(state, 1); lua_setfield(state, -2, "HIPPARCOS");
    // 旧定数の数値は資料にないため、識別できるよう連番を割り当てる。
    lua_pushinteger(state, 0); lua_setfield(state, -2, "ZOOM_NONE");
    lua_pushinteger(state, 1); lua_setfield(state, -2, "ZOOM_AUTO");
    lua_pushinteger(state, 2); lua_setfield(state, -2, "ZOOM_ALWAYS");
    lua_setglobal(state, "mtk");
    lua_sethook(state, instructionHook, LUA_MASKCOUNT, 1000);
}
void complete(bool succeeded, NSString *message) {
    NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"op":@"done", @"ok":@(succeeded), @"message":message} options:0 error:nil];
    write_script_frame(STDIN_FILENO, std::string(static_cast<const char *>(data.bytes), data.length));
}
int traceback(lua_State *state) {
    const char *message = lua_tostring(state, 1);
    luaL_traceback(state, state, message ? message : "Lua raised a non-string error", 1);
    return 1;
}
}
int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc != 2 || ::setpgid(0, 0) != 0) return 2;
        try {
            std::ifstream input(argv[1], std::ios::binary);
            if (!input) throw std::runtime_error("Cannot open script file");
            std::string source;
            source.resize(1024 * 1024 + 1);
            input.read(source.data(), source.size());
            source.resize(static_cast<std::size_t>(input.gcount()));
            if (source.size() > 1024 * 1024) throw std::runtime_error("Script exceeds 1 MiB");
            Context runtime;
            std::unique_ptr<lua_State, decltype(&lua_close)> state(lua_newstate(allocate, &runtime), lua_close);
            if (!state) throw std::runtime_error("Cannot allocate Lua state");
            *static_cast<Context **>(lua_getextraspace(state.get())) = &runtime;
            install(state.get());
            const std::string name = std::string("@") + argv[1];
            int status = luaL_loadbufferx(state.get(), source.data(), source.size(), name.c_str(), "t");
            if (status == LUA_OK) {
                lua_pushcfunction(state.get(), traceback);
                lua_insert(state.get(), 1);
                status = lua_pcall(state.get(), 0, 0, 1);
            }
            const char *failureText = status == LUA_OK ? nullptr : lua_tostring(state.get(), -1);
            NSString *failure = failureText ? [NSString stringWithUTF8String:failureText] : nil;
            NSString *message = status == LUA_OK ? @"スクリプトを実行しました。" :
                (failure ? failure : @"Lua execution failed");
            // ファイルの flush / __gc を完了させてから、親へ終了を通知する。
            state.reset();
            complete(status == LUA_OK, message);
            return status == LUA_OK ? 0 : 1;
        } catch (const std::exception& error) {
            NSString *failure = [NSString stringWithUTF8String:error.what()];
            try { complete(false, failure ? failure : @"Script worker failed"); }
            catch (const std::exception&) { /* 親が接続を閉じた中断では通知先がない。 */ }
            return 1;
        }
    }
}
