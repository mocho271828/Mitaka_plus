#import <Foundation/Foundation.h>
#include "eclipse_display.hpp"
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
constexpr double jd=2451545;
constexpr double au_km=149597870.7;
unsigned checks=0;
void require(bool value,const char* message) {
    ++checks;
    if (!value) throw std::runtime_error(message);
}
bool diagnostic(const EclipseDisplayFrame& frame,const std::string& text) {
    return std::any_of(frame.diagnostics.begin(),frame.diagnostics.end(),[&](const auto& entry) {
        return entry.find(text)!=std::string::npos;
    });
}
void integer(std::string& bytes,std::uint32_t number) {
    for (int i=0;i<4;++i) bytes.push_back(static_cast<char>((number>>(i*8))&255));
}
void real(std::string& bytes,double number) {
    std::uint64_t bits; std::memcpy(&bits,&number,sizeof(bits));
    for (int i=0;i<8;++i) bytes.push_back(static_cast<char>((bits>>(i*8))&255));
}
// test_satellite_scene と同じ正式 loader/CF96 登録経路を使う。遮蔽の配置は
// evaluator の数値試験とは分離し、検証済み snapshot の座標だけを既知値へ置く。
struct Fixture {
    std::filesystem::path root=std::filesystem::temp_directory_path()/
        ("mitaka-eclipse-display-"+std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    explicit Fixture(const std::string& first_radius="Radius: 1000\n",const std::string& spelling="Calliso") {
        std::filesystem::create_directories(root/"data/orbits");
        write("orbits/parent.dat","");
        write("orbits/satellite.dat","Epoch: 2451545\na: 1000000\ne: 0\nM0: 0\nn: 90\nw: 0\ni: 0\nnode: 0\nPw: 0\nPnode: 0\nRefPlane: E\n");
        const std::array<const char*,9> names{{"Mercury","Venus","Earth","Mars","Jupiter","Saturn","Uranus","Neptune","Pluto"}};
        std::string system="Ssystem\n{\nSun\n{\nName: Sun\n";
        for (std::size_t i=0;i<names.size();++i) {
            system+="Planet\n{\nName: "+std::string(names[i])+"\nOrbit: ./data/orbits/parent.dat\n";
            const auto satellite=[&](const std::string& name,const std::string& radius) {
                return "Satellite\n{\nName: "+name+"\n"+radius+"Orbit: ./data/orbits/satellite.dat\n}\n";
            };
            if (i==2) system+=satellite("Moon","Radius: 1737.4\n");
            if (i==4) {
                for (const auto* name : {"Io","Europa","Ganymede"}) system+=satellite(name,"Radius: 1000\n");
                system+=satellite(spelling,first_radius)+satellite(spelling,"Radius: 2000\n");
            }
            system+="}\n";
        }
        write("ssystem.dat",system+"}\n}\n");
        write("ssystem_jp.dat",system+"}\n}\n");
        std::string cf="CF96"; integer(cf,9);
        for (int i=0;i<9;++i) {
            real(cf,jd-1); real(cf,2); integer(cf,0); integer(cf,1); integer(cf,1); integer(cf,0);
            for (const double axis : {i+1.0,0.0,0.0}) {
                integer(cf,2); real(cf,axis*1e10); real(cf,0); integer(cf,1); integer(cf,0);
            }
        }
        write("cf96.dat",cf);
    }
    ~Fixture() { std::error_code error; std::filesystem::remove_all(root,error); }
    void write(const std::string& path,const std::string& bytes) const {
        std::ofstream output(root/"data"/path,std::ios::binary);
        output.write(bytes.data(),static_cast<std::streamsize>(bytes.size()));
        if (!output) throw std::runtime_error("fixture write failed");
    }
    SatelliteSnapshot snapshot() const {
        const auto model=load_satellite_browser_model(root/"data");
        auto result=*evaluate_satellite_snapshot(model,Cf96Ephemeris::load(root/"data/cf96.dat"),jd);
        require(result.evaluations.size()==2 && result.positions.size()==12,"two independent source registrations and duplicate rows retained");
        for (std::size_t source=0;source<result.evaluations.size();++source) {
            auto& evaluation=result.evaluations[source];
            require(verified_satellite_scene_context(result,evaluation)!=nullptr,"fixture registration is verified before synthetic geometry");
            for (std::size_t i=0;i<9;++i) evaluation.planets[i].position_au=Vec3{i+1.0,source*.25,0};
            for (const auto row : model->model().registration_contexts()[source].satellite_record_indices) {
                const auto& record=model->model().records()[row];
                Vec3 position{4.995,source*.25+.1,0};
                if (record.identifier_bytes=="Moon") position={3.003,source*.25,0};
                else if (record.identifier_bytes=="Calliso" || record.identifier_bytes=="Callisto") position.y=source*.25;
                evaluation.positions[row].position_au=position;
                result.positions[row]=position;
            }
        }
        return result;
    }
};
SolarBodies bodies_for(const SatelliteSnapshot& snapshot,std::size_t source=0) {
    const std::array<Body,11> ids{{Body::sun,Body::mercury,Body::venus,Body::earth,Body::mars,
        Body::jupiter,Body::saturn,Body::uranus,Body::neptune,Body::pluto,Body::moon}};
    SolarBodies bodies{};
    for (std::size_t i=0;i<bodies.size();++i) bodies[i]={ids[i],{0,0,0},{{1,0,0},{0,1,0},{0,0,1}}};
    return apply_satellite_parent_positions(bodies,snapshot,snapshot.evaluations[source].context.source_key);
}
std::size_t first_row(const SatelliteSnapshot& snapshot,const std::string& identifier) {
    for (const auto row : snapshot.model->model().registration_contexts().front().satellite_record_indices)
        if (snapshot.model->model().records()[row].identifier_bytes==identifier) return row;
    throw std::runtime_error("fixture row is missing");
}
void require_no_jupiter(const SolarBodies& bodies,const SatelliteSnapshot& snapshot,const char* message) {
    const auto frame=make_eclipse_display_frame(bodies,jd,&snapshot,{});
    require(!frame.surfaces[5],message);
    require(!frame.diagnostics.empty(),"rejected satellite input has a diagnostic");
    require(frame.surfaces[3].has_value() && frame.surfaces[10].has_value(),"satellite rejection preserves independent Earth and Moon bindings");
}
void valid_and_boundary_tests() {
    Fixture fixture;
    const auto snapshot=fixture.snapshot();
    const auto bodies=bodies_for(snapshot);
    const auto frame=make_eclipse_display_frame(bodies,jd,&snapshot,{});
    require(frame.diagnostics.empty(),"verified source has no diagnostics");
    require(frame.surfaces[3] && frame.surfaces[10] && frame.surfaces[5],"Earth Moon and Jupiter have surface bindings");
    require(frame.surfaces[5]->active(),"exact Calliso name makes Jupiter shadow active");
    require(frame.surfaces[5]->effect({-1,0,0},0).multiplier[0]<.01,"known on-axis satellite darkens day-side receiver");
    require(std::abs(frame.surfaces[5]->receiver().radius_au*au_km-71492)<1e-8,"receiver uses physical Jupiter radius");
    require(!frame.earth_moon_space,"default flags do not make space geometry");
    for (std::size_t i=0;i<frame.surfaces.size();++i)
        if (i!=3 && i!=5 && i!=10) require(!frame.surfaces[i],"unsupported receiver has no inferred eclipse binding");
    const auto none=make_eclipse_display_frame(bodies,jd,&snapshot,{false,false,false,false});
    require(std::none_of(none.surfaces.begin(),none.surfaces.end(),[](const auto& item){return item.has_value();}) &&
        !none.earth_moon_space && none.diagnostics.empty(),"all flags off produces no work");
    for (const auto options : {EclipseDisplayOptions{false,false,true,false},EclipseDisplayOptions{false,false,false,true}}) {
        const auto cones=make_eclipse_display_frame(bodies,jd,&snapshot,options);
        require(cones.earth_moon_space.has_value(),"either independent space flag creates geometry");
        require(!cones.surfaces[3] && !cones.surfaces[5] && !cones.surfaces[10],"space flags do not enable surface shadows");
    }
    require(make_eclipse_display_frame(bodies,jd,nullptr,{}).surfaces[3].has_value(),"Earth Moon work without satellite dataset");
    for (const double invalid : {std::numeric_limits<double>::quiet_NaN(),std::numeric_limits<double>::infinity()}) {
        bool rejected=false;
        try { (void)make_eclipse_display_frame(bodies,invalid,&snapshot,{}); }
        catch (const std::invalid_argument&) { rejected=true; }
        require(rejected,"nonfinite scene JD rejected");
    }
    for (int defect=0;defect<9;++defect) {
        auto invalid=snapshot;
        auto& evaluation=invalid.evaluations.front();
        if (defect==0) invalid.julian_date+=1;
        if (defect==1) evaluation.legacy_julian_date+=1;
        if (defect==2) evaluation.registration.reset();
        if (defect==3) evaluation.context.cf96_binding_evidence.clear();
        if (defect==4) evaluation.planets[4].definition_index+=1;
        if (defect==5) evaluation.planets[4].position_au->x+=.01;
        if (defect==6) evaluation.positions.clear();
        if (defect==7) invalid.positions.clear();
        if (defect==8) invalid.model.reset();
        require_no_jupiter(bodies,invalid,"JD source identity parent or shape mismatch does not use another source");
    }
    auto mismatched_bodies=bodies;
    mismatched_bodies[1].position_au.x+=.01;
    require_no_jupiter(mismatched_bodies,snapshot,"any resolved displayed parent mismatch rejects source");
    mismatched_bodies=bodies;
    mismatched_bodies[10].position_au.x+=.01;
    require_no_jupiter(mismatched_bodies,snapshot,"first Moon mismatch rejects source");
    const auto alternate=make_eclipse_display_frame(bodies_for(snapshot,1),jd,&snapshot,{});
    require(alternate.surfaces[5].has_value() && alternate.diagnostics.empty(),"matching second source is used without mixing source positions");
    const auto calliso=first_row(snapshot,"Calliso");
    for (int defect=0;defect<4;++defect) {
        auto invalid=snapshot;
        auto& position=invalid.evaluations.front().positions[calliso];
        if (defect==0) position.definition_index+=1;
        if (defect==1) position.position_au.reset();
        if (defect==2) invalid.positions[calliso].reset();
        if (defect==3) invalid.positions[calliso]->x+=.001;
        const auto result=make_eclipse_display_frame(bodies,jd,&invalid,{});
        require(result.surfaces[5] && !result.surfaces[5]->active(),"invalid first matching row is not replaced by valid duplicate");
        require(diagnostic(result,"position or parent is unresolved: Calliso"),"row identity or position rejection is explained");
    }
}
void radius_and_name_tests() {
    for (const std::string radius : {"", "Radius: 0\n", "Radius: -1\n", "Radius: 1000\nRadius: 2000\n"}) {
        Fixture fixture(radius);
        const auto snapshot=fixture.snapshot();
        const auto frame=make_eclipse_display_frame(bodies_for(snapshot),jd,&snapshot,{});
        require(frame.surfaces[5] && !frame.surfaces[5]->active(),"missing invalid or duplicate Radius does not borrow later matching row");
        require(diagnostic(frame,"physical Radius is unresolved: Calliso"),"invalid physical radius has explicit reason");
    }
    Fixture fixture("Radius: 1000\n","Callisto");
    const auto snapshot=fixture.snapshot();
    const auto frame=make_eclipse_display_frame(bodies_for(snapshot),jd,&snapshot,{});
    require(frame.surfaces[5] && !frame.surfaces[5]->active(),"Callisto is not silently substituted for original Calliso identifier");
    require(diagnostic(frame,"identifier is absent: Calliso"),"unmatched original identifier has explicit reason");
}
} // namespace
int main() {
    @autoreleasepool {
        try {
            valid_and_boundary_tests();
            radius_and_name_tests();
            std::cout<<"Eclipse display: "<<checks<<" checks PASS\n";
        } catch (const std::exception& error) {
            std::cerr<<"Eclipse display: "<<error.what()<<'\n';
            return 1;
        }
    }
}
