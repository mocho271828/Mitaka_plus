#pragma once

#include "sky_model.hpp"
#include "solar_camera.hpp"
#include <cstddef>
#include <optional>

namespace mitaka::gui {

inline constexpr double astronomical_unit_km = 149597870.7;
inline constexpr double minimum_surface_height_km = 0.002;

struct SurfaceBodyInfo {
    double radius_km;
    bool gas_reference_surface;
};

// SolarBodiesの添字。太陽0は拒否し、地球3/月10を含む公式1.3.1の基準半径を返す。
SurfaceBodyInfo surface_body_info(std::size_t body_index);

struct SurfaceSite {
    std::size_t body_index = 3;
    double latitude_deg = 0;
    double longitude_deg = 0;
    double height_km = minimum_surface_height_km;
    double heading_deg = 0; // 北0、東90。
    double elevation_deg = 0; // 地平線0、天頂90。
};

class SurfaceNavigation {
public:
    const SurfaceSite& site() const noexcept { return site_; }
    // 緯度±90、仰角±89、高度[0.002,1e9]km。経度/方位は周期化する。
    // 不正入力はinvalid_argumentで状態を保持。設定成功時は飛行を止める。
    void set_site(SurfaceSite site);
    // 同一日時の天体中心と姿勢から地表固定ENUカメラを再計算する。
    SolarCamera camera(const SolarBodies& bodies) const;
    // 実時間3秒、半径8倍の高度/仰角-80度と、2m/仰角0度の間を移動。
    void begin_ascent(double monotonic_seconds);
    void begin_descent(double monotonic_seconds);
    // >1秒の空白、時計逆行、非有限時計は現在位置を保って中断する。
    // 戻り値は視点が変化したか。開始時の非有限時計はinvalid_argument。
    bool advance(double monotonic_seconds);
    void interrupt() noexcept { flight_.reset(); }
    bool flying() const noexcept { return flight_.has_value(); }
    void look(double dx_points, double dy_points);
    void zoom(double logarithmic_delta);

private:
    struct Flight {
        double start_time, previous_time, start_height, end_height;
        double start_elevation, end_elevation;
    };
    void begin_flight(double time, double height, double elevation);
    SurfaceSite site_;
    std::optional<Flight> flight_;
};

} // namespace mitaka::gui
