/*
Copyright (c) 2007-2014 Tsunehiko Kato

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#include "mitaka/terrain.hpp"

#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace mitaka {

double terrain_elevation_m(const TerrainHeader& header, const TerrainPatch& patch,
                           const TerrainGridWindow& grid, double longitude_deg,
                           double latitude_deg) {
    if (!std::isfinite(longitude_deg) || !std::isfinite(latitude_deg) ||
        !std::isfinite(header.elevation_unit_m) || header.elevation_unit_m <= 0 ||
        !std::isfinite(patch.longitude_begin_deg) || !std::isfinite(patch.longitude_end_deg) ||
        !std::isfinite(patch.latitude_begin_deg) || !std::isfinite(patch.latitude_end_deg) ||
        patch.longitude_begin_deg >= patch.longitude_end_deg ||
        patch.latitude_begin_deg <= patch.latitude_end_deg ||
        longitude_deg < patch.longitude_begin_deg || longitude_deg > patch.longitude_end_deg ||
        latitude_deg > patch.latitude_begin_deg || latitude_deg < patch.latitude_end_deg)
        throw std::invalid_argument("terrain sampling requires coordinates inside a finite patch");
    const auto& descriptor = grid.descriptor();
    if (descriptor.columns < 1 || descriptor.rows < 1)
        throw std::invalid_argument("terrain sampling requires a loaded grid");
    const double x = (longitude_deg - patch.longitude_begin_deg) /
                      (double(patch.longitude_end_deg) - patch.longitude_begin_deg) * descriptor.columns;
    const double y = (patch.latitude_begin_deg - latitude_deg) /
                      (double(patch.latitude_begin_deg) - patch.latitude_end_deg) * descriptor.rows;
    // 両端では最後の有効cellを選び、丸めでhaloに補間を延ばさない。
    const auto column = std::min(static_cast<std::int32_t>(x), descriptor.columns - 1);
    const auto row = std::min(static_cast<std::int32_t>(y), descriptor.rows - 1);
    const double dx = x - column, dy = y - row;
    const double top = (1 - dx) * grid.elevation_units(column, row) +
                       dx * grid.elevation_units(column + 1, row);
    const double bottom = (1 - dx) * grid.elevation_units(column, row + 1) +
                          dx * grid.elevation_units(column + 1, row + 1);
    return header.elevation_unit_m * ((1 - dy) * top + dy * bottom);
}

std::array<double, 3> terrain_surface_point_m(const TerrainHeader& header,
    const TerrainPatch& patch, const TerrainGridWindow& grid, double longitude_deg,
    double latitude_deg, double elevation_factor) {
    if (!std::isfinite(header.radius_m) || header.radius_m <= 0 ||
        !std::isfinite(elevation_factor) || elevation_factor < 0 ||
        latitude_deg < -90 || latitude_deg > 90)
        throw std::invalid_argument("invalid terrain radius, latitude or display factor");
    const double radius = header.radius_m + elevation_factor *
        terrain_elevation_m(header, patch, grid, longitude_deg, latitude_deg);
    if (!std::isfinite(radius) || radius <= 0)
        throw std::invalid_argument("terrain displacement produces an invalid radius");
    constexpr double radians_per_degree = 0.017453292519943295769;
    const double latitude = latitude_deg * radians_per_degree;
    // 極端に大きいが有限なヘッダー経度でも三角関数へ無限大を渡さない。
    const double longitude = std::remainder(longitude_deg, 360.0) * radians_per_degree;
    const double latitude_cosine = std::cos(latitude);
    return {radius * latitude_cosine * std::cos(longitude),
            radius * latitude_cosine * std::sin(longitude), radius * std::sin(latitude)};
}

} // namespace mitaka
