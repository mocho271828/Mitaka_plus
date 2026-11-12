#import "ScriptController.h"
#include "script_transport.hpp"
#include <atomic>
#include <cmath>
#include <cstdlib>
#include <fcntl.h>
#include <memory>
#include <limits>
#include <stdexcept>
#include <sys/socket.h>
#include <signal.h>
#include <unistd.h>

using namespace mitaka::gui;
namespace {
struct ScriptJob {
    int socket;
    pid_t process = 0;
    NSURL *temporaryDirectory = nil;
    std::atomic<bool> cancelled{false};
    explicit ScriptJob(int descriptor) : socket(descriptor) {}
    ~ScriptJob() {
        ::close(socket);
        if (temporaryDirectory) [NSFileManager.defaultManager removeItemAtURL:temporaryDirectory error:nil];
    }
    void cancel() {
        if (cancelled.exchange(true)) return;
        ::shutdown(socket, SHUT_RDWR);
        if (process > 0) {
            // Lua の外部プロセスも同じプロセス群で停止する。
            ::kill(-process, SIGKILL);
            ::kill(process, SIGKILL);
        }
    }
};
NSError *scriptError(NSString *message) {
    return [NSError errorWithDomain:@"MitakaScript" code:1 userInfo:@{NSLocalizedDescriptionKey:message}];
}
std::string encode(NSDictionary *message) {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:message options:0 error:&error];
    if (!data) throw std::runtime_error(error.localizedDescription.UTF8String);
    return std::string(static_cast<const char *>(data.bytes), data.length);
}
NSDictionary *decode(const std::string& text) {
    NSData *data = [NSData dataWithBytes:text.data() length:text.size()];
    id value = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![value isKindOfClass:NSDictionary.class]) throw std::runtime_error("Invalid script message");
    return value;
}
bool isNumber(id value) {
    return [value isKindOfClass:NSNumber.class] && std::isfinite([value doubleValue]);
}
NSDictionary *snapshotMessage(const ScriptSnapshot& state) {
    (void)plus_time_rate(state.plus_time);
    validate_terrain_amplification(state.terrain_amplification);
    validate_radius_display_options(state.radius_display);
    validate_radius_scale_mode(state.radius_scale_mode);
    if (!std::isfinite(state.julian_date) || !std::isfinite(state.rate_seconds_per_second) ||
        !std::isfinite(state.camera_distance_au) || !std::isfinite(state.camera_azimuth_deg) ||
        !std::isfinite(state.camera_altitude_deg) ||
        !std::isfinite(state.camera_mode_duration) || state.camera_mode_duration < 0 ||
        state.camera_zoom_mode < 0 || state.camera_zoom_mode > 2 ||
        state.target_selection_mode < 0 || state.target_selection_mode > 2 ||
        (state.camera_mode && *state.camera_mode != 0 && *state.camera_mode != 1) ||
        (state.camera_fov && (!std::isfinite(*state.camera_fov) || *state.camera_fov <= 0 || *state.camera_fov > 180)) ||
        (state.camera_duration && (!std::isfinite(*state.camera_duration) || *state.camera_duration < 0)) ||
        state.atmosphere_mode < 0 || state.atmosphere_mode > 2)
        throw std::runtime_error("Invalid host snapshot");
    NSString *target = [NSString stringWithUTF8String:state.target.c_str()];
    NSString *milkyWay = [NSString stringWithUTF8String:state.milky_way_type.c_str()];
    validate_star_display(state.stars);
    NSString *marking = state.stars.marking == StarMarking::none ? @"None" :
        state.stars.marking == StarMarking::binary ? @"Binary" : @"ExoPlanets";
    if (!target || !milkyWay) throw std::runtime_error("Invalid host name");
    NSMutableArray<NSNumber *> *selectedNames = [NSMutableArray arrayWithCapacity:state.selected_star_names.size()];
    for (const auto hip : state.selected_star_names) {
        if (hip <= 0) throw std::runtime_error("Invalid host star selection");
        [selectedNames addObject:@(hip)];
    }
    NSMutableArray<NSNumber *> *orientation = [NSMutableArray array];
    if (state.camera_orientation) for (const double value : *state.camera_orientation) {
        if (!std::isfinite(value)) throw std::runtime_error("Invalid camera orientation");
        [orientation addObject:@(value)];
    }
    NSMutableArray<NSNumber *> *euler = [NSMutableArray array];
    if (state.camera_euler) for (const double value : *state.camera_euler) {
        if (!std::isfinite(value)) throw std::runtime_error("Invalid camera Euler angles");
        [euler addObject:@(value)];
    }
    return @{@"ok":@YES, @"jd":@(state.julian_date), @"rate":@(state.rate_seconds_per_second),
        @"playing":@(state.playing), @"realtime":@(state.clock_tracking), @"timeInfo":@(state.time_info),
        @"timeStep":@(static_cast<int>(state.plus_time.step.step())),
        @"timeStepValue":@(state.plus_time.step.value_days()), @"timeSpeed":@(state.plus_time.speed),
        @"plusTimeZoneWestSeconds":state.plus_time_zone ? @(state.plus_time_zone->seconds_west_of_utc) : NSNull.null,
        @"target":target, @"distance":@(state.camera_distance_au),
        @"lines":@(state.constellation_lines), @"bounds":@(state.constellation_boundaries),
        @"labels":@(state.constellation_labels), @"starLabels":@(state.stars.proper_names),
        @"illusts":@(state.constellation_illustrations), @"selectedStarNames":selectedNames,
        @"selectedStarLabels":@(state.stars.selected_proper_names_only),
        @"starsVisible":@(state.stars.visible), @"bayerLabels":@(state.stars.bayer_labels),
        @"flamsteedLabels":@(state.stars.flamsteed_labels), @"hipLabels":@(state.stars.hip_labels),
        @"starMarking":marking, @"starBrightness":@(state.stars.brightness), @"milkyWay":milkyWay,
        @"planetsVisible":@(state.planets.visible), @"planetLabels":@(state.planets.labels),
        @"planetOrbits":@(state.planets.orbits), @"planetAxes":@(state.planets.axes),
        @"earthClouds":@(state.earth_clouds), @"earthCityLights":@(state.earth_city_lights),
        @"atmosphereMode":@(state.atmosphere_mode),
        @"topoAmplification":@(static_cast<int>(state.terrain_amplification)),
        @"radiusScale":@[@(state.radius_display.space_planet), @(state.radius_display.space_sun),
            @(state.radius_display.planetarium_planet), @(state.radius_display.planetarium_sun_moon)],
        @"radiusScaleMode":@(static_cast<int>(state.radius_scale_mode)),
        @"shadows":@(state.eclipse.shadows), @"shadowBorders":@(state.eclipse.shadow_borders),
        @"shadowUmbra":@(state.eclipse.shadow_umbra), @"shadowPenumbra":@(state.eclipse.shadow_penumbra),
        @"landscape":@(state.landscape),
        @"equatorial":@(state.grids.equatorial), @"ecliptic":@(state.grids.ecliptic),
        @"galactic":@(state.grids.galactic), @"horizontal":@(state.grids.horizontal),
        @"circleScales":@(state.grids.circle_scales), @"squareScales":@(state.grids.square_scales),
        @"antialias":@(state.renderer.antialias), @"pointSmooth":@(state.renderer.point_smoothing),
        @"lineSmooth":@(state.renderer.line_smoothing), @"textSmooth":@(state.renderer.text_smoothing),
                @"asteroids_visible":@(state.asteroids.visible),
        @"asteroids_labels":@(state.asteroids.labels),
        @"asteroids_orbits":@(state.asteroids.orbits),
        @"asteroids_selectedOnly":@(state.asteroids.selected_only),
        @"tnobjects_visible":@(state.tnobjects.visible),
        @"tnobjects_labels":@(state.tnobjects.labels),
        @"tnobjects_orbits":@(state.tnobjects.orbits),
        @"tnobjects_selectedOnly":@(state.tnobjects.selected_only),
        @"comets_visible":@(state.comets.visible),
        @"comets_labels":@(state.comets.labels),
        @"comets_orbits":@(state.comets.orbits),
        @"comets_selectedOnly":@(state.comets.selected_only),
        @"satellites_visible":@(state.satellites.visible),
        @"satellites_labels":@(state.satellites.labels),
        @"satellites_orbits":@(state.satellites.orbits),
        @"satellites_selectedOnly":@(state.satellites.selected_only),
        @"fullScreen":@(state.full_screen), @"nebulae":@(state.nebulae), @"galaxies":@(state.distant_galaxies), @"quasars":@(state.quasars),
        @"azimuth":@(state.camera_azimuth_deg), @"altitude":@(state.camera_altitude_deg),
        @"cameraDuration":state.camera_duration ? (id)@(*state.camera_duration) : (id)NSNull.null,
        @"cameraFov":state.camera_fov ? (id)@(*state.camera_fov) : (id)NSNull.null,
        @"cameraMode":state.camera_mode ? (id)@(*state.camera_mode) : (id)NSNull.null,
        @"cameraModeDuration":@(state.camera_mode_duration), @"cameraZoomMode":@(state.camera_zoom_mode),
        @"targetSelectionMode":@(state.target_selection_mode),
        @"targetBrowser":@(state.target_browser),
        @"cameraOrientation":orientation, @"cameraEuler":euler,
        @"timeSetting":@(state.time_setting), @"placeSetting":@(state.place_setting),
        @"scriptOutput":@(state.script_output), @"dualScreen":@(state.dual_screen)};
}
}

@interface ScriptController () {
    NSURL *_helperURL;
    NSTask *_task;
    std::shared_ptr<ScriptJob> _job;
    BOOL _invalidated;
}
- (NSDictionary *)handleMessage:(NSDictionary *)message;
- (BOOL)runSource:(NSString *)source consoleMode:(BOOL)consoleMode error:(NSError **)error;
- (BOOL)launchFile:(NSURL *)file temporaryDirectory:(NSURL *)directory consoleMode:(BOOL)consoleMode error:(NSError **)error;
@end

@implementation ScriptController
- (instancetype)init {
    NSURL *executable = NSBundle.mainBundle.executableURL;
    return [self initWithHelperURL:[[executable URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"MitakaScript"]];
}
- (instancetype)initWithHelperURL:(NSURL *)helperURL {
    self = [super init];
    if (self) _helperURL = helperURL;
    return self;
}
- (BOOL)running { return _job != nullptr; }
- (BOOL)runSource:(NSString *)source error:(NSError **)error {
    return [self runSource:source consoleMode:NO error:error];
}
- (BOOL)runConsoleSource:(NSString *)source error:(NSError **)error {
    return [self runSource:source consoleMode:YES error:error];
}
- (BOOL)runSource:(NSString *)source consoleMode:(BOOL)consoleMode error:(NSError **)error {
    NSAssert(NSThread.isMainThread, @"Script UI must run on the main thread");
    NSData *data = [source dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    if (_invalidated || _job || !data || data.length == 0 || data.length > 1024 * 1024) {
        if (error) *error = scriptError(@"実行中・終了済み、またはソースが空・不正・1 MiB 超過です。");
        return NO;
    }
    std::string path([NSTemporaryDirectory() stringByAppendingPathComponent:@"mitaka-lua-XXXXXX"].fileSystemRepresentation);
    if (!mkdtemp(path.data())) {
        if (error) *error = scriptError(@"一時スクリプトの保存先を作成できません。");
        return NO;
    }
    NSURL *directory = [NSURL fileURLWithFileSystemRepresentation:path.c_str() isDirectory:YES relativeToURL:nil];
    NSURL *file = [directory URLByAppendingPathComponent:consoleMode ? @"console.lua" : @"html-link.lua"];
    // 原本に触れず、所有者だけが読める一時領域から同じ Lua helper を使う。
    const bool written = [NSFileManager.defaultManager createFileAtPath:file.path contents:data attributes:@{NSFilePosixPermissions:@0600}];
    if (!written || ![self launchFile:file temporaryDirectory:directory consoleMode:consoleMode error:error]) {
        if (!written && error) *error = scriptError(@"一時スクリプトを書き込めません。");
        [NSFileManager.defaultManager removeItemAtURL:directory error:nil];
        return NO;
    }
    return YES;
}
- (BOOL)runFile:(NSURL *)file error:(NSError **)error {
    return [self launchFile:file temporaryDirectory:nil consoleMode:NO error:error];
}
- (BOOL)launchFile:(NSURL *)file temporaryDirectory:(NSURL *)directory consoleMode:(BOOL)consoleMode error:(NSError **)error {
    NSAssert(NSThread.isMainThread, @"Script UI must run on the main thread");
    NSString *failure = nil;
    NSNumber *regular = nil, *size = nil;
    [file getResourceValue:&regular forKey:NSURLIsRegularFileKey error:nil];
    [file getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
    if (_invalidated) failure = @"スクリプト実行は終了しています。";
    else if (_job) failure = @"実行中のスクリプトを停止してから選択してください。";
    else if (!file.isFileURL || !regular.boolValue || size.unsignedLongLongValue > 1024 * 1024)
        failure = @"1 MiB 以下のローカル Lua ファイルを選択してください。";
    else if (!self.snapshot || !self.applyAction) failure = @"スクリプトの表示制御が接続されていません。";
    else if (![[NSFileManager defaultManager] isExecutableFileAtPath:_helperURL.path])
        failure = @"Lua helper がありません。MitakaScript を含めてビルドしてください。";
    if (failure) { if (error) *error = scriptError(failure); return NO; }
    int sockets[2];
    if (::socketpair(AF_UNIX, SOCK_STREAM, 0, sockets) != 0) {
        if (error) *error = scriptError(@"スクリプト通信用の接続を作成できません。");
        return NO;
    }
    auto job = std::make_shared<ScriptJob>(sockets[0]);
    job->temporaryDirectory = directory;
    NSFileHandle *input = [[NSFileHandle alloc] initWithFileDescriptor:sockets[1] closeOnDealloc:NO];
    NSTask *task = [[NSTask alloc] init];
    task.executableURL = _helperURL;
    task.arguments = consoleMode ? @[file.path, @"--console"] : @[file.path];
    task.currentDirectoryURL = self.workingDirectoryURL ? self.workingDirectoryURL : file.URLByDeletingLastPathComponent;
    task.standardInput = input;
    task.standardOutput = NSFileHandle.fileHandleWithNullDevice;
    task.standardError = NSFileHandle.fileHandleWithNullDevice;
    if (![task launchAndReturnError:error]) { ::close(sockets[1]); return NO; }
    ::close(sockets[1]);
    job->process = task.processIdentifier;
    _job = job;
    _task = task;
    __weak ScriptController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        @autoreleasepool {
            __block BOOL succeeded = NO;
            __block NSString *result = @"スクリプトが終了しました。";
            try {
                while (!job->cancelled.load()) {
                    NSDictionary *message = decode(read_script_frame(job->socket));
                    NSString *operation = message[@"op"];
                    if (![operation isKindOfClass:NSString.class]) throw std::runtime_error("Missing script operation");
                    if ([operation isEqualToString:@"done"]) {
                        if (![message[@"ok"] isKindOfClass:NSNumber.class] ||
                            ![message[@"message"] isKindOfClass:NSString.class])
                            throw std::runtime_error("Invalid script completion");
                        succeeded = [message[@"ok"] boolValue];
                        result = message[@"message"];
                        break;
                    }
                    __block NSDictionary *reply;
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        ScriptController *controller = weakSelf;
                        if (!controller || job->cancelled.load()) reply = @{@"ok":@NO, @"error":@"Script cancelled"};
                        else reply = [controller handleMessage:message];
                    });
                    write_script_frame(job->socket, encode(reply));
                }
            } catch (const std::exception& exception) {
                NSString *failure = [NSString stringWithUTF8String:exception.what()];
                result = failure ? failure : @"スクリプトとの通信が終了しました。";
            }
            if (job->cancelled.load()) { succeeded = NO; result = @"スクリプトを停止しました。"; }
            // 通信を終了した helper を待つ。異常な外部処理も残さない。
            job->cancel();
            [task waitUntilExit];
            if (job->temporaryDirectory) {
                [NSFileManager.defaultManager removeItemAtURL:job->temporaryDirectory error:nil];
                job->temporaryDirectory = nil;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                ScriptController *controller = weakSelf;
                if (controller && controller->_job == job) {
                    controller->_job.reset();
                    controller->_task = nil;
                    if (controller.completion) controller.completion(succeeded, result);
                }
            });
        }
    });
    const std::weak_ptr<ScriptJob> weakJob = job;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 120LL * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        auto active = weakJob.lock();
        ScriptController *controller = weakSelf;
        if (active && controller && controller->_job == active) active->cancel();
    });
    return YES;
}
- (NSDictionary *)handleMessage:(NSDictionary *)message {
    try {
        NSString *operation = message[@"op"];
        if ([operation isEqualToString:@"snapshot"]) return snapshotMessage(self.snapshot());
        if ([operation isEqualToString:@"log"]) {
            NSString *text = message[@"text"];
            if (![text isKindOfClass:NSString.class]) throw std::runtime_error("Invalid script log");
            if (self.output) self.output(text);
            return @{@"ok":@YES};
        }
        if (![operation isEqualToString:@"apply"]) throw std::runtime_error("Unsupported script operation");
        if (!isNumber(message[@"kind"]) || !isNumber(message[@"number"]) || !isNumber(message[@"duration"]) ||
            ![message[@"enabled"] isKindOfClass:NSNumber.class] || ![message[@"text"] isKindOfClass:NSString.class])
            throw std::runtime_error("Invalid script action");
        const double kind = [message[@"kind"] doubleValue];
        if (kind != std::floor(kind) || kind < 0 || kind > static_cast<int>(ScriptActionKind::set_target_selection_mode))
            throw std::runtime_error("Unknown script action");
        if (![message[@"hips"] isKindOfClass:NSArray.class] || [message[@"hips"] count] > 2048)
            throw std::runtime_error("Invalid star identifier list");
        std::vector<std::int32_t> hips;
        for (id identifier in message[@"hips"]) {
            if (!isNumber(identifier) || CFGetTypeID((__bridge CFTypeRef)identifier) == CFBooleanGetTypeID())
                throw std::runtime_error("Invalid star identifier");
            const double hip = [identifier doubleValue];
            if (hip != std::floor(hip) || hip <= 0 || hip > std::numeric_limits<std::int32_t>::max())
                throw std::runtime_error("Invalid star identifier");
            hips.push_back(static_cast<std::int32_t>(hip));
        }
        if ((static_cast<ScriptActionKind>(static_cast<int>(kind)) == ScriptActionKind::set_star_name_membership) != !hips.empty())
            throw std::runtime_error("Unexpected star identifier list");
        ScriptAction action{static_cast<ScriptActionKind>(static_cast<int>(kind)),
            [message[@"number"] doubleValue], static_cast<bool>([message[@"enabled"] boolValue]),
            std::string([message[@"text"] UTF8String]), [message[@"duration"] doubleValue], std::move(hips),
            TerrainAmplification::x1, {}, RadiusScaleMode::keep_orbit};
        if (action.kind == ScriptActionKind::set_target_selection_mode &&
            CFGetTypeID((__bridge CFTypeRef)message[@"number"]) == CFBooleanGetTypeID())
            throw std::runtime_error("Invalid Targets.selectMode");
        if ((action.kind == ScriptActionKind::set_camera_zoom_mode || action.kind == ScriptActionKind::set_target_selection_mode) &&
            (action.number != std::floor(action.number) || action.number < 0 || action.number > 2))
            throw std::runtime_error(action.kind == ScriptActionKind::set_camera_zoom_mode ? "Invalid Camera.zoomMode" : "Invalid Targets.selectMode");
        if ((action.kind == ScriptActionKind::set_camera_fov || action.kind == ScriptActionKind::animate_camera_fov) &&
            (CFGetTypeID((__bridge CFTypeRef)message[@"number"]) == CFBooleanGetTypeID() || action.number <= 0 || action.number > 90))
            throw std::runtime_error("Invalid Camera.fov");
        NSArray *orientation = message[@"orientation"];
        const bool quaternion = action.kind == ScriptActionKind::set_camera_orientation || action.kind == ScriptActionKind::animate_camera_orientation;
        const bool euler = action.kind == ScriptActionKind::set_camera_euler || action.kind == ScriptActionKind::add_camera_euler ||
            action.kind == ScriptActionKind::animate_camera_euler || action.kind == ScriptActionKind::animate_add_camera_euler;
        if (![orientation isKindOfClass:NSArray.class] || orientation.count != (quaternion ? 4u : euler ? 3u : 0u))
            throw std::runtime_error("Invalid camera orientation payload");
        for (NSUInteger index = 0; index < orientation.count; ++index) {
            id value = orientation[index];
            if (!isNumber(value) || CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID())
                throw std::runtime_error("Invalid camera orientation value");
            action.orientation[index] = [value doubleValue];
        }
        NSArray *radiusScale = message[@"radiusScale"];
        if (![radiusScale isKindOfClass:NSArray.class] ||
            radiusScale.count != (action.kind == ScriptActionKind::set_radius_scale ? 4u : 0u))
            throw std::runtime_error("Invalid radius scale payload");
        if (action.kind == ScriptActionKind::set_radius_scale) {
            for (id value in radiusScale)
                if (!isNumber(value) || CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID())
                    throw std::runtime_error("Invalid radius scale value");
            action.radius_display = checked_radius_display_options([radiusScale[0] doubleValue],
                [radiusScale[1] doubleValue], [radiusScale[2] doubleValue], [radiusScale[3] doubleValue]);
        }
        if (action.kind == ScriptActionKind::set_radius_scale_mode) {
            if (CFGetTypeID((__bridge CFTypeRef)message[@"number"]) == CFBooleanGetTypeID() ||
                (action.number != 0 && action.number != 1))
                throw std::runtime_error("Invalid radius scale mode");
            action.radius_scale_mode = static_cast<RadiusScaleMode>(static_cast<int>(action.number));
        }
        if (action.kind == ScriptActionKind::set_terrain_amplification) {
            if (CFGetTypeID((__bridge CFTypeRef)message[@"number"]) == CFBooleanGetTypeID())
                throw std::runtime_error("Invalid terrain amplification");
            action.terrain_amplification = terrain_amplification_from_lua(action.number);
        }
        const bool timeAnimation = action.kind == ScriptActionKind::set_time_animation_jd ||
            action.kind == ScriptActionKind::set_time_animation_calendar;
        if (action.duration_seconds < 0 && !timeAnimation) throw std::runtime_error("Invalid script duration");
        if (timeAnimation && (CFGetTypeID((__bridge CFTypeRef)message[@"number"]) == CFBooleanGetTypeID() ||
            CFGetTypeID((__bridge CFTypeRef)message[@"duration"]) == CFBooleanGetTypeID() ||
            CFGetTypeID((__bridge CFTypeRef)message[@"enabled"]) != CFBooleanGetTypeID()))
            throw std::runtime_error("Invalid Time animation parameters");
        if (action.kind >= ScriptActionKind::set_time_step && action.kind <= ScriptActionKind::step_time_rewind) {
            if (CFGetTypeID((__bridge CFTypeRef)message[@"number"]) == CFBooleanGetTypeID())
                throw std::runtime_error("Invalid Time numeric value");
            if (action.kind == ScriptActionKind::set_time_step &&
                (action.number != std::floor(action.number) || action.number < 0 || action.number > 11))
                throw std::runtime_error("Invalid Time step");
            if (action.kind == ScriptActionKind::set_time_speed) (void)plus_time_speed(action.number);
        }
        NSString *error = nil;
        if (!self.applyAction(action, &error)) return @{@"ok":@NO, @"error":error ? error : @"Host rejected script action"};
        return @{@"ok":@YES};
    } catch (const std::exception& exception) {
        NSString *failure = [NSString stringWithUTF8String:exception.what()];
        return @{@"ok":@NO, @"error":failure ? failure : @"Script action failed"};
    }
}
- (void)cancel {
    NSAssert(NSThread.isMainThread, @"Script UI must run on the main thread");
    if (_job) _job->cancel();
}
- (void)invalidate { _invalidated = YES; [self cancel]; }
- (void)dealloc { if (_job) _job->cancel(); }
@end
