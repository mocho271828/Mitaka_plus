#include "script_object_identity.hpp"
#include <stdexcept>
#include <iostream>
using namespace mitaka;
using namespace mitaka::gui;
static void check(bool value, const char* message) { if (!value) throw std::runtime_error(message); }
int main(int argc, char** argv) {
    SmallBodyDataset small;
    SmallBodyRecord a; a.kind = SmallBodyKind::asteroid; a.number = 1; a.name_bytes = "Ceres"; a.alias_bytes = {"Dwarf"};
    SmallBodyRecord b; b.kind = SmallBodyKind::trans_neptunian; b.number = 1; b.name_bytes = "TNO name";
    SmallBodyRecord c; c.kind = SmallBodyKind::comet; c.name_bytes = "1P/Halley";
    small.records = {a,b,c};
    check(smallBodySnapshotTarget(&small, 0, {}, "") == "Asteroids.1", "GUI asteroid");
    check(smallBodySnapshotTarget(&small, 1, {}, "") == "TNO.1", "GUI TNO");
    check(smallBodySnapshotTarget(&small, 2, {}, "") == "Comet.1P/Halley", "GUI comet");
    check(smallBodySnapshotTarget(&small, 0, 0, "Asteroids.Dwarf") == "Asteroids.Dwarf", "existing alias retained");
    check(smallBodySnapshotTarget(&small, 0, 0, "Asteroids.Wrong") == "Asteroids.1", "stale prior alias");
    check(smallBodySnapshotTarget(nullptr, 0, 0, "Asteroids.1").empty(), "missing data");
    auto duplicate = a; duplicate.name_bytes = "Other"; duplicate.alias_bytes.clear(); small.records.push_back(duplicate);
    check(smallBodyScriptTarget(small, 0) == "Asteroids.Ceres", "ambiguous number falls back to name");
    small.records.back().name_bytes = "Ceres"; small.records.back().alias_bytes = {"Dwarf"};
    check(smallBodyScriptTarget(small, 0).empty(), "ambiguity never misidentifies");
    check(smallBodyScriptTarget(small, 99).empty(), "invalid index");
    small.records[2].name_bytes = "\x83\x5c";
    check(smallBodyScriptTarget(small, 2).empty(), "source bytes must not be mislabeled UTF8");
    SpacecraftDataset ships;
    SpacecraftDefinition ship; ship.fields.push_back({"Name", "Hayabusa", 0, 0, 0, {}}); ship.fields.push_back({"DisplayName", "MUSES-C", 0, 0, 0, {}});
    ships.definitions.push_back(ship);
    check(spacecraftSnapshotTarget(&ships, 0, {}, "") == "Spacecraft.Hayabusa", "GUI spacecraft");
    check(spacecraftSnapshotTarget(&ships, 0, 0, "Spacecraft.MUSES-C") == "Spacecraft.MUSES-C", "spacecraft alias retained");
    check(spacecraftSnapshotTarget(&ships, 0, 0, "Spacecraft.Wrong") == "Spacecraft.Hayabusa", "stale spacecraft alias");
    ships.definitions.push_back(ship);
    check(spacecraftSnapshotTarget(&ships, 0, 0, "Spacecraft.Hayabusa").empty(), "ambiguous prior alias");
    check(spacecraftSnapshotTarget(nullptr, 0, {}, "").empty(), "missing spacecraft data");
    SpacecraftDataset modern;
    SpacecraftDefinition modernShip;
    modernShip.fields.push_back({"KEY", "voyager", 0, 0, 0, {}});
    modernShip.fields.push_back({"NAME", "Voyager", 0, 0, 0, "default"});
    modern.definitions.push_back(modernShip);
    check(resolveScriptSpacecraft("Spacecraft.voyager", modern) == 0, "modern KEY resolves");
    check(resolveScriptSpacecraft("Spacecraft.Voyager", modern) == 0, "modern name resolves");
    check(spacecraftScriptTarget(modern, 0) == "Spacecraft.voyager", "modern getter");
    modern.definitions.push_back(modernShip);
    check(spacecraftScriptTarget(modern, 0).empty(), "modern ambiguity never misidentifies");
    SmallBodyDataset longNames;
    SmallBodyRecord longName; longName.kind = SmallBodyKind::comet; longName.name_bytes = std::string(4090, 'X');
    longNames.records.push_back(longName);
    check(smallBodyScriptTarget(longNames, 0).empty(), "getter rejects target truncated by Lua reply");
    check(smallBodySnapshotTarget(&longNames, 0, 0, "Comet." + longName.name_bytes).empty(), "previous long target rejected");
    SmallBodyDataset boundary;
    SmallBodyRecord atLimit; atLimit.kind = SmallBodyKind::comet; atLimit.name_bytes = std::string(4089, 'x');
    boundary.records.push_back(atLimit);
    check(smallBodyScriptTarget(boundary, 0).size() == 4095, "largest Lua text roundtrips");
    check(resolveScriptSmallBody(smallBodyScriptTarget(boundary, 0), boundary) == 0, "largest Lua text resolves");
    bool badPrefix = false;
    try { (void)resolveScriptSpacecraft("invalid", modern); } catch (const std::invalid_argument&) { badPrefix = true; }
    check(badPrefix, "invalid spacecraft prefix rejected");
    SmallBodyDataset unicode;
    SmallBodyRecord japanese; japanese.kind = SmallBodyKind::comet; japanese.name_bytes = "星";
    unicode.records.push_back(japanese);
    check(smallBodySnapshotTarget(&unicode, 0, 0, "Comet.星") == "Comet.星", "explicit UTF-8 target retained");
    check(smallBodyScriptTarget(unicode, 0).empty(), "undetermined source encoding is not guessed");
    SmallBodyDataset embeddedNull;
    SmallBodyRecord nul; nul.kind = SmallBodyKind::comet; nul.name_bytes = std::string("X\0Y", 3);
    embeddedNull.records.push_back(nul);
    check(smallBodySnapshotTarget(&embeddedNull, 0, 0, std::string("Comet.X\0Y", 9)).empty(), "embedded null cannot be truncated");
    if (argc > 1) {
        auto realSmall = load_small_body_dataset(argv[1]);
        bool seen[3] = {};
        for (std::size_t i = 0; i < realSmall.records.size(); ++i) {
            const auto kind = realSmall.records[i].kind;
            const int k = kind == SmallBodyKind::asteroid ? 0 : kind == SmallBodyKind::trans_neptunian ? 1 : 2;
            if (seen[k]) continue;
            const auto target = smallBodyScriptTarget(realSmall, i);
            if (target.empty()) continue;
            check(resolveScriptSmallBody(target, realSmall) == i, "real small-body roundtrip");
            seen[k] = true;
            if (seen[0] && seen[1] && seen[2]) break;
        }
        check(seen[0] && seen[1] && seen[2], "real data missing identifiable small-body kinds");
        auto realShips = load_spacecraft_dataset(argv[1]);
        bool shipSeen = false;
        for (std::size_t i = 0; i < realShips.definitions.size(); ++i) {
            const auto target = spacecraftScriptTarget(realShips, i);
            if (target.empty()) continue;
            check(resolveScriptSpacecraft(target, realShips) == i, "real spacecraft roundtrip");
            shipSeen = true; break;
        }
        check(shipSeen, "real data missing identifiable spacecraft");
        std::cout << "real data roundtrips passed\n";
    }
    std::cout << "object identity tests passed\n";
}
