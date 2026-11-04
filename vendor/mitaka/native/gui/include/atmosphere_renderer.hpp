#pragma once

#include "planet_surface.hpp"
#include "mitaka/atmosphere.hpp"

namespace mitaka::gui {

// 原 Plus の Planets.atmosphere と同じ三状態。個々の天体の切替ではない。
enum class AtmosphereMode { none, single, multiple };
struct AtmosphereDisplayOptions {
    AtmosphereMode mode = AtmosphereMode::multiple;
    double intensity = 6;
};
void validate_atmosphere_display(const AtmosphereDisplayOptions& options);

// 同じ SurfaceSphere 配列の物理球へ結合する。呼出し中だけ map を借用する。
// single.incident_intensity は options.intensity に置換する。multiple は独立した
// 半径/密度を保持し、null なら multiple モードでも単一散乱だけを描く。
struct AtmosphereLayer {
    std::size_t surface_index;
    AtmosphereParameters single;
    const AtmosphereEmissionMap* multiple = nullptr;
};

// 公式通常描画のパラメータ。Earth は公式固定半径、Mars は実天体半径を受ける。
AtmosphereParameters earth_atmosphere_parameters();
AtmosphereParameters mars_atmosphere_parameters(double ground_radius_m);

// 透視投影の同一視線で最も手前の不透明球まで積分する。模式的な最小マーカー
// には適用しない。位置/表示半径は AU、core へは単一散乱の地表半径を基準に m
// へ変換する。視点がいずれかの不透明球上/内部なら全画素ゼロ。
// width/height は 1..1024。出力は左上原点で、RGB を PlusLighter により加算する。
// 非ゼロ画素の alpha=255 は RGB の二重減衰を防ぐためで、透過率ではない。
TextureImage render_atmosphere_scene(const std::vector<SurfaceSphere>& spheres,
    const std::vector<AtmosphereLayer>& layers, const SolarCamera& camera,
    std::size_t width, std::size_t height, AtmosphereDisplayOptions options = {});

} // namespace mitaka::gui
