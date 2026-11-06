#pragma once

#include "mitaka/astronomy.hpp"
#include "mitaka/catalog.hpp"
#include "mitaka/ephemeris.hpp"
#include "mitaka/rotation.hpp"

#include <array>
#include <cstddef>
#include <filesystem>
#include <optional>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

namespace mitaka::gui {

enum class Body { sun, mercury, venus, mars, jupiter, saturn, uranus, neptune, pluto,
                  earth, moon };

struct SkyBody {
    Body id;
    EquatorialCoordinates coordinates;
    double distance_au;
};

using SkyBodies = std::array<SkyBody, 10>;

struct SolarBody {
    Body id;
    Vec3 position_au;
    BodyOrientation orientation{};
};
using SolarBodies = std::array<SolarBody, 11>;
using SolarOrbits = std::array<std::vector<Vec3>, 9>;

class SkyModel {
public:
    // hip.dat と cf96.dat が直下にあるディレクトリを読み取り専用で開く。
    // HIP を全件保持し、不正な赤緯・9惑星が揃わない暦表・月との共通時刻範囲なしは拒否する。
    static SkyModel load(const std::filesystem::path& data_directory);
    // カタログ方向を固定して扱い、固有運動・年周視差は適用しない。
    const std::vector<HipparcosRecord>& stars() const noexcept { return stars_; }
    // constellation_HIP.dat は任意。存在するが破損している場合は読込全体を失敗させる。
    const std::vector<ConstellationRecord>& constellations() const noexcept { return constellations_; }
    std::optional<std::size_t> star_index(std::int32_t hip) const noexcept;
    const std::string& constellation_warning() const noexcept { return constellation_warning_; }
    std::pair<double, double> time_range() const noexcept { return time_range_; }
    // 衛星の絶対位置は地月補正前の親を必要とする。読取済み同一暦表を共有する。
    const Cf96Ephemeris& ephemeris() const noexcept { return ephemeris_; }

    // CF96 と月計算に同じ JD を渡す。地心から見た J2000 赤道幾何方向と距離 AU。
    // 太陽、水金火木土天海冥、月の順。地球を除外し、冥王星は衛星系の重心。
    // 地球は CF96 の地球・月重心を質量比で補正。光行差・光行時間・歳差章動は未適用。
    SkyBodies bodies(double julian_date) const;

    // 太陽中心 J2000 赤道座標、AU。太陽、水金地火木土天海冥、月の順。
    // 冥王星は衛星系の重心。太陽は原点。時刻契約は bodies() と同じ。
    // 姿勢は同じ JD の公式1.3.1モデル、J2000黄道の基底。太陽のみ固定姿勢。
    SolarBodies solar_bodies(double julian_date) const;
    // 9惑星の可視化用軌跡。指定JDを中心とする近似1公転期間を181点で標本化。
    // 共通有効時刻範囲で切り取り、閉曲線にはしない。位置は上と同じ座標系・単位。
    // 地球の各標本も、その JD の地球・月重心補正を適用する。
    SolarOrbits solar_orbits(double julian_date) const;
    // 月の可視化用軌跡。約1公転の181点を共通有効時刻範囲で切り取り、閉じない。
    // J2000 赤道座標、AU の地心相対位置。太陽中心の軌跡ではない。
    // 描画時に表示日時の地球位置を全点へ加え、地球と一緒に移動させる。
    std::vector<Vec3> lunar_orbit(double julian_date) const;

private:
    SkyModel(std::vector<HipparcosRecord> stars, std::vector<ConstellationRecord> constellations,
             Cf96Ephemeris ephemeris, std::pair<double, double> time_range,
             std::string constellation_warning);
    void validate_date(double julian_date) const;
    std::vector<HipparcosRecord> stars_;
    std::vector<ConstellationRecord> constellations_;
    std::unordered_map<std::int32_t, std::size_t> star_indices_;
    std::string constellation_warning_;
    Cf96Ephemeris ephemeris_;
    std::pair<double, double> time_range_;
};

struct SkyViewport {
    double center_ra_deg = 180;
    double center_dec_deg = 0;
    double zoom = 1;
    double perspective_blend = 0;
    double roll_deg = 0;
};

// 地平投影は視野角を正本とし、全天図の倍率制限から独立させる。
struct HorizonProjectionViewport {
    double center_ra_deg = 180;
    double center_dec_deg = 0;
    double vertical_fov_deg = 180;
    double perspective_blend = 0;
    double roll_deg = 0;
};

struct ScreenPoint { double x, y; };
struct ScreenSegment { ScreenPoint start, end; };

// 操作時は赤経を正規化する。通常は極の外に空白が出ない範囲に、
// allow_pole_center が true の場合は中心を極まで許容する。
// 倍率は1〜180。非有限値、倍率<=0、無効な寸法は invalid_argument。
SkyViewport normalize_sky_viewport(SkyViewport viewport, bool allow_pole_center = false);
SkyViewport pan_sky(SkyViewport viewport, double delta_x, double delta_y,
                    double width, double height, bool allow_pole_center = false);
SkyViewport zoom_sky(SkyViewport viewport, double factor, ScreenPoint anchor,
                     double width, double height, bool allow_pole_center = false);

// 左上原点、赤経は左向き、赤緯は上向き。幅360/zoom度、高さ180/zoom度。
// RA は360度周期。全天の継ぎ目は右端に置く。範囲外は nullopt。
// 非有限値、赤緯範囲外、zoom<1、幅または高さ<=0 は invalid_argument。
std::optional<ScreenPoint> project_sky(EquatorialCoordinates coordinates,
                                     const SkyViewport& viewport,
                                     double width, double height);

// 赤経の短い側を結び、全天図の継ぎ目と描画範囲で線を分割する。
std::vector<ScreenSegment> project_sky_segment(EquatorialCoordinates start,
                                              EquatorialCoordinates end,
                                              const SkyViewport& viewport,
                                              double width, double height);

// 地平図用。合成赤経 = 360 - 方位、高度を視野中心に合わせて球面回転し、
// perspective_blend = 0 は全天図と同じ経緯度投影、1 は縦視野角45度の透視投影。
// 中間値では各画素が指す経度と緯度を補間する。逆変換も同じ座標系を返す。
HorizonProjectionViewport normalize_horizon_viewport(HorizonProjectionViewport viewport);
HorizonProjectionViewport pan_horizon(HorizonProjectionViewport viewport, double delta_x, double delta_y,
                                      double width, double height);
EquatorialCoordinates rotate_horizon(EquatorialCoordinates coordinates, const HorizonProjectionViewport& viewport);
std::optional<ScreenPoint> project_horizon(EquatorialCoordinates coordinates,
                                         const HorizonProjectionViewport& viewport,
                                         double width, double height);
EquatorialCoordinates unproject_horizon(ScreenPoint point, const HorizonProjectionViewport& viewport,
                                        double width, double height);
// ラスターの画素中心を逆変換する。各軸と視野の計算を画像ごとに共有する。
class HorizonRasterProjection {
public:
    HorizonRasterProjection(const HorizonProjectionViewport& viewport, std::size_t width, std::size_t height);
    // x < width、y < height が必要。
    EquatorialCoordinates direction(std::size_t x, std::size_t y) const;

private:
    double center_ra_deg_;
    double cos_tilt_;
    double sin_tilt_;
    double cos_roll_;
    double sin_roll_;
    double perspective_blend_;
    double vertical_fov_deg_;
    std::vector<std::array<double, 2>> longitudes_;
    std::vector<std::array<double, 2>> latitudes_;
    std::vector<double> perspective_denominators_;
    std::vector<double> vertical_coordinates_;
};
// 可能な範囲でポインター下の方向を維持して拡大する。
HorizonProjectionViewport zoom_horizon(HorizonProjectionViewport viewport, double factor, ScreenPoint anchor,
                         double width, double height);

enum class ObjectKind { star, body };
struct Selection { ObjectKind kind; std::size_t index; };

// 表示と同じ等級上限を使い、半径内の最近傍を選択する。同距離なら惑星を優先する。
// index は model.stars() または bodies の添字。全HIPの保持状態は変更しない。
std::optional<Selection> pick_object(const SkyModel& model, const SkyBodies& bodies,
                                     const SkyViewport& viewport,
                                     double width, double height, double x, double y,
                                     double magnitude_limit, double radius = 8,
                                     bool stars_visible = true, bool bodies_visible = true);

} // namespace mitaka::gui
