#include "mitaka/satellite_position.hpp"

#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

namespace {
using namespace mitaka;
int checks = 0;
void expect(bool value, const char* message) { ++checks; if (!value) throw std::runtime_error(message); }
void near(double actual, double wanted, double tolerance, const char* message) {
    expect(std::isfinite(actual) && std::abs(actual-wanted) <= tolerance, message);
}
void point(const SatellitePositionEvaluation& result, Vec3 wanted, double tolerance) {
    expect(result.relative_position_km.has_value() && result.diagnostics.empty(), "position available without diagnostics");
    const auto actual = *result.relative_position_km;
    near(actual.x, wanted.x, tolerance, "position x");
    near(actual.y, wanted.y, tolerance, "position y");
    near(actual.z, wanted.z, tolerance, "position z");
}
void invalid(const SatellitePositionEvaluation& result, SatellitePositionDiagnosticCode wanted) {
    expect(!result.relative_position_km && result.diagnostics.size() == 1 && result.diagnostics[0].code == wanted,
           "invalid position remains absent with precise diagnostic");
}
void geometry() {
    const SatellitePositionElements circular{2451545, 1000, 0, 0, 90, 0, 0};
    for (int days = -8; days <= 8; ++days) {
        const double angle = days * std::acos(-1.0) / 2;
        point(evaluate_satellite_relative_position(circular, {circular.epoch_jd+days, {}}, circular.epoch_jd+days),
              {1000*std::cos(angle), 1000*std::sin(angle), 0}, 2e-10);
    }
    auto ellipse = circular;
    ellipse.eccentricity = .5;
    point(evaluate_satellite_relative_position(ellipse, {ellipse.epoch_jd, {}}, ellipse.epoch_jd), {500,0,0}, 1e-10);
    point(evaluate_satellite_relative_position(ellipse, {ellipse.epoch_jd+2, {}}, ellipse.epoch_jd+2), {-1500,0,0}, 1e-10);
    ellipse.mean_anomaly_deg = 0;
    ellipse.periapsis_period_years = 4.0 / 365.25;
    // dw=90°/day cancels n. This catches double time advance and omission of dw.
    point(evaluate_satellite_relative_position(ellipse, {ellipse.epoch_jd+1, {}}, ellipse.epoch_jd+1), {500,0,0}, 1e-10);
    ellipse.node_period_years = -8.0 / 365.25;
    ellipse.eccentricity = 0;
    point(evaluate_satellite_relative_position(ellipse, {ellipse.epoch_jd+2, {}}, ellipse.epoch_jd+2), {0,1000,0}, 1e-10);
    SatelliteRotation rotation{{0,1,0},{0,0,1},{1,0,0}};
    point(evaluate_satellite_relative_position(circular, {circular.epoch_jd, rotation}, circular.epoch_jd), {0,1000,0}, 1e-10);
    point(evaluate_satellite_relative_position(circular, {circular.epoch_jd+1, rotation}, circular.epoch_jd+1), {0,0,1000}, 1e-10);
}
void boundaries() {
    using Code = SatellitePositionDiagnosticCode;
    const SatellitePositionElements valid{2451545,1000,.2,40,30,0,0};
    auto e = valid;
    invalid(evaluate_satellite_relative_position(e, {e.epoch_jd+1, {}}, e.epoch_jd), Code::mismatched_rotation_time);
    invalid(evaluate_satellite_relative_position(e, {e.epoch_jd, {}}, std::numeric_limits<double>::infinity()), Code::invalid_time);
    for (const double value : {-1., 0., std::numeric_limits<double>::infinity(), std::numeric_limits<double>::quiet_NaN()}) {
        e = valid; e.semi_major_axis_km = value;
        invalid(evaluate_satellite_relative_position(e, {e.epoch_jd, {}}, e.epoch_jd), Code::invalid_elements);
    }
    for (const double value : {1., 1.5}) {
        e = valid; e.eccentricity = value;
        invalid(evaluate_satellite_relative_position(e, {e.epoch_jd, {}}, e.epoch_jd), Code::unsupported_orbit);
    }
    e = valid; e.periapsis_period_years = std::numeric_limits<double>::denorm_min();
    invalid(evaluate_satellite_relative_position(e, {e.epoch_jd, {}}, e.epoch_jd), Code::numerical_range);
    e = valid; e.mean_motion_deg_per_day = std::numeric_limits<double>::max();
    invalid(evaluate_satellite_relative_position(e, {e.epoch_jd+10, {}}, e.epoch_jd+10), Code::numerical_range);
    e = valid; e.semi_major_axis_km = std::numeric_limits<double>::max(); e.mean_anomaly_deg = 180;
    invalid(evaluate_satellite_relative_position(e, {e.epoch_jd, {}}, e.epoch_jd), Code::numerical_range);
    for (auto rotation : {SatelliteRotation{{2,0,0},{0,1,0},{0,0,1}},
                          SatelliteRotation{{1,0,0},{0,1,0},{0,0,-1}},
                          SatelliteRotation{{1,0,0},{1,0,0},{0,0,1}}}) {
        invalid(evaluate_satellite_relative_position(valid, {valid.epoch_jd, rotation}, valid.epoch_jd), Code::invalid_rotation);
    }
    e = valid; e.eccentricity = std::nextafter(1.0, 0.0); e.mean_anomaly_deg = 0;
    point(evaluate_satellite_relative_position(e, {e.epoch_jd, {}}, e.epoch_jd),
          {1000*(1-e.eccentricity),0,0}, 1e-20);
}
} // namespace
int main() {
    try { geometry(); boundaries(); std::cout << "satellite position: " << checks << " checks PASS\n"; }
    catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
}
