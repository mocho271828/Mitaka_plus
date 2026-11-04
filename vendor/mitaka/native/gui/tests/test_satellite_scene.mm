#import <Foundation/Foundation.h>
#include "satellite_scene.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstring>
#include <fstream>
#include <iostream>
#include <limits>
#include <stdexcept>

namespace {
using namespace mitaka;
using namespace mitaka::gui;
constexpr double jd = 2451545;
unsigned checks = 0;
void require(bool value, const char* message) { ++checks; if (!value) throw std::runtime_error(message); }
void same(Vec3 actual, Vec3 expected, const char* message) {
    require(std::isfinite(actual.x) && std::isfinite(actual.y) && std::isfinite(actual.z) &&
        std::hypot(actual.x-expected.x, actual.y-expected.y, actual.z-expected.z) < 1e-11, message);
}
// 変換の作用方向を既知の X 軸回転と独立比較する。
Vec3 equatorial(Vec3 p) {
    const double angle = 23.43929111111111 * std::acos(-1.0) / 180;
    return {p.x,p.y*std::cos(angle)-p.z*std::sin(angle),p.y*std::sin(angle)+p.z*std::cos(angle)};
}
const SolarBody& body(const SolarBodies& bodies, Body id) {
    return *std::find_if(bodies.begin(),bodies.end(),[=](const auto& item) { return item.id==id; });
}
SolarBodies initial_bodies() {
    const std::array<Body,11> ids{{Body::pluto,Body::earth,Body::moon,Body::sun,Body::saturn,
        Body::mercury,Body::jupiter,Body::venus,Body::neptune,Body::mars,Body::uranus}};
    SolarBodies bodies{};
    for (std::size_t i=0;i<bodies.size();++i) bodies[i]={ids[i],{123,456,789},{{0,1,0},{-1,0,0},{0,0,1}}};
    return bodies;
}
void unchanged(const SolarBodies& actual, const SolarBodies& expected, const char* message) {
    for (std::size_t i=0;i<actual.size();++i) {
        require(actual[i].id==expected[i].id,message);
        same(actual[i].position_au,expected[i].position_au,message);
        same(actual[i].orientation.x_axis,expected[i].orientation.x_axis,message);
        same(actual[i].orientation.y_axis,expected[i].orientation.y_axis,message);
        same(actual[i].orientation.north_axis,expected[i].orientation.north_axis,message);
    }
}
void integer(std::string& bytes, std::uint32_t n) {
    for (int i=0;i<4;++i) bytes.push_back(static_cast<char>((n>>(i*8))&255));
}
void real(std::string& bytes, double n) {
    std::uint64_t bits; std::memcpy(&bits,&n,sizeof(bits));
    for (int i=0;i<8;++i) bytes.push_back(static_cast<char>((bits>>(i*8))&255));
}
struct Fixture {
    std::filesystem::path root=std::filesystem::temp_directory_path()/
        ("mitaka-satellite-scene-"+std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    Fixture() {
        std::filesystem::create_directories(root/"data/orbits");
        write("orbits/parent.dat","");
        for (const int a : {100,200}) write("orbits/e"+std::to_string(a)+".dat",
            "Epoch: 2451545\na: "+std::to_string(a)+"\ne: 0\nM0: 0\nn: 90\nw: 0\ni: 0\nnode: 0\nPw: 0\nPnode: 0\nRefPlane: E\n");
        const std::array<const char*,9> names{{"Mercury","Venus","Earth","Mars","Jupiter","Saturn","Uranus","Neptune","Pluto"}};
        for (const int a : {100,200}) {
            std::string system="Ssystem\n{\nSun\n{\nName: Sun\n";
            for (std::size_t i=0;i<names.size();++i) {
                system+="Planet\n{\nName: "+std::string(names[i])+"\nOrbit: ./data/orbits/parent.dat\n";
                const auto satellite=[&](const char* name) {
                    return "Satellite\n{\nName: "+std::string(name)+"\nOrbit: ./data/orbits/e"+std::to_string(a)+".dat\n}\n";
                };
                if (i==2) system+=satellite("Moon")+satellite("Moon");
                if (i==8) system+=satellite("Charon");
                system+="}\n";
            }
            write(a==100?"ssystem.dat":"ssystem_jp.dat",system+"}\n}\n");
        }
        std::string cf="CF96"; integer(cf,9);
        for (int i=0;i<9;++i) {
            real(cf,jd-1); real(cf,2); integer(cf,0); integer(cf,1); integer(cf,1); integer(cf,0);
            for (const double axis : {i+1.0,2*i+3.0,3*i+4.0}) {
                integer(cf,2); real(cf,axis*1e10); real(cf,0); integer(cf,1); integer(cf,0);
            }
        }
        write("cf96.dat",cf);
    }
    ~Fixture() { std::error_code error; std::filesystem::remove_all(root,error); }
    void write(const std::string& key,const std::string& bytes) const {
        std::ofstream output(root/"data"/key,std::ios::binary);
        output.write(bytes.data(),static_cast<std::streamsize>(bytes.size()));
        if (!output) throw std::runtime_error("fixture write failed");
    }
};
void synthetic_tests() {
    Fixture fixture;
    const auto model=load_satellite_browser_model(fixture.root/"data");
    const auto cf96=Cf96Ephemeris::load(fixture.root/"data/cf96.dat");
    const auto snapshot=evaluate_satellite_snapshot(model,cf96,jd);
    require(snapshot->evaluations.size()==2 && snapshot->positions.size()==6,"both source contexts evaluated independently");
    const auto original=initial_bodies();
    const auto applied=apply_satellite_parent_positions(original,*snapshot);
    const auto& first=snapshot->evaluations.front();
    require(verified_satellite_scene_context(*snapshot,first)==&model->model().registration_contexts().front(),
        "verification returns borrowed context from same immutable model");
    same(body(applied,Body::earth).position_au,equatorial(*first.planets[2].position_au),"Earth uses corrected first source once");
    same(body(applied,Body::pluto).position_au,equatorial(*first.planets[8].position_au),"Pluto uses corrected first source once");
    same(body(applied,Body::moon).position_au,equatorial(*first.positions[0].position_au),"Moon uses first name rather than later duplicate");
    same(body(applied,Body::sun).position_au,body(original,Body::sun).position_au,"Sun unchanged");
    for (const auto& item : applied) {
        same(item.orientation.x_axis,body(original,item.id).orientation.x_axis,"orientation unchanged");
        same(item.orientation.y_axis,body(original,item.id).orientation.y_axis,"orientation unchanged");
        same(item.orientation.north_axis,body(original,item.id).orientation.north_axis,"orientation unchanged");
    }
    unchanged(apply_satellite_parent_positions(applied,*snapshot),applied,"repeated application does not accumulate correction or rotation");
    const auto selected=apply_satellite_parent_positions(original,*snapshot,"ssystem_jp.dat");
    same(body(selected,Body::pluto).position_au,equatorial(*snapshot->evaluations[1].planets[8].position_au),"explicit source supplies Pluto center");
    require(std::abs(body(selected,Body::pluto).position_au.x-body(applied,Body::pluto).position_au.x)>1e-9,"source choice changes fixture parent center");
    unchanged(apply_satellite_parent_positions(original,*snapshot,"absent.dat"),original,"missing requested source never falls back");
    auto partial=*snapshot;
    partial.evaluations[0].planets[2].position_au.reset();
    partial.evaluations[0].positions[0].position_au.reset();
    const auto incomplete=apply_satellite_parent_positions(original,partial);
    same(body(incomplete,Body::earth).position_au,body(original,Body::earth).position_au,"unresolved Earth preserves input");
    same(body(incomplete,Body::moon).position_au,body(original,Body::moon).position_au,"unresolved first Moon does not use second Moon");
    same(body(incomplete,Body::pluto).position_au,body(applied,Body::pluto).position_au,"resolved parent survives other unresolved positions");
    for (int failure=0;failure<8;++failure) {
        auto invalid=*snapshot;
        auto& evaluation=invalid.evaluations[0];
        if (failure==0) evaluation.legacy_julian_date+=1;
        if (failure==1) evaluation.registration.reset();
        if (failure==2) evaluation.context.cf96_binding_evidence.clear();
        if (failure==3) evaluation.planets[0].registration_index.value=1;
        if (failure==4) evaluation.planets[0].identifier_bytes="Pluto";
        if (failure==5) evaluation.planets[0].definition_index+=1;
        if (failure==6) evaluation.positions.clear();
        if (failure==7) evaluation.registration->evidence="different model evidence";
        require(!verified_satellite_scene_context(invalid,evaluation),"invalid snapshot has no verified context");
        unchanged(apply_satellite_parent_positions(original,invalid,"ssystem.dat"),original,"unverified source leaves originals");
        same(body(apply_satellite_parent_positions(original,invalid),Body::pluto).position_au,
            body(selected,Body::pluto).position_au,"default selects first verified evaluation");
    }
    auto invalid=*snapshot;
    invalid.evaluations[0].planets[8].position_au->x=std::numeric_limits<double>::quiet_NaN();
    same(body(apply_satellite_parent_positions(original,invalid),Body::pluto).position_au,
        body(original,Body::pluto).position_au,"nonfinite parent is not published");
    invalid.evaluations[0].planets[8].position_au=Vec3{0,std::numeric_limits<double>::max(),std::numeric_limits<double>::max()};
    same(body(apply_satellite_parent_positions(original,invalid),Body::pluto).position_au,
        body(original,Body::pluto).position_au,"coordinate conversion overflow is not published");
    invalid.model.reset();
    require(!verified_satellite_scene_context(invalid,invalid.evaluations.front()),"missing model rejected at public seam");
    unchanged(apply_satellite_parent_positions(original,invalid),original,"missing model leaves originals");
}
void local_tests(const std::filesystem::path& directory) {
    const auto model=load_satellite_browser_model(directory);
    const auto cf96=Cf96Ephemeris::load(directory/"cf96.dat");
    const auto snapshot=evaluate_satellite_snapshot(model,cf96,jd);
    const auto original=initial_bodies();
    if (snapshot->evaluations.empty()) {
        unchanged(apply_satellite_parent_positions(original,*snapshot),original,"no local satellite context leaves major bodies intact");
        return;
    }
    for (const auto& evaluation : snapshot->evaluations) {
        const auto result=apply_satellite_parent_positions(original,*snapshot,evaluation.context.source_key);
        const auto& records=model->model().records();
        for (std::size_t i=0;i<records.size();++i) {
            if (model->source(i)!=evaluation.context.source_key || records[i].identifier_bytes!="Moon") continue;
            if (snapshot->positions[i]) same(body(result,Body::moon).position_au,
                equatorial(*snapshot->positions[i]),"local main Moon and first satellite Moon coincide");
            break;
        }
        unchanged(apply_satellite_parent_positions(result,*snapshot,evaluation.context.source_key),result,"local correction remains idempotent");
    }
}
} // namespace
int main(int argc,char** argv) {
    @autoreleasepool {
        try {
            synthetic_tests();
            if (argc>1) local_tests(argv[1]);
            std::cout<<"Satellite scene: "<<checks<<" checks PASS\n";
        } catch (const std::exception& error) { std::cerr<<"Satellite scene: "<<error.what()<<'\n'; return 1; }
    }
}
