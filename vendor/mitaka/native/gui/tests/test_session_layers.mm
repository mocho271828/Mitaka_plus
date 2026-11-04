#include "session_layers.hpp"

#include <algorithm>
#include <iostream>
#include <stdexcept>

namespace {
using namespace mitaka;
using namespace mitaka::gui;
int checks = 0;
void check(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
template<class Function> void rejects(Function operation) {
    ++checks;
    try { operation(); } catch (const std::invalid_argument&) { return; }
    throw std::runtime_error("invalid session layer accepted");
}
std::shared_ptr<SmallBodyDataset> small_fixture() {
    auto data = std::make_shared<SmallBodyDataset>();
    data->sources = {{"mp.dat", "unused/mp.dat", "packed original", 2, true},
                     {std::string("\x82\xa0.dat"), "unused/local.dat", "local original", 1, true}};
    for (const auto& source : data->sources) {
        for (std::size_t ordinal = 0; ordinal < source.record_count; ++ordinal) {
            SmallBodyRecord record;
            record.id = {source.key, ordinal};
            record.kind = source.key == "mp.dat" ? SmallBodyKind::asteroid : SmallBodyKind::comet;
            record.name_bytes = "Repeated name";
            data->records.push_back(record);
        }
    }
    return data;
}
SatelliteDataset satellite_fixture() {
    SatelliteDataset data;
    data.sources = {{"ssystem.dat", "unused/ssystem.dat", SatelliteSourceKind::system_definition,
                     "definition original", true,true,false,4},
                    {"orbit.dat", "unused/orbit.dat", SatelliteSourceKind::orbit,
                     "orbit original", true,true,false,1}};
    for (std::size_t ordinal = 0; ordinal < 4; ++ordinal) {
        SatelliteDefinition definition;
        definition.id = {"ssystem.dat", ordinal};
        definition.kind = ordinal == 0 ? SatelliteDefinitionKind::system
            : ordinal == 1 ? SatelliteDefinitionKind::planet : SatelliteDefinitionKind::satellite;
        if (ordinal >= 2) definition.parent_ordinal = 1;
        definition.fields.push_back({"Name", "Repeated name",0,0,0,std::nullopt});
        data.definitions.push_back(definition);
    }
    return data;
}
SatelliteDisplayModel satellite_display(SatelliteDataset data) {
    return SatelliteDisplayModel(std::make_shared<const SatelliteModel>(std::move(data)));
}
void small_body_restore() {
    const auto data = small_fixture();
    SmallBodyDisplayModel current(data);
    current.set_selected_ids({data->records[0].id});
    auto saved_display = current;
    saved_display.set_kind_options(SmallBodyKind::comet, {false,true,true,true});
    saved_display.set_selected_ids({data->records[2].id, data->records[1].id});
    const auto saved = capture_small_body_session(saved_display, true, {2451500,2451600,33});
    check(saved.visible && saved.sources.size() == 2 && saved.orbit_sampling.sample_count == 33,
          "capture preserves master, sampling and selected source proofs");
    const auto restored = prepare_small_body_session(saved, current);
    check(restored->contains(data->records[1].id) && restored->contains(data->records[2].id)
          && !restored->contains(data->records[0].id), "selection restored by raw source and ordinal");
    const auto options = restored->kind_options(SmallBodyKind::comet);
    check(!options.visible && options.labels && options.orbits && options.selected_only,
          "independent kind flags restored");
    check(current.contains(data->records[0].id) && !current.contains(data->records[1].id),
          "prepared model leaves current selection unchanged");
    auto reordered = std::make_shared<SmallBodyDataset>(*data);
    std::reverse(reordered->records.begin(), reordered->records.end());
    std::reverse(reordered->sources.begin(), reordered->sources.end());
    reordered->sources[0].path = "different/location";
    check(prepare_small_body_session(saved, SmallBodyDisplayModel(reordered))->selected_ids().size() == 2,
          "file relocation and row reorder preserve source identity");
    for (int scenario = 0; scenario < 6; ++scenario) {
        auto invalid = saved;
        switch (scenario) {
            case 0: invalid.selected_ids[0].record_ordinal = 99; break;
            case 1: invalid.selected_ids.push_back(invalid.selected_ids[0]); break;
            case 2: invalid.sources[0].sha256[0] = invalid.sources[0].sha256[0] == '0' ? '1' : '0'; break;
            case 3: ++invalid.sources[0].byte_count; break;
            case 4: invalid.sources.pop_back(); break;
            case 5: invalid.orbit_sampling.sample_count = 1; break;
        }
        rejects([&] { prepare_small_body_session(invalid, current); });
        check(current.selected_ids().size() == 1 && current.contains(data->records[0].id),
              "failed restore never partially changes current set");
    }
    auto changed = std::make_shared<SmallBodyDataset>(*data);
    changed->sources[0].bytes[0] = 'P';
    rejects([&] { prepare_small_body_session(saved, SmallBodyDisplayModel(changed)); });
    auto empty = capture_small_body_session(SmallBodyDisplayModel(data), false, {2451500,2451600,2});
    check(empty.sources.empty() && prepare_small_body_session(empty, SmallBodyDisplayModel(changed))->selected_ids().empty(),
          "empty selection needs no source proof and clears existing membership");
}
void satellite_restore() {
    const auto data = satellite_fixture();
    auto current = satellite_display(data);
    current.set_selected_ids({{"ssystem.dat",2}});
    auto saved_display = current;
    saved_display.set_options({false,true,true,true});
    saved_display.set_selected_ids({{"ssystem.dat",3}});
    const auto saved = capture_satellite_session(saved_display);
    check(saved.sources.size() == 1 && saved.sources[0].source_key == "ssystem.dat",
          "satellite proof contains definition source only");
    const auto restored = prepare_satellite_session(saved, current);
    check(!restored->options().visible && restored->options().labels && restored->options().orbits
          && restored->options().selected_only && restored->contains({"ssystem.dat",3}),
          "all satellite options and membership restored");
    auto orbit_changed = data;
    orbit_changed.sources[1].bytes += "new ephemeris";
    check(prepare_satellite_session(saved, satellite_display(orbit_changed))->contains({"ssystem.dat",3}),
          "orbit changes retain definition identity");
    auto definition_changed = data;
    definition_changed.sources[0].bytes += "changed";
    rejects([&] { prepare_satellite_session(saved, satellite_display(definition_changed)); });
    auto invalid = saved;
    invalid.selected_ids.push_back({"ssystem.dat",1});
    rejects([&] { prepare_satellite_session(invalid, current); });
    check(current.selected_ids().size() == 1 && current.contains({"ssystem.dat",2}),
          "non-satellite identity rejects entire restore without mutation");
    invalid = saved;
    invalid.sources.push_back(session_source_identity("orbit.dat", data.sources[1].bytes));
    rejects([&] { prepare_satellite_session(invalid, current); });
}
void identities() {
    const auto identity = session_source_identity("key", "abc");
    check(identity.byte_count == 3 && identity.sha256 ==
          "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
          "SHA-256 uses standard known vector");
    rejects([] { session_source_identity("", "abc"); });
    rejects([] { session_source_identity(std::string("a\0b",3), "abc"); });
    ConstellationDisplayOptions constellations;
    constellations.exceptions = {std::string("\x82\xa0")};
    validate_session_layers({}, {}, constellations);
    check(constellations.exceptions.size() == 1, "non-UTF8 constellation identity remains raw bytes");
    constellations.exceptions = {std::string("a\0b",3)};
    rejects([&] { validate_session_layers({}, {}, constellations); });
}
} // namespace
int main() {
    try {
        small_body_restore(); satellite_restore(); identities();
        std::cout << "session layers: " << checks << " checks passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "session layers: " << error.what() << '\n';
        return 1;
    }
}
