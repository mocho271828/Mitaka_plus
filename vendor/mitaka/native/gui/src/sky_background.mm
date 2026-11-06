#include "sky_background.hpp"
#include "grid_geometry.hpp"

#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace mitaka::gui {
namespace {
constexpr double pi = 3.14159265358979323846;
constexpr double radians = pi / 180;
constexpr std::size_t maximum_dimension = 1024;

ScreenPoint direction_uv(Vec3 direction) {
    const Vec3 galactic = j2000_equatorial_to_galactic(direction);
    const double horizontal = std::hypot(galactic.x, galactic.y);
    const double longitude = horizontal < 1e-14 ? 0 : std::atan2(galactic.y, galactic.x);
    double u = 0.5 - longitude / (2 * pi);
    u -= std::floor(u);
    return {u, std::clamp(0.5 - std::atan2(galactic.z, horizontal) / pi, 0.0, 1.0)};
}

void require_texture(const TextureImage& texture) {
    if (!texture.width || !texture.height || texture.width > maximum_dimension
        || texture.height > maximum_dimension || texture.rgba.size() != texture.width * texture.height * 4)
        throw std::invalid_argument("invalid sky background texture");
}

void sample(const TextureImage& texture, ScreenPoint uv, std::uint8_t* target) {
    // pixel中心を基準に左右の継ぎ目を補間し、極では最端行を保持する。
    const double x = uv.x * texture.width - 0.5;
    const double y = std::clamp(uv.y * texture.height - 0.5, 0.0, static_cast<double>(texture.height - 1));
    const auto left = static_cast<long>(std::floor(x));
    const auto top = static_cast<std::size_t>(y);
    const auto wrap = [&](long value) {
        return static_cast<std::size_t>((value + static_cast<long>(texture.width)) % static_cast<long>(texture.width));
    };
    const std::array<std::size_t, 4> positions{{
        (top * texture.width + wrap(left)) * 4,
        (top * texture.width + wrap(left + 1)) * 4,
        (std::min(top + 1, texture.height - 1) * texture.width + wrap(left)) * 4,
        (std::min(top + 1, texture.height - 1) * texture.width + wrap(left + 1)) * 4
    }};
    const double dx = x - std::floor(x), dy = y - top;
    const std::array<double, 4> weights{{(1 - dx) * (1 - dy), dx * (1 - dy), (1 - dx) * dy, dx * dy}};
    std::array<double, 4> color{};
    for (std::size_t index = 0; index < positions.size(); ++index) {
        const auto offset = positions[index];
        const double alpha = texture.rgba[offset + 3] * weights[index];
        color[3] += alpha;
        for (std::size_t channel = 0; channel < 3; ++channel)
            color[channel] += texture.rgba[offset + channel] * alpha;
    }
    for (std::size_t channel = 0; channel < 3; ++channel)
        target[channel] = color[3] == 0 ? 0 : static_cast<std::uint8_t>(std::clamp(std::lround(color[channel] / color[3]), 0L, 255L));
    target[3] = static_cast<std::uint8_t>(std::clamp(std::lround(color[3]), 0L, 255L));
}
} // namespace

std::size_t SkyBackgrounds::loaded_count() const noexcept {
    return static_cast<std::size_t>(std::count_if(images.begin(), images.end(), [](const auto& image) { return image.has_value(); }));
}

const TextureImage* SkyBackgrounds::image(MilkyWayMode mode) const {
    std::size_t index;
    switch (mode) {
        case MilkyWayMode::none: return nullptr;
        case MilkyWayMode::normal: index = 0; break;
        case MilkyWayMode::bright: index = 1; break;
        case MilkyWayMode::infrared: index = 2; break;
        default: throw std::invalid_argument("invalid Milky Way mode");
    }
    return images[index] ? &*images[index] : nullptr;
}

SkyBackgrounds load_sky_backgrounds(const std::filesystem::path& data_directory) {
    SkyBackgrounds result;
    const auto directory = (data_directory / ".." / "textures").lexically_normal();
    const std::array<const char*, 3> filenames{{"milkyway.jpg", "milkyway2.jpg", "MilkyWay_IR.jpg"}};
    for (std::size_t index = 0; index < filenames.size(); ++index) {
        auto path = directory / filenames[index];
        if (index == 2) {
            std::error_code error;
            const auto status = std::filesystem::symlink_status(path, error);
            // 存在するが壊れた画像やsymlinkは、別名の成功で隠さない。
            if (status.type() == std::filesystem::file_type::not_found)
                path = directory / "milkyway_IR.jpg";
        }
        try {
            result.images[index] = load_local_image(path);
        } catch (const std::runtime_error& error) {
            result.warnings.push_back(path.filename().string() + ": " + error.what());
        }
    }
    return result;
}

ScreenPoint sky_background_uv(EquatorialCoordinates coordinates) {
    return direction_uv(equatorial_direction(coordinates));
}

EquatorialCoordinates sky_background_coordinates(ScreenPoint uv) {
    if (!std::isfinite(uv.x) || !std::isfinite(uv.y) || uv.y < 0 || uv.y > 1)
        throw std::invalid_argument("invalid sky background UV");
    const double longitude = pi - 2 * pi * (uv.x - std::floor(uv.x));
    const double latitude = pi / 2 - pi * uv.y;
    const Vec3 g{std::cos(latitude) * std::cos(longitude), std::cos(latitude) * std::sin(longitude), std::sin(latitude)};
    return equatorial_coordinates(galactic_to_j2000_equatorial(g));
}

TextureImage render_sky_background(const TextureImage& texture, SkyViewport viewport,
                                   std::size_t width, std::size_t height) {
    require_texture(texture);
    if (!width || !height || width > maximum_dimension || height > maximum_dimension)
        throw std::invalid_argument("invalid sky background output dimensions");
    viewport = normalize_sky_viewport(viewport);
    TextureImage result{width, height, std::vector<std::uint8_t>(width * height * 4)};
    std::vector<std::array<double, 2>> ra_directions(width);
    for (std::size_t x = 0; x < width; ++x) {
        const double ra = (viewport.center_ra_deg + (0.5 - (x + 0.5) / width) * 360 / viewport.zoom) * radians;
        ra_directions[x] = {std::cos(ra), std::sin(ra)};
    }
    for (std::size_t y = 0; y < height; ++y) {
        const double dec = (viewport.center_dec_deg + (0.5 - (y + 0.5) / height) * 180 / viewport.zoom) * radians;
        const double cos_dec = std::cos(dec), sin_dec = std::sin(dec);
        for (std::size_t x = 0; x < width; ++x) {
            const auto uv = direction_uv({cos_dec * ra_directions[x][0], cos_dec * ra_directions[x][1], sin_dec});
            sample(texture, uv, &result.rgba[(y * width + x) * 4]);
        }
    }
    return result;
}

TextureImage render_horizon_background(const TextureImage& texture, HorizonViewport viewport,
                                       const ObservationFrame& frame,
                                       std::size_t width, std::size_t height) {
    require_texture(texture);
    if (!width || !height || width > maximum_dimension || height > maximum_dimension)
        throw std::invalid_argument("invalid horizon background output dimensions");
    const auto normalized = normalize_sky_viewport(
        {360 - viewport.center_azimuth_deg, viewport.center_altitude_deg, viewport.zoom, viewport.perspective_blend, viewport.roll_deg}, true);
    TextureImage result{width, height, std::vector<std::uint8_t>(width * height * 4)};
    const HorizonRasterProjection projection(normalized, width, height);
    for (std::size_t y = 0; y < height; ++y) {
        for (std::size_t x = 0; x < width; ++x) {
            const auto direction = projection.direction(x, y);
            const auto uv = sky_background_uv(frame.to_equatorial({360 - direction.right_ascension_deg, direction.declination_deg}));
            sample(texture, uv, &result.rgba[(y * width + x) * 4]);
        }
    }
    return result;
}

} // namespace mitaka::gui
