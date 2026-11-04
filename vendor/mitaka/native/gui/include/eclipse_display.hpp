#pragma once

#include "mitaka/eclipse.hpp"
#include "sky_model.hpp"
#include <array>
#include <optional>
#include <string>
#include <vector>

namespace mitaka::gui {
struct SatelliteSnapshot;

// Plus の画像内初期値。四つのフラグは相互に独立し、設定スクリプトで変更できる。
struct EclipseDisplayOptions {
    bool shadows = true;
    bool shadow_borders = false;
    bool shadow_umbra = false;
    bool shadow_penumbra = false;
};

// 幾何は同一 JD の日心 J2000 黄道 AU。値を所有し、snapshot を借用しない。
// disjoint な球・有限正半径が必要。core が未対応の円柱等は例外で拒否する。
class EclipseSurfaceBinding {
public:
    EclipseSurfaceBinding(EclipseSphere sun, EclipseSphere receiver,
        std::vector<EclipseSphere> occluders, EclipseDisplayOptions options,
        std::array<double,3> shadow_rgb = {0,0,0});
    const EclipseSphere& receiver() const noexcept { return receiver_; }
    struct Effect {
        std::array<double,3> multiplier{1,1,1};
        std::optional<std::array<double,3>> border_rgb;
    };
    // 法線は慣性系の単位ベクトル。footprint は境界線半幅の物理 AU。
    // 線幅は native raster 用で、原版 GL 線分のピクセル一致を主張しない。
    Effect effect(Vec3 normal_unit, double footprint_au) const;
    // 地形の実交点用。基準球との円錐交差だけでは高い地形を除外しない。
    Effect effect_at(Vec3 point_au, Vec3 normal_unit, double footprint_au) const;
    bool active() const noexcept { return !casters_.empty(); }
private:
    struct Caster { EclipseSphere sphere; EclipseShadowCones cones; };
    EclipseSphere sun_, receiver_;
    EclipseDisplayOptions options_;
    std::array<double,3> shadow_rgb_;
    std::vector<Caster> casters_;
    std::vector<Caster> point_casters_;
};

struct EclipseDisplayFrame {
    // SolarBodies と同数・同順。幾何不正・未解決の項目を他出典で補完しない。
    std::array<std::optional<EclipseSurfaceBinding>,11> surfaces;
    std::optional<EclipseGeometry> earth_moon_space;
    std::vector<std::string> diagnostics;
};
// bodies は呼出側が julian_date と同じ時刻に揃える。衛星は追加で snapshot JD、
// 登録根拠・原行 ID・位置・表示親位置一致を確認し、1出典だけを使用する。
// Earth/Moon は既存の物理半径、木星の遮蔽衛星はその出典の Radius(km) を使う。
EclipseDisplayFrame make_eclipse_display_frame(const SolarBodies& bodies, double julian_date,
    const SatelliteSnapshot* satellites, EclipseDisplayOptions options);

} // namespace mitaka::gui
