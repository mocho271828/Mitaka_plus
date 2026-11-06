#pragma once

#include "GalaxyRenderer.h"
#include "mitaka/our_galaxy_model.hpp"
#include "mitaka/our_galaxy_radiative.hpp"
#include <cstddef>
#include <functional>
#include <optional>
#include <string>

namespace mitaka::gui {

// 原点・座標軸は未確定のため、使用者が根拠を持つ変換を必ず指定する。
// 各行は raw xyz (pc) から native J2000 黄道 xyz (pc) への線形変換。
struct OurGalaxyTransform {
    std::array<std::array<double, 3>, 3> matrix;
    NativeEclipticPositionPc offset;
};
enum class OurGalaxyPointDisplay { preview, complete };
struct OurGalaxyPointId {
    mitaka::OurGalaxyPointGroup group;
    std::size_t ordinal;
    bool operator==(const OurGalaxyPointId& other) const noexcept {
        return group == other.group && ordinal == other.ordinal;
    }
    bool operator!=(const OurGalaxyPointId& other) const noexcept { return !(*this == other); }
};
struct OurGalaxyPointPick {
    OurGalaxyPointId id;
    NativeEclipticPositionPc position;
    double distance_points;
    double depth_pc;
};

std::size_t our_galaxy_preview_step(std::size_t count) noexcept;
std::optional<NativeEclipticPositionPc> our_galaxy_transformed_position(
    mitaka::OurGalaxyRawPositionPc position, const OurGalaxyTransform& transform);
// 原順 ordinal を保つ。preview の間引きと座標妥当性を確認するが、画面内や吸収は確認しない。
std::optional<NativeEclipticPositionPc> our_galaxy_point_position(
    const mitaka::OurGalaxyModel& model, OurGalaxyPointId id,
    OurGalaxyPointDisplay display, const OurGalaxyTransform& transform);
// complete は対応する放射モデルが必要。alpha と画像世代は呼出側で確認する。
bool our_galaxy_point_visible(const mitaka::OurGalaxyModel& model, OurGalaxyPointId id,
    const OurGalaxyTransform& transform, OurGalaxyPointDisplay display, GalaxyCameraPc camera,
    double width, double height, const mitaka::OurGalaxyRadiativeModel* radiative);
// 画面距離、奥行き、群、原順の順に決定。取消時は部分結果を返さない。
// complete では同一モデルから作成済みの radiative を再利用できる。
// null の場合は候補があるときだけ内部で作成する。
std::optional<OurGalaxyPointPick> pick_our_galaxy_point(
    const mitaka::OurGalaxyModel& model, const OurGalaxyTransform& transform,
    OurGalaxyPointDisplay display, GalaxyCameraPc camera, double width, double height,
    double x, double y, double radius, std::function<bool()> should_cancel = {},
    const mitaka::OurGalaxyRadiativeModel* radiative = nullptr);
struct OurGalaxyPointStyle {
    double red, green, blue, alpha, radius_points;
};
using OurGalaxyStyles = std::array<OurGalaxyPointStyle, 4>;
struct OurGalaxyRenderSettings {
    OurGalaxyTransform transform;
    OurGalaxyStyles styles;
    // 画面等で表示できる採用根拠。空欄は受け付けないが、内容の真偽は検証しない。
    std::string coordinate_provenance;
    std::string color_provenance;
};

// 点群だけを透過画像に描く。色・点の大きさは呼出側が明示する表示設定であり、
// 元データの色情報でも旧 Plus の画素再現でもない。radiative を渡すと
// 公式 1.3.1 の点ごとの吸収を使う。画面では加算合成する。
// 公式 1.3.1 の点群・map・色・座標変換の根拠と Plus への適用限界は
// investigation/native-plus/unit7/n16-galaxy-catalog-contracts.md に記録している。
// 取消時は部分画像を公開せず null を返す。元モデルは変更しない。
std::shared_ptr<const GalaxyBitmap> render_our_galaxy_points(
    const mitaka::OurGalaxyModel& model, const OurGalaxyRenderSettings& settings,
    GalaxyCameraPc camera, RendererDisplayOptions quality,
    double width_points, double height_points, double backing_scale,
    std::function<bool()> should_cancel = {},
    const mitaka::OurGalaxyRadiativeModel* radiative = nullptr, float galaxy_alpha = 1);

} // namespace mitaka::gui
