#include "mitaka/place_catalog.hpp"

#include <chrono>
#include <fstream>
#include <iostream>

namespace {
void require(bool condition, const std::string& reason) {
    if (!condition) throw std::runtime_error(reason);
}

struct Fixture {
    std::filesystem::path path = std::filesystem::temp_directory_path() /
        ("mitaka_places_" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()) + ".dat");
    ~Fixture() { std::error_code error; std::filesystem::remove(path, error); }
    void write(const std::string& text) {
        std::ofstream output(path, std::ios::binary);
        output.write(text.data(), static_cast<std::streamsize>(text.size()));
        require(bool(output), "write place fixture");
    }
};

const std::string place = "Places:addPlace(\"Planet.Custom.Site\", \"A, B; -- C\", 721.25, -33.5, \"\", \"Scene\");";

void rejected(Fixture& fixture, const std::string& text, mitaka::CatalogLoadLimits limits = {}) {
    fixture.write(text);
    try {
        mitaka::load_plus_place_catalog(fixture.path, limits);
    } catch (const mitaka::CatalogError& error) {
        require(error.path() == fixture.path, "place error path");
        require(error.offset() <= text.size(), "place error offset in file");
        require(std::string(error.what()).find("byte ") != std::string::npos, "place error byte context");
        if (text.size() <= limits.max_file_bytes) {
            require(std::string(error.what()).find("line ") != std::string::npos, "place error line context");
        }
        return;
    }
    throw std::runtime_error("invalid place data accepted: " + text);
}

void test_literals(Fixture& fixture) {
    const std::string cp932_name("\x96\x6b\x8b\xc9", 4);
    fixture.write("-- synthetic fixture, no original user data\r\n\r\n"
        " Places : addLabelGroup('Default', 0, .8, 1, .5, 0, 1) ; -- label\r\n"
        "Places:addLandscape('Planet.Custom', 'Scene', '../local.png', 2.5e-1, -.4, -180);\n" + place +
        "\nPlaces:addPlace('Planet.Custom.Site', '" + cp932_name + "', -1.5E2, 90, '', '')");
    const auto result = mitaka::load_plus_place_catalog(fixture.path);
    require(result.places.size() == 2, "all places including repeated target retained");
    require(result.places[0].target_name == "Planet.Custom.Site" &&
        result.places[0].name_bytes == "A, B; -- C", "quoted punctuation is data");
    require(result.places[0].longitude_degrees == 721.25 && result.places[0].latitude_degrees == -33.5,
        "coordinate order and original longitude retained");
    require(result.places[1].name_bytes == cp932_name && result.places[1].longitude_degrees == -150 &&
        result.places[1].latitude_degrees == 90, "CP932 bytes and signed/exponent numbers");
    require(result.places[1].label_group.empty() && result.places[1].landscape.empty(), "default references retained");
    require(result.label_groups.size() == 1 && result.label_groups[0].name == "Default" &&
        result.label_groups[0].size == .8 && result.label_groups[0].rgba[1] == .5, "label parameters");
    require(result.landscapes.size() == 1 && result.landscapes[0].image_path_bytes == "../local.png" &&
        result.landscapes[0].vertical_scale == .25 && result.landscapes[0].offset_arguments[0] == -.4 &&
        result.landscapes[0].offset_arguments[1] == -180, "landscape arguments kept without path access");
    fixture.write("Places:addPlace('Planet.Custom.Site', 'a\\\'b\\\\c', +3, -90, '', '');");
    require(mitaka::load_plus_place_catalog(fixture.path).places[0].name_bytes == "a'b\\c", "literal quote escapes");
    const std::string cp932_backslash_trails("\x83\x5c\x94\x5c\x95\x5c", 6);
    fixture.write("Places:addPlace('Planet.Custom.Site', '" + cp932_backslash_trails +
        "', 0, 0, '', '');");
    require(mitaka::load_plus_place_catalog(fixture.path).places[0].name_bytes == cp932_backslash_trails,
        "CP932 trailing backslash bytes remain part of the character");
    fixture.write("");
    require(mitaka::load_plus_place_catalog(fixture.path).places.empty(), "empty input");
}

void test_errors(Fixture& fixture) {
    for (const auto& text : std::vector<std::string>{
        "os.execute('touch /tmp/should_not_exist')", "Places:addPlace(target, 'x', 0, 0, '', '')",
        "Places:addPlace('Planet.Earth.X', 'x', 1+2, 0, '', '')",
        "Places:addPlace('Planet.Earth.X', 'x', 0/0, 0, '', '')",
        "Places:addPlace('Planet.Earth.X', 'x', 1e999, 0, '', '')",
        "Places:addPlace('Planet.Earth.X', 'x', nan, 0, '', '')",
        "Places:addPlace('Planet.Earth.X', 'x', 0, 91, '', '')",
        "Places:addPlace('Planet.Earth.X', 'x', 0, -91, '', '')",
        "Places:addPlace('', 'x', 0, 0, '', '')",
        "Places:addPlace('Planet.Earth.X', '', 0, 0, '', '')",
        "Places:addPlace('Planet.Earth.X', 'x\\q', 0, 0, '', '')",
        "Places:addPlace('Planet.Earth.X', 'x', 0, 0, '', '', 'extra')",
        "Places:removePlace('Planet.Earth.X')",
        "--[[ long comment ]]", "--[=[ long comment ]=]",
        "Places:addLabelGroup('g', -1, 1, 1, 1, 1, 1)",
        "Places:addLabelGroup('g', 0, -1, 1, 1, 1, 1)",
        "Places:addLabelGroup('g', 0, 1, 1, -0.1, 1, 1)",
        "Places:addLabelGroup('g', 0, 1, 1, 1.1, 1, 1)",
        "Places:addLandscape('Planet.Earth', 'g', 'x.png', 0, 0, 0)",
        "Places:addLandscape('Planet.Earth', 'g', '', 1, 0, 0)",
        place + " os.execute('anything')", place + std::string(1, '\0'),
        "--" + std::string(4095, 'x')}) {
        rejected(fixture, "\n" + text);
    }
    // 引数の途中で切れた入力を成功扱いしない。閉じ括弧以降は有効な任意セミコロン。
    for (std::size_t length = 1; length < place.find_last_of(')') + 1; ++length) {
        rejected(fixture, place.substr(0, length));
    }
    mitaka::CatalogLoadLimits limits;
    limits.max_records = 0;
    rejected(fixture, place, limits);
    limits.max_records = 1;
    rejected(fixture, place + "\n" + place, limits);
    limits.max_file_bytes = place.size() - 1;
    rejected(fixture, place, limits);
    fixture.write("-- comment\n" + place);
    limits.max_file_bytes = 10000;
    require(mitaka::load_plus_place_catalog(fixture.path, limits).places.size() == 1, "comments do not consume record limit");
}

void test_source_preservation(Fixture& fixture) {
    const std::string text = "-- preserve CRLF\r\n" + place + "\n" + place + "\r\n";
    fixture.write(text);
    const auto valid = mitaka::load_plus_place_source(fixture.path);
    require(valid.path == fixture.path && std::string(valid.bytes.begin(), valid.bytes.end()) == text,
            "valid source retains every original byte");
    require(valid.catalog && !valid.error && valid.catalog->places.size() == 2,
            "duplicate source rows remain independent");
    const auto unknown = text + "Places:customExtension('private field');\n";
    fixture.write(unknown);
    const auto invalid = mitaka::load_plus_place_source(fixture.path);
    require(std::string(invalid.bytes.begin(), invalid.bytes.end()) == unknown && !invalid.catalog && invalid.error,
            "unknown custom data stays intact without executing or partially applying it");
    require(invalid.error->path() == fixture.path && invalid.error->offset() >= text.size(),
            "retained parse failure identifies its original source location");
    require(valid.catalog->places.size() == 2 && std::string(valid.bytes.begin(), valid.bytes.end()) == text,
            "source snapshot is independent from later file changes");
    mitaka::CatalogLoadLimits limits;
    limits.max_records = 1;
    const auto limited = mitaka::load_plus_place_source(fixture.path, limits);
    require(limited.bytes == invalid.bytes && limited.error && !limited.catalog,
            "record limit rejects interpretation without silently truncating the source");
}

void test_local(const std::filesystem::path& directory) {
    for (const auto* name : {"defaultplaces.dat", "defaultplaces_jp.dat", "places_jp.dat"}) {
        const auto path = directory / name;
        if (!std::filesystem::exists(path)) continue;
        const auto catalog = mitaka::load_plus_place_catalog(path);
        // 件数は配布時の値に固定せず、読み込んだローカルの状態を表示する。
        std::cout << name << ": " << catalog.places.size() << " places, " << catalog.label_groups.size()
                  << " label groups, " << catalog.landscapes.size() << " landscapes\n";
    }
}
} // namespace

int main(int argc, char** argv) {
    try {
        Fixture fixture;
        test_literals(fixture);
        test_errors(fixture);
        test_source_preservation(fixture);
        if (argc > 1) test_local(argv[1]);
        std::cout << "Place catalog tests passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
