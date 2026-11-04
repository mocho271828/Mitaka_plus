#pragma once

#include "solar_camera.hpp"
#include "terrain_surface.hpp"
#include <vector>

namespace mitaka::gui {
struct SurfaceSphere;

// 幾何と借用frameの対応を保存する。textureや表示色は深度に影響しない。
struct SurfaceDepthGeometry {
    Vec3 center;
    BodyOrientation orientation;
    double radius_au;
    const TerrainSurfaceFrame* terrain;
};

// 完成後は変更せず、geometry内のframeを存続させて同じsceneに渡す。
// 未被覆は+infinity、被覆は視線に沿った正のAU距離。左上原点。
struct SurfaceDepthFrame {
    std::size_t width = 0, height = 0;
    SolarCamera camera;
    std::vector<SurfaceDepthGeometry> geometry;
    std::vector<double> distances_au;
};

// 地形の数値/shapeを検査する。元requestとの一致はsnapshot所有側の責務。
void validate_surface_terrain(const TerrainSurfaceFrame* terrain, std::size_t width, std::size_t height);
SurfaceDepthFrame make_surface_depth_frame(const std::vector<SurfaceSphere>& spheres,
    const SolarCamera& camera, std::size_t width, std::size_t height, std::vector<double> distances);
void validate_surface_depth_frame(const SurfaceDepthFrame& frame,
    const std::vector<SurfaceSphere>& spheres, const SolarCamera& camera,
    std::size_t width, std::size_t height);
// 色や法線を参照しない後段用。sceneとの対応は呼出側で別途照合する。
void validate_surface_depth_frame(const SurfaceDepthFrame& frame,
    const SolarCamera& camera, std::size_t width, std::size_t height);

// terrainはsphereを代替し、未被覆を基準球で埋めない。frameは事前検査済みが必要。
std::optional<double> surface_opaque_distance(const SurfaceSphere& sphere,
    const SolarCamera& camera, std::size_t x, std::size_t y, std::size_t width, std::size_t height);
} // namespace mitaka::gui
