#pragma once

#include "sky_model.hpp"
#include "solar_camera.hpp"
#include "surface_navigation.hpp"
#include "horizon_viewport.hpp"
#include "calendar_time.hpp"
#include "sky_background.hpp"
#include "display_options.hpp"
#include "renderer_options.hpp"
#include "session_layers.hpp"
#include "earth_layers.hpp"
#include "atmosphere_renderer.hpp"
#include "eclipse_display.hpp"
#include "plus_time_playback.hpp"
#include "plus_time_calendar.hpp"
#include "terrain_amplification.hpp"
#include "radius_display.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <set>
#include <string>
#include <string_view>

namespace mitaka::gui {

constexpr std::size_t maximum_session_state_bytes = 1024 * 1024;

// 再生設定は保存するが、復元時は停止する。飛行・外部ファイルの実行状態は持ち込まない。
struct SessionState {
    std::uint32_t version = 9;
    double julian_date = 2451545;
    double simulation_rate = 3600;
    int mode = 0;
    double magnitude_limit = 6.5;
    SkyViewport sky_viewport;
    HorizonViewport horizon_viewport;
    SolarCamera solar_camera;
    // 停止中の地表を復元するときは、この地表固定座標がカメラ位置・姿勢に優先する。
    std::optional<SurfaceSite> surface_site;
    Body selected_body = Body::sun;
    std::optional<Body> sky_selected_body;
    std::optional<Body> horizon_selected_body;
    ConstellationDisplayOptions constellations;
    PlanetDisplayOptions planets;
    RadiusDisplayOptions radius_display;
    RadiusScaleMode radius_scale_mode = RadiusScaleMode::keep_orbit;
    TerrainAmplification terrain_amplification = TerrainAmplification::x1;
    StarDisplayOptions stars;
    std::set<std::int32_t> selected_star_name_hips;
    EarthLayerOptions earth_layers;
    AtmosphereDisplayOptions atmosphere;
    EclipseDisplayOptions eclipse;
    GridDisplayOptions grids;
    RendererDisplayOptions renderer;
    bool show_time_info = true;
    bool show_nebulae = false;
    bool show_galaxies = false;
    bool show_quasars = false;
    MilkyWayMode milky_way_mode = MilkyWayMode::none;
    TimeSettings time_settings;
    PlusTimeState plus_time;
    std::optional<PlusTimeZone> plus_time_zone;
    bool show_landscape_image = true;
    std::string observer_place_identifier;
    SmallBodySessionDisplay small_bodies;
    SatelliteSessionDisplay satellites;
    SpacecraftSessionDisplay spacecraft;
    double observer_latitude_deg = 35.68;
    double observer_longitude_deg = 139.76;
};

// 全項目の型・範囲を検証してから返す。JD のデータ固有有効範囲は適用側で検証する。
// 未対応version、欠落、null、型/範囲違反、サイズ超過、不正JSONは invalid_argument。
// frame、天球/地平の未選択天体、未設定のplus_time_zoneはnullを許容する。
// 地方時の初期値は推測しない。未知のキーはコードとして評価しない。
SessionState decode_session_state(std::string_view json);

// 同じ検証を行い、整形済みUTF-8 JSONを返す。ファイルI/Oや状態の変更は行わない。
std::string encode_session_state(const SessionState& state);

} // namespace mitaka::gui
