#include "earth_landscapes.hpp"
#include "landscape_geometry.hpp"
#import <Foundation/Foundation.h>
#include <algorithm>
#include <map>
#include <stdexcept>
#include <utility>

namespace mitaka::gui {
namespace {
constexpr std::size_t maximum_image_bytes = 128 * 1024 * 1024;

std::filesystem::path image_path(const std::filesystem::path& root, const std::string& bytes) {
    if (bytes.find('\0') != std::string::npos) throw std::runtime_error("landscape path contains NUL");
    NSString* text = [[NSString alloc] initWithBytes:bytes.data() length:bytes.size()
                                          encoding:NSUTF8StringEncoding];
    if (!text) text = [[NSString alloc] initWithBytes:bytes.data() length:bytes.size()
        encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese)];
    if (!text) throw std::runtime_error("landscape path is not UTF-8 or CP932");
    std::string decoded(text.UTF8String);
    std::replace(decoded.begin(), decoded.end(), '\\', '/');
    const std::filesystem::path relative(decoded);
    if (decoded.empty() || relative.is_absolute() || decoded.find(':') != std::string::npos ||
        decoded.find('\0') != std::string::npos)
        throw std::runtime_error("landscape path must be local and relative");
    const auto canonical_root = std::filesystem::canonical(root);
    const auto resolved = std::filesystem::canonical(canonical_root / relative);
    const auto inside = resolved.lexically_relative(canonical_root);
    if (inside.empty() || *inside.begin() == "..")
        throw std::runtime_error("landscape path leaves the selected data root");
    return resolved;
}
}

EarthLandscapes::EarthLandscapes(ObserverPlaces places) : definitions_(std::move(places)) {
    images_.resize(definitions_.landscapes().size());
}

EarthLandscapes EarthLandscapes::load(const std::filesystem::path& data_directory, ObserverPlaces places) {
    EarthLandscapes result(std::move(places));
    std::map<std::filesystem::path, std::shared_ptr<const TextureImage>> loaded;
    std::size_t loaded_bytes = 0;
    // data/ と data の両方で同じ親を使う。
    auto data = data_directory.lexically_normal();
    while (data.filename().empty() && data != data.root_path()) data = data.parent_path();
    for (std::size_t index = 0; index < result.definitions_.landscapes().size(); ++index) {
        const auto& entry = result.definitions_.landscapes()[index];
        if (entry.definition.target_name != "Planet.Earth" && entry.qualified_name != "Planet.Default") continue;
        // 空画像は原版でも黒い地面を指定する有効な定義。
        if (entry.definition.image_path_bytes.empty()) continue;
        try {
            // parserを経由しない構築でも、非有限UVを描画へ流さない。
            LandscapeImageMesh validated(entry.definition);
            const auto path = image_path(data.parent_path(), entry.definition.image_path_bytes);
            const auto cached = loaded.find(path);
            if (cached != loaded.end()) {
                result.images_[index] = cached->second;
                continue;
            }
            auto texture = load_local_image(path);
            if (texture.rgba.size() > maximum_image_bytes - loaded_bytes)
                throw std::runtime_error("landscape image cache exceeds 128 MiB");
            loaded_bytes += texture.rgba.size();
            result.images_[index] = std::make_shared<const TextureImage>(std::move(texture));
            loaded.emplace(path, result.images_[index]);
        } catch (const std::runtime_error& error) {
            result.warnings_.push_back(entry.qualified_name + ": " + error.what());
        } catch (const std::invalid_argument& error) {
            result.warnings_.push_back(entry.qualified_name + ": " + error.what());
        }
    }
    return result;
}

std::optional<std::size_t> EarthLandscapes::selection(std::string_view identifier) const {
    return select_earth_landscape(definitions_, identifier);
}

const TextureImage* EarthLandscapes::image(std::size_t index) const {
    return images_.at(index).get();
}

} // namespace mitaka::gui
