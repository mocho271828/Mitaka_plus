#import "AppControllerInternal.h"
#import "SolarSystemViewInternal.h"
#include "star_brightness.hpp"

#include <algorithm>
#include <array>
#include <cstdio>
#include <cstdlib>
#include <stdexcept>

namespace {
void requirePlus(bool condition, const char *message) {
    if (!condition) throw std::runtime_error(message);
}

bool sameRadius(const RadiusDisplayOptions& a, const RadiusDisplayOptions& b) {
    return a.space_planet == b.space_planet && a.space_sun == b.space_sun &&
        a.planetarium_planet == b.planetarium_planet && a.planetarium_sun_moon == b.planetarium_sun_moon;
}

bool sameCamera(const SolarCamera& a, const SolarCamera& b) {
    const auto sameVector = [](mitaka::Vec3 x, mitaka::Vec3 y) {
        return x.x == y.x && x.y == y.y && x.z == y.z;
    };
    if (!sameVector(a.target, b.target) || a.yaw_deg != b.yaw_deg || a.pitch_deg != b.pitch_deg ||
        a.distance_au != b.distance_au || a.frame.has_value() != b.frame.has_value()) return false;
    return !a.frame || (sameVector(a.frame->outward, b.frame->outward) &&
        sameVector(a.frame->right, b.frame->right) && sameVector(a.frame->up, b.frame->up));
}

void checkSolarObservation(SolarSystemView *view, mitaka::ObserverSite site, double julianDate) {
    const auto scene = [view scene];
    requirePlus(scene.julian_date == julianDate, "solar eclipse frame did not receive the current Julian date");
    requirePlus(scene.grid_cache != nullptr, "solar scene has no grid observation frame");
    const mitaka::ObservationFrame expected(site, julianDate);
    for (const mitaka::HorizontalCoordinates point : {mitaka::HorizontalCoordinates{0, 0}, {90, 0}, {0, 90}}) {
        const auto direction = expected.to_equatorial(point);
        const auto actual = scene.grid_cache->frame().to_horizontal(direction);
        requirePlus(std::abs(actual.altitude_deg - point.altitude_deg) < 1e-7 &&
                    (point.altitude_deg == 90 || std::abs(std::remainder(actual.azimuth_deg - point.azimuth_deg, 360.0)) < 1e-7),
                    "solar horizontal grid did not receive the current observer and Julian date");
    }
}

void collectCommands(NSMenu *menu, SEL action, NSMutableArray<NSMenuItem *> *result) {
    for (NSMenuItem *item in menu.itemArray) {
        if (item.action == action) [result addObject:item];
        if (item.submenu) collectCommands(item.submenu, action, result);
    }
}

NSArray<NSMenuItem *> *commands(SEL action, NSUInteger expectedCount, id expectedTarget) {
    NSMutableArray<NSMenuItem *> *items = [NSMutableArray array];
    collectCommands(NSApp.mainMenu, action, items);
    if (items.count != expectedCount)
        throw std::runtime_error([[NSString stringWithFormat:
            @"missing or duplicate Plus menu command %@: expected %lu, found %lu",
            NSStringFromSelector(action), static_cast<unsigned long>(expectedCount),
            static_cast<unsigned long>(items.count)] UTF8String]);
    for (NSMenuItem *item in items)
        requirePlus(item.target == expectedTarget && [item.target respondsToSelector:action],
                    "Plus menu command has no valid target/action");
    return items;
}

std::array<bool, 7> displayFlags(SkyView *view) {
    return {{bool(view.showsConstellationLines), bool(view.showsConstellationBoundaries),
        bool(view.showsConstellationNames),
        bool(view.showsNebulae), bool(view.showsGalaxies), bool(view.showsQuasars),
        view.constellationDisplayOptions.illustrations}};
}

std::array<bool, 4> flags(const PlanetDisplayOptions& options) {
    return {{options.visible, options.labels, options.orbits, options.axes}};
}
std::array<bool, 6> flags(const StarDisplayOptions& options) {
    return {{options.visible, options.proper_names, options.bayer_labels, options.flamsteed_labels,
        options.hip_labels, options.selected_proper_names_only}};
}
std::array<bool, 2> flags(const EarthLayerOptions& options) {
    return {{options.clouds, options.city_lights}};
}
std::array<bool, 4> flags(const EclipseDisplayOptions& options) {
    return {{options.shadows, options.shadow_borders, options.shadow_umbra, options.shadow_penumbra}};
}
std::array<bool, 6> flags(const GridDisplayOptions& options) {
    return {{options.equatorial, options.ecliptic, options.galactic, options.horizontal, options.circle_scales, options.square_scales}};
}
std::array<bool, 4> flags(const RendererDisplayOptions& options) {
    return {{options.antialias, options.point_smoothing, options.line_smoothing, options.text_smoothing}};
}

template<class Getter>
void checkDisplayCommands(SEL action, NSUInteger count, AppController *controller, Getter currentFlags) {
    const auto items = commands(action, count, controller);
    for (NSUInteger index = 0; index < items.count; ++index) {
        NSMenuItem *item = items[index];
        auto expected = currentFlags();
        expected[index] = !expected[index];
        requirePlus(item.tag == static_cast<NSInteger>(index) &&
                    [NSApp sendAction:item.action to:item.target from:item], "display action has an invalid tag or dispatch");
        requirePlus(currentFlags() == expected, "display action changed the wrong option");
        [item.menu update];
        requirePlus(item.state == (expected[index] ? NSControlStateValueOn : NSControlStateValueOff),
                    "display checkmark did not follow its option");
    }
}

void checkCapturedImage(DisplayOutputController *output, DisplayImageFormat format) {
    NSError *error = nil;
    NSData *data = [output captureFormat:format error:&error];
    requirePlus(data.length > 64 && !error, "actual view capture or native encoding failed");
    NSBitmapImageRep *image = [[NSBitmapImageRep alloc] initWithData:data];
    requirePlus(image.pixelsWide > 100 && image.pixelsHigh > 100, "captured image has no usable dimensions");
    NSUInteger litSamples = 0;
    for (NSInteger y = 0; y < image.pixelsHigh; y += 12)
        for (NSInteger x = 0; x < image.pixelsWide; x += 12) {
            NSColor *color = [[image colorAtX:x y:y] colorUsingColorSpace:NSColorSpace.sRGBColorSpace];
            if (color && std::max({color.redComponent, color.greenComponent, color.blueComponent}) > 0.3)
                ++litSamples;
        }
    requirePlus(litSamples > 10, "captured scene is empty");
}
}

@implementation AppController (PlusSmokeTests)
- (BOOL)runPlusSmokeTest {
    try {
        requirePlus(_model && !_loading && _mode.segmentCount == 3, "Plus views are not ready");
        const SessionState original = [self sessionState];
        NSMenuItem *flightToggle = commands(@selector(toggleFlightMode:), 1, self).firstObject;
        const auto savedModeDuration = _scriptCameraModeDuration;
        _scriptCameraModeDuration = 0;
        _mode.selectedSegment = 2;
        [self changeMode:nil];
        [flightToggle.menu update];
        requirePlus(flightToggle.enabled &&
                    [NSApp sendAction:flightToggle.action to:flightToggle.target from:flightToggle] &&
                    [self plusCameraMode] == 1 && !_solar.flightAnimating,
                    "the flight menu must honor an immediate takeoff");
        [_travelButtons[6] sendAction:_travelButtons[6].action to:_travelButtons[6].target];
        requirePlus(_mode.selectedSegment == 2 && [self plusCameraMode] == 0 && !_horizonFlightView,
                    "the horizon landing button must honor the same duration");
        [_horizon setViewport:{70, 12, 35, 0, 7}];
        NSString *flightError = nil;
        requirePlus([self setEarthSurfaceMode:NO duration:12 error:&flightError] &&
                    [self plusCameraMode] == 1 && _solar.flightAnimating,
                    "Earth takeoff must publish space mode on acceptance");
        requirePlus([self setEarthSurfaceMode:YES duration:1 error:&flightError] &&
                    [self plusCameraMode] == 1 && _solar.flightAnimating,
                    "another ordinary mode request must leave the current Earth flight in progress");
        requirePlus([self setEarthSurfaceMode:YES duration:0 force:YES error:&flightError] &&
                    [self plusCameraMode] == 0 && !_solar.flightAnimating && !_horizonFlightView,
                    "forceMode must finish and clear an interrupted Earth takeoff");
        const auto returned = [_horizon viewport];
        requirePlus(returned.center_altitude_deg == 12 && returned.center_azimuth_deg == 70 &&
                    returned.vertical_fov_deg == 35 && returned.roll_deg == 7,
                    "forcing a return to the observer must restore the ground view");
        _scriptCameraModeDuration = savedModeDuration;
        requirePlus([self applySessionState:original], "could not restore the scene after the flight controls");
        requirePlus(bool(_observerPlaces), "observer place catalog was not loaded with the sky model");
        const auto observerSource = _observerPlaces;
        [self showObserver:nil];
        requirePlus(_observerPlacesPopup.numberOfItems == static_cast<NSInteger>(observerSource->places.size() + 1),
                    "observer popup omitted a local place");
        NSInteger earthPlace = -1;
        NSInteger otherPlace = -1;
        for (std::size_t index = 0; index < observerSource->places.size(); ++index) {
            if (observer_place_is_earth(observerSource->places[index])) earthPlace = static_cast<NSInteger>(index);
            else otherPlace = static_cast<NSInteger>(index);
        }
        if (otherPlace >= 0) {
            [_observerPlacesPopup selectItemAtIndex:otherPlace + 1];
            [_observerPlacesPopup sendAction:_observerPlacesPopup.action to:_observerPlacesPopup.target];
            requirePlus(!_observerApplyButton.enabled && !_observerLatitudeField.enabled &&
                        [_observerPlacesPopup.selectedItem.title containsString:@"未対応"],
                        "non-Earth place can be silently applied as an Earth observer");
        }
        if (earthPlace >= 0) {
            const auto& place = observerSource->places[earthPlace];
            const double longitude = std::remainder(place.longitude_degrees, 360.0);
            [_observerPlacesPopup selectItemAtIndex:earthPlace + 1];
            requirePlus([_observerPlacesPopup sendAction:_observerPlacesPopup.action to:_observerPlacesPopup.target] &&
                        _observerApplyButton.enabled, "local Earth place could not be selected");
            requirePlus([_observerApplyButton sendAction:_observerApplyButton.action to:_observerApplyButton.target],
                        "local Earth place apply action was not dispatched");
            const auto actual = [_horizon observerSite];
            requirePlus(std::abs(actual.latitude_deg - place.latitude_degrees) < 1e-8 &&
                        std::abs(actual.longitude_deg - longitude) < 1e-8 && _mode.selectedSegment == 2,
                        "local observer coordinates did not reach the horizon view");
        } else {
            [_observerPlacesPopup selectItemAtIndex:0];
            [_observerPlacesPopup sendAction:_observerPlacesPopup.action to:_observerPlacesPopup.target];
            requirePlus(_observerApplyButton.enabled && _observerLatitudeField.enabled,
                        "missing Earth observer places prevent manual coordinates");
            [_observerWindow close];
        }
        requirePlus(_observerPlaces == observerSource, "observer selection replaced its source catalog");
        checkSolarObservation(_solar, {_observerLatitude, _observerLongitude}, _jd);
        for (NSString *name in @[@"saveSession:", @"openSession:", @"rememberSession:", @"restoreSession:",
                                 @"showBrowser:", @"showObserver:", @"showRadiusDisplay:", @"showCalendar:", @"setCurrentTime:",
                                 @"showProjection:", @"toggleProjectionPointer:", @"toggleProjectionFade:",
                                 @"runScript:", @"cancelScript:", @"showScriptConsole:"])
            commands(NSSelectorFromString(name), 1, self);
        RadiusDisplayOptions initialRadius;
        RadiusScaleMode initialMode;
        NSString *radiusError = nil;
        requirePlus([self readRadiusDisplayOptions:&initialRadius mode:&initialMode error:&radiusError],
                    "radius settings could not be read");
        NSMenuItem *radiusCommand = commands(@selector(showRadiusDisplay:), 1, self).firstObject;
        requirePlus([NSApp sendAction:radiusCommand.action to:radiusCommand.target from:radiusCommand] &&
                    _radiusDisplayController.isWindowLoaded, "radius settings menu did not open its window");
        requirePlus([_radiusDisplayController applyFieldValues:@[@"2", @"3", @"4", @"5"]
                    mode:static_cast<NSInteger>(RadiusScaleMode::keep_orbit) error:&radiusError],
                    "radius settings panel did not apply to the app");
        RadiusDisplayOptions appliedRadius;
        RadiusScaleMode appliedMode;
        requirePlus([self readRadiusDisplayOptions:&appliedRadius mode:&appliedMode error:&radiusError] &&
                    appliedRadius.space_planet == 2 && appliedRadius.space_sun == 3 &&
                    appliedRadius.planetarium_planet == 4 && appliedRadius.planetarium_sun_moon == 5 &&
                    appliedMode == RadiusScaleMode::keep_orbit, "radius settings panel changed the wrong fields");
        requirePlus(![_radiusDisplayController applyFieldValues:@[@"2", @"0", @"4", @"5"]
                    mode:1 error:&radiusError] && radiusError.length &&
                    [self readRadiusDisplayOptions:&appliedRadius mode:&appliedMode error:nullptr] &&
                    appliedRadius.space_sun == 3, "invalid radius field altered app state");
        [_solar selectBody:10];
        [_solar focusSelection];
        const auto previousMoonTarget = [_solar cameraState].target;
        RadiusDisplayOptions movedMoon = appliedRadius;
        movedMoon.space_planet = 20;
        requirePlus([self applyRadiusDisplayOptions:movedMoon mode:RadiusScaleMode::keep_orbit error:&radiusError],
                    "could not change scale while following the moon");
        const auto moonPosition = [_solar displayPosition:10];
        const auto moonTarget = [_solar cameraState].target;
        requirePlus((moonPosition.x != previousMoonTarget.x || moonPosition.y != previousMoonTarget.y ||
                     moonPosition.z != previousMoonTarget.z) &&
                    moonTarget.x == moonPosition.x && moonTarget.y == moonPosition.y && moonTarget.z == moonPosition.z &&
                    [[_solar cameraStateDescription] containsString:@"選択天体を追従"],
                    "scale change did not update the tracked moon target");
        requirePlus([self applyRadiusDisplayOptions:appliedRadius mode:RadiusScaleMode::keep_orbit error:&radiusError],
                    "could not restore radius settings while following the moon");
        requirePlus([self applyRadiusDisplayOptions:appliedRadius mode:RadiusScaleMode::keep_radius error:&radiusError],
                    "could not select keep-radius mode without changing scales");
        [_solar selectBody:10];
        [_solar focusSelection];
        const auto followedCamera = [_solar cameraState];
        NSString *followingDescription = [_solar cameraStateDescription];
        requirePlus([followingDescription containsString:@"選択天体を追従"], "radius test did not start tracking");
        RadiusDisplayOptions rejectedRadius = appliedRadius;
        rejectedRadius.space_planet = 6;
        radiusError = nil;
        requirePlus(![self applyRadiusDisplayOptions:rejectedRadius mode:RadiusScaleMode::keep_radius error:&radiusError] &&
                    radiusError.length && [self readRadiusDisplayOptions:&appliedRadius mode:&appliedMode error:nullptr] &&
                    sameRadius(appliedRadius, {2, 3, 4, 5}) && appliedMode == RadiusScaleMode::keep_radius &&
                    sameCamera(followedCamera, [_solar cameraState]) &&
                    [[_solar cameraStateDescription] isEqualToString:followingDescription] &&
                    !_solar.journeyActive && !_solar.flightAnimating,
                    "rejected keep-radius change altered scales, camera, or tracking");
        [_solar startJourneyAtLatitude:0 longitude:0];
        requirePlus(_solar.journeyActive && _solar.flightAnimating, "radius test did not start flight");
        const auto flightCamera = [_solar cameraState];
        rejectedRadius = appliedRadius;
        rejectedRadius.space_sun = 6;
        radiusError = nil;
        requirePlus(![self applyRadiusDisplayOptions:rejectedRadius mode:RadiusScaleMode::keep_radius error:&radiusError] &&
                    radiusError.length && [self readRadiusDisplayOptions:&appliedRadius mode:&appliedMode error:nullptr] &&
                    sameRadius(appliedRadius, {2, 3, 4, 5}) && appliedMode == RadiusScaleMode::keep_radius &&
                    sameCamera(flightCamera, [_solar cameraState]) && _solar.journeyActive && _solar.flightAnimating,
                    "rejected keep-radius change altered scales, camera, or flight");
        RadiusDisplayOptions planetariumRadius = appliedRadius;
        planetariumRadius.planetarium_planet = 7;
        planetariumRadius.planetarium_sun_moon = 8;
        requirePlus([self applyRadiusDisplayOptions:planetariumRadius mode:RadiusScaleMode::keep_radius error:&radiusError] &&
                    [self readRadiusDisplayOptions:&appliedRadius mode:&appliedMode error:nullptr] &&
                    sameRadius(appliedRadius, planetariumRadius) && appliedMode == RadiusScaleMode::keep_radius &&
                    sameCamera(flightCamera, [_solar cameraState]) && _solar.journeyActive && _solar.flightAnimating,
                    "keep-radius planetarium-only change failed or interrupted flight");
        [_solar resetCamera];
        requirePlus([self applyRadiusDisplayOptions:initialRadius mode:RadiusScaleMode::keep_orbit error:&radiusError] &&
                    [self applyRadiusDisplayOptions:initialRadius mode:initialMode error:&radiusError],
                    "radius settings could not be restored");
        [_radiusDisplayController close];
        for (NSString *name in @[@"playForward", @"playBackward", @"playRealtime", @"pause"])
            commands(NSSelectorFromString(name), 1, _playback);
        const auto range = _model->time_range();
        const auto stepCommands = commands(@selector(stepTime:), 2, self);
        requirePlus(stepCommands[0].tag == -1 && stepCommands[1].tag == 1,
                    "time step menu directions are incorrect");
        const auto unitCommands = commands(@selector(selectTimeStep:), 11, self);
        for (NSUInteger index = 0; index < unitCommands.count; ++index)
            requirePlus(unitCommands[index].tag == static_cast<NSInteger>(index), "time unit menu tag mismatch");
        NSMenuItem *monthCommand = unitCommands[static_cast<NSUInteger>(TimeStep::month)];
        const double beforeUnitSelection = _jd;
        requirePlus([NSApp sendAction:monthCommand.action to:monthCommand.target from:monthCommand] &&
                    _timeSettings.step == TimeStep::month && _jd == beforeUnitSelection,
                    "choosing a calendar unit changed the date or selected the wrong unit");
        [monthCommand.menu update];
        requirePlus(monthCommand.state == NSControlStateValueOn, "calendar unit menu checkmark is missing");

        // 利用者の暦表範囲内で月末を選ぶ。狭い独自範囲に合わせてデータを置換しない。
        constexpr int offset = 345;
        std::optional<mitaka::GregorianDateTime> januaryEnd;
        const int firstYear = mitaka::gregorian_date_time(range.first).year;
        const int lastYear = mitaka::gregorian_date_time(range.second).year;
        for (int year = firstYear; year <= lastYear && !januaryEnd; ++year) {
            const mitaka::GregorianDateTime january{year, 1, 31, 12, 34, 56};
            const double start = julian_date_at_offset(january, offset);
            const double end = julian_date_at_offset({year, 3, 1, 12, 34, 56}, offset);
            if (start >= range.first && end <= range.second) januaryEnd = january;
        }
        const auto calendarInput = januaryEnd.value_or(calendar_at_offset(
            range.first + (range.second - range.first) / 2, offset));
        const double calendarJD = julian_date_at_offset(calendarInput, offset);
        [self showCalendar:nil];
        const auto initialCalendar = calendar_at_offset(_jd, _timeSettings.utc_offset_minutes);
        const std::array<int, 5> initialFields{{initialCalendar.year, initialCalendar.month,
            initialCalendar.day, initialCalendar.hour, initialCalendar.minute}};
        for (NSUInteger index = 0; index < initialFields.size(); ++index)
            requirePlus([_calendarFields[index].stringValue isEqualToString:
                [NSString stringWithFormat:@"%d", initialFields[index]]],
                "calendar initial integer field contains locale grouping");
        requirePlus([_customTimeStepField.stringValue isEqualToString:
            [NSString stringWithFormat:@"%d", _timeSettings.custom_seconds]],
            "calendar custom step contains locale grouping");
        const std::array<double, 6> calendarValues{{double(calendarInput.year), double(calendarInput.month),
            double(calendarInput.day), double(calendarInput.hour), double(calendarInput.minute), calendarInput.second}};
        for (NSUInteger index = 0; index < calendarValues.size(); ++index)
            _calendarFields[index].stringValue = [NSString stringWithFormat:index == 5 ? @"%.6f" : @"%.0f", calendarValues[index]];
        const NSInteger offsetIndex = [_calendarOffsetPopup indexOfItemWithRepresentedObject:@(offset)];
        requirePlus(offsetIndex >= 0, "calendar fixed offset is not selectable");
        [_calendarOffsetPopup selectItemAtIndex:offsetIndex];
        _customTimeStepField.stringValue = @"123";
        [self refreshCalendarGrid];
        requirePlus(_calendarDayButtons.count == 42, "calendar month grid must contain six full weeks");
        const double beforeCalendarDraft = _jd;
        NSButton *firstDay = nil;
        for (NSButton *button in _calendarDayButtons) {
            requirePlus(button.enabled == (button.tag > 0), "calendar blank cells are selectable");
            if (button.tag == 1) firstDay = button;
        }
        requirePlus(firstDay && [firstDay sendAction:firstDay.action to:firstDay.target] &&
                    _calendarFields[2].integerValue == 1 && _jd == beforeCalendarDraft,
                    "calendar day selection did not update only the draft");
        // 暦表範囲によらずドラフトだけで、桁区切りが入り得る年と閏年の月末を検証する。
        _calendarFields[0].stringValue = @"2000";
        _calendarFields[1].stringValue = @"1";
        _calendarFields[2].stringValue = @"31";
        [self refreshCalendarGrid];
        requirePlus(_calendarNextButton.enabled &&
                    [_calendarNextButton sendAction:_calendarNextButton.action to:_calendarNextButton.target],
                    "calendar next month action failed");
        requirePlus([_calendarFields[0].stringValue isEqualToString:@"2000"] &&
                    [_calendarFields[1].stringValue isEqualToString:@"2"] &&
                    [_calendarFields[2].stringValue isEqualToString:@"29"],
                    "calendar month navigation introduced grouping or failed to clamp leap day");
        NSUInteger enabledDays = 0, selectedDays = 0;
        for (NSButton *button in _calendarDayButtons) {
            if (button.enabled) ++enabledDays;
            if (button.state == NSControlStateValueOn && button.tag == 29) ++selectedDays;
        }
        requirePlus(enabledDays == 29 && selectedDays == 1 && _calendarPreviousButton.enabled && _calendarNextButton.enabled,
                    "calendar month navigation disabled the grid or lost its selected leap day");
        requirePlus([_calendarPreviousButton sendAction:_calendarPreviousButton.action to:_calendarPreviousButton.target] &&
                    [_calendarFields[0].stringValue isEqualToString:@"2000"] &&
                    [_calendarFields[1].stringValue isEqualToString:@"1"] &&
                    [_calendarFields[2].stringValue isEqualToString:@"29"],
                    "calendar previous month did not preserve the clamped draft day");
        requirePlus(_jd == beforeCalendarDraft && _calendarFields[3].integerValue == calendarInput.hour &&
                    _calendarFields[4].integerValue == calendarInput.minute &&
                    std::abs(_calendarFields[5].doubleValue - calendarInput.second) < 1e-5 &&
                    [_calendarOffsetPopup.selectedItem.representedObject isEqual:@(offset)],
                    "calendar draft navigation changed time, fixed offset, or active date");
        for (NSUInteger index = 0; index < 3; ++index)
            _calendarFields[index].stringValue = [NSString stringWithFormat:@"%.0f", calendarValues[index]];
        [self refreshCalendarGrid];
        [self applyCalendar:nil];
        requirePlus(std::abs(_jd - calendarJD) < 1e-8 && _timeSettings.utc_offset_minutes == offset &&
                    _timeSettings.custom_seconds == 123 && [_dateLabel.stringValue containsString:@"UTC+05:45"] &&
                    !_calendarWindow.visible, "calendar input did not apply its date, offset, custom step, or display");
        if (januaryEnd) {
            NSMenuItem *forward = stepCommands[1];
            requirePlus([NSApp sendAction:forward.action to:forward.target from:forward], "forward calendar step was not dispatched");
            const auto february = calendar_at_offset(_jd, offset);
            const int year = januaryEnd->year;
            const int februaryLastDay = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0) ? 29 : 28;
            requirePlus(february.year == year && february.month == 2 && february.day == februaryLastDay &&
                        february.hour == 12 && february.minute == 34 && std::abs(february.second - 56) < 0.001,
                        "calendar month step did not clamp to February while preserving local time");
            NSMenuItem *backward = stepCommands[0];
            requirePlus([NSApp sendAction:backward.action to:backward.target from:backward], "backward calendar step was not dispatched");
            const auto january = calendar_at_offset(_jd, offset);
            requirePlus(january.year == year && january.month == 1 && january.day == februaryLastDay,
                        "backward calendar step incorrectly remembered the original month-end day");
        } else {
            std::printf("Plus time smoke: month-end UI case skipped; selected ephemeris has no complete January/February interval\n");
        }
        NSMenuItem *trackingCommand = commands(@selector(toggleClockTracking:), 1, self).firstObject;
        const auto captures = commands(@selector(captureImage:), 3, self);
        for (NSUInteger index = 0; index < captures.count; ++index)
            requirePlus(captures[index].tag == static_cast<NSInteger>(index), "image menu format tag mismatch");
        const auto toggles = commands(@selector(toggleDisplay:), 7, self);
        for (NSUInteger index = 0; index < toggles.count; ++index) {
            NSMenuItem *item = toggles[index];
            requirePlus(item.tag == static_cast<NSInteger>(index), "display menu toggle tag mismatch");
            auto expected = displayFlags(_sky);
            expected[index] = !expected[index];
            const NSInteger beforeMode = _mode.selectedSegment;
            const auto beforeConstellations = [self constellationDisplayOptions];
            requirePlus([NSApp sendAction:item.action to:item.target from:item], "display menu action was not dispatched");
            requirePlus(displayFlags(_sky) == expected, "display menu toggled the wrong layer");
            requirePlus(_mode.selectedSegment == (index < 3 || index == 6 ? beforeMode : 0),
                        "display menu selected the wrong view mode");
            const auto horizon = _horizon.constellationDisplayOptions;
            requirePlus(horizon.lines == expected[0] && horizon.boundaries == expected[1] && horizon.labels == expected[2] &&
                        horizon.illustrations == expected[6] &&
                        horizon.default_visible == beforeConstellations.default_visible &&
                        horizon.exceptions == beforeConstellations.exceptions &&
                        _sky.constellationDisplayOptions.default_visible == beforeConstellations.default_visible &&
                        _sky.constellationDisplayOptions.exceptions == beforeConstellations.exceptions,
                        "display menu desynchronized constellation views or changed their membership");
            [item.menu update];
            requirePlus(item.state == (expected[index] ? NSControlStateValueOn : NSControlStateValueOff),
                        "display menu checkmark does not reflect its layer");
        }
        _mode.selectedSegment = 2;
        [self changeMode:_mode];
        checkDisplayCommands(@selector(togglePlanetDisplay:), 4, self, [&] {
            const auto current = flags([self planetDisplayOptions]);
            requirePlus(flags(_sky.planetDisplayOptions) == current && flags(_horizon.planetDisplayOptions) == current &&
                        flags(_solar.planetDisplayOptions) == current, "planet options disagree between views");
            return current;
        });
        const auto planetFlags = flags([self planetDisplayOptions]);
        const auto terrainCommands = commands(@selector(selectTerrainAmplification:), 5, self);
        for (NSUInteger index = 0; index < terrainCommands.count; ++index) {
            NSMenuItem *item = terrainCommands[index];
            requirePlus(item.tag == static_cast<NSInteger>(index) &&
                        [NSApp sendAction:item.action to:item.target from:item], "terrain amplification action failed");
            requirePlus(static_cast<NSUInteger>([self terrainAmplification]) == index + 1 &&
                        _solar.terrainAmplification == [self terrainAmplification] &&
                        flags([self planetDisplayOptions]) == planetFlags,
                        "terrain amplification changed unrelated state or failed to reach the solar view");
            [item.menu update];
            for (NSMenuItem *candidate in terrainCommands)
                requirePlus(candidate.state == (candidate == item ? NSControlStateValueOn : NSControlStateValueOff),
                            "terrain amplification checkmarks disagree with the selected level");
        }
        checkDisplayCommands(@selector(toggleEarthLayer:), 2, self, [&] {
            const auto current = flags([self earthLayerOptions]);
            requirePlus(flags(_solar.earthLayerOptions) == current && flags([self planetDisplayOptions]) == planetFlags,
                        "Earth layer action changed its planet master or disagrees with the solar view");
            return current;
        });
        auto atmosphere = [self atmosphereDisplayOptions];
        atmosphere.intensity = 2.5;
        [self setAtmosphereDisplayOptions:atmosphere];
        const auto earthFlags = flags([self earthLayerOptions]);
        checkDisplayCommands(@selector(toggleLandscapeImage:), 1, self, [&] {
            requirePlus(flags([self planetDisplayOptions]) == planetFlags && flags([self earthLayerOptions]) == earthFlags,
                        "landscape action changed unrelated planet or Earth layers");
            return std::array<bool, 1>{{bool(_horizon.showsLandscapeImage)}};
        });
        checkDisplayCommands(@selector(toggleEclipseDisplay:), 4, self, [&] {
            const auto current = flags([self eclipseDisplayOptions]);
            requirePlus(flags(_solar.eclipseDisplayOptions) == current &&
                        flags([self planetDisplayOptions]) == planetFlags && flags([self earthLayerOptions]) == earthFlags,
                        "eclipse action changed unrelated layers or disagrees with the solar view");
            return current;
        });
        const auto atmosphereCommands = commands(@selector(selectAtmosphereMode:), 3, self);
        for (NSUInteger index = 0; index < atmosphereCommands.count; ++index) {
            NSMenuItem *item = atmosphereCommands[index];
            requirePlus(item.tag == static_cast<NSInteger>(index) &&
                        [NSApp sendAction:item.action to:item.target from:item], "atmosphere mode action has an invalid tag or dispatch");
            const auto actual = [self atmosphereDisplayOptions];
            requirePlus(static_cast<NSUInteger>(actual.mode) == index && actual.intensity == atmosphere.intensity &&
                        _solar.atmosphereDisplayOptions.mode == actual.mode &&
                        _solar.atmosphereDisplayOptions.intensity == actual.intensity &&
                        flags([self planetDisplayOptions]) == planetFlags && flags([self earthLayerOptions]) == earthFlags,
                        "atmosphere mode action changed intensity or unrelated layers");
            [item.menu update];
            for (NSMenuItem *candidate in atmosphereCommands)
                requirePlus(candidate.state == (candidate == item ? NSControlStateValueOn : NSControlStateValueOff),
                            "atmosphere radio checkmarks disagree with the selected mode");
        }
        std::set<std::int32_t> selectedNames;
        if (!_starNameSelection->known_hips().empty()) selectedNames.insert(*_starNameSelection->known_hips().begin());
        [self setSelectedStarNameHIPs:selectedNames];
        [self setStarBrightness:1.25 cancelTransition:YES];
        const auto initialStars = [self starDisplayOptions];
        checkDisplayCommands(@selector(toggleStarDisplay:), 6, self, [&] {
            const auto current = flags([self starDisplayOptions]);
            requirePlus(flags(_sky.starDisplayOptions) == current && flags(_horizon.starDisplayOptions) == current,
                        "star options disagree between views");
            requirePlus([self selectedStarNameHIPs] == selectedNames &&
                        [self starDisplayOptions].brightness == initialStars.brightness &&
                        [self starDisplayOptions].marking == initialStars.marking,
                        "star display action changed name membership, brightness, or marking");
            requirePlus([_status.stringValue containsString:[NSString stringWithFormat:@"恒星表示 %lu 件",
                            static_cast<unsigned long>(_horizon.visibleStarCount)]],
                        "star visibility left a stale count in the paused view status");
            return current;
        });
        const auto starCommands = commands(@selector(toggleStarDisplay:), 6, self);
        // 固有名の全体スイッチを切っても、選択限定と集合を維持して再表示できることを確認する。
        for (bool properNames : {false, true}) {
            for (bool selectedOnly : {false, true}) {
                for (const NSUInteger index : {NSUInteger(1), NSUInteger(5)}) {
                    const bool expected = index == 1 ? properNames : selectedOnly;
                    if (flags([self starDisplayOptions])[index] != expected) {
                        NSMenuItem *item = starCommands[index];
                        requirePlus([NSApp sendAction:item.action to:item.target from:item],
                                    "star name master action did not dispatch");
                    }
                }
                const auto actual = [self starDisplayOptions];
                requirePlus(actual.proper_names == properNames && actual.selected_proper_names_only == selectedOnly &&
                            flags(_sky.starDisplayOptions) == flags(actual) && flags(_horizon.starDisplayOptions) == flags(actual) &&
                            [self selectedStarNameHIPs] == selectedNames,
                            "star name master and selected-name filter are not independent");
            }
        }
        const auto starFlags = flags([self starDisplayOptions]);
        const auto starMarking = [self starDisplayOptions].marking;
        const auto brightnessCommands = commands(@selector(changeStarBrightness:), 3, self);
        for (NSUInteger index = 0; index < brightnessCommands.count; ++index) {
            NSMenuItem *item = brightnessCommands[index];
            const float before = [self starDisplayOptions].brightness;
            const float expected = index == 0 ? brighter_star_brightness(before) :
                index == 1 ? darker_star_brightness(before) : 1;
            requirePlus(item.tag == static_cast<NSInteger>(index) &&
                        [NSApp sendAction:item.action to:item.target from:item], "brightness action has an invalid tag or dispatch");
            requirePlus([self starDisplayOptions].brightness == expected &&
                        _sky.starDisplayOptions.brightness == expected && _horizon.starDisplayOptions.brightness == expected &&
                        flags([self starDisplayOptions]) == starFlags && [self starDisplayOptions].marking == starMarking &&
                        [self selectedStarNameHIPs] == selectedNames,
                        "brightness command disagrees with its common calculation or changed star options");
            [item.menu update];
            for (NSMenuItem *candidate in brightnessCommands)
                requirePlus(candidate.state == NSControlStateValueOff, "momentary brightness command has a persistent checkmark");
        }
        checkDisplayCommands(@selector(toggleGridDisplay:), 6, self, [&] {
            const auto current = flags([self gridDisplayOptions]);
            requirePlus(flags(_sky.gridDisplayOptions) == current && flags(_horizon.gridDisplayOptions) == current &&
                        flags(_solar.gridDisplayOptions) == current, "grid options disagree between views");
            return current;
        });
        checkDisplayCommands(@selector(toggleRendererDisplay:), 4, self, [&] {
            const auto current = flags([self rendererDisplayOptions]);
            requirePlus(flags(_sky.rendererDisplayOptions) == current && flags(_horizon.rendererDisplayOptions) == current &&
                        flags(_solar.rendererDisplayOptions) == current, "renderer options disagree between views");
            return current;
        });
        for (NSMenuItem *item in commands(@selector(selectStarMarking:), 3, self)) {
            requirePlus([NSApp sendAction:item.action to:item.target from:item] &&
                        static_cast<NSInteger>([self starDisplayOptions].marking) == item.tag &&
                        _horizon.starDisplayOptions.marking == _sky.starDisplayOptions.marking,
                        "star marking action did not reach both views");
            [item.menu update];
            requirePlus(item.state == NSControlStateValueOn, "star marking checkmark is missing");
        }
        NSMenuItem *timeInfo = commands(@selector(toggleTimeInfo:), 1, self).firstObject;
        for (int iteration = 0; iteration < 2; ++iteration) {
            const bool expected = ![self timeInfoVisible];
            requirePlus([NSApp sendAction:timeInfo.action to:timeInfo.target from:timeInfo] &&
                        [self timeInfoVisible] == expected && _dateLabel.hidden == !expected &&
                        _horizon.showsTimeInfo == expected && _solar.showsTimeInfo == expected,
                        "time information visibility did not reach every view");
            [timeInfo.menu update];
            requirePlus(timeInfo.state == (expected ? NSControlStateValueOn : NSControlStateValueOff),
                        "time information checkmark is incorrect");
        }
        requirePlus(_mode.selectedSegment == 2, "shared display options unexpectedly switched the view mode");
        SessionState saved = original;
        saved.julian_date = range.first + (range.second - range.first) / 2;
        saved.simulation_rate = -60;
        saved.time_settings = {TimeStep::month, 123, offset};
        saved.mode = 2;
        saved.magnitude_limit = 12.5;
        saved.sky_viewport = {234, 30, 4};
        saved.horizon_viewport = {71, -20, 3};
        saved.solar_camera = {{0.25, -0.5, 0.75}, 68, -15, 8,
                             SolarCameraBasis{{0, 0, 1}, {1, 0, 0}, {0, 1, 0}}};
        saved.selected_body = Body::moon;
        saved.sky_selected_body = Body::venus;
        saved.horizon_selected_body = Body::mars;
        saved.constellations.lines = true;
        saved.constellations.boundaries = false;
        saved.constellations.labels = true;
        saved.planets = {false, false, false, true};
        saved.stars = {false, true, true, true, true, StarMarking::exoplanets};
        saved.grids = {true, true, true, true, false, true};
        saved.renderer = {true, false, true, false};
        saved.satellites.options.visible = false;
        saved.show_time_info = false;
        saved.show_nebulae = false;
        saved.show_galaxies = true;
        saved.show_quasars = false;
        saved.observer_latitude_deg = -33.87;
        saved.observer_longitude_deg = 151.21;
        requirePlus([self applySessionState:saved], "configured session could not be applied");
        checkSolarObservation(_solar, {saved.observer_latitude_deg, saved.observer_longitude_deg}, saved.julian_date);
        const auto savedJSON = encode_session_state(saved);
        requirePlus(encode_session_state([self sessionState]) == savedJSON,
                    "session capture did not preserve every configured field");

        SessionState changed = saved;
        changed.julian_date += std::min(1.0, (range.second - range.first) / 4);
        changed.simulation_rate = 60;
        changed.time_settings = {TimeStep::hundred_years, 456, -210};
        changed.mode = 1;
        changed.magnitude_limit = -2.5;
        changed.sky_viewport = {34, -10, 2};
        changed.horizon_viewport = {301, 12, 5};
        changed.solar_camera = {{-1, 0, 1}, -32, 42, 15, std::nullopt};
        changed.selected_body = Body::mars;
        changed.sky_selected_body = Body::saturn;
        changed.horizon_selected_body = Body::sun;
        changed.constellations.lines = !saved.constellations.lines;
        changed.constellations.boundaries = !saved.constellations.boundaries;
        changed.constellations.labels = !saved.constellations.labels;
        changed.planets = {true, true, true, false};
        changed.stars = {true, false, false, false, false, StarMarking::binary};
        changed.grids = {false, false, false, false, true, false};
        changed.renderer = {false, true, false, true};
        changed.satellites.options.visible = true;
        changed.show_time_info = true;
        changed.show_nebulae = !saved.show_nebulae;
        changed.show_galaxies = !saved.show_galaxies;
        changed.show_quasars = !saved.show_quasars;
        changed.observer_latitude_deg = 51.5;
        changed.observer_longitude_deg = -0.1;
        requirePlus([self applySessionState:changed], "changed session could not be applied");
        requirePlus(flags(_sky.rendererDisplayOptions) == flags(changed.renderer) &&
                    flags(_horizon.rendererDisplayOptions) == flags(changed.renderer) &&
                    flags(_solar.rendererDisplayOptions) == flags(changed.renderer),
                    "session renderer settings did not reach every view");
        checkSolarObservation(_solar, {changed.observer_latitude_deg, changed.observer_longitude_deg}, changed.julian_date);
        requirePlus(encode_session_state([self sessionState]) == encode_session_state(changed),
                    "session change did not reach every view setting");
        [_playback play];
        requirePlus(_playback.playing, "session restore test did not start playback");
        requirePlus([self applySessionState:decode_session_state(savedJSON)], "saved JSON session could not be restored");
        requirePlus(flags(_sky.rendererDisplayOptions) == flags(saved.renderer) &&
                    flags(_horizon.rendererDisplayOptions) == flags(saved.renderer) &&
                    flags(_solar.rendererDisplayOptions) == flags(saved.renderer),
                    "session renderer settings did not restore every view");
        checkSolarObservation(_solar, {saved.observer_latitude_deg, saved.observer_longitude_deg}, saved.julian_date);
        requirePlus(!_playback.playing && !_playback.clockTracking && !_solar.flightAnimating && !_solar.journeyActive,
                    "session restore retained playback or flight");
        requirePlus(encode_session_state([self sessionState]) == savedJSON,
                    "session restore did not restore every saved field");
        const double currentJD = NSDate.date.timeIntervalSince1970 / 86400.0 + 2440587.5;
        if (currentJD >= range.first && currentJD <= range.second) {
            requirePlus([NSApp sendAction:trackingCommand.action to:trackingCommand.target from:trackingCommand] &&
                        _playback.clockTracking && !_playback.playing && !_jdField.enabled,
                        "clock tracking menu did not start tracking or protect the date field");
            [trackingCommand.menu update];
            requirePlus(trackingCommand.state == NSControlStateValueOn && std::abs(_jd - currentJD) < 1.0 / 86400.0 &&
                        _playback.julianDate == _jd && _horizon.julianDate == _jd,
                        "clock tracking checkmark or shared current date is incorrect");
            requirePlus([self applySessionState:decode_session_state(savedJSON)] && !_playback.clockTracking &&
                        !_playback.playing && _jdField.enabled && encode_session_state([self sessionState]) == savedJSON,
                        "session restore did not stop clock tracking and restore time settings");
            [trackingCommand.menu update];
            requirePlus(trackingCommand.state == NSControlStateValueOff, "restored session retained the tracking checkmark");
        } else {
            std::printf("Plus time smoke: current-clock UI case skipped; current UTC is outside the selected ephemeris\n");
        }
        requirePlus(_sky.selectedBodyIndex < _bodies.size() && _horizon.selectedBodyIndex < _bodies.size() &&
                    _bodies[_sky.selectedBodyIndex].id == Body::venus &&
                    _bodies[_horizon.selectedBodyIndex].id == Body::mars,
                    "restored body selection disagrees across sky/horizon views");
        SessionState cleared = saved;
        cleared.sky_selected_body.reset();
        cleared.horizon_selected_body.reset();
        requirePlus([self applySessionState:cleared] && _sky.selectedBodyIndex == NSNotFound &&
                    _horizon.selectedBodyIndex == NSNotFound, "null session selection retained the previous body");
        requirePlus([self applySessionState:saved], "session did not restore after clearing body selections");
        const auto site = [_horizon observerSite];
        requirePlus(site.latitude_deg == saved.observer_latitude_deg && site.longitude_deg == saved.observer_longitude_deg &&
                    _horizon.julianDate == saved.julian_date && _playback.julianDate == saved.julian_date &&
                    _horizon.magnitudeLimit == saved.magnitude_limit && _magnitudeSlider.doubleValue == saved.magnitude_limit,
                    "restored date, observer, or magnitude disagrees across controls and views");

        SessionState captureState = saved;
        captureState.planets = {true, true, true, true};
        captureState.stars.visible = true;
        requirePlus([self applySessionState:captureState], "capture scene could not enable its astronomical layers");
        DisplayOutputController *output = [[DisplayOutputController alloc] init];
        const std::array<NSView *, 3> views{{_sky, _solar, _horizon}};
        for (NSInteger mode = 0; mode < 3; ++mode) {
            _mode.selectedSegment = mode;
            requirePlus([_mode sendAction:_mode.action to:_mode.target], "mode control action was not dispatched");
            requirePlus([self activeView] == views[mode], "active view did not follow mode selection");
            NSString *selection = mode == 0 ? _skySelection : mode == 1 ? _solarSelection : _horizonSelection;
            requirePlus(selection.length > 0 && [_selectionLabel.stringValue isEqualToString:selection],
                        "mode switch did not restore the selected body's description");
            for (NSInteger index = 0; index < 3; ++index)
                requirePlus(views[index].hidden == (index != mode), "mode selected an incorrect visible view");
            [_window.contentView layoutSubtreeIfNeeded];
            [[self activeView] displayIfNeeded];
            output.sourceView = [self activeView];
            // 実際の3表示をメモリ上だけで符号化し、元データや画像ファイルを書き換えない。
            for (DisplayImageFormat format : {DisplayImageFormatPNG, DisplayImageFormatJPEG, DisplayImageFormatBMP})
                checkCapturedImage(output, format);
        }
        [output invalidate];
        NSURL *destination = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"mitaka-smoke-output.png"]];
        requirePlus([self canWriteOutputURL:destination], "output policy rejected a temporary destination outside source data");
        requirePlus([self applySessionState:original] && encode_session_state([self sessionState]) == encode_session_state(original),
                    "Plus smoke did not restore the original application state");
        requirePlus([self runSessionLayerSmokeTest], "v8 display layer session smoke failed");
        std::printf("Plus AppKit smoke passed: local observers, calendar grid/offset controls, 30 layer toggles, three atmosphere modes, three brightness commands, independent name selection, four renderer quality settings, three star markings, time information, three modes, full session restore, playback/tracking stop, nine encoded scene captures\n");
        return YES;
    } catch (const std::exception& error) {
        std::fprintf(stderr, "Plus AppKit smoke failed: %s\n", error.what());
        std::exit(EXIT_FAILURE);
    }
}
@end
