#include "terrain_snapshot_test_fixture.hpp"
#include "../src/terrain_source_lease.hpp"
#include <algorithm>
#include <cmath>
#include <fcntl.h>
#include <iostream>
#include <sys/stat.h>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
unsigned checks=0;
void require(bool value,const char* message) { ++checks;if(!value) throw std::runtime_error(message); }
template<class E=std::invalid_argument,class F> void rejects(F fn,const char* message) {
    try { fn(); } catch(const E&) { ++checks;return; }throw std::runtime_error(message);
}
std::vector<int> descriptors() {
    std::vector<int> result;
    for(int fd=0;fd<1024;++fd) if(::fcntl(fd,F_GETFD)>=0) result.push_back(fd);
    return result;
}
void requires_close_on_exec(const std::filesystem::path& path,const char* message) {
    const auto before=descriptors();
    {
        auto source=TerrainFile::open(path);
        std::vector<int> added;
        for(const int fd:descriptors())
            if(std::find(before.begin(),before.end(),fd)==before.end()) added.push_back(fd);
        require(added.size()==1&&(::fcntl(added[0],F_GETFD)&FD_CLOEXEC),message);
    }
    require(descriptors()==before,"terrain descriptor is closed after destruction");
}
void keys() {
    terrain_test::Temporary temp;
    const auto a=temp.request();
    validate_terrain_surface_request(a);
    require(terrain_surface_request_matches(a,a),"request reflexive key");
    const std::vector<std::function<void(TerrainSurfaceRequest&)>> mutations{
        [](auto& r){r.data_directory/="other";},[](auto& r){r.body=TerrainBody::moon;},
        [](auto& r){++r.julian_date;},[](auto& r){r.center_au.x=1;},[](auto& r){r.center_au.y=1;},
        [](auto& r){r.center_au.z=1;},[](auto& r){r.orientation.x_axis.y=.1;},
        [](auto& r){r.orientation.y_axis.z=.1;},[](auto& r){r.orientation.north_axis.x=.1;},
        [](auto& r){r.display_radius_au*=2;},[](auto& r){r.elevation_factor=2;},
        [](auto& r){r.low_resolution=true;},[](auto& r){r.camera.target.x=1;},
        [](auto& r){r.camera.target.y=1;},[](auto& r){r.camera.target.z=1;},
        [](auto& r){r.camera.yaw_deg=1;},[](auto& r){r.camera.pitch_deg=1;},
        [](auto& r){r.camera.roll_deg=1;},[](auto& r){r.camera.frame_is_orbit=true;},
        [](auto& r){r.camera.precise_target=PreciseCameraTarget{};},
        [](auto& r){r.camera.distance_au*=2;},[](auto& r){r.camera.vertical_fov_deg=90;},
        [](auto& r){r.camera.frame=solar_camera_basis(r.camera);},
        [](auto& r){++r.width;},[](auto& r){++r.height;},
        [](auto& r){++r.load_limits.max_file_bytes;},[](auto& r){++r.load_limits.max_patches;},
        [](auto& r){++r.load_limits.max_index_bytes;},[](auto& r){++r.load_limits.max_grid_bytes;},
        [](auto& r){++r.surface_limits.frame_bytes;},[](auto& r){++r.surface_limits.mesh_bytes;},
        [](auto& r){++r.surface_limits.triangles;},[](auto& r){++r.surface_limits.pixel_tests;}
    };
    for(const auto& change:mutations) { auto b=a;change(b);require(!terrain_surface_request_matches(a,b),"every request dimension belongs to key"); }
    auto f=a;f.camera.frame=solar_camera_basis(f.camera);
    for(int axis=0;axis<3;++axis) { auto g=f;
        if(axis==0) g.camera.frame->outward.x+=.1;
        if(axis==1) g.camera.frame->right.x+=.1;
        if(axis==2) g.camera.frame->up.x+=.1;
        require(!terrain_surface_request_matches(f,g),"explicit camera basis belongs to key");
    }
    auto precise=a;precise.camera.set_target_pc({1e9,1e9,1e9});
    require(terrain_surface_request_matches(precise,precise),"precise target matches itself");
    auto moved=precise;moved.camera.translate_target_au({.001,0,0});
    require(moved.camera.target.x==precise.camera.target.x,"small movement preserves rounded AU target");
    require(!terrain_surface_request_matches(precise,moved)&&!terrain_surface_request_matches(moved,precise),
        "sub-ULP precise movement changes request key");
    for(int axis=0;axis<3;++axis) {
        for(bool anchor:{false,true}) {
            auto changed=precise;
            auto& v=anchor?changed.camera.precise_target->anchor_pc:changed.camera.precise_target->offset_au;
            if(axis==0) v.x+=1;
            if(axis==1) v.y+=1;
            if(axis==2) v.z+=1;
            require(!terrain_surface_request_matches(precise,changed),"every precise coordinate belongs to key");
        }
    }
    const std::vector<std::function<void(TerrainSurfaceRequest&)>> invalid{
        [](auto& r){r.data_directory="relative";},[](auto& r){r.data_directory=std::string("/a\0b",4);},
        [](auto& r){r.body=static_cast<TerrainBody>(99);},[](auto& r){r.julian_date=NAN;},
        [](auto& r){r.center_au.x=INFINITY;},[](auto& r){r.display_radius_au=0;},
        [](auto& r){r.elevation_factor=-1;},[](auto& r){r.width=0;},[](auto& r){r.height=1025;},
        [](auto& r){r.camera.distance_au=NAN;},[](auto& r){r.camera.vertical_fov_deg=0;},
        [](auto& r){r.orientation.x_axis.x=2;},
        [](auto& r){r.orientation.north_axis.z=-1;},[](auto& r){r.load_limits.max_patches=0;},
        [](auto& r){r.surface_limits.triangles=0;},[](auto& r){r.surface_limits.frame_bytes=1;}
    };
    for(const auto& change:invalid) { auto b=a;change(b);rejects([&]{validate_terrain_surface_request(b);},"invalid synchronous boundary"); }
}
void source_and_publication() {
    terrain_test::Temporary temp;
    auto request=temp.request();
    const auto absent=prepare_terrain_surface_snapshot(request,1);
    require(absent->generation==1&&absent->status==TerrainSnapshotStatus::unavailable&&
        absent->frame.samples.empty()&&!absent->diagnostic.empty(),"missing selected source is explicit unavailable");
    for(const auto body:{TerrainBody::earth,TerrainBody::moon,TerrainBody::mercury,TerrainBody::mars}) {
        request.body=body;const auto path=temp.write(body);
        const auto result=prepare_terrain_surface_snapshot(request,7);
        require(result->status==TerrainSnapshotStatus::ready&&result->generation==7,"all fixed body paths resolve");
        require(result->source_path==std::filesystem::canonical(path)&&result->source_identity&&result->source_header,
            "snapshot retains actual selected source identity and header");
        require(result->source_identity->file_bytes==terrain_test::bytes().size()&&result->source_header->radius_m==1000,
            "snapshot identity and original header values");
        require(terrain_surface_request_matches(result->request,request)&&result->frame.mode==TerrainSurfaceMode::terrain,
            "snapshot retains exact key and frame mode");
        require(std::abs(result->frame.samples[16*33+16].distance_au-.0021)<1e-15,"negative terrain remains below datum");
    }
    request.body=TerrainBody::earth;
    const auto first=prepare_terrain_surface_snapshot(request,8);
    const auto path=temp.root/terrain_source_relative_path(request.body);
    const auto replacement=temp.write(TerrainBody::moon,terrain_test::bytes(100));
    std::filesystem::rename(replacement,path);
    const auto second=prepare_terrain_surface_snapshot(request,9);
    require(first->source_identity->inode!=second->source_identity->inode,"new request observes replacement source identity");
    require(first->frame.samples[16*33+16].distance_au>second->frame.samples[16*33+16].distance_au,
        "completed snapshot immutable while later source changes");
    auto later=request;++later.julian_date;
    const auto date=prepare_terrain_surface_snapshot(later,10);
    require(!terrain_surface_request_matches(first->request,date->request),"same camera at another JD is not reused");
    temp.write(TerrainBody::earth,"broken");
    const auto bad=prepare_terrain_surface_snapshot(request,11);
    require(bad->status==TerrainSnapshotStatus::failed&&!bad->diagnostic.empty()&&bad->frame.samples.empty(),
        "corrupt source fails without partial frame");
    temp.write(TerrainBody::earth);
    auto bounded=request;bounded.surface_limits.pixel_tests=1;
    const auto limit=prepare_terrain_surface_snapshot(bounded,12);
    require(limit->status==TerrainSnapshotStatus::failed&&limit->source_identity&&limit->frame.samples.empty(),
        "budget failure retains source identity but no partial frame");
    auto far=request;far.camera.distance_au=.1;
    const auto sphere=prepare_terrain_surface_snapshot(far,13);
    require(sphere->status==TerrainSnapshotStatus::ready&&sphere->frame.mode==TerrainSurfaceMode::sphere&&sphere->frame.samples.empty(),
        "distant sphere is an explicit successful mode");
    rejects<TerrainSurfaceCancelled>([&]{prepare_terrain_surface_snapshot(request,14,[]{return true;});},"early cancellation");
    unsigned polls=0;
    rejects<TerrainSurfaceCancelled>([&]{prepare_terrain_surface_snapshot(request,15,[&]{return ++polls==5;});},"in-render cancellation has no published snapshot");
    require(polls==5,"cooperative cancellation is polled within render");
    terrain_test::Temporary outside;
    const auto outside_path=outside.write(TerrainBody::earth);
    std::filesystem::remove(path);std::filesystem::create_symlink(outside_path,path);
    const auto escaped=prepare_terrain_surface_snapshot(request,16);
    require(escaped->status==TerrainSnapshotStatus::failed&&!escaped->source_identity&&escaped->frame.samples.empty(),
        "source symlink outside selected data root is refused");
    std::filesystem::remove(path);
    const auto inside=temp.write(TerrainBody::moon);
    std::filesystem::create_symlink(inside,path);
    require(prepare_terrain_surface_snapshot(request,17)->status==TerrainSnapshotStatus::ready,"same selected root alias allowed");
}
void source_lease() {
    terrain_test::Temporary temp,outside;
    const auto path=temp.write(TerrainBody::earth);
    const auto escaped=outside.write(TerrainBody::earth,terrain_test::bytes(100));
    const auto root=std::filesystem::canonical(temp.root),resolved=std::filesystem::canonical(path);
    const TerrainSourceLease lease(root,resolved);
    const auto original=TerrainFile::open(lease.descriptor_path()).identity();
    std::filesystem::rename(path,path.string()+".original");
    std::filesystem::create_symlink(escaped,path);
    auto pinned=TerrainFile::open(lease.descriptor_path());
    require(pinned.identity().inode==original.inode&&pinned.read_grid(0,0).elevation_units(2,2)==-100,
        "validated descriptor stays on original source after pathname replacement");
    rejects<std::filesystem::filesystem_error>([&]{TerrainSourceLease invalid(root,resolved);},
        "leaf symlink installed after canonical check is refused");
    std::filesystem::remove(path);
    std::filesystem::rename(path.parent_path(),path.parent_path().string()+".original");
    std::filesystem::create_directory_symlink(escaped.parent_path(),path.parent_path());
    rejects<std::filesystem::filesystem_error>([&]{TerrainSourceLease invalid(root,resolved);},
        "ancestor symlink installed after canonical check is refused");
    terrain_test::Temporary rooted;
    const auto rootedpath=rooted.write(TerrainBody::moon);
    const auto rootedroot=std::filesystem::canonical(rooted.root);
    const auto rootedresolved=std::filesystem::canonical(rootedpath);
    const auto savedroot=rooted.root.string()+".original";
    std::filesystem::rename(rooted.root,savedroot);
    std::filesystem::create_directory_symlink(outside.root,rooted.root);
    rejects<std::filesystem::filesystem_error>([&]{TerrainSourceLease invalid(rootedroot,rootedresolved);},
        "selected root itself changed to symlink is refused");
    std::filesystem::remove(rooted.root);
    std::filesystem::rename(savedroot,rooted.root);
    rejects([&]{TerrainSourceLease invalid(root,std::filesystem::canonical(escaped));},
        "lease also validates source belongs to root");
    terrain_test::Temporary fifotemp;
    const auto fifo=fifotemp.root/"moon_topo.dat";
    require(::mkfifo(fifo.c_str(),0600)==0,"create nonblocking lease fixture");
    rejects([&]{TerrainSourceLease invalid(std::filesystem::canonical(fifotemp.root),fifo);},
        "lease rejects FIFO without blocking");
    terrain_test::Temporary clean;
    const auto cleanpath=clean.write(TerrainBody::moon);
    requires_close_on_exec(cleanpath,"ordinary terrain descriptor is close-on-exec");
    TerrainSourceLease cleanlease(std::filesystem::canonical(clean.root),std::filesystem::canonical(cleanpath));
    requires_close_on_exec(cleanlease.descriptor_path(),"duplicated terrain descriptor is close-on-exec");
}
}
int main() {
    try { keys();source_and_publication();source_lease();std::cout<<"terrain snapshot: "<<checks<<" checks passed\n";return 0; }
    catch(const std::exception& e) {std::cerr<<"terrain snapshot: "<<e.what()<<'\n';return 1;}
}
