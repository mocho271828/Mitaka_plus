#include "place_display_model.hpp"

#include <fstream>
#include <iostream>
#include <iterator>
#include <map>
#include <stdexcept>
#include <type_traits>
#include <utility>

namespace {
using namespace mitaka;
using namespace mitaka::gui;
std::size_t checks = 0;

void require(bool condition, const std::string& message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}

PlaceLabelGroup group(std::string name, double size) {
    return {std::move(name), size / 100.0, size, {0.1, 0.2, 0.3, 0.4}};
}

PlaceLandscape landscape(std::string target, std::string name, std::string image) {
    return {std::move(target), std::move(name), std::move(image), 0.25, {0.125, 90.0}};
}

ObserverPlaces fixture() {
    ObserverPlaces result;
    result.sources.push_back({"defaultplaces_jp.dat", {'d', '\0', '\r', '\n'}, PlaceCatalog{}, {}});
    result.sources.back().catalog->label_groups = {group("Ignored", 1)};
    result.sources.back().catalog->landscapes = {landscape("Planet.Earth", "Ignored", "ignored.png")};
    result.sources.push_back({"places_jp.dat", {'u', '\0', '\r', '\n', static_cast<char>(0x83)}, PlaceCatalog{}, {}});
    auto& catalog = *result.sources.back().catalog;
    catalog.label_groups = {group("Default", 1), group("default", 2), group("Other", 3), group("Default", 4)};
    catalog.landscapes = {
        landscape("Planet.Earth", "City", "first.png"),
        landscape("Planet.Mars", "City", "mars.png"),
        landscape("Planet.Earth", "city", "lowercase.png"),
        landscape("Planet.Earth", "City", "last.png"),
        landscape("Unknown.A", "B", "unknown-first.png"),
        landscape("Unknown", "A.B", "unknown-last.png")};
    catalog.places = {{"Planet.Earth.Site", "Local", 499.5, -30, "Other", "City"}};
    result.selected_source = 1;
    result.places = catalog.places;
    result.origins = {{1, 0}};
    result.source_place_count = 1;
    result.warnings = {"retained diagnostic"};
    result.missing_files = {"places.dat"};
    return result;
}

void test_effective_and_snapshot() {
    auto input = fixture();
    const PlaceDisplayModel model(input);
    const auto& groups = model.label_groups();
    const auto& landscapes = model.landscapes();
    require(groups.size() == 3 && groups[0].definition.name == "Default" && groups[0].definition.size == 4 &&
            groups[1].definition.name == "default" && groups[2].definition.name == "Other",
            "label group exact keys use last value at the first insertion position");
    require(groups[0].origin.source == 1 && groups[0].origin.row == 3 &&
            groups[1].origin.row == 1 && groups[2].origin.row == 2, "group provenance follows winning rows");
    require(landscapes.size() == 4 && landscapes[0].qualified_name == "Planet.Earth.City" &&
            landscapes[0].definition.image_path_bytes == "last.png" &&
            landscapes[1].qualified_name == "Planet.Mars.City" &&
            landscapes[2].qualified_name == "Planet.Earth.city", "landscape target and case are part of exact key");
    require(landscapes[3].qualified_name == "Unknown.A.B" &&
            landscapes[3].definition.target_name == "Unknown" && landscapes[3].origin.row == 5,
            "qualified key concatenation preserves original duplicate collision semantics without resolving target");
    require(landscapes[0].origin.source == 1 && landscapes[0].origin.row == 3 &&
            landscapes[0].definition.offset_arguments == std::array<double, 2>{0.125, 90},
            "landscape provenance and raw argument order retained");
    require(model.find_label_group("Default") == 0 && model.find_label_group("default") == 1 &&
            !model.find_label_group("") && !model.find_label_group("DEFAULT") && !model.find_label_group("Ignored"),
            "exact group lookup does not invent default or merge unselected sources");
    require(model.find_landscape("Planet.Mars.City") == 1 && !model.find_landscape("City") &&
            !model.find_landscape("Planet.earth.City") && !model.find_landscape("Planet.Earth.Ignored"),
            "exact qualified landscape lookup does not resolve body aliases or default");
    input.sources[1].bytes.clear();
    input.sources[1].catalog->label_groups.clear();
    input.places[0].name_bytes = "Changed";
    const auto& retained = model.observer_places();
    require(retained.sources[1].bytes == std::vector<char>{'u', '\0', '\r', '\n', static_cast<char>(0x83)} &&
            retained.sources[1].catalog->label_groups.size() == 4 && retained.sources[1].catalog->landscapes.size() == 6,
            "snapshot owns all original bytes and overwritten rows independently of input");
    require(retained.places[0].name_bytes == "Local" && retained.places[0].longitude_degrees == 499.5 &&
            retained.origins[0].source == 1 && retained.origins[0].place == 0 &&
            retained.source_place_count == 1 && retained.warnings == std::vector<std::string>{"retained diagnostic"} &&
            retained.missing_files == std::vector<std::string>{"places.dat"}, "observer data and diagnostics remain intact");
}

void test_absence_and_failure() {
    const PlaceDisplayModel empty(ObserverPlaces{});
    require(empty.label_groups().empty() && empty.landscapes().empty(), "empty input stays empty");
    auto input = fixture();
    input.selected_source.reset();
    const PlaceDisplayModel unselected(input);
    require(unselected.label_groups().empty() && unselected.observer_places().sources.size() == 2,
            "unselected sources remain available but do not contribute effective data");
    input.selected_source = 1;
    input.sources[1].catalog.reset();
    const PlaceDisplayModel failed(input);
    require(failed.label_groups().empty() && failed.landscapes().empty() && !failed.observer_places().sources[1].bytes.empty(),
            "selected parse failure retains bytes without fallback to a valid source");
    input.selected_source = 2;
    bool rejected = false;
    try { const PlaceDisplayModel invalid(input); }
    catch (const std::invalid_argument&) { rejected = true; }
    require(rejected, "out of range selected source is rejected");
}

void test_local(const std::filesystem::path& directory) {
    const PlaceDisplayModel model(load_observer_places(directory));
    const auto& loaded = model.observer_places();
    for (const auto& source : loaded.sources) {
        std::ifstream file(source.path, std::ios::binary);
        require(bool(file), "open local source independently");
        const std::vector<char> bytes{std::istreambuf_iterator<char>(file), std::istreambuf_iterator<char>()};
        require(!file.bad() && bytes == source.bytes, "all local source bytes retained");
    }
    std::map<std::string, std::size_t> last_groups;
    std::map<std::string, std::size_t> last_landscapes;
    if (loaded.selected_source && loaded.sources[*loaded.selected_source].catalog) {
        const auto& catalog = *loaded.sources[*loaded.selected_source].catalog;
        for (std::size_t row = 0; row < catalog.label_groups.size(); ++row) last_groups[catalog.label_groups[row].name] = row;
        for (std::size_t row = 0; row < catalog.landscapes.size(); ++row) {
            const auto& landscape = catalog.landscapes[row];
            last_landscapes[landscape.target_name + "." + landscape.name] = row;
        }
    }
    require(model.label_groups().size() == last_groups.size() && model.landscapes().size() == last_landscapes.size(),
            "every distinct selected local definition survives exactly once");
    for (const auto& group : model.label_groups()) {
        require(group.origin.source == loaded.selected_source, "local group belongs to sole selected source");
        const auto& raw = loaded.sources.at(group.origin.source).catalog->label_groups.at(group.origin.row);
        require(raw.name == group.definition.name && raw.display_distance == group.definition.display_distance &&
                raw.size == group.definition.size && raw.rgba == group.definition.rgba, "all winning group fields preserved");
        require(last_groups.at(group.definition.name) == group.origin.row, "local group origin is the last matching row");
    }
    for (const auto& landscape : model.landscapes()) {
        require(landscape.origin.source == loaded.selected_source, "local landscape belongs to sole selected source");
        const auto& raw = loaded.sources.at(landscape.origin.source).catalog->landscapes.at(landscape.origin.row);
        require(raw.target_name == landscape.definition.target_name && raw.name == landscape.definition.name &&
                raw.image_path_bytes == landscape.definition.image_path_bytes && raw.vertical_scale == landscape.definition.vertical_scale &&
                raw.offset_arguments == landscape.definition.offset_arguments, "all winning landscape fields preserved");
        require(last_landscapes.at(landscape.qualified_name) == landscape.origin.row, "local landscape origin is the last matching row");
    }
    std::cout << "Local place display: sources=" << loaded.sources.size() << ", places=" << loaded.places.size()
              << ", groups=" << model.label_groups().size() << ", landscapes=" << model.landscapes().size() << '\n';
}
} // namespace

static_assert(std::is_same_v<decltype(std::declval<mitaka::gui::PlaceDisplayModel&>().observer_places()), const mitaka::gui::ObserverPlaces&>);
static_assert(std::is_same_v<decltype(std::declval<mitaka::gui::PlaceDisplayModel&>().label_groups()), const std::vector<mitaka::gui::EffectivePlaceLabelGroup>&>);

int main(int argc, char** argv) {
    try {
        test_effective_and_snapshot();
        test_absence_and_failure();
        for (int index = 1; index < argc; ++index) test_local(argv[index]);
        std::cout << "Place display model checks passed: " << checks << '\n';
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
