#pragma once

#include "solar_camera.hpp"
#include "local_image.hpp"
#include "earth_layers.hpp"
#include "eclipse_display.hpp"
#include "mitaka/rotation.hpp"
#include <cstddef>
#include <cstdint>
#include <vector>

namespace mitaka::gui {

// 呼び出し中だけtextureを参照する。位置と半径はAU、姿勢はJ2000黄道系。
struct SurfaceSphere {
    const TextureImage& texture;
    Vec3 center;
    BodyOrientation orientation;
    double radius_au;
    bool emissive = false;
    double longitude_offset_turns = 0.5;
    const EarthLayerBinding* earth_layers = nullptr;
    const EclipseSurfaceBinding* eclipse = nullptr;
};

// 球の投影範囲だけを走査し、最も近い正の交点を合成する。配列順には依存しない。
// 中心が画面外・カメラ背面でも見える縁を描く。視点は全ての球の外側が必要。
// viewport・画像・姿勢の検証条件はrender_surface_viewと同じ。
// 地球層のbindingは同じカメラ位置・太陽方向・物理半径を持つ必要がある。
// 夜景は地表へ加算、雲はadditive_outputへ出力する。呼出し側は地表を
// SourceOver、その後additive_outputをRGB加算する。alphaは透過率ではない。
// 可視な雲で出力先がnullなら拒否。例外時の出力先は変更しない。
TextureImage render_surface_scene(const std::vector<SurfaceSphere>& spheres,
                                  const SolarCamera& camera,
                                  std::size_t width, std::size_t height,
                                  TextureImage* additive_output = nullptr);

// 経緯度テクスチャをカメラに正対する模式的な球面へ描く。入力の上端は北極。
// orientationはJ2000黄道で表す天体固定系の右手正規直交基底。
// 自転・軸傾斜はorientationから反映し、照明は慣性系のまま計算する。
// 物理半径・透視による球面の歪みは適用しない。
// 入力alphaは使わず、出力は円盤内255/外0。照明は太陽方向＋環境光0.3。
// longitude_offset_turnsは経度原点の画像内位置。公式画像は火星・太陽0、他0.5。
// emissiveは照明を省略する。非発光体の原点、非有限値、不正な画像寸法・
// byte数、不正な基底、diameterが1..512でない場合はinvalid_argument。
// earth_layers使用時はdiameter/描画矩形をearth_layer_extent倍にする。
// 雲は独立のadditive_outputへ出力し、呼出し側がRGB加算で重ねる。
// 可視な雲がある場合にadditive_outputがnullなら拒否する。失敗時は変更しない。
TextureImage render_planet_surface(const TextureImage& texture, const SolarCamera& camera,
                                  Vec3 body_ecliptic, const BodyOrientation& orientation,
                                  std::size_t diameter,
                                  bool emissive = false, double longitude_offset_turns = 0.5,
                                  const EarthLayerBinding* earth_layers = nullptr,
                                  TextureImage* additive_output = nullptr,
                                  const EclipseSurfaceBinding* eclipse = nullptr);

// 物理半径の球を画面全体へ透視投影する。地表・上空で同じ交点計算を使う。
// 未命中は透明、命中は不透明。width/heightは1..1024、視点は球の外側が必要。
// 色・UV・日照の契約は上と同じ。太陽への着陸用途は扱わない。
TextureImage render_surface_view(const TextureImage& texture, const SolarCamera& camera,
                                 Vec3 body_ecliptic, const BodyOrientation& orientation,
                                 double radius_au, std::size_t width, std::size_t height,
                                 double longitude_offset_turns = 0.5,
                                 const EarthLayerBinding* earth_layers = nullptr,
                                 TextureImage* additive_output = nullptr,
                                 const EclipseSurfaceBinding* eclipse = nullptr);

// 描画と同じ視線・球交点で、カメラから最初の正の交点までのAU距離を返す。
// 未命中はnullopt。視点は球外、半径とviewport寸法は正、入力は有限が必要。
std::optional<double> sphere_hit_distance(const SolarCamera& camera, Vec3 body_ecliptic,
                                          double radius_au, double x, double y,
                                          double width, double height);

} // namespace mitaka::gui
