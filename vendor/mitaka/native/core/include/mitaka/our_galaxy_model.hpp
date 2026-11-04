#pragma once

#include "mitaka/galaxy_catalog.hpp"

namespace mitaka {

// 原 xyz の単位は pc。原点/参照面を native J2000 と暗黙に同一視しない。
struct OurGalaxyRawPositionPc { float x_pc, y_pc, z_pc; };
struct OurGalaxyMap {
    std::int32_t width = 0, height = 0;
    std::vector<float> values;
    std::size_t nonfinite_count = 0, outside_unit_interval_count = 0;
};
enum class OurGalaxyPointGroup : std::size_t { disk1, disk2, disk_ob, bulge };
struct OurGalaxyPointCloud {
    std::vector<OurGalaxyRawPositionPc> positions;
    std::size_t nonfinite_count = 0;
};
struct OurGalaxyModel {
    GalaxyCatalogSource source;
    // 入力順: thin disk / dust。8-bit 化、clamp、補間を行わない。
    std::array<OurGalaxyMap, 2> maps;
    std::array<OurGalaxyPointCloud, 4> groups;
};

// 同じローカル bytes が確認された公式 1.3.1 の 2 map +4 群形式。
// dimensions>0、count>=0、全体の map sample/point 数をそれぞれ max_records で制限。
// 構造不正/末尾余剰は原子的に拒否。非有限/範囲外の原値は診断件数付きで保持。
// 旧読取の 512 固定上書きは再現せず、入力 dimensions を尊重する native 契約。
OurGalaxyModel load_our_galaxy_model(const std::filesystem::path& path,
                                    CatalogLoadLimits limits = {});

} // namespace mitaka
