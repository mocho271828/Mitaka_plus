#include "mitaka/small_body_orbit.hpp"

#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>

namespace {
int checks = 0;
constexpr double k = 0.01720209895;
constexpr double pi = 3.14159265358979323846;
void expect(bool value, const std::string& label) {
    ++checks; if (!value) throw std::runtime_error(label);
}
void near(double value, double wanted, double tolerance, const std::string& label) {
    expect(std::isfinite(value) && std::abs(value-wanted) <= tolerance,
           label + ": actual=" + std::to_string(value) + ", expected=" + std::to_string(wanted));
}
void near(mitaka::Vec3 value, mitaka::Vec3 wanted, double tolerance, const std::string& label) {
    near(value.x,wanted.x,tolerance,label+" x"); near(value.y,wanted.y,tolerance,label+" y");
    near(value.z,wanted.z,tolerance,label+" z");
}
template<class Exception, class Function> void throws(Function action, const std::string& label) {
    try { action(); } catch (const Exception&) { ++checks; return; }
    throw std::runtime_error(label);
}
double norm(mitaka::Vec3 v) { return std::hypot(v.x,std::hypot(v.y,v.z)); }

void parabolic() {
    using namespace mitaka;
    PerihelionElements e{1,1,2451545,0,0,0};
    const auto at = perihelion_orbital_state(e,e.perihelion_jd);
    near(at.position_au,{1,0,0},1e-15,"parabolic perihelion");
    near(at.velocity_au_per_day,{0,std::sqrt(2.0)*k,0},1e-15,"parabolic speed");
    // D=1 の独立な解析値: Δt=sqrt(2 q^3 / μ) (D+D^3/3)。
    const double dt = std::sqrt(2.0)/k*4/3;
    const auto quarter = perihelion_orbital_state(e,e.perihelion_jd+dt);
    near(quarter.position_au,{0,2,0},5e-12,"Barker quarter position");
    near(quarter.velocity_au_per_day,{-k/std::sqrt(2.0),k/std::sqrt(2.0),0},5e-14,"Barker quarter velocity");
    for (double q : {0.01,1.0,100.0}) {
        e.perihelion_distance_au=q;
        e.ascending_node_deg=23; e.inclination_deg=57; e.argument_of_perihelion_deg=93;
        for (double days : {-10000.0,-100.0,-0.001,0.0,0.001,100.0,10000.0}) {
            const double jd=e.perihelion_jd+days;
            const auto state=perihelion_orbital_state(e,jd);
            const auto p=state.position_au, v=state.velocity_au_per_day;
            near(norm(v)*norm(v)/2-k*k/norm(p),0,2e-16,"parabolic zero energy");
            near(norm({p.y*v.z-p.z*v.y,p.z*v.x-p.x*v.z,p.x*v.y-p.y*v.x}),
                 k*std::sqrt(2*q),1e-13,"parabolic angular momentum");
            // 近点の曲率と遠方での差分桁落ちの両方を避け、局所的な力学時刻で刻む。
            const double step=0.0001*norm(p)*std::sqrt(norm(p));
            const auto before=perihelion_orbital_state(e,jd-step).position_au;
            const auto after=perihelion_orbital_state(e,jd+step).position_au;
            const double actual_step=(jd+step)-(jd-step);
            near(v,{(after.x-before.x)/actual_step,(after.y-before.y)/actual_step,
                    (after.z-before.z)/actual_step},2e-8,"parabolic derivative");
        }
    }
    e={1,1,2451545,0,90,90};
    near(perihelion_orbital_state(e,e.perihelion_jd).position_au,{0,0,1},1e-14,"parabolic rotation");
}

void conics() {
    using namespace mitaka;
    for (double eccentricity : {0.0,0.7,0.9999,1.0001,1.5,20.0}) {
        PerihelionElements e{0.7,eccentricity,2451545,23,57,93};
        const double a=e.perihelion_distance_au/std::abs(1-eccentricity);
        OrbitalElements old{e.perihelion_jd,a,eccentricity,0,k*180/pi/a/std::sqrt(a),23,57,93};
        for (double days : {-1000.0,0.0,1000.0}) {
            const auto actual=perihelion_orbital_state(e,e.perihelion_jd+days);
            const auto wanted=orbital_state(old,e.perihelion_jd+days);
            near(actual.position_au,wanted.position_au,0,"existing Kepler position");
            near(actual.velocity_au_per_day,wanted.velocity_au_per_day,0,"existing Kepler velocity");
            const double energy=norm(actual.velocity_au_per_day)*norm(actual.velocity_au_per_day)/2-k*k/norm(actual.position_au);
            near(energy,(eccentricity-1)*k*k/(2*e.perihelion_distance_au),1e-12,"conic energy");
        }
    }
    for (double days : {-100.0,0.0,100.0}) {
        PerihelionElements e{1,1,2451545,0,0,0};
        const auto p=perihelion_orbital_state(e,e.perihelion_jd+days).position_au;
        for(double eccentricity : {0.999999,1.000001}) {
            e.eccentricity=eccentricity;
            near(perihelion_orbital_state(e,e.perihelion_jd+days).position_au,p,5e-6,"parabolic limit");
        }
    }
}

void invalid() {
    using namespace mitaka;
    PerihelionElements e{1,1,2451545,0,0,0};
    for (double bad : {std::numeric_limits<double>::quiet_NaN(),std::numeric_limits<double>::infinity()}) {
        throws<std::invalid_argument>([&]{perihelion_orbital_state(e,bad);},"invalid time");
        auto changed=e; changed.ascending_node_deg=bad;
        throws<std::invalid_argument>([&]{perihelion_orbital_state(changed,2451545);},"invalid node");
    }
    e.perihelion_distance_au=0;
    throws<std::invalid_argument>([&]{perihelion_orbital_state(e,2451545);},"zero q");
    e.perihelion_distance_au=1; e.eccentricity=-1;
    throws<std::invalid_argument>([&]{perihelion_orbital_state(e,2451545);},"negative eccentricity");
    e.eccentricity=1; e.perihelion_jd=-std::numeric_limits<double>::max();
    throws<std::out_of_range>([&]{perihelion_orbital_state(e,std::numeric_limits<double>::max());},"time subtraction overflow");
    e={std::numeric_limits<double>::min(),1,2451545,0,0,0};
    throws<std::out_of_range>([&]{perihelion_orbital_state(e,2451546);},"tiny q overflow");
}
} // namespace
int main() {
    try { parabolic(); conics(); invalid(); std::cout<<"small-body orbit: "<<checks<<" checks passed\n"; }
    catch(const std::exception& error) { std::cerr<<"small-body orbit failure: "<<error.what()<<'\n'; return 1; }
}
