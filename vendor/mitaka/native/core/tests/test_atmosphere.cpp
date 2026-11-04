#include "mitaka/atmosphere.hpp"

#include <chrono>
#include <cmath>
#include <cstring>
#include <fstream>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <type_traits>

namespace {
using namespace mitaka;
int checks = 0;
void expect(bool value, const std::string& label) {
    ++checks;
    if (!value) throw std::runtime_error(label);
}
template<class Exception, class Function> void throws(Function action, const char* label) {
    try { action(); } catch (const Exception&) { ++checks; return; }
    throw std::runtime_error(label);
}
template<class Value> void put(std::string& bytes, std::size_t offset, Value value) {
    using Bits = std::conditional_t<sizeof(Value)==4,std::uint32_t,std::uint64_t>;
    Bits bits;
    std::memcpy(&bits,&value,sizeof(bits));
    for (std::size_t i=0; i<sizeof(bits); ++i) bytes[offset+i] = static_cast<char>((bits>>(8*i))&255);
}
std::string fixture() {
    std::string bytes(48+12*6,'\0');
    put(bytes,0,std::int32_t(2)); put(bytes,4,std::int32_t(3));
    put(bytes,8,6378000.0); put(bytes,16,6442000.0); put(bytes,24,8000.0);
    put(bytes,32,2.5469e25); put(bytes,40,3.141592653589793);
    for (std::size_t i=0; i<18; ++i) put(bytes,48+4*i,float(i+1)*1e-8f);
    return bytes;
}
void rejected(const std::string& bytes) {
    const auto source = parse_atmosphere_emission_map(bytes,"invalid-emmap.dat");
    expect(!source.map && source.read_complete,"invalid data not substituted");
    expect(source.bytes == bytes && source.file_size == bytes.size(),"invalid bytes preserved");
    expect(source.diagnostics.size()==1 && source.diagnostics[0].code==AtmosphereLoadFailure::invalid_format,
           "invalid data diagnostic");
    throws<CatalogError>([&]{AtmosphereEmissionMap::parse(bytes,"invalid-emmap.dat");},"direct parser rejected");
}
void loader() {
    const auto bytes = fixture();
    const auto source = parse_atmosphere_emission_map(bytes,"emmap.dat");
    expect(source.map && source.read_complete && source.diagnostics.empty(),"valid source");
    expect(source.bytes==bytes && source.file_size==bytes.size() && source.path=="emmap.dat","raw source identity");
    const auto& map = *source.map;
    expect(map.grid().radial_count==2 && map.grid().angle_count==3,"dimensions");
    expect(map.grid().ground_radius_m==6378000 && map.grid().outer_radius_m==6442000 &&
           map.grid().scale_height_m==8000 && map.grid().surface_number_density_per_m3==2.5469e25,
           "header values");
    expect(map.radii_m()==std::vector<double>({6378000,6442000}),"radial endpoints");
    for (std::size_t i=0; i<6; ++i) {
        const auto node=map.nodes()[i];
        expect(node.r==float(3*i+1)*1e-8f && node.g==float(3*i+2)*1e-8f &&
               node.b==float(3*i+3)*1e-8f,"node order and value");
    }
    for (std::size_t size=0; size<bytes.size(); ++size) rejected(bytes.substr(0,size));
    rejected(bytes+"x");
    for (std::int32_t count : {-1,0,1,std::numeric_limits<std::int32_t>::max()}) {
        for (std::size_t offset : {0,4}) { auto bad=bytes; put(bad,offset,count); rejected(bad); }
    }
    for (double bad : {std::numeric_limits<double>::quiet_NaN(),std::numeric_limits<double>::infinity(),-1.0}) {
        for (std::size_t offset : {8,16,24,32,40}) { auto changed=bytes; put(changed,offset,bad); rejected(changed); }
    }
    for (std::size_t offset : {8,24,40}) { auto bad=bytes; put(bad,offset,0.0); rejected(bad); }
    for (double value : {6378000.0,6300000.0,1e200}) { auto bad=bytes; put(bad,16,value); rejected(bad); }
    for (double value : {4.0,std::numeric_limits<double>::denorm_min()}) {
        auto bad=bytes; put(bad,40,value); rejected(bad);
    }
    { auto bad=bytes; put(bad,8,1e-300); put(bad,16,2e-300); rejected(bad); }
    for (float bad : {-1.0f,std::numeric_limits<float>::infinity(),std::numeric_limits<float>::quiet_NaN()}) {
        for (std::size_t offset : {48,52,56,116}) { auto changed=bytes; put(changed,offset,bad); rejected(changed); }
    }
    CatalogLoadLimits limits;
    limits.max_records=5;
    expect(!parse_atmosphere_emission_map(bytes,"limited",limits).map,"node limit");
    limits.max_records=6; limits.max_file_bytes=bytes.size();
    expect(parse_atmosphere_emission_map(bytes,"limited",limits).map.has_value(),"exact limits");
    --limits.max_file_bytes;
    const auto limited=parse_atmosphere_emission_map(bytes,"limited",limits);
    expect(!limited.map && limited.bytes==bytes && limited.read_complete &&
           limited.diagnostics[0].code==AtmosphereLoadFailure::limit_exceeded,"provided bytes limit");

    const auto id=std::chrono::steady_clock::now().time_since_epoch().count();
    const auto directory=std::filesystem::temp_directory_path()/("mitaka atmosphere "+std::to_string(id));
    expect(std::filesystem::create_directory(directory),"create fixture directory");
    struct Cleanup { std::filesystem::path path; ~Cleanup() { std::error_code error; std::filesystem::remove_all(path,error); } } cleanup{directory};
    const auto path=directory/"emmap.dat";
    const auto missing=load_atmosphere_emission_map(path);
    expect(!missing.map && !missing.read_complete && missing.diagnostics[0].code==AtmosphereLoadFailure::unreadable,"missing source");
    { std::ofstream file(path,std::ios::binary); file.write(bytes.data(),bytes.size()); expect(bool(file),"write fixture"); }
    const auto loaded=load_atmosphere_emission_map(path);
    expect(loaded.map && loaded.read_complete && loaded.bytes==bytes && loaded.path==path,"file raw preservation");
    const auto too_large=load_atmosphere_emission_map(path,limits);
    expect(!too_large.map && !too_large.read_complete && too_large.bytes.empty() &&
           too_large.file_size==bytes.size() && too_large.diagnostics[0].code==AtmosphereLoadFailure::limit_exceeded,
           "file checked before allocation");
}
bool zero(AtmosphereRgb value) { return value.r==0 && value.g==0 && value.b==0; }
void computation() {
    const AtmosphereParameters params{6378136.6,6442136.6,8000,2.69e25,1};
    const AtmosphereRay ray{{0,0,6380000},{0,0,1},{0,0,1}};
    const auto map=AtmosphereEmissionMap::parse(fixture(),"fixture");
    const auto single=atmosphere_single_scattering(params,ray);
    const auto multiple=atmosphere_multiple_scattering(map,ray);
    expect(single.r>0 && single.g>single.r && single.b>single.g,"daylight single spectrum");
    expect(multiple.r>0 && multiple.g>0 && multiple.b>0,"multiple scattering nonzero");
    auto clipped=ray;
    clipped.maximum_distance_m=0;
    expect(zero(atmosphere_single_scattering(params,clipped)),"zero finite single path");
    expect(zero(atmosphere_multiple_scattering(map,clipped)),"zero finite multiple path");
    clipped.maximum_distance_m=1000;
    const auto short_single=atmosphere_single_scattering(params,clipped);
    const auto short_multiple=atmosphere_multiple_scattering(map,clipped);
    expect(short_single.r>0 && short_single.r<single.r,"single finite endpoint clips emission");
    expect(short_multiple.r>0 && short_multiple.r<multiple.r,"multiple finite endpoint clips emission");
    clipped.maximum_distance_m=1e8;
    const auto full_single=atmosphere_single_scattering(params,clipped);
    const auto full_multiple=atmosphere_multiple_scattering(map,clipped);
    expect(full_single.r==single.r && full_single.g==single.g && full_single.b==single.b,"single distant endpoint unchanged");
    expect(full_multiple.r==multiple.r && full_multiple.g==multiple.g && full_multiple.b==multiple.b,"multiple distant endpoint unchanged");
    const AtmosphereRay before_entry{{0,0,13000000},{0,0,-1},{0,0,1},1};
    expect(zero(atmosphere_single_scattering(params,before_entry)),"single occluder before atmosphere entry");
    expect(zero(atmosphere_multiple_scattering(map,before_entry)),"multiple occluder before atmosphere entry");
    auto clear=fixture(); put(clear,32,0.0);
    for(std::size_t i=48;i<clear.size();i+=4) put(clear,i,1e-6f);
    const auto uniform=AtmosphereEmissionMap::parse(clear,"uniform");
    const AtmosphereRay uniform_ray{{0,0,6380000},{0,0,1},{0,0,1},1000};
    expect(std::abs(atmosphere_multiple_scattering(uniform,uniform_ray).r-.001f)<1e-9,
           "partial shell uses clipped rectangle length and original endpoint sample");
    for (double limit : {-1.0,std::numeric_limits<double>::infinity(),std::numeric_limits<double>::quiet_NaN()}) {
        clipped.maximum_distance_m=limit;
        throws<std::invalid_argument>([&]{atmosphere_single_scattering(params,clipped);},"invalid single distance limit");
        throws<std::invalid_argument>([&]{atmosphere_multiple_scattering(map,clipped);},"invalid multiple distance limit");
    }
    expect(zero(atmosphere_multiple_scattering(map,{{0,0,map.grid().ground_radius_m},
        {0.9998476951563913,0,-0.01745240643728351},{0,0,1}})),"ground inward zero path");
    const AtmosphereRay away{{0,0,13000000},{0,0,1},{0,0,1}};
    const AtmosphereRay miss{{0,0,13000000},{1,0,0},{0,0,1}};
    for (const auto& no_hit : {away,miss}) {
        expect(zero(atmosphere_single_scattering(params,no_hit)),"single forward miss");
        expect(zero(atmosphere_multiple_scattering(map,no_hit)),"multiple forward miss");
    }
    auto doubled=params; doubled.incident_intensity=2;
    const auto twice=atmosphere_single_scattering(doubled,ray);
    expect(twice.r==2*single.r && twice.g==2*single.g && twice.b==2*single.b,"incident intensity linearity");
    auto dark=params; dark.incident_intensity=0;
    expect(zero(atmosphere_single_scattering(dark,ray)),"zero incident intensity");
    dark=params; dark.surface_number_density_per_m3=0;
    expect(zero(atmosphere_single_scattering(dark,ray)),"zero density");
    auto zero_map=fixture();
    for (std::size_t i=48; i<zero_map.size(); i+=4) put(zero_map,i,0.0f);
    expect(zero(atmosphere_multiple_scattering(AtmosphereEmissionMap::parse(zero_map,"zero"),ray)),"zero emission");
    const auto composed=compose_atmosphere_display({.1f,.2f,.3f},{.02f,.03f,.04f},2);
    expect(composed.rgb.r==.1f+2*.02f && composed.rgb.g==.2f+2*.03f &&
           composed.rgb.b==.3f+2*.04f && composed.alpha==1,"additive RGB and alpha cap");
    expect(compose_atmosphere_display({.01f,.02f,.03f},{},1).alpha==4*.03f,"alpha is not RGB weight");
    expect(compose_atmosphere_display({},{},1).alpha==0,"black alpha");
    for (std::size_t samples : {0,1,4097})
        throws<std::invalid_argument>([&]{atmosphere_single_scattering(params,ray,samples);},"sample bound");
    for (const auto& bad_ray : {AtmosphereRay{{0,0,6300000},{0,0,1},{0,0,1}},
                               AtmosphereRay{{0,0,6380000},{0,0,0},{0,0,1}},
                               AtmosphereRay{{0,0,6380000},{0,0,1},{0,0,2}},
                               AtmosphereRay{{0,0,std::numeric_limits<double>::quiet_NaN()},{0,0,1},{0,0,1}}}) {
        throws<std::invalid_argument>([&]{atmosphere_single_scattering(params,bad_ray);},"single invalid ray");
        throws<std::invalid_argument>([&]{atmosphere_multiple_scattering(map,bad_ray);},"multiple invalid ray");
    }
    for (double bad : {-1.0,std::numeric_limits<double>::quiet_NaN(),std::numeric_limits<double>::infinity()}) {
        auto invalid=params; invalid.incident_intensity=bad;
        throws<std::invalid_argument>([&]{atmosphere_single_scattering(invalid,ray);},"invalid intensity");
        throws<std::invalid_argument>([&]{compose_atmosphere_display({},{},bad);},"invalid composition intensity");
    }
    for (double bad : {0.0,-1.0,std::numeric_limits<double>::quiet_NaN()}) {
        auto invalid=params; invalid.scale_height_m=bad;
        throws<std::invalid_argument>([&]{atmosphere_single_scattering(invalid,ray);},"invalid height");
    }
    auto invalid=params; invalid.outer_radius_m=1e200;
    throws<std::out_of_range>([&]{atmosphere_single_scattering(invalid,ray);},"squared radius overflow");
    invalid=params; invalid.scale_height_m=1e-300;
    throws<std::out_of_range>([&]{atmosphere_single_scattering(invalid,ray);},"scaled radius overflow");
    invalid=params; invalid.ground_radius_m=1e-300; invalid.outer_radius_m=2e-300;
    throws<std::out_of_range>([&]{atmosphere_single_scattering(invalid,ray);},"squared radius underflow");
    throws<std::out_of_range>([]{compose_atmosphere_display({-1,0,0},{},1);},"negative result rejected");
    throws<std::out_of_range>([]{compose_atmosphere_display({},{1,1,1},1e300);},"display float overflow");
}
} // namespace
int main() {
    try { loader(); computation(); std::cout<<"atmosphere: "<<checks<<" checks passed\n"; }
    catch(const std::exception& error) { std::cerr<<"atmosphere failure: "<<error.what()<<'\n'; return 1; }
}
