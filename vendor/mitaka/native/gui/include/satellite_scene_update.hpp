#pragma once
#include "satellite_display.hpp"
#include "satellite_orbit_geometry.hpp"
#include <utility>

namespace mitaka::gui {
// 検証と軌道生成が完了した値だけを日時更新の公開処理に渡す。
class PreparedSatelliteScene {
public:
    const std::shared_ptr<const SatelliteSnapshot>& snapshot() const noexcept { return snapshot_; }
    const std::shared_ptr<const SatelliteDisplayModel>& display() const noexcept { return display_; }
    const std::shared_ptr<const SatelliteOrbitGeometry>& orbits() const noexcept { return orbits_; }

private:
    friend PreparedSatelliteScene prepare_satellite_scene(
        std::shared_ptr<const SatelliteSnapshot>, std::shared_ptr<const SatelliteDisplayModel>);
    PreparedSatelliteScene(std::shared_ptr<const SatelliteSnapshot> snapshot,
                           std::shared_ptr<const SatelliteDisplayModel> display,
                           std::shared_ptr<const SatelliteOrbitGeometry> orbits)
        : snapshot_(std::move(snapshot)), display_(std::move(display)), orbits_(std::move(orbits)) {}
    std::shared_ptr<const SatelliteSnapshot> snapshot_;
    std::shared_ptr<const SatelliteDisplayModel> display_;
    std::shared_ptr<const SatelliteOrbitGeometry> orbits_;
};

// display が null のときは snapshot に適合する既定の表示モデルを用意する。
PreparedSatelliteScene prepare_satellite_scene(
    std::shared_ptr<const SatelliteSnapshot> snapshot,
    std::shared_ptr<const SatelliteDisplayModel> display);
} // namespace mitaka::gui
