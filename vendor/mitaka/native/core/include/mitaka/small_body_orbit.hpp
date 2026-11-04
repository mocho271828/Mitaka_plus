#pragma once

#include "mitaka/astronomy.hpp"

namespace mitaka {

// 日心二体近似。q は AU、時刻は同一時系の JD、角度は度。
// 参照面は呼び出し側が明示する。摂動・非重力加速度・時系変換は含まない。
struct PerihelionElements {
    double perihelion_distance_au;
    double eccentricity;
    double perihelion_jd;
    double ascending_node_deg;
    double inclination_deg;
    double argument_of_perihelion_deg;
};

// 楕円・双曲線は既存 orbital_state、放物線は Barker 方程式を用いる。
// 不正値は invalid_argument、範囲超過は out_of_range、非収束は runtime_error。
OrbitalState perihelion_orbital_state(const PerihelionElements& elements, double julian_date);

} // namespace mitaka
