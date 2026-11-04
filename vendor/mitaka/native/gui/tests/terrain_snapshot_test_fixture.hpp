#pragma once
#include "terrain_snapshot.hpp"
#include <chrono>
#include <cstring>
#include <fstream>
#include <type_traits>

namespace terrain_test {
template<class T> void append(std::string& bytes,T value) {
    using Bits=std::conditional_t<sizeof(T)==2,std::uint16_t,std::uint32_t>;
    Bits bits;std::memcpy(&bits,&value,sizeof(bits));
    for(std::size_t i=0;i<sizeof(bits);++i) bytes+=char((bits>>(8*i))&255);
}
inline std::string bytes(int height=-100) {
    std::string out;
    append(out,1.0f);append(out,1000.0f);append(out,std::int32_t(1));append(out,std::int32_t(1));
    for(float value:{-30.0f,30.0f,30.0f,-30.0f}) append(out,value);
    append(out,std::int32_t(0));append(out,std::int32_t(0));
    append(out,std::int32_t(4));append(out,std::int32_t(4));
    for(int i=0;i<49;++i) append(out,std::int16_t(height));
    return out;
}
struct Temporary {
    std::filesystem::path root=std::filesystem::temp_directory_path()/
        ("mitaka-terrain-snapshot-"+std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    Temporary() { if(!std::filesystem::create_directory(root)) throw std::runtime_error("temp directory"); }
    ~Temporary() { std::error_code ignored;std::filesystem::remove_all(root,ignored); }
    std::filesystem::path write(mitaka::gui::TerrainBody body,const std::string& data=bytes()) const {
        const auto path=root/mitaka::gui::terrain_source_relative_path(body);
        std::filesystem::create_directories(path.parent_path());
        std::ofstream out(path,std::ios::binary);out.write(data.data(),data.size());
        if(!out) throw std::runtime_error("fixture write");return path;
    }
    mitaka::gui::TerrainSurfaceRequest request() const {
        mitaka::gui::TerrainSurfaceRequest r;
        r.data_directory=root;r.display_radius_au=.001;r.width=33;r.height=33;
        r.camera.distance_au=.003;r.camera.yaw_deg=0;r.camera.pitch_deg=0;
        return r;
    }
};
}
