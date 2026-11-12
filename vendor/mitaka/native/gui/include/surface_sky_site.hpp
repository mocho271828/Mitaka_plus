#pragma once

#include "surface_navigation.hpp"
#include <cmath>
#include <stdexcept>

namespace mitaka::gui {

// 星空の方位・姿勢を復元するコピーだけを、同じ動径上の基準球外へ移す。
inline SurfaceSite surface_sky_site_from_camera(const SolarCamera& camera, const SolarBodies& bodies,
                                                std::size_t body_index) {
    const auto& body = bodies.at(body_index);
    const auto basis = solar_camera_basis(camera);
    const auto center = j2000_equatorial_to_ecliptic(body.position_au);
    const Vec3 radial{camera.target.x + basis.outward.x * camera.distance_au - center.x,
                      camera.target.y + basis.outward.y * camera.distance_au - center.y,
                      camera.target.z + basis.outward.z * camera.distance_au - center.z};
    const double distance = std::hypot(radial.x, radial.y, radial.z);
    if (!std::isfinite(distance) || distance <= 0) throw std::invalid_argument("invalid sky camera position");
    SolarCamera sky_camera = camera;
    const double safe_radius = (surface_body_info(body_index).radius_km + minimum_surface_height_km + 0.001)
                               / astronomical_unit_km;
    if (distance < safe_radius) {
        const double shift = (safe_radius - distance) / distance;
        sky_camera.translate_target_au({radial.x * shift, radial.y * shift, radial.z * shift});
    }
    return surface_site_from_camera_with_roll(sky_camera, bodies, body_index);
}

} // namespace mitaka::gui
