#pragma once

#include "mitaka/our_galaxy_model.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace mitaka {

struct OurGalaxyRgb { float r, g, b; };
struct OurGalaxyGalacticVector { float x, y, z; };
struct OurGalaxyRadiativeResult {
    OurGalaxyRgb intensity{0, 0, 0};
    OurGalaxyRgb transmittance{1, 1, 1};
    float optical_depth = 0;
    std::size_t steps = 0;
};
struct OurGalaxyPointExtinction {
    float optical_depth = 0;
    OurGalaxyRgb transmittance{1, 1, 1};
    std::size_t steps = 0;
    bool visible = true;
};

// 銀河中心を原点とする pc と方向。方向は内部で正規化する。
// 公式 1.3.1 に基づく固定光線のみ。旧 Plus との同一性・実画面は未検証。
class OurGalaxyRadiativeModel {
public:
    explicit OurGalaxyRadiativeModel(const OurGalaxyModel& source);
    OurGalaxyRadiativeResult trace(OurGalaxyGalacticVector origin_pc,
                                   OurGalaxyGalacticVector direction,
                                   float step_pc = 40.0f) const;
    // 点光源の吸収は公式の別式に従う。両端は銀河中心原点の pc。
    OurGalaxyPointExtinction point_extinction(OurGalaxyGalacticVector observer_pc,
                                              OurGalaxyGalacticVector point_pc,
                                              float step_pc = 40.0f) const;
    std::array<float, 2> modulation(float x_pc, float y_pc) const;
private:
    std::array<std::vector<std::uint8_t>, 2> maps_;
};

// RGB 別の透過率を保持する。描画順・色空間・出力の clamp は呼び出し元の責任。
OurGalaxyRgb compose_our_galaxy(OurGalaxyRgb background,
                                const OurGalaxyRadiativeResult& ray,
                                float alpha);

} // namespace mitaka
