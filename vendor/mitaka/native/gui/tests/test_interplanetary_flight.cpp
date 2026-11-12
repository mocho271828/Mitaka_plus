#include "interplanetary_flight.hpp"

#include <algorithm>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

namespace {
using namespace mitaka;
using namespace mitaka::gui;
void check(bool value, const char* message) { if (!value) throw std::runtime_error(message); }
double distance(Vec3 a, Vec3 b) { return std::hypot(a.x-b.x,a.y-b.y,a.z-b.z); }
Vec3 eye(const SolarCamera& camera) {
    const auto out=solar_camera_basis(camera).outward;
    return {camera.target.x+out.x*camera.distance_au,camera.target.y+out.y*camera.distance_au,
            camera.target.z+out.z*camera.distance_au};
}
void same_camera(const SolarCamera& a, const SolarCamera& b, double tolerance=1e-11) {
    check(distance(eye(a),eye(b))<tolerance,"camera eye mismatch");
    const auto x=solar_camera_basis(a), y=solar_camera_basis(b);
    check(distance(x.outward,y.outward)<tolerance && distance(x.up,y.up)<tolerance
          && distance(x.right,y.right)<tolerance,"camera orientation mismatch");
}
SolarCamera surface_camera(SurfaceSite site, const SolarBodies& bodies) {
    SurfaceNavigation nav;
    nav.set_site(site);
    return nav.camera(bodies);
}
template<class F> void rejects(F operation) {
    try { operation(); } catch (const std::invalid_argument&) { return; }
    throw std::runtime_error("expected invalid_argument");
}
SolarBodies fixture() {
    const std::array<Body,11> ids{Body::sun,Body::mercury,Body::venus,Body::earth,Body::mars,
        Body::jupiter,Body::saturn,Body::uranus,Body::neptune,Body::pluto,Body::moon};
    SolarBodies bodies{};
    for (std::size_t i=0;i<bodies.size();++i)
        bodies[i]={ids[i],j2000_ecliptic_to_equatorial({static_cast<double>(i),0,0}),{}};
    bodies[10].position_au=j2000_ecliptic_to_equatorial({3.0025,0,0});
    return bodies;
}
void finish(InterplanetaryFlight& flight, const SolarBodies& bodies, double start=0) {
    for (int i=1;i<=192;++i) {
        flight.advance(start+i/8.0,bodies);
        check(flight.flying() || flight.completed(),"flight unexpectedly interrupted");
        solar_camera_basis(flight.camera());
    }
    check(flight.completed(),"flight did not land");
    same_camera(flight.camera(),surface_camera(flight.destination(),bodies));
}
void all_targets(const SolarBodies& bodies) {
    for (std::size_t index=1;index<bodies.size();++index) {
        SurfaceSite destination;
        destination.body_index=index;
        destination.latitude_deg=-17;
        destination.longitude_deg=113;
        destination.terrain_offset_km=1.25;
        InterplanetaryFlight flight;
        flight.begin(SurfaceSite{},destination,bodies,0);
        same_camera(flight.camera(),surface_camera(SurfaceSite{},bodies));
        try { finish(flight,bodies); }
        catch (const std::runtime_error& e) {
            throw std::runtime_error("target "+std::to_string(index)+": "+e.what());
        }
        check(flight.destination().height_km==minimum_surface_height_km,"landing height must be 2m");
        check(flight.destination().terrain_offset_km==1.25,"landing terrain offset must be preserved");
    }
}
void boundaries(const SolarBodies& bodies) {
    SurfaceSite destination;
    destination.body_index=10;
    InterplanetaryFlight flight;
    flight.begin(SurfaceSite{},destination,bodies,0);
    double time=0;
    for (double boundary : {4.0,20.0,24.0}) {
        while (time+0.5<boundary-1e-6) { time+=0.5; flight.advance(time,bodies); }
        flight.advance(boundary-1e-6,bodies);
        const auto before=flight.camera();
        flight.advance(boundary,bodies);
        same_camera(before,flight.camera(),1e-6);
        if (boundary<24) {
            const auto exact=flight.camera();
            flight.advance(boundary+1e-6,bodies);
            same_camera(exact,flight.camera(),1e-6);
        }
        time=boundary+1e-6;
    }
    check(flight.completed(),"phase boundary flight must complete");
}
void invalid_and_interrupt(const SolarBodies& bodies) {
    InterplanetaryFlight flight;
    SurfaceSite destination;
    destination.body_index=4;
    flight.begin({},destination,bodies,10);
    flight.advance(10.5,bodies);
    const auto saved=flight.camera();
    const double progress=flight.progress();
    auto bad_site=destination;
    bad_site.body_index=0;
    rejects([&]{flight.begin({},bad_site,bodies,10.5);});
    rejects([&]{flight.begin_from_camera(saved,destination,bodies,std::numeric_limits<double>::infinity());});
    auto bad=bodies;
    bad[10].orientation.x_axis={0,0,0};
    rejects([&]{flight.advance(10.6,bad);});
    same_camera(saved,flight.camera());
    check(flight.flying() && flight.progress()==progress,"invalid input must retain state");
    for (double clock : {12.0,10.0,std::numeric_limits<double>::quiet_NaN()}) {
        flight.begin_from_camera(saved,destination,bodies,10.5);
        check(!flight.advance(clock,bodies),"invalid clock must not move");
        check(flight.stop_reason()==FlightStopReason::clock_discontinuity,"clock reason mismatch");
        same_camera(saved,flight.camera());
    }
    flight.begin_from_camera(saved,destination,bodies,20);
    flight.advance(20.5,bodies);
    flight.interrupt();
    const auto stopped=flight.camera();
    check(!flight.advance(21,bodies),"interrupted flight must stay stopped");
    same_camera(stopped,flight.camera());
    flight.begin_from_camera(stopped,destination,bodies,22);
    same_camera(stopped,flight.camera());
    finish(flight,bodies,22);
    flight.begin({},destination,bodies,0);
    flight.advance(0.5,bodies);
    const auto safe=flight.camera();
    bad=bodies;
    bad[5].position_au=j2000_ecliptic_to_equatorial(eye(safe));
    check(!flight.advance(0.5,bad),"new obstacle must stop flight");
    check(flight.stop_reason()==FlightStopReason::collision,"collision reason mismatch");
    same_camera(safe,flight.camera());
}
void moving_endpoints(SolarBodies bodies) {
    InterplanetaryFlight flight;
    SurfaceSite destination;
    destination.body_index=10;
    flight.begin({},destination,bodies,0);
    for (int step=1;step<=192;++step) {
        const double angle=step*0.004;
        bodies[3].orientation={{std::cos(angle),std::sin(angle),0},
                               {-std::sin(angle),std::cos(angle),0},{0,0,1}};
        bodies[10].orientation=bodies[3].orientation;
        bodies[3].position_au.x+=1e-7;
        bodies[10].position_au.x+=1e-7;
        flight.advance(step/8.0,bodies);
        check(flight.flying() || flight.completed(),"moving endpoints must remain reachable");
    }
    same_camera(flight.camera(),surface_camera(flight.destination(),bodies));
}
void antipodes_and_fast_spin(SolarBodies bodies) {
    for (double latitude : {0.0,90.0,-90.0}) {
        SurfaceSite destination;
        destination.longitude_deg=180;
        destination.latitude_deg=latitude;
        InterplanetaryFlight flight;
        flight.begin({},destination,bodies,0);
        finish(flight,bodies);
    }
    SurfaceSite destination;
    destination.body_index=4;
    destination.longitude_deg=180;
    InterplanetaryFlight flight;
    flight.begin({},destination,bodies,0);
    auto before=solar_camera_basis(flight.camera());
    for (int step=1;step<=480;++step) {
        const double angle=step/20.0*3.14159265358979323846/5;
        bodies[4].orientation={{std::cos(angle),std::sin(angle),0},
                               {-std::sin(angle),std::cos(angle),0},{0,0,1}};
        flight.advance(step/20.0,bodies);
        check(flight.flying() || flight.completed(),"fast spin flight interrupted");
        const auto after=solar_camera_basis(flight.camera());
        check(distance(before.outward,after.outward)<0.1 && distance(before.up,after.up)<0.1,
              "fast spin caused a camera orientation jump");
        before=after;
    }
    same_camera(flight.camera(),surface_camera(flight.destination(),bodies));
}
void sun_detour() {
    auto bodies=fixture();
    bodies[3].position_au=j2000_ecliptic_to_equatorial({-1,0,0});
    bodies[4].position_au=j2000_ecliptic_to_equatorial({1,0,0});
    bodies[1].position_au=j2000_ecliptic_to_equatorial({0,3,0});
    SurfaceSite source, destination;
    source.longitude_deg=90;
    destination=source;
    destination.body_index=4;
    InterplanetaryFlight flight;
    flight.begin(source,destination,bodies,0);
    for (int step=1;step<=480;++step) {
        flight.advance(step/20.0,bodies);
        check(flight.flying() || flight.completed(),"Sun detour must complete");
        check(distance(eye(flight.camera()),{})>696000/astronomical_unit_km,"flight crossed the Sun");
    }
}
void real_surface_roundtrips(const SolarBodies& bodies) {
    for (std::size_t body : {std::size_t{3}, std::size_t{4}, std::size_t{10}}) {
        for (double latitude : {-90.0, -65.0, 0.0, 35.68, 90.0}) {
            const SurfaceSite original{body, latitude, 139.76, minimum_surface_height_km,
                                       125, -80, 17};
            SurfaceNavigation navigation;
            navigation.set_site(original);
            const auto ground = navigation.camera(bodies);
            navigation.begin_ascent(10, 3);
            double previous_height = original.height_km;
            for (int step = 1; step <= 6; ++step) {
                check(navigation.advance(10 + step * 0.5), "real ascent must progress");
                check(navigation.site().height_km > previous_height, "real ascent must rise");
                previous_height = navigation.site().height_km;
                solar_camera_basis(navigation.camera(bodies));
            }
            check(!navigation.flying(), "real ascent must finish");
            const auto space = navigation.camera(bodies);
            const auto recovered = surface_site_from_camera_with_roll(space, bodies, body);
            navigation.set_site(recovered);
            same_camera(navigation.camera(bodies), space, 1e-11);
            navigation.begin_descent_preserving_look(20, 3);
            for (int step = 1; step <= 6; ++step) {
                check(navigation.advance(20 + step * 0.5), "real descent must progress");
                check(navigation.site().height_km < previous_height, "real descent must fall");
                previous_height = navigation.site().height_km;
                solar_camera_basis(navigation.camera(bodies));
            }
            check(!navigation.flying(), "real descent must finish");
            check(std::abs(navigation.site().height_km - minimum_surface_height_km) < 1e-9,
                  "real descent must reach the ground");
            same_camera(navigation.camera(bodies), ground, 1e-11);

            navigation.set_site(original);
            navigation.begin_ascent(30, 3);
            navigation.advance(30.5);
            const auto interrupted = navigation.camera(bodies);
            navigation.interrupt();
            navigation.begin_ascent(31, 3);
            same_camera(navigation.camera(bodies), interrupted, 1e-11);
            for (int step = 1; step <= 6; ++step) navigation.advance(31 + step * 0.5);
            check(!navigation.flying(), "resumed ascent must finish");

            auto far_camera = space;
            far_camera.distance_au = 5;
            const auto forced = forced_surface_site_from_camera(far_camera, bodies, body);
            check(forced.body_index == body && forced.height_km == minimum_surface_height_km,
                  "far forced landing must choose the selected body and ground height");
            check(forced.roll_deg == 0, "forced landing must level roll");
            solar_camera_basis(surface_camera(forced, bodies));

            // 降下を途中で離陸へ切り替えても視点を保持し、途中の時刻欠落は移動を中断する。
            navigation.set_site(recovered);
            navigation.begin_descent_preserving_look(50, 3);
            check(navigation.advance(50.5), "descent must progress before retarget");
            const auto descentInterrupted = navigation.camera(bodies);
            navigation.begin_ascent(50.5, 3);
            same_camera(navigation.camera(bodies), descentInterrupted, 1e-11);
            check(navigation.advance(51), "retargeted ascent must progress");
            const auto beforeGap = navigation.camera(bodies);
            check(!navigation.advance(53), "time gap must interrupt flight");
            check(!navigation.flying(), "time gap left flight active");
            same_camera(navigation.camera(bodies), beforeGap, 1e-11);

            // 地形の読み込み・再指定では上空の位置を維持し、接地目標は地形から 2m。
            auto terrainSite = original;
            terrainSite.terrain_offset_km = 1.25;
            navigation.set_site(terrainSite);
            const auto terrainGround = navigation.camera(bodies);
            navigation.begin_ascent(60, 3);
            navigation.advance(60.5);
            const auto beforeTerrain = navigation.camera(bodies);
            navigation.update_terrain_offset(1.0);
            same_camera(navigation.camera(bodies), beforeTerrain, 1e-11);
            for (int step = 2; step <= 6; ++step) navigation.advance(60 + step * 0.5);
            check(!navigation.flying(), "terrain-adjusted ascent must finish");
            const auto terrainSpace = navigation.camera(bodies);
            const auto terrainRecovered = surface_site_from_camera_with_roll(terrainSpace, bodies, body);
            navigation.set_site(terrainRecovered);
            navigation.update_terrain_offset(1.25);
            same_camera(navigation.camera(bodies), terrainSpace, 1e-11);
            navigation.begin_descent_preserving_look(70, 3);
            for (int step = 1; step <= 6; ++step) navigation.advance(70 + step * 0.5);
            check(!navigation.flying(), "terrain-adjusted descent must finish");
            same_camera(navigation.camera(bodies), terrainGround, 1e-11);

            // 負標高の地表から通常宇宙に切り替え、同じ視点を復元する。
            auto belowDatum = original;
            belowDatum.terrain_offset_km = -0.4;
            navigation.set_site(belowDatum);
            const auto belowSpace = navigation.camera(bodies);
            rejects([&] { surface_site_from_camera_with_roll(belowSpace, bodies, body); });
            const auto belowRecovered = surface_site_from_camera_with_known_terrain(
                belowSpace, bodies, body, belowDatum);
            check(belowRecovered.has_value(), "known below-datum site must restore");
            check(belowRecovered->terrain_offset_km == belowDatum.terrain_offset_km,
                  "restoration must retain signed terrain offset");
            auto lookedSite = belowDatum;
            lookedSite.heading_deg = 260;
            lookedSite.elevation_deg = 30;
            const auto lookedCamera = surface_camera(lookedSite, bodies);
            const auto looked = surface_site_from_camera_with_known_terrain(lookedCamera, bodies, body, belowDatum);
            check(looked.has_value(), "rotation at the same position must retain known terrain");
            same_camera(surface_camera(*looked, bodies), lookedCamera, 1e-11);
            navigation.set_site(*belowRecovered);
            same_camera(navigation.camera(bodies), belowSpace, 1e-11);
            navigation.begin_descent_preserving_look(80, 0);
            same_camera(navigation.camera(bodies), belowSpace, 1e-11);
            check(!surface_site_from_camera_with_known_terrain(belowSpace, bodies, body == 3 ? 4 : 3, belowDatum),
                  "known terrain must not be reused for another body");
            auto moved = belowSpace;
            moved.target.x += 1e-10;
            check(!surface_site_from_camera_with_known_terrain(moved, bodies, body, belowDatum),
                  "known terrain must not be reused after moving");

            navigation.set_site(original);
            navigation.begin_ascent(40, 0);
            check(!navigation.flying(), "zero-duration ascent must be immediate");
            const auto immediate = navigation.camera(bodies);
            navigation.set_site(surface_site_from_camera_with_roll(immediate, bodies, body));
            same_camera(navigation.camera(bodies), immediate, 1e-11);
            navigation.begin_descent_preserving_look(41, 0);
            check(!navigation.flying(), "zero-duration descent must be immediate");
            same_camera(navigation.camera(bodies), ground, 1e-11);
        }
    }
}
void real_data(const char* path) {
    const auto model=SkyModel::load(path);
    const auto range=model.time_range();
    // この配置では離陸直後から月へ向かう線と、最初の横方向の迂回線が地球を横切る。
    constexpr double blocked_lunar_route_jd = 2451501.600;
    if (range.first <= blocked_lunar_route_jd && blocked_lunar_route_jd <= range.second) {
        const auto bodies = model.solar_bodies(blocked_lunar_route_jd);
        const SurfaceSite lunar{10,25,-40};
        InterplanetaryFlight flight;
        flight.begin({},lunar,bodies,0);
        flight.advance(.5,bodies);
        flight.interrupt();
        const SolarCamera stopped = flight.camera();
        flight.begin_from_camera(stopped,lunar,bodies,1);
        same_camera(stopped,flight.camera());
        finish(flight,bodies,1);
    }
    const double date=std::clamp(2451545.0,range.first,range.second-1);
    all_targets(model.solar_bodies(date));
    boundaries(model.solar_bodies(date));
    invalid_and_interrupt(model.solar_bodies(date));
    real_surface_roundtrips(model.solar_bodies(date));
    real_surface_roundtrips(model.solar_bodies(date + std::min(30.0, (range.second - date) / 2)));
    for (std::size_t index=1;index<=10;++index) {
        InterplanetaryFlight flight;
        SurfaceSite destination;
        destination.body_index=index;
        flight.begin({},destination,model.solar_bodies(date),0);
        SolarBodies current{};
        for (int step=1;step<=192;++step) {
            current=model.solar_bodies(date+step*0.00001);
            flight.advance(step/8.0,current);
            check(flight.flying() || flight.completed(),"real moving ephemeris flight interrupted");
        }
        same_camera(flight.camera(),surface_camera(flight.destination(),current));
    }
}
} // namespace

int main(int argc, char** argv) {
    try {
        const auto bodies=fixture();
        all_targets(bodies);
        boundaries(bodies);
        invalid_and_interrupt(bodies);
        moving_endpoints(bodies);
        antipodes_and_fast_spin(bodies);
        sun_detour();
        if (argc>1) real_data(argv[1]);
        std::cout << "Interplanetary flight tests passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "Interplanetary flight test failed: " << error.what() << '\n';
        return 1;
    }
}
