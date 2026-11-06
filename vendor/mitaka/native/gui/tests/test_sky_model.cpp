#include "sky_model.hpp"
#include "mitaka/lunar.hpp"

#include <unistd.h>

#include <array>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <iterator>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>

namespace {
using namespace mitaka::gui;
using Bytes = std::vector<char>;

void check(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}

void near(double actual, double expected, double tolerance = 1e-10) {
    check(std::abs(actual - expected) <= tolerance,
          "numeric mismatch: " + std::to_string(actual) + " vs " + std::to_string(expected));
}

void check_position(const SkyBody& body, mitaka::Vec3 expected) {
    const auto direction = mitaka::equatorial_direction(body.coordinates);
    near(direction.x * body.distance_au, expected.x);
    near(direction.y * body.distance_au, expected.y);
    near(direction.z * body.distance_au, expected.z);
}

template <typename Exception, typename Function>
void rejects(Function operation) {
    try { operation(); }
    catch (const Exception&) { return; }
    throw std::runtime_error("expected exception was not raised");
}

void integer(Bytes& bytes, std::uint64_t value, unsigned width = 4) {
    for (unsigned i = 0; i < width; ++i)
        bytes.push_back(static_cast<char>((value >> (8 * i)) & 255));
}

void real(Bytes& bytes, double value) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(value));
    integer(bytes, bits, 8);
}

void single(Bytes& bytes, float value) {
    std::uint32_t bits;
    std::memcpy(&bits, &value, sizeof(value));
    integer(bytes, bits);
}

void write(const std::filesystem::path& path, const Bytes& bytes) {
    std::ofstream stream(path, std::ios::binary);
    stream.write(bytes.data(), static_cast<std::streamsize>(bytes.size()));
    check(static_cast<bool>(stream), "fixture write failed");
}

Bytes read(const std::filesystem::path& path) {
    std::ifstream stream(path, std::ios::binary);
    check(static_cast<bool>(stream), "cannot read integration input");
    Bytes bytes{std::istreambuf_iterator<char>(stream), std::istreambuf_iterator<char>()};
    check(!stream.bad(), "integration input read failed");
    return bytes;
}

void append_star(Bytes& bytes, std::int32_t hip, float ra, float dec, float magnitude) {
    integer(bytes, static_cast<std::uint32_t>(hip));
    for (const float value : {ra, dec, -1.0f, 0.1f, 0.0f, 0.0f, magnitude, 0.5f})
        single(bytes, value);
    // 未知のスペクトル型等も保持することを確認する。
    integer(bytes, 255, 1);
    integer(bytes, 255, 1);
    integer(bytes, 0, 1);
    integer(bytes, 0, 2);
    for (int i = 0; i < 4; ++i) integer(bytes, 0, 1);
}

Bytes hip_fixture(float declination = 20) {
    Bytes bytes;
    append_star(bytes, 123, 90, declination, 2);
    append_star(bytes, 456, 100, -20, 10);
    append_star(bytes, 789, 180, 0, 3);
    return bytes;
}

Bytes constellation_fixture(float declination = 30, std::int32_t endpoint = 456) {
    Bytes bytes;
    for (const std::string& name : {"And", "And", "Andromeda", "Andromedae", "\x82\xa0", "*"}) {
        integer(bytes, name.size(), 1);
        bytes.insert(bytes.end(), name.begin(), name.end());
    }
    single(bytes, 10);
    single(bytes, declination);
    integer(bytes, 1, 1);
    integer(bytes, 2, 1);
    integer(bytes, 123);
    integer(bytes, static_cast<std::uint32_t>(endpoint));
    integer(bytes, 3, 2);
    for (const float value : {23.0f, 10.0f, 1.0f, 10.0f, 1.0f, 20.0f}) single(bytes, value);
    return bytes;
}

Bytes cf96_fixture(unsigned count = 9, bool disjoint = false, bool coincident = false,
                   double start = 2451544, double span = 2) {
    Bytes bytes{'C', 'F', '9', '6'};
    integer(bytes, count);
    for (unsigned planet = 0; planet < count; ++planet) {
        const bool last = planet == 8;
        real(bytes, last ? (disjoint ? start + span + 1 : start + 0.5) : start);
        real(bytes, last ? span - 1 : span);
        integer(bytes, 0); // Poisson の次数
        integer(bytes, 1); // 軸ごとに定数項と一次項
        integer(bytes, 1); // 時間ブロック数
        integer(bytes, 0); // 周波数項は不要
        const bool earth = planet == 2 || (coincident && planet == 0);
        const std::array<double, 3> position{earth ? 1.0 : planet + 2.0,
                                            earth ? 0.0 : 1.0, 0.0};
        for (unsigned axis = 0; axis < 3; ++axis) {
            integer(bytes, 2);
            real(bytes, position[axis] * 1e10);
            real(bytes, !earth && axis == 0 ? 0.5e10 : 0);
            integer(bytes, 1);
            integer(bytes, 0);
        }
    }
    return bytes;
}

void test_projection() {
    const auto at = [](double ra, double dec, SkyViewport view = {}) {
        const auto point = project_sky({ra, dec}, view, 360, 180);
        check(point.has_value(), "expected visible coordinate");
        return *point;
    };
    near(at(180, 0).x, 180);
    near(at(180, 0).y, 90);
    near(at(270, 0).x, 90);
    near(at(90, 0).x, 270);
    near(at(0, 0).x, 360);
    near(at(360, 0).x, 360);
    near(at(-90, 0).x, 90);
    near(at(180, 90).y, 0);
    near(at(180, -90).y, 180);
    near(at(10, 0, {350, 0, 2}).x, 140);
    near(at(350, 0, {10, 0, 2}).x, 220);
    near(at(180, 30, {180, 30, 2}).y, 90);
    check(!project_sky({179, 0}, {0, 0, 2}, 360, 180), "zoom must clip opposite RA");
    check(!project_sky({180, 46}, {180, 0, 2}, 360, 180), "zoom must clip declination");
    const double nan = std::numeric_limits<double>::quiet_NaN();
    rejects<std::invalid_argument>([&] { project_sky({nan, 0}, {}, 360, 180); });
    rejects<std::invalid_argument>([&] { project_sky({0, 91}, {}, 360, 180); });
    rejects<std::invalid_argument>([&] { project_sky({0, 0}, {0, nan, 1}, 360, 180); });
    rejects<std::invalid_argument>([&] { project_sky({0, 0}, {0, 0, 0}, 360, 180); });
    rejects<std::invalid_argument>([&] { project_sky({0, 0}, {}, 0, 180); });
    rejects<std::invalid_argument>([&] { project_sky({0, 0}, {}, 360, nan); });
    for (const double altitude : {-90.0, -45.0, 0.0, 45.0, 90.0}) {
        const HorizonProjectionViewport view{73, altitude, 180};
        for (const auto point : {ScreenPoint{20, 20}, ScreenPoint{100, 60}, ScreenPoint{180, 90},
                                 ScreenPoint{270, 120}, ScreenPoint{340, 160}}) {
            const auto projected = project_horizon(unproject_horizon(point, view, 360, 180), view, 360, 180);
            check(projected.has_value(), "horizon round trip must remain visible");
            near(projected->x, point.x);
            near(projected->y, point.y);
        }
    }
    for (const double blend : {0.0, 0.25, 0.5, 0.75, 1.0}) {
        const HorizonProjectionViewport view{73, 32, 90, blend};
        const HorizonRasterProjection raster(view, 360, 180);
        for (const auto point : {ScreenPoint{20.5, 20.5}, ScreenPoint{100.5, 60.5},
                                 ScreenPoint{180.5, 90.5}, ScreenPoint{340.5, 160.5}}) {
            const auto direction = unproject_horizon(point, view, 360, 180);
            const auto pixel = raster.direction(static_cast<std::size_t>(point.x),
                                                static_cast<std::size_t>(point.y));
            near(pixel.right_ascension_deg, direction.right_ascension_deg);
            near(pixel.declination_deg, direction.declination_deg);
            const auto projected = project_horizon(direction, view, 360, 180);
            check(projected.has_value(), "blended horizon direction must remain visible");
            near(projected->x, point.x);
            near(projected->y, point.y);
        }
    }
    const HorizonProjectionViewport perspective{0, 0, 180, 1};
    const auto top = unproject_horizon({320, 0}, perspective, 640, 480);
    near(top.declination_deg, 22.5);
    const auto right = unproject_horizon({640, 240}, perspective, 640, 480);
    near(right.right_ascension_deg,
         360 - std::atan(0.4142135623730950488 * 4 / 3) * 180 / 3.14159265358979323846);
}

void test_horizon_field_of_view() {
    constexpr double pi = 3.14159265358979323846;
    constexpr double perspective_scale = 0.4142135623730950488;
    constexpr double width = 640, height = 480;
    for (const double field_of_view : {180.0, 90.0, 45.0, 0.5}) {
        for (const double blend : {0.0, 0.5, 1.0}) {
            const HorizonProjectionViewport view{0, 0, field_of_view, blend};
            // 中央の上下端と左右端は、正逆変換の往復とは独立に求める。
            const double half_height = ((1 - blend) * field_of_view + blend * 45) / 2;
            const auto top = unproject_horizon({width / 2, 0}, view, width, height);
            const auto bottom = unproject_horizon({width / 2, height}, view, width, height);
            near(top.declination_deg, half_height, 1e-9);
            near(bottom.declination_deg, -half_height, 1e-9);
            const double half_width = (1 - blend) * field_of_view
                + blend * std::atan(perspective_scale * width / height) * 180 / pi;
            const auto right = unproject_horizon({width, height / 2}, view, width, height);
            near(std::remainder(right.right_ascension_deg + half_width, 360.0), 0, 1e-9);

            const HorizonRasterProjection raster(view, 640, 480);
            for (const auto point : {ScreenPoint{80.5, 60.5}, ScreenPoint{320.5, 240.5},
                                     ScreenPoint{559.5, 419.5}}) {
                const auto direction = unproject_horizon(point, view, width, height);
                const auto pixel = raster.direction(static_cast<std::size_t>(point.x),
                                                    static_cast<std::size_t>(point.y));
                near(std::remainder(pixel.right_ascension_deg - direction.right_ascension_deg, 360.0), 0, 1e-9);
                near(pixel.declination_deg, direction.declination_deg, 1e-9);
                const auto projected = project_horizon(direction, view, width, height);
                check(projected.has_value(), "field-of-view sample must remain visible");
                near(projected->x, point.x, 1e-7);
                near(projected->y, point.y, 1e-7);
            }
        }
    }

    // 正の画角を保持できても極小値では方向が丸められるため、ここでは有限性を確認する。
    const HorizonProjectionViewport tiny{0, 0, 1e-300, 0};
    const auto direction = unproject_horizon({160, 120}, tiny, width, height);
    check(std::isfinite(direction.right_ascension_deg) && std::isfinite(direction.declination_deg),
          "tiny field of view must yield a finite direction");
    const HorizonRasterProjection raster(tiny, 640, 480);
    const auto pixel = raster.direction(160, 120);
    check(std::isfinite(pixel.right_ascension_deg) && std::isfinite(pixel.declination_deg),
          "tiny field of view must yield a finite raster direction");
    const auto center = project_horizon({0, 0}, tiny, width, height);
    check(center && std::isfinite(center->x) && std::isfinite(center->y),
          "tiny field of view must project its center to finite coordinates");
    const auto zoomed_out = zoom_horizon(tiny, 0.5, {width / 2, height / 2}, width, height);
    near(tiny.vertical_fov_deg, 1e-300, 0);
    near(zoomed_out.vertical_fov_deg, 2e-9, 1e-21);
    const auto visible_top = unproject_horizon({width / 2, 0}, zoomed_out, width, height);
    near(visible_top.declination_deg, 1e-9, 1e-15);
    const HorizonProjectionViewport subpixel{0, 0, 1e-12};
    const ScreenPoint off_center{width / 4, height / 4};
    const auto unchanged = zoom_horizon(subpixel, 1, off_center, width, height);
    near(unchanged.vertical_fov_deg, subpixel.vertical_fov_deg, 0);
    near(unchanged.center_ra_deg, subpixel.center_ra_deg, 0);
    near(unchanged.center_dec_deg, subpixel.center_dec_deg, 0);
    const auto zoomed_in = zoom_horizon(subpixel, 1.5, off_center, width, height);
    near(zoomed_in.vertical_fov_deg, 1e-12 / 1.5, 1e-24);
    const auto anchored_out = zoom_horizon(subpixel, 0.5, off_center, width, height);
    const auto original_anchor = unproject_horizon(off_center, subpixel, width, height);
    const auto projected_anchor = project_horizon(original_anchor, anchored_out, width, height);
    check(projected_anchor.has_value(), "zoomed-out anchor must remain visible");
    near(projected_anchor->x, off_center.x, 0.1);
    near(projected_anchor->y, off_center.y, 0.1);

    for (const double pole : {-90.0, 90.0}) {
        const HorizonProjectionViewport polar{0, pole, 1e-9};
        const auto above = unproject_horizon({width / 2, height / 4}, polar, width, height);
        const auto below = unproject_horizon({width / 2, 3 * height / 4}, polar, width, height);
        check(std::abs(above.declination_deg) < 90 && std::abs(below.declination_deg) < 90,
              "small polar offsets must not round to the pole");
        for (const auto screen : {ScreenPoint{width / 2, height / 4}, ScreenPoint{width / 2, 3 * height / 4}}) {
            const auto projected = project_horizon(unproject_horizon(screen, polar, width, height), polar, width, height);
            check(projected.has_value(), "small polar offset must remain visible");
            near(projected->x, screen.x, 0.1);
            near(projected->y, screen.y, 0.1);
        }
    }
}

void test_navigation() {
    const auto normalized = normalize_sky_viewport({-10, 90, 2});
    near(normalized.center_ra_deg, 350);
    near(normalized.center_dec_deg, 45);
    near(normalize_sky_viewport({5, -90, 0.2}).center_dec_deg, 0);
    near(normalize_sky_viewport({0, 0, 500}).zoom, 180);
    const auto panned = pan_sky({350, 0, 2}, 30, 20, 360, 180);
    near(panned.center_ra_deg, 5);
    near(panned.center_dec_deg, 10);
    const auto zoomed = zoom_sky({}, 2, {270, 70}, 360, 180);
    const auto anchor = project_sky({90, 20}, zoomed, 360, 180);
    check(anchor.has_value(), "zoom anchor remains visible");
    near(anchor->x, 270);
    near(anchor->y, 70);
    for (const HorizonProjectionViewport view : {HorizonProjectionViewport{73, -70, 90},
                                                 HorizonProjectionViewport{73, 0, 90},
                                                 HorizonProjectionViewport{73, 70, 90},
                                                 HorizonProjectionViewport{73, 20, 0.5, 0, 25},
                                                 HorizonProjectionViewport{73, 20, 45, 0.5, 25}}) {
        const ScreenPoint point{230, 60};
        const auto target = unproject_horizon(point, view, 360, 180);
        const auto zoomed_horizon = zoom_horizon(view, 1.5, point, 360, 180);
        const auto projected = project_horizon(target, zoomed_horizon, 360, 180);
        check(projected.has_value(), "horizon zoom anchor remains visible");
        near(projected->x, point.x, 1e-7);
        near(projected->y, point.y, 1e-7);
    }
    const auto seam = project_sky_segment({350, 0}, {10, 0}, {}, 360, 180);
    check(seam.size() == 2, "RA seam must produce two short segments");
    for (const auto& segment : seam) {
        near(std::abs(segment.end.x - segment.start.x), 10);
        near(segment.start.y, 90);
        check(segment.start.x >= 0 && segment.end.x <= 360, "seam segments must be clipped");
    }
    const auto clipped = project_sky_segment({40, 0}, {160, 0}, {100, 0, 4}, 360, 180);
    check(clipped.size() == 1, "segment crossing visible area must survive invisible endpoints");
    near(clipped[0].start.x, 360);
    near(clipped[0].end.x, 0);
    check(project_sky_segment({180, 60}, {190, 80}, {180, 0, 2}, 360, 180).empty(),
          "offscreen segments must be omitted");
    rejects<std::invalid_argument>([] { normalize_sky_viewport({0, 0, 0}); });
    rejects<std::invalid_argument>([] { pan_sky({}, 0, 0, 0, 180); });
    rejects<std::invalid_argument>([] { zoom_sky({}, -1, {0, 0}, 360, 180); });
    rejects<std::invalid_argument>([] { project_sky_segment({0, 91}, {0, 0}, {}, 360, 180); });
}

void test_constellations(const std::filesystem::path& directory) {
    write(directory / "hip.dat", hip_fixture());
    write(directory / "cf96.dat", cf96_fixture());
    const auto path = directory / "constellation_HIP.dat";
    const auto absent = SkyModel::load(directory);
    check(absent.constellations().empty() && !absent.constellation_warning().empty(),
          "missing optional constellation file must not prevent sky loading");
    write(path, constellation_fixture());
    const auto bytes = read(path);
    const auto timestamp = std::filesystem::last_write_time(path);
    const auto model = SkyModel::load(directory);
    check(model.constellations().size() == 1 && model.constellation_warning().empty(),
          "valid optional constellation catalog must be available");
    check(model.star_index(123) == 0 && model.star_index(456) == 1 && !model.star_index(999),
          "HIP lookup must preserve source indices");
    check(model.constellations()[0].japanese_hiragana_bytes == "\x82\xa0", "CP932 must remain raw bytes");
    near(model.constellations()[0].boundary[0].right_ascension_hours, 23);
    check(read(path) == bytes && std::filesystem::last_write_time(path) == timestamp,
          "constellation load must be read only");
    write(path, constellation_fixture(30, -2));
    check(!SkyModel::load(directory).constellation_warning().empty(), "missing special HIP must be reported");
    write(path, constellation_fixture(91));
    rejects<mitaka::CatalogError>([&] { SkyModel::load(directory); });
    auto truncated = constellation_fixture();
    truncated.pop_back();
    write(path, truncated);
    rejects<mitaka::CatalogError>([&] { SkyModel::load(directory); });
    std::filesystem::remove(path);
}

void test_model(const std::filesystem::path& directory) {
    rejects<std::invalid_argument>([] { SkyModel::load({}); });
    write(directory / "hip.dat", hip_fixture());
    write(directory / "cf96.dat", cf96_fixture());
    const auto model = SkyModel::load(directory);
    check(model.stars().size() == 3, "must retain faint and negative-parallax HIP records");
    near(model.stars()[1].parallax_mas, -1);
    check(model.stars()[0].spectral_type == -1, "must retain unknown spectral type");
    check(model.time_range() == std::make_pair(2451544.5, 2451545.5), "common time range");
    const auto bodies = model.bodies(2451545);
    const std::array<Body, 10> order{Body::sun, Body::mercury, Body::venus, Body::mars,
        Body::jupiter, Body::saturn, Body::uranus, Body::neptune, Body::pluto, Body::moon};
    for (std::size_t i = 0; i < order.size(); ++i) check(bodies[i].id == order[i], "body order");
    const auto moon = mitaka::lunar_position(2451545);
    const double correction = 1 / (mitaka::earth_moon_mass_ratio + 1);
    // 地心補正を全ての方向へ適用し、月だけは地心位置をそのまま使う。
    check_position(bodies[0], {-1 + moon.x * correction, moon.y * correction,
                               moon.z * correction});
    check_position(bodies[1], {1 + moon.x * correction, 1 + moon.y * correction,
                               moon.z * correction});
    check_position(bodies[8], {9 + moon.x * correction, 1 + moon.y * correction,
                               moon.z * correction});
    check_position(bodies.back(), moon);
    check(bodies.back().distance_au > 0.002 && bodies.back().distance_au < 0.003,
          "Moon must use geocentric AU, not heliocentric AU");
    const auto first = model.bodies(model.time_range().first);
    const auto last = model.bodies(model.time_range().second);
    check(first[1].coordinates.right_ascension_deg != last[1].coordinates.right_ascension_deg,
          "JD changes must recompute planet positions");
    check(first.back().coordinates.right_ascension_deg != last.back().coordinates.right_ascension_deg,
          "JD changes must recompute the Moon");
    rejects<std::out_of_range>([&] { model.bodies(2451544); });
    rejects<std::out_of_range>([&] { model.bodies(2451546); });
    rejects<std::invalid_argument>([&] { model.bodies(std::numeric_limits<double>::infinity()); });

    const auto select = [&](double x, double y, double magnitude = 6) {
        return pick_object(model, bodies, {}, 360, 180, x, y, magnitude);
    };
    const auto star = select(270, 70);
    check(star && star->kind == ObjectKind::star && star->index == 0, "select visible star");
    check(!select(260, 110), "faint stars must not be selectable when filtered");
    const auto faint = select(260, 110, 11);
    check(faint && faint->kind == ObjectKind::star && faint->index == 1, "select faint star");
    auto tied_bodies = bodies;
    tied_bodies[0].coordinates = {180, 0};
    const auto sun = pick_object(model, tied_bodies, {}, 360, 180, 180, 90, 6);
    check(sun && sun->kind == ObjectKind::body && sun->index == 0, "body wins equal-distance tie");
    const auto star_only = pick_object(model, tied_bodies, {}, 360, 180, 180, 90, 6, 8, true, false);
    check(star_only && star_only->kind == ObjectKind::star && star_only->index == 2,
          "hidden body must not prevent picking a star at the same position");
    const auto body_only = pick_object(model, tied_bodies, {}, 360, 180, 180, 90, 6, 8, false, true);
    check(body_only && body_only->kind == ObjectKind::body && body_only->index == 0,
          "hidden star must not prevent picking a body");
    check(!pick_object(model, tied_bodies, {}, 360, 180, 180, 90, 6, 8, false, false),
          "hidden layers must not be selectable");
    const auto moon_point = project_sky(bodies.back().coordinates, {}, 360, 180);
    const auto selected_moon = select(moon_point->x, moon_point->y);
    check(selected_moon && selected_moon->kind == ObjectKind::body && selected_moon->index == 9,
          "Moon must be selectable at its displayed position");
    check(!select(0, 0), "empty chart selection");
    check(!select(-1, 0), "outside chart selection");
    rejects<std::invalid_argument>([&] { pick_object(model, bodies, {}, 360, 180, 0, 0, 6, -1); });

    for (unsigned count : {8u, 10u}) {
        write(directory / "cf96.dat", cf96_fixture(count));
        rejects<std::runtime_error>([&] { SkyModel::load(directory); });
    }
    write(directory / "cf96.dat", cf96_fixture(9, true));
    rejects<std::runtime_error>([&] { SkyModel::load(directory); });
    write(directory / "cf96.dat", cf96_fixture(9, false, true));
    const auto coincident = SkyModel::load(directory);
    // CF96 位置が地球・月重心と一致しても、地球中心との距離はゼロではない。
    near(coincident.bodies(2451545)[1].distance_au,
         std::hypot(moon.x, moon.y, moon.z) * correction);
    write(directory / "cf96.dat", cf96_fixture(9, false, false, 2414000, 80000));
    const auto wide = SkyModel::load(directory);
    check(wide.time_range() == std::make_pair(mitaka::lunar_minimum_jd, mitaka::lunar_maximum_jd),
          "display range must intersect lunar coverage");
    wide.bodies(wide.time_range().first);
    wide.bodies(wide.time_range().second);
    rejects<std::out_of_range>([&] { wide.bodies(mitaka::lunar_minimum_jd - 1); });
    rejects<std::out_of_range>([&] { wide.bodies(mitaka::lunar_maximum_jd + 1); });
    write(directory / "cf96.dat", cf96_fixture(9, false, false, 2400000));
    rejects<std::runtime_error>([&] { SkyModel::load(directory); });
    write(directory / "cf96.dat", cf96_fixture());
    write(directory / "hip.dat", hip_fixture(91));
    rejects<mitaka::CatalogError>([&] { SkyModel::load(directory); });
    write(directory / "hip.dat", hip_fixture(std::numeric_limits<float>::quiet_NaN()));
    rejects<mitaka::CatalogError>([&] { SkyModel::load(directory); });
    rejects<mitaka::CatalogError>([&] { SkyModel::load(directory / "missing"); });
    write(directory / "hip.dat", hip_fixture());
    auto truncated = cf96_fixture();
    truncated.pop_back();
    write(directory / "cf96.dat", truncated);
    rejects<std::runtime_error>([&] { SkyModel::load(directory); });
}

void test_existing_data(const std::filesystem::path& directory) {
    const auto hip = directory / "hip.dat";
    const auto cf96 = directory / "cf96.dat";
    const auto hip_bytes = read(hip);
    const auto cf96_bytes = read(cf96);
    const auto hip_time = std::filesystem::last_write_time(hip);
    const auto cf96_time = std::filesystem::last_write_time(cf96);
    const auto model = SkyModel::load(directory);
    check(model.stars().size() * 45 == hip_bytes.size(), "existing HIP must retain every record");
    const auto range = model.time_range();
    for (const double date : {range.first, (range.first + range.second) / 2, range.second}) {
        const auto bodies = model.bodies(date);
        check(bodies.back().id == Body::moon, "existing Moon order");
        check_position(bodies.back(), mitaka::lunar_position(date));
        for (const auto& body : bodies) {
            check(body.distance_au > 0 && std::isfinite(body.distance_au), "existing body distance");
            check(body.coordinates.right_ascension_deg >= 0 && body.coordinates.right_ascension_deg < 360,
                  "existing body RA");
            check(project_sky(body.coordinates, {}, 1200, 600).has_value(), "existing body projection");
        }
    }
    for (const auto& star : model.stars())
        check(project_sky({star.right_ascension_degrees, star.declination_degrees}, {}, 1200, 600)
              .has_value(), "existing star projection");
    check(read(hip) == hip_bytes && read(cf96) == cf96_bytes, "input file bytes changed");
    check(std::filesystem::last_write_time(hip) == hip_time
          && std::filesystem::last_write_time(cf96) == cf96_time, "input modification time changed");
    std::cout << "read-only integration passed: " << directory << ", HIP=" << model.stars().size()
              << ", bodies=10\n";
}

} // namespace

int main(int argc, char** argv) {
    auto pattern = (std::filesystem::temp_directory_path() / "mitaka-sky-model-XXXXXX").string();
    if (!mkdtemp(pattern.data())) { std::cerr << "cannot create test directory\n"; return 1; }
    const auto directory = std::filesystem::path(pattern);
    try {
        test_projection();
        test_horizon_field_of_view();
        test_navigation();
        test_model(directory);
        test_constellations(directory);
        for (int argument = 1; argument < argc; ++argument) test_existing_data(argv[argument]);
        std::filesystem::remove_all(directory);
        std::cout << "sky model tests passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::filesystem::remove_all(directory);
        std::cerr << error.what() << '\n';
        return 1;
    }
}
