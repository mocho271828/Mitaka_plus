#include "mitaka/constellation_art.hpp"
#include <algorithm>
#include <cmath>
#include <cstring>
#include <fstream>
#include <iostream>
#include <limits>
#include <unistd.h>

using namespace mitaka;
namespace {
unsigned checks = 0;
void check(bool ok, const char* message) { ++checks; if (!ok) throw std::runtime_error(message); }
void integer(std::vector<std::uint8_t>& bytes, std::uint32_t n) {
    for (unsigned i = 0; i < 4; ++i) bytes.push_back(static_cast<std::uint8_t>(n >> (8 * i)));
}
void number(std::vector<std::uint8_t>& bytes, float n) {
    std::uint32_t bits; std::memcpy(&bits, &n, 4); integer(bytes, bits);
}
std::vector<std::uint8_t> fixture() {
    std::vector<std::uint8_t> bytes;
    for (float n : {0.f, 0.f, 1.f, .5f, 0.f}) number(bytes,n);
    integer(bytes, 3);
    for (float n : {0.f, 0.f, 1.f, 2.f, 9.f, 9.f}) number(bytes,n);
    integer(bytes, 5);
    for (auto n : {0U,1U,0xffffffffU,0xfffffffeU,1U}) integer(bytes,n);
    return bytes;
}
void save(const std::filesystem::path& path, const std::vector<std::uint8_t>& bytes) {
    std::ofstream out(path, std::ios::binary); out.write(reinterpret_cast<const char*>(bytes.data()), bytes.size());
}
template<class F> void rejects(F f) {
    try { f(); } catch (const CatalogError&) { ++checks; return; }
    throw std::runtime_error("expected CatalogError");
}
// 独立な Rodrigues 回転で符号、順序、通常天球への frame 差を照合する。
Vec3 reference(const ConstellationArt& a, std::size_t index) {
    constexpr double rad = 3.14159265358979323846 / 180;
    double n=std::hypot(double(a.header[0]),double(a.header[1]),double(a.header[2]));
    Vec3 h{a.header[0]/n,a.header[1]/n,a.header[2]/n};
    double angle=std::remainder(double(a.header[4]),360)*rad;
    Vec3 v{-a.points[index][0]*std::cos(angle)-a.points[index][1]*std::sin(angle),
        -a.points[index][0]*std::sin(angle)+a.points[index][1]*std::cos(angle),0};
    if (h.z < -.999989986419677734375) v={v.x,-v.y,-v.z};
    else if (h.z <= .999989986419677734375) {
        double axis=std::hypot(h.x,h.y); Vec3 k{-h.y/axis,h.x/axis,0};
        double dot=k.x*v.x+k.y*v.y;
        Vec3 cross{k.y*v.z,-k.x*v.z,k.x*v.y-k.y*v.x};
        v={v.x*h.z+cross.x*axis+k.x*dot*(1-h.z),v.y*h.z+cross.y*axis+k.y*dot*(1-h.z),
            v.z*h.z+cross.z*axis};
    }
    Vec3 w{h.x+2*a.header[3]*v.x,h.y+2*a.header[3]*v.y,h.z+2*a.header[3]*v.z};
    double tilt=(23.43870583-23.3999996185302734375)*rad;
    return {w.x,w.y*std::cos(tilt)-w.z*std::sin(tilt),w.y*std::sin(tilt)+w.z*std::cos(tilt)};
}
void compare(const ConstellationArt& art) {
    for (std::size_t i=0;i<art.points.size();++i) {
        const auto a=constellation_art_direction(art,i), b=reference(art,i);
        const double norm=std::hypot(b.x,b.y,b.z);
        check(std::hypot(a.x-b.x,a.y-b.y,a.z-b.z) <= 2e-12*norm,"CAB transform differs from independent rotation");
    }
}
}
int main(int argc,char** argv) {
    const auto path=std::filesystem::temp_directory_path()/ ("mitaka-cab-test-"+std::to_string(getpid())+".cab");
    try {
        const auto bytes=fixture(); save(path,bytes); auto art=load_constellation_art(path);
        check(art.source_bytes==bytes && art.points.size()==3 && art.indices==std::vector<std::int32_t>({0,1,-1,-2,1}),"raw order or terminators changed");
        compare(art);
        for (auto h : {std::array<float,5>{1,2,3,.1f,90}, {0,0,-1,.2f,-45}, {1e-4f,0,1,-.3f,360},
                {1e-4f,0,-1,1,720}, {std::numeric_limits<float>::max(),1,0,0,0}}) { art.header=h; compare(art); }
        for (std::size_t i=0;i<bytes.size();++i) { save(path,{bytes.begin(),bytes.begin()+i}); rejects([&]{load_constellation_art(path);}); }
        auto corrupt=bytes; corrupt.push_back(0); save(path,corrupt); rejects([&]{load_constellation_art(path);});
        corrupt=bytes; corrupt[56]=3; save(path,corrupt); rejects([&]{load_constellation_art(path);});
        corrupt=bytes; std::fill(corrupt.begin(),corrupt.begin()+12,0); save(path,corrupt); rejects([&]{load_constellation_art(path);});
        corrupt=bytes; corrupt[2]=0x80; corrupt[3]=0x7f; save(path,corrupt); rejects([&]{load_constellation_art(path);});
        save(path,bytes); rejects([&]{load_constellation_art(path,{bytes.size()-1,100});});
        rejects([&]{load_constellation_art(path,{bytes.size(),2});});
        std::vector<std::uint8_t> empty(bytes.begin(),bytes.begin()+20); integer(empty,0);integer(empty,0);save(path,empty);
        check(load_constellation_art(path).points.empty(),"empty art rejected");
        if(argc==2) {
            std::size_t count=0;
            const auto directory=std::filesystem::path(argv[1])/"constellations";
            check(std::filesystem::is_directory(argv[1]),"local data directory missing");
            if(std::filesystem::exists(directory)) for(const auto& entry:std::filesystem::directory_iterator(directory)) {
                if(entry.path().extension()!=".cab")continue;
                const auto local=load_constellation_art(entry.path()); compare(local); ++count;
                check(local.source_bytes.size()==28+8*local.points.size()+4*local.indices.size(),"local source structure changed");
            }
            std::cout<<"Local CAB files: "<<count<<'\n';
        }
        std::filesystem::remove(path); std::cout<<"CAB tests passed: "<<checks<<" checks\n";
    } catch(const std::exception& e) { std::filesystem::remove(path);std::cerr<<"FAIL: "<<e.what()<<'\n';return 1; }
}
