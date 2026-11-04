#include "satellite_display.hpp"

#include <algorithm>
#include <iostream>
#include <stdexcept>

namespace {
using namespace mitaka;
using namespace mitaka::gui;
int checks = 0;
void expect(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
template<class Exception = std::invalid_argument, class Function> void rejected(Function action) {
    bool result = false;
    try { action(); } catch (const Exception&) { result = true; }
    expect(result, "invalid display input rejected");
}
bool same_id(const SatelliteRecordId& a, const SatelliteRecordId& b) {
    return a.source_key == b.source_key && a.record_ordinal == b.record_ordinal;
}
bool same_options(SatelliteDisplayOptions a, SatelliteDisplayOptions b) {
    return a.visible == b.visible && a.labels == b.labels && a.orbits == b.orbits
        && a.selected_only == b.selected_only;
}
SatelliteDataset fixture() {
    SatelliteDataset data;
    data.sources = {
        {"ssystem.dat", "unused/ssystem.dat", SatelliteSourceKind::system_definition, "original", true,true,false,5},
        {"ssystem_jp.dat", "unused/ssystem_jp.dat", SatelliteSourceKind::system_definition, "JP original", true,true,true,5},
        {"orbits/missing.dat", "unused/missing.dat", SatelliteSourceKind::orbit, "", false,false,false,0}};
    for (std::size_t source = 0; source < 2; ++source) {
        for (std::size_t ordinal = 0; ordinal < 5; ++ordinal) {
            SatelliteDefinition definition;
            definition.id = {data.sources[source].key, ordinal};
            definition.kind = ordinal == 0 ? SatelliteDefinitionKind::system
                : ordinal == 1 ? SatelliteDefinitionKind::planet : SatelliteDefinitionKind::satellite;
            if (ordinal >= 2) definition.parent_ordinal = 1;
            if (ordinal != 4) definition.fields.push_back({"Name", "Rhea localized",0,0,0,std::nullopt});
            data.definitions.push_back(definition);
        }
    }
    return data;
}
std::shared_ptr<const SatelliteModel> model_from(SatelliteDataset data) {
    return std::make_shared<const SatelliteModel>(std::move(data));
}
void options_and_sets() {
    const auto source = model_from(fixture());
    SatelliteDisplayModel display(source);
    expect(display.model() == source && source->records().size() == 6, "all same-name and unnamed rows retained");
    expect(display.selected_ids().empty(), "native initial membership is empty");
    expect(same_options(display.options(), {true,false,false,false}), "native initial four options");
    for (std::size_t row = 0; row < source->records().size(); ++row) {
        expect(display.id_at(row).record_ordinal == row % 3 + 2, "original block ordinal is not filtered row");
        expect(display.row_for_id(display.id_at(row)) == row, "row and identity round trip");
        expect(!source->records()[row].position_elements, "unpositioned fixture row not removed");
    }
    display.set_selected_ids({display.id_at(0)});
    for (unsigned mask = 0; mask < 16; ++mask) {
        const SatelliteDisplayOptions options{bool(mask & 1),bool(mask & 2),bool(mask & 4),bool(mask & 8)};
        display.set_options(options);
        expect(same_options(display.options(), options), "all four flags readable");
        for (std::size_t row = 0; row < 2; ++row) {
            const bool body = options.visible && (!options.selected_only || row == 0);
            const auto layers = display.visibility(row);
            expect(layers.body == body && layers.label == (body && options.labels)
                && layers.orbit == (body && options.orbits), "visibility and membership truth table");
        }
        expect(display.contains(display.id_at(0)), "global hide never erases display set");
    }
    display.set_options({true,true,true,true});
    display.set_selected_ids({display.id_at(4), display.id_at(0), display.id_at(2)});
    for (std::size_t row = 0; row < 6; ++row)
        expect(display.visibility(row).body == (row == 0 || row == 2 || row == 4),
               "same-name rows and unnamed rows selected independently");
    const auto sorted = display.selected_ids();
    expect(same_id(sorted[0], display.id_at(0)) && same_id(sorted[2], display.id_at(4)), "stable source-ordinal output");
    display.set_selected_ids({});
    expect(!display.visibility(0).body && !display.visibility(4).body, "empty selected-only set hides all rows");
    display.set_options({true,true,true,false});
    expect(display.visibility(0).label && display.visibility(4).orbit, "disabling filter restores layers");
}
void invalid_inputs() {
    const auto source = model_from(fixture());
    SatelliteDisplayModel display(source);
    const auto selected = display.id_at(0);
    display.set_selected_ids({selected});
    display.set_options({false,true,true,true});
    rejected([&] { display.set_selected_ids({display.id_at(1), {"unknown.dat",0}}); });
    expect(display.selected_ids().size() == 1 && display.contains(selected), "unknown ID rejects whole set update");
    rejected([&] { display.set_selected_ids({display.id_at(1), display.id_at(1)}); });
    expect(display.contains(selected) && !display.contains(display.id_at(1)), "duplicate ID rejects whole set update");
    rejected([&] { display.set_selected_ids({{"ssystem.dat",1}}); });
    expect(!display.row_for_id({"ssystem.dat",1}) && !display.contains({"unknown.dat",0}), "non-satellite IDs unresolved");
    rejected<std::out_of_range>([&] { display.visibility(6); });
    rejected<std::out_of_range>([&] { display.id_at(6); });
    rejected([] { SatelliteDisplayModel invalid(nullptr); });
    rejected([&] { display.rebind(nullptr); });
    for (int scenario = 0; scenario < 8; ++scenario) {
        auto data = fixture();
        switch (scenario) {
            case 0: data.sources[0].key.clear(); break;
            case 1: data.sources.push_back(data.sources[0]); break;
            case 2: data.definitions[0].id.source_key = "unknown.dat"; break;
            case 3: data.definitions[0].id.record_ordinal = 5; break;
            case 4: data.definitions.push_back(data.definitions[0]); break;
            case 5: data.sources[0].kind = SatelliteSourceKind::orbit; break;
            case 6: data.sources[0].read_complete = false; break;
            case 7: data.sources[0].parsed = false; break;
        }
        const auto invalid = model_from(std::move(data));
        rejected([&] { SatelliteDisplayModel next(invalid); });
        rejected([&] { display.rebind(invalid); });
        expect(display.model() == source && display.contains(selected)
            && same_options(display.options(), {false,true,true,true}), "invalid rebind preserves model options and set");
    }
    SatelliteDisplayModel empty(model_from({}));
    expect(empty.selected_ids().empty(), "empty model accepted");
}
void rebinding() {
    const auto original = model_from(fixture());
    SatelliteDisplayModel display(original);
    const SatelliteRecordId first{"ssystem.dat",2}, second{"ssystem.dat",3}, localized{"ssystem_jp.dat",2};
    display.set_selected_ids({first,second,localized});
    display.set_options({false,true,true,true});
    auto data = fixture();
    std::reverse(data.sources.begin(), data.sources.end());
    std::reverse(data.definitions.begin(), data.definitions.end());
    for (auto& source : data.sources) source.path = "different/location";
    auto report = display.rebind(model_from(data));
    expect(report.retained_count == 3 && report.removed_ids.empty(), "identical bytes retain IDs across path/order change");
    expect(display.row_for_id(first) == 5, "reordered rows resolved using source ID");
    expect(same_options(display.options(), {false,true,true,true}), "options survive rebind");
    data.sources[0].bytes = "changed orbital data";
    report = display.rebind(model_from(data));
    expect(report.retained_count == 3 && report.removed_ids.empty(), "orbit bytes do not replace definition identity");
    data.sources[2].bytes += " edited definition";
    report = display.rebind(model_from(data));
    expect(report.retained_count == 1 && report.removed_ids.size() == 2
        && same_id(report.removed_ids[0], first) && same_id(report.removed_ids[1], second),
        "changed definition bytes explicitly drop its memberships");
    expect(display.contains(localized) && !display.contains(first), "other source untouched");
    for (auto& definition : data.definitions)
        if (same_id(definition.id, localized)) definition.kind = SatelliteDefinitionKind::planet;
    report = display.rebind(model_from(data));
    expect(report.retained_count == 0 && report.removed_ids.size() == 1, "row kind change cannot silently rebind");
    display.set_selected_ids({first});
    data.definitions.erase(std::remove_if(data.definitions.begin(), data.definitions.end(),
        [](const auto& item) { return item.id.source_key == "ssystem.dat"; }), data.definitions.end());
    data.sources.erase(std::remove_if(data.sources.begin(), data.sources.end(),
        [](const auto& item) { return item.key == "ssystem.dat"; }), data.sources.end());
    report = display.rebind(model_from(data));
    expect(report.removed_ids.size() == 1 && same_id(report.removed_ids[0], first), "removed source reported");
    expect(original->dataset().sources[0].bytes == "original" && original->records().size() == 6,
           "original immutable snapshot preserved");
}
void local_data(const std::filesystem::path& root) {
    const auto source = model_from(load_satellite_dataset(root));
    SatelliteDisplayModel display(source);
    std::vector<SatelliteRecordId> ids;
    std::size_t rhea = 0, proteus = 0;
    for (std::size_t row = 0; row < source->records().size(); ++row) {
        ids.push_back(display.id_at(row));
        rhea += source->records()[row].identifier_bytes == "Rhea";
        proteus += source->records()[row].identifier_bytes == "Proteus";
    }
    expect(rhea >= 4 && proteus >= 4, "local same-name rows retained across both definition sources");
    display.set_selected_ids(ids);
    display.set_options({true,true,true,true});
    expect(display.selected_ids().size() == source->records().size(), "all local satellite identities retained");
    for (std::size_t row = 0; row < source->records().size(); ++row) {
        const auto layers = display.visibility(row);
        expect(layers.body && layers.label && layers.orbit && display.row_for_id(ids[row]) == row,
               "every selected local identity represented without name merge");
    }
    const auto report = display.rebind(model_from(load_satellite_dataset(root)));
    expect(report.retained_count == ids.size() && report.removed_ids.empty(), "read-only identical reload retains all IDs");
    std::cout << "local sources=" << source->dataset().sources.size() << " rows=" << ids.size()
              << " Rhea=" << rhea << " Proteus=" << proteus << '\n';
}
} // namespace

int main(int argc, char** argv) {
    try {
        options_and_sets(); invalid_inputs(); rebinding();
        if (argc == 2) local_data(argv[1]);
        else if (argc != 1) throw std::invalid_argument("usage: test_satellite_display [data_directory]");
        std::cout << "satellite_display: " << checks << " checks passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "satellite_display: " << error.what() << '\n';
        return 1;
    }
}
