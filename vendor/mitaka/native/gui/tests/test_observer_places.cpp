#include "observer_places.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <fstream>
#include <iostream>
#include <iterator>
#include <stdexcept>

namespace {
std::size_t checks = 0;
void require(bool condition, const std::string& message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}

constexpr std::array<const char*, 4> names = {
    "places_jp.dat", "places.dat", "defaultplaces_jp.dat", "defaultplaces.dat"};

void write(const std::filesystem::path& path, const std::string& text) {
    std::ofstream file(path, std::ios::binary);
    file << text;
    require(bool(file), "write temporary fixture");
}

std::string definition(const std::string& id, const std::string& name, int longitude = 0) {
    return "Places:addPlace('" + id + "','" + name + "'," + std::to_string(longitude) +
           ",20,'group','scene');\r\n";
}

std::string read(const std::filesystem::path& path) {
    std::ifstream file(path, std::ios::binary);
    require(bool(file), "open source for independent byte comparison");
    const std::string text{std::istreambuf_iterator<char>(file), std::istreambuf_iterator<char>()};
    require(!file.bad(), "read source for independent byte comparison");
    return text;
}

void same_place(const mitaka::PlaceRecord& left, const mitaka::PlaceRecord& right) {
    require(left.target_name == right.target_name && left.name_bytes == right.name_bytes &&
            left.longitude_degrees == right.longitude_degrees && left.latitude_degrees == right.latitude_degrees &&
            left.label_group == right.label_group && left.landscape == right.landscape,
            "effective row retains every original field");
}

void test_selection(const std::filesystem::path& root) {
    using mitaka::gui::ObserverPlacesLanguage;
    for (unsigned mask = 0; mask < 16; ++mask) {
        for (unsigned index = 0; index < names.size(); ++index) {
            if (mask & (1U << index)) write(root / names[index], definition("Planet.Earth.Site", names[index]));
            else std::filesystem::remove(root / names[index]);
        }
        for (const auto language : {ObserverPlacesLanguage::japanese, ObserverPlacesLanguage::english}) {
            const auto loaded = mitaka::gui::load_observer_places(root, {}, language);
            const std::vector<unsigned> priority = language == ObserverPlacesLanguage::japanese ?
                std::vector<unsigned>{0, 1, 2, 3} : std::vector<unsigned>{1, 3};
            const auto chosen = std::find_if(priority.begin(), priority.end(), [&](unsigned index) {
                return (mask & (1U << index)) != 0;
            });
            require(loaded.warnings.empty(), "valid candidates have no warnings");
            require(loaded.sources.size() + loaded.missing_files.size() == names.size(), "all candidates accounted for");
            require(loaded.source_place_count == loaded.sources.size(), "all parsed source rows retained");
            for (const auto& source : loaded.sources) {
                require(std::string(source.bytes.begin(), source.bytes.end()) == read(source.path),
                        "selected and unselected candidate bytes remain unchanged");
            }
            if (chosen == priority.end()) {
                require(!loaded.selected_source && loaded.places.empty(), "absence has no effective source");
            } else {
                require(loaded.selected_source && loaded.sources[*loaded.selected_source].path.filename() == names[*chosen],
                        "language-aware user precedence selects exactly one source");
                require(loaded.places.size() == 1 && loaded.places[0].name_bytes == names[*chosen],
                        "other candidate files do not merge into the effective catalog");
                require(loaded.origins.size() == 1 && loaded.origins[0].source == *loaded.selected_source &&
                        loaded.origins[0].place == 0, "origin points to the selected source row");
            }
        }
    }
}

void test_errors_and_empty(const std::filesystem::path& root) {
    write(root / names[0], "OBJECT: legacy custom data\n");
    auto loaded = mitaka::gui::load_observer_places(root);
    require(loaded.places.empty() && loaded.warnings.size() == 1 && loaded.selected_source == 0,
            "invalid existing user file never falls back to a valid default or unsuffixed file");
    require(loaded.sources[0].error && !loaded.sources[0].catalog && !loaded.sources[0].bytes.empty(),
            "unsupported user content stays intact without execution or conversion");
    write(root / names[0], "");
    loaded = mitaka::gui::load_observer_places(root);
    require(loaded.places.empty() && loaded.warnings.empty() && loaded.selected_source == 0,
            "an empty existing user catalog intentionally supplies zero places");
    write(root / names[0], definition("Planet.Earth.Local", "Local"));
    write(root / names[2], "os.execute('must not execute')\n");
    loaded = mitaka::gui::load_observer_places(root);
    require(loaded.places.size() == 1 && loaded.warnings.empty() && loaded.sources[2].error,
            "an unselected parse error is retained without invalidating the selected source");
    mitaka::CatalogLoadLimits limits;
    limits.max_records = 0;
    loaded = mitaka::gui::load_observer_places(root, limits);
    require(loaded.places.empty() && loaded.sources.size() == 4 && loaded.warnings.size() == 1,
            "record limits preserve all bytes but reject the selected interpretation");
    limits.max_file_bytes = 0;
    loaded = mitaka::gui::load_observer_places(root, limits);
    require(loaded.places.empty() && loaded.selected_source == 0 && loaded.warnings.size() == 4,
            "unreadable bounded sources report failure without changing selection");
    std::filesystem::remove(root / names[0]);
    require(std::filesystem::create_directory(root / names[0]), "create invalid file-type fixture");
    loaded = mitaka::gui::load_observer_places(root);
    require(loaded.places.empty() && loaded.selected_source == 0 && !loaded.warnings.empty(),
            "an existing unreadable user path is not treated as absence");
    std::filesystem::remove(root / names[0]);
}

void test_keys(const std::filesystem::path& root) {
    const auto original = definition("Planet.Earth.Shared", "First", 10) +
        definition("Planet.Earth.Other", "Same display", 20) +
        definition("Planet.Earth.Shared", "Renamed", 370) +
        definition("Planet.Mars.Base", "Mars first", 30) +
        definition("Planet.Mars.Base", "Mars renamed", 40) +
        definition("Planet.Custom.Site", "Unknown first", 50) +
        definition("Planet.Custom.Site", "Unknown second", 60) +
        definition("Planet.Earth", "No suffix") + definition("Planet.Earth.", "Empty suffix") +
        definition("Planet.Earth.More.Components", "Extra component") +
        definition("Planet.Earth2.Site", "Similar body") + definition("Planet.earth.Site", "Wrong case");
    write(root / names[0], original);
    const auto loaded = mitaka::gui::load_observer_places(root);
    require(loaded.places.size() == 10 && loaded.sources[0].catalog->places.size() == 12,
            "known complete IDs update while unresolved rows remain independent");
    require(loaded.places[0].name_bytes == "Renamed" && loaded.places[0].longitude_degrees == 370 &&
            loaded.places[1].target_name == "Planet.Earth.Other" && loaded.places[2].name_bytes == "Mars renamed",
            "ID overrides ignore display names, preserve first insertion order and raw longitude");
    require(loaded.origins[0].place == 2 && loaded.origins[2].place == 4 &&
            loaded.places[3].name_bytes == "Unknown first" && loaded.places[4].name_bytes == "Unknown second",
            "origins track winning rows without guessing unresolved aliases");
    require(loaded.warnings.size() == 7, "every unresolved row has a diagnostic");
    for (std::size_t index = 0; index < loaded.places.size(); ++index) {
        require(mitaka::gui::observer_place_is_earth(loaded.places[index]) == (index < 2),
                "only a complete canonical Earth place is applicable");
        same_place(loaded.places[index], loaded.sources[loaded.origins[index].source].catalog->places[loaded.origins[index].place]);
    }
    require(std::string(loaded.sources[0].bytes.begin(), loaded.sources[0].bytes.end()) == original,
            "duplicate and unknown source rows are preserved byte for byte");
}

void test_body_resolution(const std::filesystem::path& root) {
    using mitaka::gui::observer_place_body_index;
    const auto original = definition("Planet.Earth.Tokyo", "Tokyo") +
        definition("Planet.Mars.OlympusMons", "Olympus Mons") +
        definition("Satellite.Moon.NorthPole", "Moon first", 10) +
        definition("Satellite.Moon.NorthPole", "Moon replacement", 20) +
        definition("Planet.Venus.Site", "Unsupported planet") +
        definition("Satellite.Moon", "No suffix") +
        definition("Satellite.Moon.", "Empty suffix") +
        definition("Satellite.Moon.A.B", "Extra component") +
        definition("Satellite.Moon2.Site", "Similar body") +
        definition("Satellite.moon.Site", "Wrong case");
    write(root / names[0], original);
    const auto loaded = mitaka::gui::load_observer_places(root);
    require(loaded.places.size() == 9 && loaded.sources[0].catalog->places.size() == 10,
            "known Moon duplicates use the same last-wins rule as planets");
    require(loaded.places[2].name_bytes == "Moon replacement" && loaded.origins[2].place == 3,
            "Moon replacement preserves winning record and provenance");
    require(loaded.warnings.size() == 5, "unsupported or incomplete Moon IDs remain unresolved");
    require(observer_place_body_index(loaded.places[0]) == 3 &&
            observer_place_body_index(loaded.places[1]) == 4 &&
            observer_place_body_index(loaded.places[2]) == 10,
            "Earth, Mars and Moon IDs resolve to the solar model indices");
    require(mitaka::gui::observer_place_is_earth(loaded.places[0]) &&
            !mitaka::gui::observer_place_is_earth(loaded.places[1]) &&
            !mitaka::gui::observer_place_is_earth(loaded.places[2]),
            "existing Earth-only behavior is retained");
    for (std::size_t index = 3; index < loaded.places.size(); ++index)
        require(!observer_place_body_index(loaded.places[index]),
                "unsupported bodies and malformed IDs do not resolve");
    require(std::string(loaded.sources[0].bytes.begin(), loaded.sources[0].bytes.end()) == original,
            "source bytes remain unchanged");
}

void test_local(const std::filesystem::path& directory) {
    const auto loaded = mitaka::gui::load_observer_places(directory);
    std::optional<std::filesystem::path> selected;
    for (const auto* name : names) {
        const auto path = directory / name;
        const bool exists = std::filesystem::exists(path);
        const auto found = std::find_if(loaded.sources.begin(), loaded.sources.end(), [&](const auto& source) {
            return source.path == path;
        });
        require((found != loaded.sources.end()) == exists, "each local candidate presence is reflected");
        if (!exists) {
            require(std::find(loaded.missing_files.begin(), loaded.missing_files.end(), name) != loaded.missing_files.end(),
                    "optional local absence is explicit");
            continue;
        }
        if (!selected) selected = path;
        const auto original = read(path);
        require(std::string(found->bytes.begin(), found->bytes.end()) == original, "all local candidate bytes retained");
        if (path.filename() == "defaultplaces.dat" && found->catalog) {
            const auto& places = found->catalog->places;
            const auto verify = [&](const std::string& id, std::size_t body) {
                const auto place = std::find_if(places.begin(), places.end(), [&](const auto& row) {
                    return row.target_name == id;
                });
                if (place != places.end())
                    require(mitaka::gui::observer_place_body_index(*place) == body,
                            "known real-data place resolves to its own body");
            };
            verify("Satellite.Moon.NorthPole", 10);
            verify("Planet.Mars.OlympusMons", 4);
        }
    }
    require(bool(loaded.selected_source) == bool(selected), "local selection presence follows source existence");
    if (selected) {
        const auto& source = loaded.sources[*loaded.selected_source];
        require(source.path == *selected, "local effective source follows exclusive priority");
        if (source.error) require(loaded.places.empty() && !loaded.warnings.empty(), "invalid local source diagnosed");
        else {
            require(loaded.origins.size() == loaded.places.size(), "all effective local rows retain provenance");
            for (std::size_t index = 0; index < loaded.places.size(); ++index) {
                require(loaded.origins[index].source == *loaded.selected_source, "local rows come only from selected file");
                same_place(loaded.places[index], source.catalog->places.at(loaded.origins[index].place));
            }
        }
    }
    std::cout << "Local observer places: " << loaded.places.size() << ", source rows: " << loaded.source_place_count
              << ", sources: " << loaded.sources.size() << ", selected: "
              << (selected ? selected->filename().string() : "none") << ", warnings: " << loaded.warnings.size() << '\n';
}
} // namespace

int main(int argc, char** argv) {
    const auto root = std::filesystem::temp_directory_path() /
        ("mitaka_places_" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    try {
        require(std::filesystem::create_directory(root), "create temporary fixtures");
        test_selection(root);
        test_errors_and_empty(root);
        test_keys(root);
        test_body_resolution(root);
        std::filesystem::remove_all(root);
        if (argc > 1) test_local(argv[1]);
        std::cout << "Observer places: " << checks << " checks passed\n";
        return 0;
    } catch (const std::exception& failure) {
        std::error_code error;
        std::filesystem::remove_all(root, error);
        std::cerr << failure.what() << '\n';
        return 1;
    }
}
