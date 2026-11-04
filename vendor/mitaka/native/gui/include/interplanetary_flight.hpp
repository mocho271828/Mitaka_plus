#pragma once

#include "surface_navigation.hpp"
#include <vector>

namespace mitaka::gui {

enum class FlightPhase { idle, ascent, cruise, descent, completed, interrupted };
enum class FlightStopReason { none, user, clock_discontinuity, collision };

// 実時間24秒の幾何航行。公転・自転は呼出側が渡す同一日時の bodies に従う。
// 推進・重力積分ではなく、実半径の球を避ける表示用の経路である。
class InterplanetaryFlight {
public:
    void begin(SurfaceSite departure, SurfaceSite destination,
               const SolarBodies& bodies, double monotonic_seconds);
    // 中断位置や自由視点から開始する。最初の位置・姿勢は引数と一致する。
    void begin_from_camera(const SolarCamera& camera, SurfaceSite destination,
                           const SolarBodies& bodies, double monotonic_seconds);
    // >1秒の空白・逆行・非有限時計では最後のカメラを保持して中断する。
    // 不正な bodies は invalid_argument とし、前状態を変更しない。
    // 同じ時計値で呼ぶ場合も、移動した天体中心・自転に追従する。
    bool advance(double monotonic_seconds, const SolarBodies& bodies);
    void interrupt() noexcept;

    const SolarCamera& camera() const noexcept { return camera_; }
    const SurfaceSite& destination() const noexcept { return destination_; }
    FlightPhase phase() const noexcept { return phase_; }
    FlightStopReason stop_reason() const noexcept { return stop_reason_; }
    bool flying() const noexcept;
    bool completed() const noexcept { return phase_ == FlightPhase::completed; }
    double progress() const noexcept { return elapsed_ / duration_seconds; }
    static constexpr double duration_seconds = 24;

private:
    void start(std::optional<SurfaceSite> departure, const SolarCamera& camera,
               SurfaceSite destination, const SolarBodies& bodies, double time);
    SolarCamera evaluate(double elapsed, const SolarBodies& bodies) const;
    SolarCamera cruise_camera(double fraction, const SolarBodies& bodies) const;
    void prepare_cruise(const SolarBodies& bodies);
    struct RoutePoint { double fraction; Vec3 offset; };
    std::optional<SurfaceSite> departure_;
    SurfaceSite destination_;
    SolarCamera start_camera_;
    SolarCamera camera_;
    Vec3 route_normal_{0, 0, 1};
    std::optional<SolarCameraBasis> cruise_rotation_;
    std::vector<RoutePoint> route_;
    double elapsed_ = 0;
    double previous_time_ = 0;
    FlightPhase phase_ = FlightPhase::idle;
    FlightStopReason stop_reason_ = FlightStopReason::none;
};

} // namespace mitaka::gui
