#pragma once

#include "mitaka/observation.hpp"
#include <vector>

namespace mitaka::gui {

enum class GridCoordinateSystem { equatorial, ecliptic, galactic, horizontal };
using CoordinateGrid = std::vector<std::vector<EquatorialCoordinates>>;

// 各線は J2000 赤道座標の列。経線は南極から北極へ、緯線は経度 0 から一周し、
// 閉曲線の末尾には始点を再掲する。標本間隔は 2 度。極の退化した緯線は省く。
// 赤道・銀河は経線 30 度、地平は方位線 45 度、緯線・高度線は -75..75 度を 15 度刻み。
// 黄道は J2000 黄道面の大円 1 本だけ。旧公式の黄道 5 度標本を GUI では 2 度に細分する。
// 地平以外の結果は frame に依存しない。地平は ObservationFrame の精度・補正範囲に従う。
// 不正な列挙値は std::invalid_argument。線の順序は経線、緯線の順でそれぞれ昇順。
CoordinateGrid make_coordinate_grid(GridCoordinateSystem system, const ObservationFrame& frame);

// 天の川画像と grid が共有する公式 1.3.1 の銀河基底。J2000 赤道系との線形変換。
// 入力を正規化せず、ゼロベクトルも許可する。基底は厳密な正規直交基底ではない。
// 非有限入力は std::invalid_argument、結果の範囲超過は std::out_of_range。
Vec3 galactic_to_j2000_equatorial(Vec3 direction);
Vec3 j2000_equatorial_to_galactic(Vec3 direction);

} // namespace mitaka::gui
