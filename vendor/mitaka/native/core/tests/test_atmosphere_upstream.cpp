#include "mitaka/atmosphere.hpp"
#include "vector3.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <iterator>
#include <limits>
#include <sstream>
#include <stdexcept>
#include <string>
#include <type_traits>
#include <vector>
#include <unistd.h>

// 原本から機械抽出した参照関数。製品ライブラリにはリンクしない。
using RGBf = vector3<float>;
RGBf reference_atmosphere_single(double, double, double, double, double,
    const vector3d&, const vector3d&, const vector3d&, int);
RGBf calc_scattered_light_intensity(float, float, float, float, float,
    const vector3f&, const vector3f&, const vector3f&, int);
void init_multiple_scattering(const char*);
void free_multiple_scattering_work();
RGBf calc_multiple_scattered_light_intensity(const vector3d&, const vector3d&, const vector3d&);
extern int msRN, msThN;
extern double msR1, msR2, msH, msN0, msThMax;
extern double* msR;
extern RGBf* vEmMap;
extern bool bInitMultipleScattering;

namespace {
struct Comparison {
    std::size_t components = 0;
    std::size_t exact_components = 0;
    double maximum_difference = 0;
    double maximum_relative_difference = 0;
    std::size_t ground_occluded_rays = 0;
    double maximum_ground_reference_magnitude = 0;
};

void require(bool condition, const char* message) {
    if (!condition) throw std::runtime_error(message);
}

vector3d upstream(mitaka::Vec3 value) { return {value.x, value.y, value.z}; }
mitaka::Vec3 native(vector3f value) { return {value.x, value.y, value.z}; }

mitaka::Vec3 direction(double degrees, double azimuth = 0) {
    const double polar = degrees * std::acos(-1.0) / 180;
    const double longitude = azimuth * std::acos(-1.0) / 180;
    return {std::sin(polar) * std::cos(longitude),
            std::sin(polar) * std::sin(longitude), std::cos(polar)};
}

std::vector<double> view_angles(double radius, double ground, double outer, double height) {
    std::vector<double> angles{0, 45, 80, 89, 90, 91, 100, 135, 180};
    if (radius > outer) {
        // 宇宙から地表を外れる光路も通し、手前と奥に分かれる影の区間を照合する。
        for (double impact : {ground + 0.1 * height, ground + height, outer - 0.1 * height})
            angles.push_back(180 - std::asin(impact / radius) * 180 / std::acos(-1.0));
    }
    return angles;
}

void compare(mitaka::AtmosphereRgb actual, RGBf expected, const std::string& context,
             Comparison& result) {
    const std::array<float, 3> lhs{actual.r, actual.g, actual.b};
    const std::array<float, 3> rhs{expected.r, expected.g, expected.b};
    for (std::size_t channel = 0; channel < lhs.size(); ++channel) {
        const double difference = std::abs(double(lhs[channel]) - rhs[channel]);
        const double scale = std::max(std::abs(double(lhs[channel])), std::abs(double(rhs[channel])));
        // float 積算の丸め境界は保持し、異なるコンパイラの積和融合だけを狭く許容する。
        const double tolerance = 8 * std::numeric_limits<float>::epsilon() * scale;
        ++result.components;
        if (lhs[channel] == rhs[channel]) ++result.exact_components;
        result.maximum_difference = std::max(result.maximum_difference, difference);
        if (scale > 0) result.maximum_relative_difference =
            std::max(result.maximum_relative_difference, difference / scale);
        if (!std::isfinite(lhs[channel]) || !std::isfinite(rhs[channel]) || difference > tolerance) {
            std::ostringstream message;
            message << std::setprecision(17) << "atmosphere reference mismatch: " << context
                    << ", channel=" << channel << ", actual=" << lhs[channel]
                    << ", expected=" << rhs[channel] << ", difference=" << difference
                    << ", tolerance=" << tolerance;
            throw std::runtime_error(message.str());
        }
    }
}

void compare_single(const mitaka::AtmosphereParameters& parameters, Comparison& result) {
    const std::array<double, 6> radii{parameters.ground_radius_m, parameters.ground_radius_m + 200,
        parameters.ground_radius_m + parameters.scale_height_m,
        parameters.outer_radius_m, parameters.outer_radius_m * 1.01,
        parameters.outer_radius_m * 2};
    for (const double radius : radii) {
        for (const double polar : view_angles(radius, parameters.ground_radius_m,
                                              parameters.outer_radius_m, parameters.scale_height_m)) {
            for (const double sun : {0.0, 45.0, 89.0, 90.0, 100.0, 135.0, 180.0}) {
                const mitaka::AtmosphereRay ray{{0, 0, radius}, direction(polar, 17), direction(sun, 53)};
                for (const int samples : {2, 3, 14, 22, 64}) {
                    const auto expected = reference_atmosphere_single(parameters.ground_radius_m,
                        parameters.outer_radius_m, parameters.surface_number_density_per_m3,
                        parameters.scale_height_m, parameters.incident_intensity,
                        upstream(ray.observer_position_m), upstream(ray.view_direction),
                        upstream(ray.sun_direction), samples);
                    std::ostringstream context;
                    context << "single R=" << parameters.ground_radius_m << ", observer=" << radius
                            << ", polar=" << polar << ", sun=" << sun << ", samples=" << samples;
                    mitaka::AtmosphereRgb actual;
                    try { actual = mitaka::atmosphere_single_scattering(parameters, ray, samples); }
                    catch (const std::exception& error) {
                        throw std::runtime_error(context.str() + ": " + error.what());
                    }
                    compare(actual, expected, context.str(), result);
                }
            }
        }
    }
    // 原 public 関数は float 入力を一度丸めてから double の本体へ渡す。
    const float r1 = parameters.ground_radius_m, r2 = parameters.outer_radius_m;
    const float density = parameters.surface_number_density_per_m3;
    const float height = parameters.scale_height_m, intensity = parameters.incident_intensity;
    const vector3f eye(0, 0, r1 + 1000), view(0.8f, 0, 0.6f), sun(0, 0.6f, 0.8f);
    compare(mitaka::atmosphere_single_scattering({r1, r2, height, density, intensity},
        {native(eye), native(view), native(sun)}, 22),
        calc_scattered_light_intensity(r1, r2, density, height, intensity, eye, view, sun, 22),
        "single float public wrapper", result);
}

template<class Value>
void append_little_endian(std::string& bytes, Value value) {
    static_assert(sizeof(Value) == 4 || sizeof(Value) == 8);
    using Bits = std::conditional_t<sizeof(Value) == 4, std::uint32_t, std::uint64_t>;
    Bits bits;
    std::memcpy(&bits, &value, sizeof(value));
    for (std::size_t index = 0; index < sizeof(value); ++index)
        bytes.push_back(static_cast<char>((bits >> (8 * index)) & 0xff));
}

std::string synthetic_map() {
    std::string bytes;
    constexpr std::int32_t radial_count = 20, angle_count = 129;
    append_little_endian(bytes, radial_count);
    append_little_endian(bytes, angle_count);
    for (double value : {6378000.0, 6442000.0, 8000.0, 2.5469e25, 1.884955644607544})
        append_little_endian(bytes, value);
    for (int radial = 0; radial < radial_count; ++radial) {
        for (int angle = 0; angle < angle_count; ++angle) {
            const float value = 1e-7f * (1 + radial) * (1 + angle);
            append_little_endian(bytes, value);
            append_little_endian(bytes, value * 0.37f);
            append_little_endian(bytes, value * 2.1f);
        }
    }
    return bytes;
}

class TemporaryMap {
public:
    explicit TemporaryMap(const std::string& bytes) {
        auto pattern = (std::filesystem::temp_directory_path() / "mitaka-atmosphere-reference-XXXXXX").string();
        std::vector<char> writable(pattern.begin(), pattern.end());
        writable.push_back('\0');
        const int descriptor = mkstemp(writable.data());
        if (descriptor < 0) throw std::runtime_error("cannot create reference map fixture");
        path_ = writable.data();
        close(descriptor);
        std::ofstream file(path_, std::ios::binary);
        file.write(bytes.data(), static_cast<std::streamsize>(bytes.size()));
        if (!file) throw std::runtime_error("cannot write reference map fixture");
    }
    ~TemporaryMap() { std::error_code ignored; std::filesystem::remove(path_, ignored); }
    const std::filesystem::path& path() const { return path_; }
private:
    std::filesystem::path path_;
};

class ReferenceMap {
public:
    explicit ReferenceMap(const std::filesystem::path& path) {
        init_multiple_scattering(path.c_str());
        require(bInitMultipleScattering, "original reference map loader failed");
    }
    ~ReferenceMap() { free_multiple_scattering_work(); }
};

void compare_multiple(const std::string& bytes, const std::filesystem::path& path, Comparison& result) {
    // 検証済みファイルだけを、境界検査を持たない原 loader に渡す。
    const auto map = mitaka::AtmosphereEmissionMap::parse(bytes, path);
    const ReferenceMap reference(path);
    const auto& grid = map.grid();
    require(grid.radial_count == std::size_t(msRN) && grid.angle_count == std::size_t(msThN),
            "reference grid dimensions differ");
    require(grid.ground_radius_m == msR1 && grid.outer_radius_m == msR2 &&
            grid.scale_height_m == msH && grid.surface_number_density_per_m3 == msN0 &&
            grid.maximum_sun_zenith_angle_rad == msThMax, "reference grid header differs");
    for (std::size_t index = 0; index < map.radii_m().size(); ++index)
        require(map.radii_m()[index] == msR[index], "reference radial coordinate differs");
    for (std::size_t index = 0; index < map.nodes().size(); ++index) {
        const auto actual = map.nodes()[index];
        const auto expected = vEmMap[index];
        require(actual.r == expected.r && actual.g == expected.g && actual.b == expected.b,
                "reference RGB node differs");
    }
    const std::array<double, 5> radii{msR1, msR1 + 200, msR1 + msH, msR2 * 1.01, msR2 * 2};
    for (const double radius : radii) {
        for (const double polar : view_angles(radius, msR1, msR2, msH)) {
            const auto view = direction(polar, 17);
            const double projection = radius * view.z;
            const double discriminant = projection * projection - radius * radius + msR2 * msR2;
            // 原描画側にない外部後方向 ray は、native の追加 guard と分けて試験する。
            if (radius >= msR2 && (discriminant <= 0 || -projection + std::sqrt(discriminant) <= 0)) continue;
            for (const double sun : {0.0, 45.0, 89.0, 90.0, 100.0, 107.0, 135.0, 180.0}) {
                const mitaka::AtmosphereRay ray{{0, 0, radius}, view, direction(sun, 53)};
                std::ostringstream context;
                context << "multiple observer=" << radius << ", polar=" << polar << ", sun=" << sun;
                const auto expected = calc_multiple_scattered_light_intensity(upstream(ray.observer_position_m),
                    upstream(ray.view_direction), upstream(ray.sun_direction));
                mitaka::AtmosphereRgb actual;
                try { actual = mitaka::atmosphere_multiple_scattering(map, ray); }
                catch (const std::exception& error) {
                    context << std::setprecision(17) << ", reference RGB=" << expected.r << ','
                            << expected.g << ',' << expected.b << ": " << error.what();
                    throw std::runtime_error(context.str());
                }
                if (radius <= msR1 && projection < 0) {
                    // 原版の地表交差の桁落ちは微小な負 dt を生む。native は遮蔽を厳密な 0 とする。
                    require(actual.r == 0 && actual.g == 0 && actual.b == 0,
                            "ground-inward ray must be fully occluded");
                    require(std::isfinite(expected.r) && std::isfinite(expected.g) &&
                            std::isfinite(expected.b), "ground reference must remain finite");
                    ++result.ground_occluded_rays;
                    result.maximum_ground_reference_magnitude = std::max(
                        result.maximum_ground_reference_magnitude,
                        std::max({std::abs(double(expected.r)), std::abs(double(expected.g)),
                                  std::abs(double(expected.b))}));
                    continue;
                }
                compare(actual, expected, context.str(), result);
            }
        }
    }
}

std::string read_bytes(const std::filesystem::path& path) {
    std::ifstream file(path, std::ios::binary);
    if (!file) throw std::runtime_error("cannot read reference emission map");
    return {std::istreambuf_iterator<char>(file), std::istreambuf_iterator<char>()};
}
} // namespace

int main(int argc, char** argv) {
    try {
        if (argc != 1 && !(argc == 3 && std::string(argv[1]) == "--emmap")) {
            std::cerr << "Usage: test_atmosphere_upstream [--emmap PATH]\n";
            return 2;
        }
        Comparison single, multiple;
        // 公式 Earth の単一散乱と emmap の基準半径・密度は異なる。統合して比較しない。
        compare_single({6378136.6, 6378136.6 + 6 * 8000, 8000, 2.69e25, 1}, single);
        compare_single({3397000, 3397000 + 6 * 11000, 11000, 3e23, 0.7}, single);
        const auto bytes = synthetic_map();
        const TemporaryMap fixture(bytes);
        compare_multiple(bytes, fixture.path(), multiple);
        if (argc == 3) compare_multiple(read_bytes(argv[2]), argv[2], multiple);
        std::cout << std::setprecision(12)
                  << "atmosphere reference: single " << single.components << " components ("
                  << single.exact_components << " exact), multiple " << multiple.components << " components ("
                  << multiple.exact_components << " exact); maximum absolute/relative differences: single "
                  << single.maximum_difference << '/' << single.maximum_relative_difference
                  << ", multiple " << multiple.maximum_difference << '/'
                  << multiple.maximum_relative_difference << "; ground-inward native-zero cases "
                  << multiple.ground_occluded_rays << " (maximum original magnitude "
                  << multiple.maximum_ground_reference_magnitude << ")\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
