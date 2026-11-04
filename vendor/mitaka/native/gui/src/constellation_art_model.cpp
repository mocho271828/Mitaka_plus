#include "constellation_art_model.hpp"
#include <algorithm>
#include <map>
#include <set>

namespace mitaka::gui {
namespace {
std::string folded(std::string value) {
    for (auto& byte : value) if (byte >= 'A' && byte <= 'Z') byte += 'a' - 'A';
    return value;
}
}
ConstellationArtModel ConstellationArtModel::load(const std::filesystem::path& data_directory,
    const std::vector<ConstellationRecord>& constellations, CatalogLoadLimits limits) {
    ConstellationArtModel model;
    std::map<std::string, std::set<std::string>> names;
    for (const auto& record : constellations) names[folded(record.abbreviation)].insert(record.abbreviation);
    const auto directory = data_directory / "constellations";
    std::error_code error;
    if (!std::filesystem::exists(directory, error) && !error) return model;
    std::vector<std::filesystem::path> paths;
    std::filesystem::directory_iterator iterator(directory, error);
    const std::filesystem::directory_iterator end;
    while (!error && iterator != end) {
        if (iterator->is_regular_file(error) && folded(iterator->path().extension().string()) == ".cab")
            paths.push_back(iterator->path());
        if (!error) iterator.increment(error);
    }
    if (error) model.warnings_.push_back(directory.string() + ": " + error.message());
    std::sort(paths.begin(), paths.end());
    if (paths.size() > limits.max_records) throw CatalogError(directory, 0, "too many CAB files");
    std::size_t total_bytes = 0;
    for (const auto& path : paths) {
        try {
            auto remaining = limits;
            remaining.max_file_bytes = limits.max_file_bytes - total_bytes;
            BoundConstellationArt record{load_constellation_art(path, remaining), std::nullopt, {}};
            total_bytes += record.art.source_bytes.size();
            auto name = folded(path.stem().string());
            if (name == "serh" || name == "sert") name = "ser";
            const auto match = names.find(name);
            if (match != names.end() && match->second.size() == 1) record.abbreviation = *match->second.begin();
            else model.warnings_.push_back(path.string() + ": no unambiguous constellation abbreviation");
            record.directions.reserve(record.art.points.size());
            for (std::size_t index = 0; index < record.art.points.size(); ++index)
                record.directions.push_back(constellation_art_direction(record.art, index));
            model.records_.push_back(std::move(record));
        } catch (const CatalogError& failure) { model.warnings_.push_back(failure.what()); }
    }
    return model;
}
}
