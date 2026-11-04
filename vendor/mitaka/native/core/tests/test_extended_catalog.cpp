#include "mitaka/extended_catalog.hpp"

#include <chrono>
#include <cstring>
#include <fstream>
#include <iostream>
#include <limits>

namespace {
using Bytes = std::vector<unsigned char>;

void require(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}

struct Fixtures {
    std::filesystem::path root = std::filesystem::temp_directory_path() /
        ("mitaka_extended_" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    Fixtures() { require(std::filesystem::create_directory(root), "create fixtures"); }
    ~Fixtures() { std::error_code error; std::filesystem::remove_all(root, error); }
};

void write(const std::filesystem::path& path, const Bytes& bytes) {
    std::ofstream file(path, std::ios::binary);
    file.write(reinterpret_cast<const char*>(bytes.data()), static_cast<std::streamsize>(bytes.size()));
    require(bool(file), "write fixture");
}

void write(const std::filesystem::path& path, const std::string& text) {
    write(path, Bytes(text.begin(), text.end()));
}

void put_float(Bytes& bytes, std::size_t offset, float value) {
    std::uint32_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (unsigned int i = 0; i < 4; ++i) bytes.at(offset + i) = (bits >> (8 * i)) & 0xffU;
}

Bytes ngc_fixture() {
    Bytes bytes(21);
    bytes[0] = 0x34; bytes[1] = 0x12; bytes[2] = 1; bytes[11] = 4; bytes[20] = 1;
    put_float(bytes, 3, 123.5f); put_float(bytes, 7, -42.25f);
    put_float(bytes, 12, 15.5f); put_float(bytes, 16, -1.0f);
    return bytes;
}

Bytes sdss_fixture() {
    Bytes bytes(16);
    put_float(bytes, 0, 259.5f); put_float(bytes, 4, 90.0f);
    put_float(bytes, 8, 123456.0f); put_float(bytes, 12, -0.2f);
    return bytes;
}

template <typename Load>
void expect_error(const std::filesystem::path& path, Load load, bool text = false) {
    try {
        load();
    } catch (const mitaka::CatalogError& error) {
        require(error.path() == path, "error path");
        require(std::string(error.what()).find("byte ") != std::string::npos, "error offset");
        if (text) require(std::string(error.what()).find("line ") != std::string::npos, "error line");
        return;
    }
    throw std::runtime_error("invalid catalog accepted");
}

void test_binary(const std::filesystem::path& path) {
    auto ngc = ngc_fixture();
    write(path, ngc);
    const auto rows = mitaka::load_ngc_catalog(path);
    require(rows.size() == 1 && rows[0].number == 0x1234 && rows[0].is_ngc, "NGC ID endian/flag");
    require(rows[0].coordinates.right_ascension_deg == 123.5 &&
        rows[0].coordinates.declination_deg == -42.25, "NGC angular units");
    require(rows[0].kind == mitaka::DeepSkyKind::emission_or_reflection_nebula &&
        rows[0].angular_size_arcminutes == 15.5f && rows[0].magnitude == -1.0f &&
        rows[0].is_photographic_magnitude, "NGC metadata");
    for (std::size_t length = 1; length < ngc.size(); ++length) {
        write(path, Bytes(ngc.begin(), ngc.begin() + length));
        expect_error(path, [&] { mitaka::load_ngc_catalog(path); });
    }
    for (const auto offset : {2, 11, 20}) {
        auto invalid = ngc; invalid[offset] = 99; write(path, invalid);
        expect_error(path, [&] { mitaka::load_ngc_catalog(path); });
    }
    for (const auto offset : {3, 7, 12, 16}) {
        auto invalid = ngc; put_float(invalid, offset, std::numeric_limits<float>::quiet_NaN());
        write(path, invalid); expect_error(path, [&] { mitaka::load_ngc_catalog(path); });
    }
    for (const auto& invalid_field : std::vector<std::pair<std::size_t, float>>{
            {3, -1}, {3, 360}, {7, -91}, {7, 91}, {12, -1}}) {
        auto invalid = ngc; put_float(invalid, invalid_field.first, invalid_field.second);
        write(path, invalid); expect_error(path, [&] { mitaka::load_ngc_catalog(path); });
    }
    auto duplicate = ngc; duplicate.insert(duplicate.end(), ngc.begin(), ngc.end()); write(path, duplicate);
    expect_error(path, [&] { mitaka::load_ngc_catalog(path); });
    duplicate[23] = 0; write(path, duplicate);
    require(mitaka::load_ngc_catalog(path).size() == 2, "NGC and IC may share number");
    write(path, ngc);
    expect_error(path, [&] { mitaka::load_ngc_catalog(path, {20, 1}); });
    expect_error(path, [&] { mitaka::load_ngc_catalog(path, {21, 0}); });
    auto additional_ngc = ngc; additional_ngc[0] = 0; additional_ngc[1] = 125;
    write(path, additional_ngc);
    require(mitaka::load_ngc_catalog(path)[0].number == 32000, "not restricted to standard NGC list");

    const auto sdss = sdss_fixture(); write(path, sdss);
    const auto galaxies = mitaka::load_sdss_catalog(path, mitaka::SdssKind::galaxy);
    require(galaxies.size() == 1 && galaxies[0].coordinates.right_ascension_deg == 259.5 &&
        galaxies[0].distance_parsecs == 123456 && galaxies[0].classification_value == -0.2f,
        "SDSS values preserved");
    require(mitaka::load_sdss_catalog(path, mitaka::SdssKind::quasar).size() == 1, "QSO format");
    for (std::size_t length = 1; length < sdss.size(); ++length) {
        write(path, Bytes(sdss.begin(), sdss.begin() + length));
        expect_error(path, [&] { mitaka::load_sdss_catalog(path, mitaka::SdssKind::galaxy); });
    }
    for (const auto offset : {0, 4, 8, 12}) {
        auto invalid = sdss; put_float(invalid, offset, std::numeric_limits<float>::infinity());
        write(path, invalid);
        expect_error(path, [&] { mitaka::load_sdss_catalog(path, mitaka::SdssKind::quasar); });
    }
    auto zero_distance = sdss; put_float(zero_distance, 8, 0); write(path, zero_distance);
    require(mitaka::load_sdss_catalog(path, mitaka::SdssKind::galaxy)[0].distance_parsecs == 0,
        "SDSS zero distance retained");
    put_float(zero_distance, 8, -1); write(path, zero_distance);
    expect_error(path, [&] { mitaka::load_sdss_catalog(path, mitaka::SdssKind::galaxy); });
    write(path, Bytes{});
    require(mitaka::load_ngc_catalog(path).empty() &&
        mitaka::load_sdss_catalog(path, mitaka::SdssKind::galaxy).empty(), "empty catalogs");
}

void test_text(const std::filesystem::path& path) {
    const std::string localized("\x83\x41\x83\x4e\x83\x72", 6);
    write(path, "% HIP F Name\r\n  7588*Achernar            " + localized + "\r\n109268 Al Na'ir\n");
    const auto names = mitaka::load_star_names(path);
    require(names.size() == 2 && names[0].hip == 7588 && names[0].is_featured &&
        names[0].name_bytes == "Achernar" && names[0].localized_name_bytes == localized &&
        names[1].name_bytes == "Al Na'ir", "star names and original bytes preserved");
    expect_error(path, [&] { mitaka::load_star_names(path, {4096, 1}); }, true);
    for (const auto& invalid : {"bad", "      *x", "  7588?x", "  7588 ",
                               "  7588 x\n  7588 y"}) {
        write(path, std::string(invalid));
        expect_error(path, [&] { mitaka::load_star_names(path); }, true);
    }
    write(path, "  7588 " + std::string(4097, 'x'));
    expect_error(path, [&] { mitaka::load_star_names(path); }, true);
    write(path, std::string("  7588 x\0y", 10));
    expect_error(path, [&] { mitaka::load_star_names(path); }, true);
    write(path, std::string("# hosts\n% second comment\n\n 7588\r\n109268"));
    require(mitaka::load_exoplanet_host_hips(path) == std::vector<std::int32_t>({7588, 109268}),
        "exoplanet hosts and CRLF/last line");
    expect_error(path, [&] { mitaka::load_exoplanet_host_hips(path, {4096, 1}); }, true);
    for (const auto& invalid : {"0", "-1", "2147483648", "12 trailing", "7.5"}) {
        write(path, std::string(invalid));
        expect_error(path, [&] { mitaka::load_exoplanet_host_hips(path); }, true);
    }
    write(path, std::string("2\n2"));
    require(mitaka::load_exoplanet_host_hips(path) == std::vector<std::int32_t>({2, 2}),
        "original host list includes repeated systems and must retain rows");
    write(path, std::string("999999 New User Star\n"));
    require(mitaka::load_star_names(path)[0].hip == 999999, "custom HIP and name retained");
    write(path, std::string("2147483647\n"));
    require(mitaka::load_exoplanet_host_hips(path)[0] == 2147483647, "HIP is not filtered to known stars");
    write(path, std::string("% comment only\n"));
    require(mitaka::load_star_names(path).empty() && mitaka::load_exoplanet_host_hips(path).empty(),
        "comments only");
}

void test_local_data(const std::filesystem::path& directory) {
    const auto ngc_path = directory / "ngc.dat";
    if (std::filesystem::exists(ngc_path)) {
        const auto ngc = mitaka::load_ngc_catalog(ngc_path);
        require(ngc.size() * 21 == std::filesystem::file_size(ngc_path), "every local NGC row loaded");
        std::cout << "NGC/IC: " << ngc.size() << '\n';
    }
    for (const auto& catalog : std::vector<std::pair<const char*, mitaka::SdssKind>>{
            {"SDSS_GAL.dat", mitaka::SdssKind::galaxy}, {"SDSS_QSO.dat", mitaka::SdssKind::quasar}}) {
        const auto path = directory / catalog.first;
        if (!std::filesystem::exists(path)) continue;
        const auto rows = mitaka::load_sdss_catalog(path, catalog.second);
        require(rows.size() * 16 == std::filesystem::file_size(path), "every local SDSS row loaded");
        std::cout << catalog.first << ": " << rows.size() << '\n';
    }
    for (const auto& name : {"star_names.dat", "star_names_jp.dat", "star_names_HIP.dat"}) {
        if (!std::filesystem::exists(directory / name)) continue;
        const auto rows = mitaka::load_star_names(directory / name);
        std::cout << name << ": " << rows.size() << "\n";
    }
    const auto hosts_path = directory / "exoplanets_HIP_list.dat";
    if (std::filesystem::exists(hosts_path))
        std::cout << "Exoplanet hosts: " << mitaka::load_exoplanet_host_hips(hosts_path).size() << '\n';
}
} // namespace

int main(int argc, char** argv) {
    try {
        Fixtures fixtures;
        const auto path = fixtures.root / "追加 catalog.dat";
        expect_error(path, [&] { mitaka::load_ngc_catalog(path); });
        test_binary(path);
        test_text(path);
        if (argc > 1) test_local_data(argv[1]);
        std::cout << "Extended catalog tests passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
