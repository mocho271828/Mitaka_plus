#include "landscape_projection.hpp"
#include "landscape_geometry.hpp"
#include "sky_model.hpp"
#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace mitaka::gui {
namespace {
double wrap(double angle) {
    angle = std::fmod(angle, 360);
    return angle < 0 ? angle + 360 : angle;
}

std::array<double, 2> image_uv(const PlaceLandscape& landscape, HorizontalCoordinates direction) {
    const double u = wrap(wrap(direction.azimuth_deg) + 180 + wrap(landscape.offset_arguments[1])) / 360;
    const double v = 0.5 - direction.altitude_deg / 180 / landscape.vertical_scale + landscape.offset_arguments[0];
    return {u, v};
}

void sample(const TextureImage& texture, const std::array<double, 2>& uv, std::uint8_t* result) {
    const double x = std::clamp(uv[0] * texture.width - 0.5, 0.0, static_cast<double>(texture.width - 1));
    const double y = std::clamp(uv[1] * texture.height - 0.5, 0.0, static_cast<double>(texture.height - 1));
    const auto left = static_cast<std::size_t>(x), top = static_cast<std::size_t>(y);
    const auto right = std::min(left + 1, texture.width - 1), bottom = std::min(top + 1, texture.height - 1);
    const std::array<std::size_t, 4> positions{{top * texture.width + left, top * texture.width + right,
                                             bottom * texture.width + left, bottom * texture.width + right}};
    const double dx = x - left, dy = y - top;
    const std::array<double, 4> weights{{(1-dx)*(1-dy), dx*(1-dy), (1-dx)*dy, dx*dy}};
    // GLのstraight RGBA texture filteringに合わせ、透明色も独立に補間する。
    for (std::size_t channel = 0; channel < 4; ++channel) {
        double value = 0;
        for (std::size_t i = 0; i < positions.size(); ++i) value += texture.rgba[positions[i] * 4 + channel] * weights[i];
        result[channel] = static_cast<std::uint8_t>(std::clamp(std::lround(value), 0L, 255L));
    }
}
}

std::array<double, 2> landscape_image_uv(const PlaceLandscape& landscape, HorizontalCoordinates direction) {
    if (!std::isfinite(direction.azimuth_deg) || !std::isfinite(direction.altitude_deg) ||
        direction.altitude_deg < -90 || direction.altitude_deg > 90)
        throw std::invalid_argument("invalid landscape direction");
    LandscapeImageMesh validated(landscape);
    const auto uv = image_uv(landscape, direction);
    if (!std::isfinite(uv[1])) throw std::invalid_argument("non-finite landscape UV");
    return uv;
}

TextureImage render_horizon_landscape(const TextureImage* texture, const PlaceLandscape* landscape,
                                      HorizonViewport viewport, std::size_t width, std::size_t height) {
    if (!width || !height || width > 1024 || height > 1024)
        throw std::invalid_argument("invalid landscape output dimensions");
    if (texture) {
        if (!landscape || !texture->width || !texture->height || texture->width > 1024 || texture->height > 1024 ||
            texture->rgba.size() != texture->width * texture->height * 4)
            throw std::invalid_argument("invalid landscape texture");
        LandscapeImageMesh validated(*landscape);
    }
    const auto normalized = normalize_sky_viewport({360 - viewport.center_azimuth_deg, viewport.center_altitude_deg,
        viewport.zoom, viewport.perspective_blend}, true);
    TextureImage result{width, height, std::vector<std::uint8_t>(width * height * 4)};
    // 風景画像がないときは、既に暗く描いた地平線下の天体を覆わない。
    if (!texture) return result;
    const HorizonRasterProjection projection(normalized, width, height);
    for (std::size_t y = 0; y < height; ++y) {
        for (std::size_t x = 0; x < width; ++x) {
            const auto direction = projection.direction(x, y);
            auto* pixel = &result.rgba[(y * width + x) * 4];
            sample(*texture, image_uv(*landscape, {360 - direction.right_ascension_deg, direction.declination_deg}), pixel);
        }
    }
    return result;
}

} // namespace mitaka::gui
