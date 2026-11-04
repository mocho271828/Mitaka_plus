/*
Copyright (c) 2007-2014   Tsunehiko Kato

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

#include "terrain_mesh.hpp"

#include <algorithm>
#include <cmath>
#include <limits>
#include <stdexcept>

namespace mitaka::gui {
namespace {
constexpr double radians = 3.14159265358979323846 / 180;
bool finite(Vec3 p) { return std::isfinite(p.x) && std::isfinite(p.y) && std::isfinite(p.z); }
Vec3 subtract(Vec3 a, Vec3 b) { return {a.x-b.x,a.y-b.y,a.z-b.z}; }
Vec3 cross(Vec3 a, Vec3 b) { return {a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x}; }
Vec3 normalize(Vec3 p) {
    const double length=std::hypot(p.x,p.y,p.z);
    if (!finite(p) || !std::isfinite(length) || length==0)
        throw std::invalid_argument("terrain normal is degenerate or non-finite");
    return {p.x/length,p.y/length,p.z/length};
}
Vec3 direction(double longitude, double latitude) {
    const double lon=std::remainder(longitude,360.0)*radians, lat=latitude*radians;
    const double c=std::cos(lat);
    return {c*std::cos(lon),c*std::sin(lon),std::sin(lat)};
}
void validate_eye(Vec3 eye) {
    if (!finite(eye) || !std::isfinite(std::hypot(eye.x,eye.y,eye.z)))
        throw std::invalid_argument("terrain eye must have finite coordinates and distance");
}
} // namespace

std::array<std::size_t,3> TerrainPatchMesh::triangle(std::size_t ordinal) const {
    if (ordinal>=triangle_count()) throw std::out_of_range("terrain triangle ordinal");
    const auto cell=ordinal/2, row=cell/columns_, column=cell%columns_;
    const auto top=row*(columns_+1)+column, bottom=top+columns_+1;
    if (ordinal%2==0) return {top,bottom,top+1};
    return {top+1,bottom,bottom+1};
}

TerrainPatchMesh make_terrain_patch_mesh(TerrainFile& source, std::size_t patch_index,
    std::size_t level_index, double elevation_factor, std::size_t max_working_bytes) {
    if (!std::isfinite(elevation_factor) || elevation_factor<0)
        throw std::invalid_argument("terrain elevation factor must be finite and nonnegative");
    const auto& grid=source.read_grid(patch_index,level_index);
    const auto& patch=source.patches().at(patch_index);
    const auto& header=source.header();
    const auto columns=std::size_t(grid.descriptor().columns), rows=std::size_t(grid.descriptor().rows);
    // 寸法はTerrainFileが1..256に検証済み。借用raw gridと別に、派生領域だけを制限する。
    const auto vertex_count=(columns+1)*(rows+1), halo_count=3*(columns+3);
    if (vertex_count*sizeof(TerrainVertex)>max_working_bytes ||
        halo_count*sizeof(Vec3)>max_working_bytes-vertex_count*sizeof(TerrainVertex))
        throw std::invalid_argument("terrain mesh working memory limit exceeded");
    TerrainPatchMesh result;
    result.patch_=patch_index; result.level_=level_index; result.columns_=columns; result.rows_=rows;
    result.vertices_.resize(vertex_count);
    std::array<std::vector<Vec3>,3> halo;
    for (auto& row:halo) row.resize(columns+3);
    const double dlon=double(patch.longitude_end_deg)-patch.longitude_begin_deg;
    const double dlat=double(patch.latitude_end_deg)-patch.latitude_begin_deg;
    const double factor=double(header.elevation_unit_m)/header.radius_m*elevation_factor;
    if (!std::isfinite(factor)) throw std::invalid_argument("terrain radial factor exceeds finite range");
    const auto fill=[&](std::vector<Vec3>& output,int row) {
        const double lat=patch.latitude_begin_deg+dlat*row/double(rows);
        for (int column=-1;column<=int(columns)+1;++column) {
            const double lon=patch.longitude_begin_deg+dlon*column/double(columns);
            const auto n=direction(lon,lat);
            const double radius=1+factor*grid.elevation_units(column,row);
            if (!std::isfinite(radius) || radius<=0)
                throw std::invalid_argument("terrain elevation produces a nonpositive or non-finite radius");
            output[std::size_t(column+1)]={radius*n.x,radius*n.y,radius*n.z};
        }
    };
    fill(halo[0],-1); fill(halo[1],0); fill(halo[2],1);
    for (std::size_t row=0;row<=rows;++row) {
        const double lat=patch.latitude_begin_deg+dlat*double(row)/double(rows);
        for (std::size_t column=0;column<=columns;++column) {
            const double lon=patch.longitude_begin_deg+dlon*double(column)/double(columns);
            const auto position=halo[1][column+1];
            const bool pole=(row==0 && patch.latitude_begin_deg==90) ||
                            (row==rows && patch.latitude_end_deg==-90);
            const auto right=subtract(halo[1][column+2],halo[1][column]);
            const auto down=subtract(halo[2][column+1],halo[0][column+1]);
            const auto normal=pole?normalize(position):normalize(cross(down,right));
            result.vertices_[row*(columns+1)+column]={position,normal,lon/360.0,.5-lat/180.0};
        }
        if (row<rows) {
            halo[0].swap(halo[1]); halo[1].swap(halo[2]); fill(halo[2],int(row)+2);
        }
    }
    source.verify_source_unchanged();
    return result;
}

TerrainSurfaceMode terrain_surface_mode(Vec3 eye) {
    validate_eye(eye);
    const double distance=std::hypot(eye.x,eye.y,eye.z);
    if (distance<=1) return TerrainSurfaceMode::none;
    return 1/distance<std::tan(6*radians)?TerrainSurfaceMode::sphere:TerrainSurfaceMode::terrain;
}

std::size_t terrain_level_index(const TerrainPatch& patch, Vec3 eye, bool low_resolution) {
    validate_eye(eye);
    if (!std::isfinite(patch.longitude_begin_deg) || !std::isfinite(patch.longitude_end_deg) ||
        !std::isfinite(patch.latitude_begin_deg) || !std::isfinite(patch.latitude_end_deg) ||
        patch.longitude_begin_deg>=patch.longitude_end_deg ||
        double(patch.longitude_end_deg)-patch.longitude_begin_deg>360 ||
        patch.latitude_begin_deg>90 || patch.latitude_end_deg<-90 ||
        patch.latitude_begin_deg<=patch.latitude_end_deg ||
        patch.maximum_level_index<0 || patch.maximum_level_index>9)
        throw std::invalid_argument("invalid terrain patch for level selection");
    const double middle_lon=.5*double(patch.longitude_begin_deg)+.5*double(patch.longitude_end_deg);
    const double middle_lat=.5*double(patch.latitude_begin_deg)+.5*double(patch.latitude_end_deg);
    const auto mid=direction(middle_lon,middle_lat), separation=subtract(mid,eye);
    const double distance=std::hypot(separation.x,separation.y,separation.z);
    const double diameter=2*radians*std::max(
        (double(patch.longitude_end_deg)-patch.longitude_begin_deg)*std::cos(middle_lat*radians),
        double(patch.latitude_begin_deg)-patch.latitude_end_deg);
    int level=patch.maximum_level_index;
    for (;level>=0;--level)
        if (diameter/distance>std::ldexp(.13*radians,level)) break;
    if (low_resolution) --level;
    return std::size_t(std::max(0,level));
}

} // namespace mitaka::gui
