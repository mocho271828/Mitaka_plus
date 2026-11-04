#include "grid_geometry.hpp"

#include <cmath>
#include <stdexcept>
#include <utility>

namespace mitaka::gui {
namespace {
constexpr int sample_step_deg = 2;

Vec3 cross(Vec3 a, Vec3 b) {
    return {a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x};
}
double dot(Vec3 a, Vec3 b) { return a.x * b.x + a.y * b.y + a.z * b.z; }
bool finite(Vec3 value) {
    return std::isfinite(value.x) && std::isfinite(value.y) && std::isfinite(value.z);
}
void require_finite(Vec3 value) {
    if (!finite(value)) throw std::invalid_argument("non-finite Galactic transform input");
}
Vec3 finite_result(Vec3 value) {
    if (!finite(value)) throw std::out_of_range("Galactic transform result exceeds numeric range");
    return value;
}

// sky_background.mm から抽出。公式 astrometry.cpp の GC/GN と同じ基底を共有し、
// 赤道方向へ黄道変換を重ねない。由来は local-rendering-audit.md の grid 契約を参照。
struct GalacticBasis {
    const Vec3 center = equatorial_direction({(17 + 45 / 60.0 + 40.0383 / 3600.0) * 15,
                                             -(29 + 28.069 / 3600.0)});
    const Vec3 north = equatorial_direction({(12 + 51 / 60.0 + 24 / 3600.0) * 15,
                                            27 + 8 / 60.0});
    const Vec3 east = cross(north, center);
    const Vec3 inverse_x = cross(east, north);
    const Vec3 inverse_y = cross(north, center);
    const Vec3 inverse_z = cross(center, east);
    const double determinant = dot(center, inverse_x);
};
const GalacticBasis& basis() {
    // 公式の GC/GN は厳密に直交しないため、転置でなく実際の逆行列を使う。
    static const GalacticBasis value;
    return value;
}

EquatorialCoordinates grid_point(GridCoordinateSystem system, double longitude,
                                 double latitude, const ObservationFrame& frame) {
    switch (system) {
        case GridCoordinateSystem::equatorial: return {longitude, latitude};
        case GridCoordinateSystem::ecliptic:
            return equatorial_coordinates(j2000_ecliptic_to_equatorial(equatorial_direction({longitude, latitude})));
        case GridCoordinateSystem::galactic:
            return equatorial_coordinates(galactic_to_j2000_equatorial(equatorial_direction({longitude, latitude})));
        case GridCoordinateSystem::horizontal: return frame.to_equatorial({longitude, latitude});
    }
    throw std::invalid_argument("invalid grid coordinate system");
}
} // namespace

Vec3 galactic_to_j2000_equatorial(Vec3 direction) {
    require_finite(direction);
    const auto& axes = basis();
    return finite_result({axes.center.x * direction.x + axes.east.x * direction.y + axes.north.x * direction.z,
                          axes.center.y * direction.x + axes.east.y * direction.y + axes.north.y * direction.z,
                          axes.center.z * direction.x + axes.east.z * direction.y + axes.north.z * direction.z});
}

Vec3 j2000_equatorial_to_galactic(Vec3 direction) {
    require_finite(direction);
    const auto& axes = basis();
    return finite_result({dot(axes.inverse_x, direction) / axes.determinant,
                          dot(axes.inverse_y, direction) / axes.determinant,
                          dot(axes.inverse_z, direction) / axes.determinant});
}

CoordinateGrid make_coordinate_grid(GridCoordinateSystem system, const ObservationFrame& frame) {
    int meridian_step;
    switch (system) {
        case GridCoordinateSystem::equatorial:
        case GridCoordinateSystem::galactic: meridian_step = 30; break;
        case GridCoordinateSystem::horizontal: meridian_step = 45; break;
        case GridCoordinateSystem::ecliptic: meridian_step = 0; break;
        default: throw std::invalid_argument("invalid grid coordinate system");
    }

    CoordinateGrid grid;
    grid.reserve(meridian_step == 0 ? 1 : 360 / meridian_step + 11);
    if (meridian_step != 0) {
        for (int longitude = 0; longitude < 360; longitude += meridian_step) {
            std::vector<EquatorialCoordinates> line;
            line.reserve(180 / sample_step_deg + 1);
            for (int latitude = -90; latitude <= 90; latitude += sample_step_deg)
                line.push_back(grid_point(system, longitude, latitude, frame));
            grid.push_back(std::move(line));
        }
    }

    const int first_latitude = meridian_step == 0 ? 0 : -75;
    const int last_latitude = meridian_step == 0 ? 0 : 75;
    for (int latitude = first_latitude; latitude <= last_latitude; latitude += 15) {
        std::vector<EquatorialCoordinates> line;
        line.reserve(360 / sample_step_deg + 1);
        for (int longitude = 0; longitude < 360; longitude += sample_step_deg)
            line.push_back(grid_point(system, longitude, latitude, frame));
        // 始点を再利用し、浮動小数点の丸めによる一周後の隙間を作らない。
        line.push_back(line.front());
        grid.push_back(std::move(line));
    }
    return grid;
}

} // namespace mitaka::gui
