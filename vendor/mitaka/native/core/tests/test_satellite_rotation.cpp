#include "mitaka/satellite_rotation.hpp"

#include <array>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>

namespace {
using namespace mitaka;
using Code = SatelliteRotationDiagnosticCode;
using Matrix = std::array<double, 9>;
constexpr double pi = 3.14159265358979323846;
constexpr double epoch = 2451545.0;
int checks = 0;

void expect(bool condition, const std::string& label) {
    ++checks;
    if (!condition) throw std::runtime_error(label);
}

void near(double actual, double expected, double tolerance, const std::string& label) {
    expect(std::isfinite(actual) && std::abs(actual - expected) <= tolerance, label);
}

void near(Vec3 actual, Vec3 expected, double tolerance, const std::string& label) {
    near(actual.x, expected.x, tolerance, label + ".x");
    near(actual.y, expected.y, tolerance, label + ".y");
    near(actual.z, expected.z, tolerance, label + ".z");
}

void near(SatelliteRotation actual, SatelliteRotation expected, double tolerance, const std::string& label) {
    near(actual.x_axis, expected.x_axis, tolerance, label + ".X");
    near(actual.y_axis, expected.y_axis, tolerance, label + ".Y");
    near(actual.z_axis, expected.z_axis, tolerance, label + ".Z");
}

SatelliteRotation evaluate(const std::vector<SatelliteRotationInput>& inputs,
                           std::size_t index = 0, double jd = epoch) {
    const auto result = evaluate_satellite_rotation(inputs, index, jd);
    expect(result.rotation.has_value(), "expected rotation");
    expect(result.diagnostics.empty(), "unexpected rotation diagnostic");
    return *result.rotation;
}

void diagnostic(const std::vector<SatelliteRotationInput>& inputs, std::size_t selected,
                double jd, Code code, std::size_t offender, const std::string& label) {
    const auto result = evaluate_satellite_rotation(inputs, selected, jd);
    expect(!result.rotation, label + ": invalid input produced rotation");
    expect(result.diagnostics.size() == 1, label + ": missing diagnostic");
    expect(result.diagnostics[0].code == code, label + ": wrong diagnostic");
    expect(result.diagnostics[0].record_index == offender, label + ": wrong source index");
    expect(!result.diagnostics[0].field.empty() && !result.diagnostics[0].message.empty(),
           label + ": empty diagnostic detail");
}

SatelliteRotationInput input(char plane = 'E') {
    SatelliteRotationInput result;
    result.name_bytes = "fixture satellite";
    result.reference_plane = plane;
    result.elements = SatelliteRotationElements{epoch, 0, 0, 0, 0, 0, std::nullopt, std::nullopt};
    return result;
}

// 実装の列ベクトル逐次回転とは独立した、展開済みの Rz(node) Rx(i) Rz(w)。
Matrix euler(double node, double inclination, double w) {
    const double n = node*pi/180, i = inclination*pi/180, p = w*pi/180;
    const double cn = std::cos(n), sn = std::sin(n), ci = std::cos(i), si = std::sin(i);
    const double cp = std::cos(p), sp = std::sin(p);
    return {cn*cp-sn*ci*sp, -cn*sp-sn*ci*cp, sn*si,
            sn*cp+cn*ci*sp, -sn*sp+cn*ci*cp, -cn*si,
            si*sp, si*cp, ci};
}

Matrix multiply(Matrix a, Matrix b) {
    Matrix result{};
    for (std::size_t row = 0; row < 3; ++row)
        for (std::size_t column = 0; column < 3; ++column)
            for (std::size_t k = 0; k < 3; ++k)
                result[row*3+column] += a[row*3+k] * b[k*3+column];
    return result;
}

SatelliteRotation columns(Matrix m) {
    return {{m[0],m[3],m[6]}, {m[1],m[4],m[7]}, {m[2],m[5],m[8]}};
}

double dot(Vec3 a, Vec3 b) { return a.x*b.x + a.y*b.y + a.z*b.z; }
Vec3 cross(Vec3 a, Vec3 b) {
    return {a.y*b.z-a.z*b.y, a.z*b.x-a.x*b.z, a.x*b.y-a.y*b.x};
}

void test_legacy_parent_poles() {
    // 監査の係数を 1900/2000/2100 年に代入した固定値。現在の惑星姿勢とは比較しない。
    using Poles = std::array<std::array<double,2>,9>;
    const std::array<Poles,3> expected{{
        {{{281.043,61.455}, {272.76,67.16}, {0.641,90.557}, {317.78753,52.9474},
          {268.059,64.487}, {40.625,83.541}, {257.311,-15.175},
          {298.79036045472429,43.16359516075056}, {313.02,9.09}}},
        {{{281.01,61.45}, {272.76,67.16}, {0,90}, {317.68143,52.8865},
          {268.05,64.49}, {40.589,83.537}, {257.311,-15.175},
          {299.33373895877264,42.950359021844847}, {313.02,9.09}}},
        {{{280.977,61.445}, {272.76,67.16}, {-0.641,89.443}, {317.57533,52.8256},
          {268.041,64.493}, {40.553,83.533}, {257.311,-15.175},
          {299.897532477722,43.133311597358556}, {313.02,9.09}}}
    }};
    for (std::size_t date=0; date<expected.size(); ++date) {
        const double jd=epoch+(static_cast<double>(date)-1)*36525;
        for (std::size_t index=0; index<expected[date].size(); ++index) {
            const auto result=evaluate_legacy_satellite_parent_pole({index},jd);
            expect(result.pole.has_value() && result.diagnostics.empty(),"legacy pole evaluates");
            near(result.pole->legacy_julian_date,jd,0,"pole date preserved");
            near(result.pole->right_ascension_deg,expected[date][index][0],6e-14,"legacy pole RA");
            near(result.pole->declination_deg,expected[date][index][1],2e-14,"legacy pole Decl");
            auto q=input('Q'); q.parent_pole=result.pole;
            const auto basis=evaluate({q},0,jd);
            near(cross(basis.x_axis,basis.y_axis),basis.z_axis,8e-16,"computed pole to Q basis");
        }
    }
    for (std::size_t index : {std::size_t{9},std::numeric_limits<std::size_t>::max()}) {
        const auto result=evaluate_legacy_satellite_parent_pole({index},epoch);
        expect(!result.pole && result.diagnostics.size()==1,"unknown registration index has no pole");
        expect(result.diagnostics[0].code==SatelliteParentPoleDiagnosticCode::invalid_registration_index,
               "unknown index diagnostic");
        expect(!result.diagnostics[0].message.empty(),"unknown index detail");
    }
    for (double jd : {std::numeric_limits<double>::quiet_NaN(),
                      std::numeric_limits<double>::infinity(),-std::numeric_limits<double>::infinity()}) {
        const auto result=evaluate_legacy_satellite_parent_pole({0},jd);
        expect(!result.pole && result.diagnostics.size()==1,"nonfinite pole date rejected");
        expect(result.diagnostics[0].code==SatelliteParentPoleDiagnosticCode::invalid_time,
               "invalid pole date diagnostic");
    }
    for (double jd : {-std::numeric_limits<double>::max(),std::numeric_limits<double>::max()}) {
        for (std::size_t index=0; index<9; ++index) {
            const auto result=evaluate_legacy_satellite_parent_pole({index},jd);
            expect(result.pole.has_value() && result.diagnostics.empty(),"finite pole date numerical boundary");
            expect(std::isfinite(result.pole->right_ascension_deg) && std::isfinite(result.pole->declination_deg),
                   "finite extreme legacy pole angles");
        }
    }
}

void test_axis_order_and_legacy_constants() {
    auto e = input();
    near(evaluate({e}), {}, 0, "zero angles identity");
    e.elements->argument_of_periapsis_deg = 90;
    e.elements->inclination_deg = 90;
    near(evaluate({e}), {{0,0,1},{-1,0,0},{0,-1,0}}, 2e-16, "periapsis before inclination");
    e.elements->raw_ascending_node_deg = 90;
    near(evaluate({e}), {{0,0,1},{0,-1,0},{1,0,0}}, 2e-16, "node applied last");
    auto i = input('I');
    const double li = 23.43870583*pi/180;
    near(evaluate({i}), {{1,0,0},{0,std::cos(li),std::sin(li)},
                        {0,-std::sin(li),std::cos(li)}}, 2e-16, "I positive legacy tilt");
    i.elements->pole_right_ascension_deg = std::numeric_limits<double>::quiet_NaN();
    i.elements->pole_declination_deg = 9999;
    near(evaluate({i}), evaluate({input('I')}), 0, "I ignores RA and Decl");
    auto l = input('L');
    l.elements->pole_right_ascension_deg = -90;
    l.elements->pole_declination_deg = 90;
    near(evaluate({l}), evaluate({input('I')}), 0, "L identity pole reduces to I");
    auto q = input('Q');
    q.parent_pole = SatelliteParentPole{epoch, -90, 90};
    const double qt = 23.439291111111114*pi/180;
    near(evaluate({q}), {{1,0,0},{0,std::cos(qt),-std::sin(qt)},
                        {0,std::sin(qt),std::cos(qt)}}, 2e-16, "Q negative distinct tilt");
    // 原版の Earth 極は T<0 で赤緯が 90 度を越える。座標範囲へ丸めない。
    q.parent_pole = SatelliteParentPole{epoch-36525, 0.641, 90.557};
    near(evaluate({q},0,epoch-36525),
         columns(multiply(euler(0,-23.439291111111114,0),euler(90.641,-0.557,0))),
         2e-15,"Q preserves legacy pole crossing at 1900");
}

void test_composition_and_precession() {
    const auto g = euler(0,23.43870583,0);
    for (double jd : {epoch-36525, epoch, epoch+1234.5}) {
        for (char plane : {'E','I','L','Q'}) {
            auto a = input(plane);
            a.elements = SatelliteRotationElements{epoch+20, 37, 61, -118, 4, -9, 75, -31};
            a.parent_pole = SatelliteParentPole{jd, 213.25, 54.5};
            const double w = 37 + (jd-epoch-20)*360/4/365.25;
            const double node = -118 + (jd-epoch-20)*360/-9/365.25;
            Matrix expected = euler(node,61,w);
            if (plane == 'I') expected = multiply(g, expected);
            if (plane == 'L') expected = multiply(multiply(g,euler(165,121,0)),expected);
            if (plane == 'Q') expected = multiply(multiply(euler(0,-23.439291111111114,0),
                                                          euler(303.25,35.5,0)),expected);
            const auto actual = evaluate({a},0,jd);
            near(actual,columns(expected),4e-14,"independent expanded matrix and epochs");
            near(dot(actual.x_axis,actual.x_axis),1,8e-16,"unit X");
            near(dot(actual.y_axis,actual.y_axis),1,8e-16,"unit Y");
            near(dot(actual.z_axis,actual.z_axis),1,8e-16,"unit Z");
            near(dot(actual.x_axis,actual.y_axis),0,8e-16,"orthogonal XY");
            near(cross(actual.x_axis,actual.y_axis),actual.z_axis,8e-16,"right handed");
        }
    }
    auto mars = input('I');
    mars.elements->raw_ascending_node_deg = 12;
    mars.apply_mars_node_correction = true;
    const auto first = evaluate({mars});
    near(first,columns(multiply(g,euler(55,0,0))),5e-16,"Mars adds 43 once outside Q");
    near(evaluate({mars}),first,0,"Mars reevaluation idempotent");
    near(mars.elements->raw_ascending_node_deg,12,0,"Mars raw element preserved");
    mars.elements->periapsis_period_years = -0.0;
    mars.elements->node_period_years = -0.0;
    near(evaluate({mars},0,epoch+100000),first,0,"zero periods disable precession");
}

void test_charon_and_moon() {
    auto child = input('C');
    child.elements = SatelliteRotationElements{epoch+17, 23, 11, 31, 2, -3, {}, {}};
    child.charon_rotation_index = 1;
    auto charon = input('I');
    charon.name_bytes = "Charon";
    charon.elements = SatelliteRotationElements{epoch-9, -47, 71, 119, -4, 6, 999, -999};
    const double jd = epoch+123;
    const Matrix child_o = euler(31+(123-17)*360.0/-3/365.25,11,23+(123-17)*360.0/2/365.25);
    const Matrix charon_o = euler(119+(123+9)*360.0/6/365.25,71,-47+(123+9)*360.0/-4/365.25);
    const auto expected = columns(multiply(multiply(euler(0,23.43870583,0),charon_o),child_o));
    near(evaluate({child,charon},0,jd),expected,2e-15,"C uses full Charon rotation at same date");
    auto grandchild = input('C');
    grandchild.elements->inclination_deg = 45;
    grandchild.charon_rotation_index = 0;
    near(evaluate({child,charon,grandchild},2,jd),
         columns(multiply(multiply(multiply(euler(0,23.43870583,0),charon_o),child_o),euler(0,45,0))),
         2e-15,"nested dependency composition order");
    child.charon_rotation_index.reset();
    diagnostic({child,charon,charon},0,jd,Code::unresolved_charon,0,"names do not resolve ambiguous edges");
    child.charon_rotation_index = 99;
    diagnostic({child,charon},0,jd,Code::invalid_charon_index,0,"invalid dependency index");
    child.charon_rotation_index = 0;
    diagnostic({child},0,jd,Code::cyclic_dependency,0,"self cycle");
    child.charon_rotation_index = 1;
    auto other = child;
    other.charon_rotation_index = 0;
    diagnostic({child,other},0,jd,Code::cyclic_dependency,0,"two node cycle");
    other.reference_plane = '?';
    diagnostic({child,other},0,jd,Code::unknown_reference_plane,1,"dependency diagnostic identifies source");
    auto moon = input('C');
    moon.name_bytes = "Moon";
    moon.elements.reset();
    moon.charon_rotation_index = 0;
    near(evaluate({moon}),{},0,"Moon identity precedes dependencies and elements");
    moon.reference_plane = '?';
    near(evaluate({moon}),{},0,"Moon identity precedes reference plane");
    moon.name_bytes = "moon";
    diagnostic({moon},0,epoch,Code::unknown_reference_plane,0,"Moon special is exact name");
    // 入力が深くても C++ の再帰スタックに依存しない。
    std::vector<SatelliteRotationInput> chain(20000,input('C'));
    for (std::size_t index=0; index+1<chain.size(); ++index) chain[index].charon_rotation_index=index+1;
    chain.back()=input();
    near(evaluate(chain),{},0,"deep dependency path");
    chain.back().reference_plane='C';
    chain.back().charon_rotation_index=0;
    diagnostic(chain,0,epoch,Code::cyclic_dependency,0,"deep dependency cycle");
}

void test_invalid_values() {
    const double nan = std::numeric_limits<double>::quiet_NaN();
    const double inf = std::numeric_limits<double>::infinity();
    diagnostic({},0,epoch,Code::invalid_record_index,0,"empty records");
    diagnostic({input()},1,epoch,Code::invalid_record_index,1,"record outside vector");
    for (double jd : {nan,inf,-inf}) diagnostic({input()},0,jd,Code::invalid_time,0,"nonfinite time");
    for (char value : {'?', 'e', '\0'}) {
        diagnostic({input(value)},0,epoch,Code::unknown_reference_plane,0,"no fallback for unknown plane");
    }
    auto a=input(); a.elements.reset();
    diagnostic({a},0,epoch,Code::missing_elements,0,"missing elements");
    const std::array<double SatelliteRotationElements::*,6> fields{
        &SatelliteRotationElements::epoch_jd,&SatelliteRotationElements::argument_of_periapsis_deg,
        &SatelliteRotationElements::inclination_deg,&SatelliteRotationElements::raw_ascending_node_deg,
        &SatelliteRotationElements::periapsis_period_years,&SatelliteRotationElements::node_period_years};
    for (const auto field : fields) {
        a=input(); (*a.elements).*field=nan;
        diagnostic({a},0,epoch,Code::invalid_elements,0,"nonfinite element");
    }
    a=input(); a.elements->node_period_years=std::numeric_limits<double>::denorm_min();
    diagnostic({a},0,epoch,Code::numerical_range,0,"rate overflow even at epoch");
    a=input(); a.elements->epoch_jd=-std::numeric_limits<double>::max();
    diagnostic({a},0,std::numeric_limits<double>::max(),Code::numerical_range,0,"elapsed overflow");
    a=input(); a.elements->periapsis_period_years=1e-300;
    diagnostic({a},0,1e10,Code::numerical_range,0,"precession overflow");
    a=input('L');
    diagnostic({a},0,epoch,Code::missing_elements,0,"L missing pole");
    a.elements->pole_right_ascension_deg=0; a.elements->pole_declination_deg=91;
    diagnostic({a},0,epoch,Code::invalid_elements,0,"L invalid declination");
    a.elements->pole_declination_deg=0; a.elements->pole_right_ascension_deg=inf;
    diagnostic({a},0,epoch,Code::invalid_elements,0,"L nonfinite RA");
    a=input('Q');
    diagnostic({a},0,epoch,Code::unresolved_parent_pole,0,"Q missing parent");
    a.parent_pole=SatelliteParentPole{epoch+1,0,0};
    diagnostic({a},0,epoch,Code::mismatched_parent_time,0,"Q stale parent");
    for (const auto p : {SatelliteParentPole{nan,0,0}, SatelliteParentPole{epoch,nan,0},
                         SatelliteParentPole{epoch,0,inf}}) {
        a.parent_pole=p;
        diagnostic({a},0,epoch,Code::invalid_parent_pole,0,"Q invalid parent");
    }
    a=input('L'); a.elements->pole_right_ascension_deg=std::numeric_limits<double>::max();
    for (double dec : {-90.0,90.0}) {
        a.elements->pole_declination_deg=dec;
        const auto basis=evaluate({a});
        near(dot(basis.z_axis,basis.z_axis),1,8e-16,"L extreme finite RA and pole boundary");
    }
}
} // namespace

int main() {
    try {
        test_legacy_parent_poles();
        test_axis_order_and_legacy_constants();
        test_composition_and_precession();
        test_charon_and_moon();
        test_invalid_values();
        std::cout << "satellite_rotation: " << checks << " checks passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
