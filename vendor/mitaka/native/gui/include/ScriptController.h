#pragma once
#import <Foundation/Foundation.h>
#include "display_options.hpp"
#include "renderer_options.hpp"
#include "small_body_display.hpp"
#include "satellite_display.hpp"
#include "plus_time_playback.hpp"
#include "plus_time_calendar.hpp"
#include "eclipse_display.hpp"
#include "terrain_amplification.hpp"
#include "radius_display.hpp"
#include <string>
#include <cstdint>
#include <set>
#include <vector>
#include <optional>

namespace mitaka::gui {

struct ScriptSnapshot {
    double julian_date = 2451545.0;
    double rate_seconds_per_second = 1;
    bool playing = false;
    bool clock_tracking = false;
    bool time_info = true;
    PlusTimeState plus_time;
    std::optional<PlusTimeZone> plus_time_zone;
    std::string target = "Sun";
    double camera_distance_au = 100;
    bool constellation_lines = false;
    bool constellation_boundaries = false;
    bool constellation_labels = false;
    bool constellation_illustrations = false;
    std::set<std::int32_t> selected_star_names;
    PlanetDisplayOptions planets;
    TerrainAmplification terrain_amplification = TerrainAmplification::x1;
    RadiusDisplayOptions radius_display;
    RadiusScaleMode radius_scale_mode = RadiusScaleMode::keep_orbit;
    EclipseDisplayOptions eclipse;
    bool landscape = true;
    bool earth_clouds = true;
    bool earth_city_lights = false;
    int atmosphere_mode = 2;
    StarDisplayOptions stars;
    GridDisplayOptions grids;
    RendererDisplayOptions renderer;
    SmallBodyKindDisplayOptions asteroids, tnobjects, comets;
    SatelliteDisplayOptions satellites;
    std::string milky_way_type = "None";
    bool nebulae = false;
    bool distant_galaxies = false;
    bool quasars = false;
    double camera_azimuth_deg = 180;
    bool target_browser = false;
    bool time_setting = false;
    bool place_setting = false;
    bool script_output = false;
    bool dual_screen = false;
    bool full_screen = false;
};

enum class ScriptActionKind {
    set_date, set_rate, stop, select_target, set_camera_distance,
    set_constellation_lines, set_constellation_boundaries, set_constellation_labels,
    set_star_labels, set_nebulae, set_distant_galaxies, set_quasars, set_camera_azimuth,
    set_target_browser, set_time_setting, set_place_setting, set_script_output,
    set_dual_screen, save_image_dialog,
    set_clock_tracking, set_time_info, set_milky_way_type, set_star_marking,
    set_stars_visible, set_bayer_labels, set_flamsteed_labels, set_hip_labels,
    set_planets_visible, set_planet_labels, set_planet_orbits, set_planet_axes,
    set_equatorial_grid, set_ecliptic_grid, set_galactic_grid, set_horizontal_grid,
    set_circle_scales, set_square_scales,
    set_antialias, set_point_smoothing, set_line_smoothing, set_text_smoothing,
    set_full_screen, toggle_full_screen, show_about,
    set_asteroids_visible, set_asteroids_labels, set_asteroids_orbits, set_asteroids_selected_only,
    set_tnobjects_visible, set_tnobjects_labels, set_tnobjects_orbits, set_tnobjects_selected_only,
    set_comets_visible, set_comets_labels, set_comets_orbits, set_comets_selected_only,
    set_satellites_visible, set_satellites_labels, set_satellites_orbits, set_satellites_selected_only,
    set_star_brightness, brighten_stars, darken_stars, default_star_brightness, animate_star_brightness,
    set_constellation_illustrations, set_selected_star_labels,
    set_star_name_membership, set_all_star_names_selected,
    set_earth_clouds, set_earth_city_lights, set_atmosphere_mode,
    set_time_step, set_time_step_value, set_time_speed,
    previous_time_step, next_time_step, step_time_forward, step_time_rewind,
    set_shadows, set_shadow_borders, set_shadow_umbra, set_shadow_penumbra, set_landscape,
    set_time_animation_jd, set_time_animation_calendar, set_terrain_amplification,
    set_radius_scale, set_radius_scale_mode
};
struct ScriptAction {
    ScriptActionKind kind;
    double number = 0;
    bool enabled = false;
    std::string text;
    double duration_seconds = 0;
    std::vector<std::int32_t> hips{};
    TerrainAmplification terrain_amplification = TerrainAmplification::x1;
    RadiusDisplayOptions radius_display;
    RadiusScaleMode radius_scale_mode = RadiusScaleMode::keep_orbit;
};

} // namespace mitaka::gui

// 全公開メソッドとコールバックはメインスレッド。Lua は専用プロセスで実行する。
@interface ScriptController : NSObject
@property(nonatomic, readonly) BOOL running;
// dofile / require / io の相対パス基準。未指定時は選択したファイルの親。
@property(nonatomic, copy) NSURL *workingDirectoryURL;
@property(nonatomic, copy) mitaka::gui::ScriptSnapshot (^snapshot)(void);
@property(nonatomic, copy) BOOL (^applyAction)(const mitaka::gui::ScriptAction& action, NSString **error);
@property(nonatomic, copy) void (^output)(NSString *text);
@property(nonatomic, copy) void (^completion)(BOOL succeeded, NSString *message);
// 明示的に選んだ信頼済みローカルファイルだけを渡す。元データフォルダから自動実行しない。
- (BOOL)runFile:(NSURL *)file error:(NSError **)error;
// 明示的に信頼されたローカル HTML 等の UTF-8 ソース。元ファイルへの書込みは行わない。
- (BOOL)runSource:(NSString *)source error:(NSError **)error;
// テスト・別配置ビルド向け。通常は init で同一bundleの MitakaScript を使用する。
- (instancetype)initWithHelperURL:(NSURL *)helperURL;
- (void)cancel;
- (void)invalidate;
@end
