#pragma once

namespace mitaka::gui {

enum class Body;

enum class RadiusDisplayContext { space, planetarium };
enum class RadiusScaleMode { keep_radius = 0, keep_orbit = 1 };

// 旧 Plus 実行版の setScale/getScale 順。同梱 HTML の引数名とは順番が異なる。
struct RadiusDisplayOptions {
    float space_planet = 1;
    float space_sun = 1;
    float planetarium_planet = 1;
    float planetarium_sun_moon = 1;
};

// native は正の有限 float に限定する。旧版の無検証な入力受入れは再現しない。
float checked_radius_scale(double value);
RadiusDisplayOptions checked_radius_display_options(double space_planet, double space_sun,
    double planetarium_planet, double planetarium_sun_moon);
void validate_radius_display_options(const RadiusDisplayOptions& options);
void validate_radius_scale_mode(RadiusScaleMode mode);

// response は選択した原本の Radius 第3値（省略時 1）。別言語の値で上書きしない。
// 物理半径、扁平率、位置、カメラには作用しない。非正・非有限の計算結果は拒否する。
double planet_radius_display_factor(const RadiusDisplayOptions& options,
    RadiusDisplayContext context, float response = 1);
double sun_radius_display_factor(const RadiusDisplayOptions& options,
    RadiusDisplayContext context);

// 旧 Moon 半径 getter の式。planetarium では別途拡大された月軌道との組合せを前提とする。
// 角度表示へこの値だけを適用して旧版互換とはしない。他の衛星の半径倍率は 1。
double moon_radius_display_factor(const RadiusDisplayOptions& options,
    RadiusDisplayContext context);
double moon_orbit_display_factor(const RadiusDisplayOptions& options);

// 模式マーカー用。月の角度表示は月軌道と半径の共通倍率が打ち消される。
// 惑星 response が未確定のため、この表示経路では 1 を用いる。
double body_marker_display_factor(const RadiusDisplayOptions& options,
    RadiusDisplayContext context, Body body);

// 単位は呼出側で揃える。戻り値だけが表示用であり、入力の物理半径は不変。
double scaled_display_radius(double physical_radius, double display_factor);

} // namespace mitaka::gui
