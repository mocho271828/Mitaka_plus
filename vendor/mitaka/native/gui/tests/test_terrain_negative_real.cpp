#include "terrain_landing.hpp"
#include "surface_navigation.hpp"
#include "terrain_snapshot.hpp"
#include "planet_surface.hpp"
#include <cmath>
#include <iostream>
#include <stdexcept>
#include <tuple>
using namespace mitaka::gui;
int main(int argc,char** argv) {
    try {
        if (argc != 2) throw std::invalid_argument("expected data root");
        for (auto [body,index,longitude] : {std::tuple{TerrainBody::earth,3,135.0},
                                          std::tuple{TerrainBody::mars,4,35.5}}) {
            TerrainLandingRequest landing;
            landing.data_directory=argv[1]; landing.body=body; landing.latitude_deg=31.5;
            landing.longitude_deg=longitude; landing.display_radius_km=surface_body_info(index).radius_km;
            const auto result=prepare_terrain_landing(landing);
            if (result.status!=TerrainSnapshotStatus::ready || !result.radius_km ||
                *result.radius_km>=landing.display_radius_km) throw std::runtime_error("missing negative elevation");
            SurfaceNavigation navigation;
            navigation.set_site({static_cast<std::size_t>(index),31.5,longitude,minimum_surface_height_km,
                                 0,-90,0,*result.radius_km-landing.display_radius_km});
            SolarBodies bodies{};
            bodies[index].position_au={1,0,0};
            bodies[index].orientation={{1,0,0},{0,1,0},{0,0,1}};
            TerrainSurfaceRequest request;
            request.data_directory=argv[1]; request.body=body; request.center_au={1,0,0};
            request.display_radius_au=landing.display_radius_km/astronomical_unit_km;
            request.orientation=bodies[index].orientation; request.camera=navigation.camera(bodies);
            request.width=65; request.height=65;
            const auto snapshot=prepare_terrain_surface_snapshot(request,1);
            if (snapshot->status!=TerrainSnapshotStatus::ready || snapshot->frame.mode!=TerrainSurfaceMode::terrain)
                throw std::runtime_error("negative terrain snapshot failed");
            const TextureImage texture{1,1,{200,200,200,255}};
            const SurfaceSphere sphere{texture,request.center_au,request.orientation,request.display_radius_au,
                                       false,0,nullptr,nullptr,&snapshot->frame};
            SurfaceDepthFrame depth;
            const auto image=render_surface_scene({sphere},request.camera,65,65,nullptr,&depth);
            const auto pixel=32*65+32;
            const auto picked=surface_opaque_distance(sphere,request.camera,32,32,65,65);
            const double distance=depth.distances_au[pixel];
            if (image.rgba[pixel*4+3]!=255 || !picked || *picked!=distance ||
                std::abs(distance*astronomical_unit_km*1000-2)>0.01)
                throw std::runtime_error("negative terrain drawing, selection, or clearance mismatch");
            std::cout << "body=" << index << " depth_m=" << distance*astronomical_unit_km*1000 << '\n';
        }
        return 0;
    } catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
}
