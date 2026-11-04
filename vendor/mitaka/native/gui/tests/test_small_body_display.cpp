#include "small_body_display.hpp"

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
bool same_id(const SmallBodyId& a, const SmallBodyId& b) {
    return a.source_key == b.source_key && a.record_ordinal == b.record_ordinal;
}
bool same_options(SmallBodyKindDisplayOptions a, SmallBodyKindDisplayOptions b) {
    return a.visible == b.visible && a.labels == b.labels && a.orbits == b.orbits
        && a.selected_only == b.selected_only;
}
std::shared_ptr<SmallBodyDataset> fixture() {
    auto data = std::make_shared<SmallBodyDataset>();
    data->sources = {{"mp.dat", "unused/mp.dat", "packed original", 2, true},
                     {"TNO.dat", "unused/TNO.dat", "TNO original", 2, true},
                     {"comets.dat", "unused/comets.dat", "JPL original", 2, true},
                     {"orbits/comets/local.dat", "unused/local.dat", "local original", 1, true},
                     {"orbits/comets/local_jp.dat", "unused/local_jp.dat", "local JP original", 1, true},
                     {"missing.dat", "unused/missing.dat", "", 0, false}};
    const SmallBodyKind kinds[]{SmallBodyKind::asteroid, SmallBodyKind::trans_neptunian, SmallBodyKind::comet};
    for (std::size_t source = 0; source < 5; ++source) {
        for (std::size_t ordinal = 0; ordinal < data->sources[source].record_count; ++ordinal) {
            SmallBodyRecord record;
            record.id = {data->sources[source].key, ordinal};
            record.kind = kinds[std::min(source, std::size_t{2})];
            record.name_bytes = "Repeated name";
            record.number = -1;
            record.raw_record_bytes = "record raw bytes";
            data->records.push_back(record);
        }
    }
    return data;
}
void kind_options_and_sets() {
    const auto data = fixture();
    SmallBodyDisplayModel model(data);
    expect(model.dataset().get() == data.get(), "source model retained without replacement");
    expect(model.selected_ids().empty(), "native initial membership is explicit empty set");
    for (const auto& record : data->records) {
        const auto options = model.kind_options(record.kind);
        expect(options.visible && !options.labels && !options.orbits && !options.selected_only,
               "native initial options do not infer raw Visible fields");
    }
    for (std::size_t kind_index = 0; kind_index < 3; ++kind_index) {
        const std::size_t first = kind_index * 2;
        const auto kind = data->records[first].kind;
        model.set_selected_ids({data->records[first].id});
        for (unsigned mask = 0; mask < 16; ++mask) {
            const SmallBodyKindDisplayOptions options{bool(mask & 1), bool(mask & 2),
                                                     bool(mask & 4), bool(mask & 8)};
            model.set_kind_options(kind, options);
            expect(same_options(model.kind_options(kind), options), "all four options readable");
            for (std::size_t offset = 0; offset < 2; ++offset) {
                const auto layer = model.visibility(first + offset);
                const bool visible = options.visible && (!options.selected_only || offset == 0);
                expect(layer.body == visible && layer.label == (visible && options.labels)
                       && layer.orbit == (visible && options.orbits), "kind master and membership truth table");
            }
            const std::size_t other = ((kind_index + 1) % 3) * 2;
            expect(model.visibility(other).body, "one kind never changes another kind");
            expect(model.contains(data->records[first].id), "hiding kind never erases membership");
        }
        model.set_kind_options(kind, {});
    }
    model.set_kind_options(SmallBodyKind::comet, {true,true,true,true});
    model.set_selected_ids({data->records[7].id, data->records[4].id});
    expect(model.selected_ids().size() == 2, "multiple selected display rows independent of click selection");
    expect(model.visibility(4).body && !model.visibility(5).body
           && !model.visibility(6).body && model.visibility(7).body,
           "identical names and numbers remain source ordinal identities");
    model.set_selected_ids({});
    expect(!model.visibility(4).body && !model.visibility(7).body, "empty selected-only set hides every row");
    model.set_kind_options(SmallBodyKind::comet, {true,true,true,false});
    expect(model.visibility(4).label && model.visibility(7).orbit, "all rows restored without repopulating set");
}
void invalid_inputs() {
    const auto data = fixture();
    SmallBodyDisplayModel model(data);
    model.set_selected_ids({data->records[0].id});
    rejected([&] { model.set_selected_ids({data->records[1].id, {"unknown.dat", 0}}); });
    expect(model.selected_ids().size() == 1 && model.contains(data->records[0].id),
           "unknown ID rejects whole update");
    rejected([&] { model.set_selected_ids({data->records[1].id, data->records[1].id}); });
    expect(model.contains(data->records[0].id) && !model.contains(data->records[1].id),
           "duplicate ID rejects whole update");
    rejected([&] { model.set_selected_ids({{"mp.dat", 2}}); });
    expect(!model.contains({"unknown.dat", 0}), "unknown ID query is false");
    rejected<std::out_of_range>([&] { model.visibility(data->records.size()); });
    rejected([&] { model.kind_options(static_cast<SmallBodyKind>(-1)); });
    rejected([&] { model.set_kind_options(static_cast<SmallBodyKind>(-1), {}); });
    rejected([] { SmallBodyDisplayModel(nullptr); });
    SmallBodyDisplayModel empty(std::make_shared<const SmallBodyDataset>());
    expect(empty.selected_ids().empty(), "empty dataset valid");

    for (int scenario = 0; scenario < 7; ++scenario) {
        auto bad = fixture();
        switch (scenario) {
            case 0: bad->sources.front().key.clear(); break;
            case 1: bad->sources.push_back(bad->sources.front()); break;
            case 2: bad->records.push_back(bad->records.front()); break;
            case 3: bad->records.front().id.source_key = "unknown.dat"; break;
            case 4: bad->records.front().id.record_ordinal = 2; break;
            case 5: bad->sources.front().loaded = false; break;
            case 6: bad->records.front().kind = static_cast<SmallBodyKind>(-1); break;
        }
        rejected([&] { SmallBodyDisplayModel invalid(bad); });
        rejected([&] { model.rebind(bad); });
        expect(model.dataset().get() == data.get() && model.contains(data->records[0].id),
               "invalid rebind is atomic");
    }
}
void source_rebinding() {
    auto data = fixture();
    SmallBodyDisplayModel model(data);
    model.set_kind_options(SmallBodyKind::comet, {false,true,true,true});
    model.set_selected_ids({data->records[0].id, data->records[4].id, data->records[6].id, data->records[7].id});
    auto same = std::make_shared<SmallBodyDataset>(*data);
    std::reverse(same->records.begin(), same->records.end());
    std::reverse(same->sources.begin(), same->sources.end());
    for (auto& source : same->sources) source.path = "different/location";
    auto report = model.rebind(same);
    expect(report.retained_count == 4 && report.removed_ids.empty(), "byte-identical sources retain stable IDs after reorder");
    expect(same_options(model.kind_options(SmallBodyKind::comet), {false,true,true,true}),
           "static kind settings survive rebind");

    auto changed = std::make_shared<SmallBodyDataset>(*same);
    const auto source = std::find_if(changed->sources.begin(), changed->sources.end(),
                                    [](const auto& item) { return item.key == "comets.dat"; });
    source->bytes += "changed bytes";
    report = model.rebind(changed);
    expect(report.retained_count == 3 && report.removed_ids.size() == 1
           && same_id(report.removed_ids.front(), data->records[4].id), "changed source explicitly drops membership");
    expect(!model.contains(data->records[4].id), "same numeric ordinal cannot bind to changed source");
    expect(model.contains(data->records[6].id) && model.contains(data->records[7].id),
           "independent local and language definitions remain selected");

    auto missing = std::make_shared<SmallBodyDataset>(*changed);
    missing->records.erase(std::remove_if(missing->records.begin(), missing->records.end(),
        [](const auto& item) { return item.id.source_key == "orbits/comets/local.dat"; }), missing->records.end());
    missing->sources.erase(std::remove_if(missing->sources.begin(), missing->sources.end(),
        [](const auto& item) { return item.key == "orbits/comets/local.dat"; }), missing->sources.end());
    report = model.rebind(missing);
    expect(report.retained_count == 2 && report.removed_ids.size() == 1
           && same_id(report.removed_ids.front(), data->records[6].id), "missing source reported without shifting IDs");

    auto kind_changed = std::make_shared<SmallBodyDataset>(*missing);
    const auto row = std::find_if(kind_changed->records.begin(), kind_changed->records.end(),
                                 [](const auto& item) { return item.id.source_key == "orbits/comets/local_jp.dat"; });
    row->kind = SmallBodyKind::asteroid;
    report = model.rebind(kind_changed);
    expect(report.retained_count == 1 && report.removed_ids.size() == 1,
           "kind change is not silently rebound even with unchanged source bytes");
    expect(model.contains(data->records[0].id), "unrelated member preserved");
    expect(data->sources[2].bytes == "JPL original" && data->records.size() == 8
           && data->records[7].kind == SmallBodyKind::comet, "original model never rewritten");
}
void local_data(const std::filesystem::path& root) {
    const auto data = std::make_shared<const SmallBodyDataset>(load_small_body_dataset(root));
    SmallBodyDisplayModel model(data);
    std::vector<SmallBodyId> ids;
    for (const auto& record : data->records) ids.push_back(record.id);
    model.set_selected_ids(ids);
    expect(model.selected_ids().size() == data->records.size(), "all local rows retained without cap or name merge");
    for (auto kind : {SmallBodyKind::asteroid, SmallBodyKind::trans_neptunian, SmallBodyKind::comet})
        model.set_kind_options(kind, {true,true,true,true});
    for (std::size_t row = 0; row < data->records.size(); ++row) {
        const auto layers = model.visibility(row);
        expect(layers.body && layers.label && layers.orbit, "every selected local identity represented");
    }
    const auto report = model.rebind(std::make_shared<const SmallBodyDataset>(load_small_body_dataset(root)));
    expect(report.retained_count == ids.size() && report.removed_ids.empty(), "read-only reload retains every original-byte identity");
    std::cout << "local sources=" << data->sources.size() << " rows=" << data->records.size() << '\n';
}
} // namespace

int main(int argc, char** argv) {
    try {
        kind_options_and_sets(); invalid_inputs(); source_rebinding();
        if (argc == 2) local_data(argv[1]);
        else if (argc != 1) throw std::invalid_argument("usage: test_small_body_display [data_directory]");
        std::cout << "small_body_display: " << checks << " checks passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "small_body_display: " << error.what() << '\n';
        return 1;
    }
}
