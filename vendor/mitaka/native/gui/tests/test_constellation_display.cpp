#include "constellation_display.hpp"
#include <algorithm>
#include <iostream>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
unsigned checks = 0;
void check(bool condition, const char* message) { ++checks; if (!condition) throw std::runtime_error(message); }
template<class Error = std::invalid_argument, class Action> void rejects(Action action) {
    try { action(); } catch (const Error&) { ++checks; return; }
    throw std::runtime_error("expected exception was not thrown");
}
ConstellationRecord record(std::string id) { ConstellationRecord value{}; value.abbreviation = std::move(id); return value; }
bool same(const ConstellationDisplayOptions& a, const ConstellationDisplayOptions& b) {
    return a.lines == b.lines && a.boundaries == b.boundaries && a.labels == b.labels
        && a.default_visible == b.default_visible && a.exceptions == b.exceptions && a.illustrations == b.illustrations;
}
void synthetic() {
    ConstellationDisplayModel empty({});
    check(empty.row_count() == 0 && empty.abbreviations().empty(), "empty catalog is valid");
    rejects<std::out_of_range>([&] { empty.visibility(0); });
    const std::string raw("\x83\x5c\0", 3);
    std::vector<ConstellationRecord> rows{record("Ser"), record("Ser"), record("Ori"), record("ori"), record("All"), record(raw), record("")};
    for (unsigned index = 0; index < 120; ++index) rows.push_back(record("Local" + std::to_string(index)));
    ConstellationDisplayModel model(rows);
    check(model.row_count() == rows.size() && model.abbreviations().size() == rows.size() - 1, "all original rows and raw IDs retained");
    for (unsigned flags = 0; flags < 16; ++flags) {
        auto options = model.options();
        options.lines = (flags & 1) != 0; options.boundaries = (flags & 2) != 0; options.labels = (flags & 4) != 0;
        options.illustrations = (flags & 8) != 0;
        model.set_options(options);
        for (bool member : {false, true}) {
            model.set_visible({"Ser", "Ser"}, member);
            check(model.membership("Ser") == member, "membership must be independent of global layers");
            for (unsigned index : {0, 1}) {
                const auto effective = model.visibility(index);
                check(effective.lines == (member && options.lines) && effective.boundaries == (member && options.boundaries)
                    && effective.labels == (member && options.labels)
                    && effective.illustrations == (member && options.illustrations), "both Ser figures must share all layer membership");
            }
        }
    }
    model.set_visible({"All", raw, ""}, false);
    check(!model.membership("All") && !model.membership(raw) && !model.membership("") && model.membership("Ori"), "All must not gain an undocumented string meaning");
    model.set_visible({"Ori"}, false);
    check(model.membership("ori"), "native raw identifiers must be case-sensitive");
    auto before = model.options();
    rejects([&] { model.set_visible({"Ser", "unknown"}, false); });
    check(same(before, model.options()), "mixed known/unknown update must be atomic");
    auto invalid = before; invalid.lines = !invalid.lines; invalid.exceptions.insert("unknown");
    rejects([&] { model.set_options(invalid); });
    check(same(before, model.options()), "invalid whole options must not partly update");
    rejects([&] { model.membership("unknown"); });
    rejects<std::out_of_range>([&] { model.visibility(rows.size()); });
    model.set_all_visible(false);
    check(model.options().exceptions.empty() && !model.membership("Ser") && model.options().lines == before.lines,
        "all-hide resets exceptions without touching layers");
    model.set_visible({"Ser", raw}, true);
    const auto report = model.rebind({record("New"), record("Ser"), record("Ser")});
    check(report.removed_exceptions == std::vector<std::string>{raw}, "rebind must report every vanished exception");
    check(model.row_count() == 3 && !model.membership("New") && model.membership("Ser")
        && model.visibility(1).lines && model.visibility(2).lines, "rebind preserves matching raw IDs and default for new rows");
    model.set_all_visible(true);
    check(model.options().exceptions.empty() && model.membership("New"), "all-show restores complete membership");
    check(rows[0].abbreviation == "Ser" && rows[1].abbreviation == "Ser" && rows[5].abbreviation == raw,
        "display settings must not modify original records");
}
void local(const char* directory) {
    const auto path = std::filesystem::path(directory) / "constellation_HIP.dat";
    const auto rows = std::filesystem::exists(path) ? load_constellations(path)
        : std::vector<ConstellationRecord>{};
    ConstellationDisplayModel model(rows);
    check(model.row_count() == rows.size(), "local catalog row count changed");
    for (const auto& id : model.abbreviations()) {
        model.set_visible({id}, false);
        for (std::size_t index = 0; index < rows.size(); ++index)
            check(model.visibility(index).lines == (rows[index].abbreviation != id), "local raw ID did not control all matching rows");
        model.set_visible({id}, true);
    }
    std::cout << "local rows=" << rows.size() << " identities=" << model.abbreviations().size() << '\n';
}
}
int main(int argc, char** argv) {
    try { synthetic(); if (argc > 1) local(argv[1]); std::cout << "Constellation display tests passed: " << checks << " checks\n"; }
    catch (const std::exception& error) { std::cerr << "FAIL: " << error.what() << '\n'; return 1; }
}
