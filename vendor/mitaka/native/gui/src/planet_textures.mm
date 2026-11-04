#include "planet_textures.hpp"

#include <algorithm>
#include <stdexcept>

namespace mitaka::gui {
namespace {
constexpr std::array<const char*, 11> filenames{{
    "sun.jpg", "mercury.jpg", "venus.jpg", "earth.jpg", "mars.jpg",
    "jupiter.jpg", "saturn.jpg", "uranus.jpg", "neptune.jpg", "pluto.jpg", "moon.jpg"
}};

} // namespace

std::size_t PlanetTextures::loaded_count() const noexcept {
    return static_cast<std::size_t>(std::count_if(images.begin(), images.end(), [](const auto& image) { return image.has_value(); }));
}

PlanetTextures load_planet_textures(const std::filesystem::path& data_directory) {
    PlanetTextures result;
    const auto texture_directory = (data_directory / ".." / "textures").lexically_normal();
    for (std::size_t index = 0; index < filenames.size(); ++index) {
        const auto path = texture_directory / filenames[index];
        try {
            result.images[index] = load_local_image(path);
        } catch (const std::runtime_error& error) {
            result.warnings.push_back(path.filename().string() + ": " + error.what());
        }
    }
    const auto load_layer = [&](const char* filename, std::optional<TextureImage>& destination) {
        try {
            destination = load_local_image(texture_directory / filename);
        } catch (const std::runtime_error& error) {
            result.earth_layers.diagnostics.push_back(std::string(filename) + ": " + error.what());
        }
    };
    load_layer("earth_cloud.jpg", result.earth_layers.clouds);
    load_layer("earth_lights.jpg", result.earth_layers.night_lights);
    result.atmosphere_emission = load_atmosphere_emission_map(data_directory / "emmap.dat");
    return result;
}

} // namespace mitaka::gui
