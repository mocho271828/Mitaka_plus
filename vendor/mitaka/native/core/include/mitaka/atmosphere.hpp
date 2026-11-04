#pragma once

#include "mitaka/astronomy.hpp"
#include "mitaka/catalog.hpp"

#include <array>
#include <memory>
#include <optional>
#include <string_view>

namespace mitaka {

struct AtmosphereRgb { float r = 0, g = 0, b = 0; };

struct AtmosphereParameters {
    double ground_radius_m;
    double outer_radius_m;
    double scale_height_m;
    double surface_number_density_per_m3;
    double incident_intensity;
};

struct AtmosphereRay {
    // 同一の直交基底。惑星中心→視点 [m]、視点→画素、惑星→太陽。
    Vec3 observer_position_m;
    Vec3 view_direction;
    Vec3 sun_direction;
    // native の不透明物体による積分終端。未指定なら原版の全光路。
    // multiple の末尾殻は原 sample を保持し、その区間長だけを短縮する。
    std::optional<double> maximum_distance_m = std::nullopt;
};

struct AtmosphereEmissionGrid {
    std::size_t radial_count;
    std::size_t angle_count;
    double ground_radius_m;
    double outer_radius_m;
    double scale_height_m;
    double surface_number_density_per_m3;
    double maximum_sun_zenith_angle_rad;
};

// 検証後のグリッドを不変にし、画素ごとの全ノード再検査を避ける。
class AtmosphereEmissionMap {
public:
    static AtmosphereEmissionMap parse(std::string_view bytes,
        const std::filesystem::path& source, CatalogLoadLimits limits = {});
    const AtmosphereEmissionGrid& grid() const noexcept;
    const std::vector<AtmosphereRgb>& nodes() const noexcept;
    const std::vector<double>& radii_m() const noexcept;
private:
    struct Data;
    explicit AtmosphereEmissionMap(std::shared_ptr<const Data> data);
    std::shared_ptr<const Data> data_;
};

enum class AtmosphereLoadFailure { unreadable, limit_exceeded, invalid_format };
struct AtmosphereLoadDiagnostic {
    AtmosphereLoadFailure code;
    std::uint64_t byte_offset;
    std::string message;
};
struct AtmosphereEmissionSource {
    std::filesystem::path path;
    std::uint64_t file_size = 0;
    std::string bytes; // 不正な内容も読込上限内なら原 bytes を保持する。
    bool read_complete = false;
    std::optional<AtmosphereEmissionMap> map;
    std::vector<AtmosphereLoadDiagnostic> diagnostics;
};

// 原本を変更しない。欠損/破損/上限超過を黒い正常マップに置換しない。
AtmosphereEmissionSource load_atmosphere_emission_map(
    const std::filesystem::path& path, CatalogLoadLimits limits = {});
AtmosphereEmissionSource parse_atmosphere_emission_map(
    std::string bytes, const std::filesystem::path& source, CatalogLoadLimits limits = {});

// 公式 1.3.1 の scalar 経路。exp_d 近似と各段階の float 丸めを保持する。
// 単位方向（norm の許容差 2e-6）、地表以上の視点、有限の正の半径/H が必要。
// 不正入力は invalid_argument、扱えない幾何/光学深度/出力は out_of_range。
// 光線が大気へ到達しない場合は正常な RGB=0。標本数は 2..4096。
AtmosphereRgb atmosphere_single_scattering(const AtmosphereParameters& atmosphere,
    const AtmosphereRay& ray, std::size_t samples = 14);

// map 自身の半径/密度を使い、I0 はまだ掛けない。single の設定へ同一化しない。
// 原描画側に依存していた前方交差と地表以上の条件を native の入口で検証する。
AtmosphereRgb atmosphere_multiple_scattering(const AtmosphereEmissionMap& map,
    const AtmosphereRay& ray);

struct AtmosphereDisplaySample {
    AtmosphereRgb rgb;
    float alpha;
};
// single + I0*multiple、alpha=min(1,4*max(rgb))。RGBは加算合成用で、alphaを
// もう一度掛けない。alphaは透過率ではない。multipleが不要ならRGB=0を渡す。
AtmosphereDisplaySample compose_atmosphere_display(AtmosphereRgb single,
    AtmosphereRgb multiple, double incident_intensity);

} // namespace mitaka
