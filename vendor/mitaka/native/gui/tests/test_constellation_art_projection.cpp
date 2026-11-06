#include "constellation_art_projection.hpp"
#include <algorithm>
#include <cmath>
#include <iostream>
#include <limits>
using namespace mitaka;
using namespace mitaka::gui;
namespace {
unsigned checks=0;
void check(bool b,const char*m){++checks;if(!b)throw std::runtime_error(m);}
template<class F>void rejects(F f){try{f();}catch(const std::invalid_argument&){++checks;return;}throw std::runtime_error("expected rejection");}
double distance(ScreenPoint p,ScreenSegment s){
    double dx=s.end.x-s.start.x,dy=s.end.y-s.start.y,square=dx*dx+dy*dy;
    double t=square?std::clamp(((p.x-s.start.x)*dx+(p.y-s.start.y)*dy)/square,0.,1.):0;
    return std::hypot(p.x-s.start.x-t*dx,p.y-s.start.y-t*dy);
}
void morph_oracle(const ObservationFrame& frame, HorizontalCoordinates first, HorizontalCoordinates last, double blend) {
    const auto start=equatorial_direction(frame.to_equatorial(first));
    const auto end=equatorial_direction(frame.to_equatorial(last));
    const auto result=project_horizon_constellation_art_segment(start,end,frame,{0,0,179,blend},1200,700);
    check(result.evaluations<=8193,"morph oracle exceeds evaluation budget");
    unsigned visible=0;
    for (unsigned i=0;i<=2000;++i) {
        const double t=i/2000.;
        const auto p=equatorial_coordinates({(1-t)*start.x+t*end.x,(1-t)*start.y+t*end.y,(1-t)*start.z+t*end.z});
        const auto horizontal=frame.to_horizontal(p);
        const auto screen=project_horizon({360-horizontal.azimuth_deg,horizontal.altitude_deg},{360,0,179,blend},1200,700);
        if (!screen) continue;
        ++visible;
        double nearest=std::numeric_limits<double>::infinity();
        for (const auto& segment:result.segments) nearest=std::min(nearest,distance(*screen,segment));
        check(nearest<=1,"morph oracle visible point missing");
    }
    check(visible>100,"morph oracle fixture has insufficient visible points");
}
void curve(EquatorialCoordinates a,EquatorialCoordinates b,const ObservationFrame*frame,SkyViewport viewport={}){
    auto start=equatorial_direction(a),end=equatorial_direction(b);
    const double width=1200,height=700;
    const HorizonProjectionViewport horizon_viewport{viewport.center_ra_deg,viewport.center_dec_deg,180/viewport.zoom};
    auto result=frame?project_horizon_constellation_art_segment(start,end,*frame,{360-viewport.center_ra_deg,viewport.center_dec_deg,180/viewport.zoom},width,height)
        :project_sky_constellation_art_segment(start,end,viewport,width,height);
    check(result.evaluations<=8193&&result.omitted_intervals==0,"ordinary line omitted");
    for(auto s:result.segments){
        for(auto p:{s.start,s.end})check(std::isfinite(p.x)&&std::isfinite(p.y)&&p.x>=-1e-8&&p.x<=width+1e-8&&p.y>=-1e-8&&p.y<=height+1e-8,"invalid clip");
        check(viewport.zoom>1||std::abs(s.end.x-s.start.x)<width/2,"seam or pole bridged");
    }
    for(unsigned i=0;i<=4000;++i){
        double t=i/4000.;auto p=equatorial_coordinates({(1-t)*start.x+t*end.x,(1-t)*start.y+t*end.y,(1-t)*start.z+t*end.z});
        if(frame){auto h=frame->to_horizontal(p);p={360-h.azimuth_deg,h.altitude_deg};}
        if(std::abs(p.declination_deg)>89.99999)continue;
        auto screen=frame?project_horizon(p,horizon_viewport,width,height):project_sky(p,viewport,width,height);if(!screen)continue;
        double nearest=std::numeric_limits<double>::infinity();
        for(auto s:result.segments){nearest=std::min(nearest,distance(*screen,s));if(viewport.zoom==1)for(double dx:{-width,width})nearest=std::min(nearest,distance({screen->x+dx,screen->y},s));}
        check(nearest<=.3,"dense spatial-line oracle outside tolerance");
    }
}
}
int main(){try{
    for(auto site:{ObserverSite{0,0},{35,139},{90,0},{-90,40}})for(double jd:{2451545.,2460000.25}){
        ObservationFrame frame(site,jd);curve({350,-35},{10,45},&frame);curve({35,15},{175,-10},&frame);
        auto c=frame.to_horizontal({90,0});curve({89.9,-.1},{90.1,.1},&frame,{360-c.azimuth_deg,c.altitude_deg,180});
    }
    const ObservationFrame narrow_frame({35,139},2451545);
    morph_oracle(narrow_frame,{185,89.499},{175,89.499},1e-12);
    morph_oracle(narrow_frame,{270,45},{90,45},1e-6);
    for (double blend : {0.01,0.5}) morph_oracle(narrow_frame,{269,45},{91,45},blend);
    for (double blend : {0.01,0.5}) {
        morph_oracle(narrow_frame,{269,0},{91,0},blend);
        morph_oracle(narrow_frame,{91,0},{269,0},blend);
    }
    const auto narrow_center=narrow_frame.to_horizontal({90,0});
    curve({89.9,-.1},{90.1,.1},&narrow_frame,{360-narrow_center.azimuth_deg,narrow_center.altitude_deg,360});
    const HorizonViewport tiny_view{narrow_center.azimuth_deg,narrow_center.altitude_deg,1e-7};
    const auto outside=project_horizon_constellation_art_segment(equatorial_direction({0,0}),
        equatorial_direction({2,0}),narrow_frame,tiny_view,1200,700);
    check(outside.segments.empty() && outside.evaluations<=9,"distant CAB interval must be culled early");
    const HorizonViewport blended_view{narrow_center.azimuth_deg,narrow_center.altitude_deg,0.001,0.000001};
    const auto crossing=project_horizon_constellation_art_segment(equatorial_direction({88.9,0}),
        equatorial_direction({90.9,0}),narrow_frame,blended_view,1200,700);
    check(!crossing.segments.empty(),"narrow blended viewport must retain crossing CAB segment");
    const HorizonViewport extreme_view{narrow_center.azimuth_deg,narrow_center.altitude_deg,1e-9,1e-12};
    const auto extreme_crossing=project_horizon_constellation_art_segment(equatorial_direction({88.9,0}),
        equatorial_direction({90.9,0}),narrow_frame,extreme_view,1200,700);
    check(!extreme_crossing.segments.empty(),"extremely narrow viewport must retain crossing CAB segment");
    check(extreme_crossing.evaluations<=8193,"extreme CAB crossing must respect evaluation budget");
    const HorizonViewport edge_view{narrow_center.azimuth_deg,narrow_center.altitude_deg+0.00049,0.001,0.000001};
    const auto edge_crossing=project_horizon_constellation_art_segment(equatorial_direction({88.9,0}),
        equatorial_direction({90.9,0}),narrow_frame,edge_view,1200,700);
    check(std::any_of(edge_crossing.segments.begin(),edge_crossing.segments.end(),[](const auto& segment) {
        return segment.start.y>690 || segment.end.y>690;
    }),"narrow blended viewport must retain CAB segment near edge");
    check(edge_crossing.evaluations<=8193,"edge CAB crossing must respect evaluation budget");
    const HorizonViewport polar_edge_view{0,0,179,1e-12};
    const auto polar_edge_crossing=project_horizon_constellation_art_segment(
        equatorial_direction(narrow_frame.to_equatorial({181.1,89.499})),
        equatorial_direction(narrow_frame.to_equatorial({180.9,89.499})),
        narrow_frame,polar_edge_view,1200,700);
    check(!polar_edge_crossing.segments.empty(),"polar CAB crossing near viewport edge must remain visible");
    check(polar_edge_crossing.evaluations<=8193,"polar CAB crossing must respect evaluation budget");
    const HorizonViewport tiny_crossing_view{0,0,1e-9,1e-12};
    const auto tiny_crossing=project_horizon_constellation_art_segment(
        equatorial_direction(narrow_frame.to_equatorial({-2e-7,0})),
        equatorial_direction(narrow_frame.to_equatorial({2e-7,0})),
        narrow_frame,tiny_crossing_view,1200,700);
    check(!tiny_crossing.segments.empty(),"near-coincident CAB endpoints must retain visible crossing");
    check(tiny_crossing.evaluations<=8193,"near-coincident CAB crossing must respect evaluation budget");
    const ObservationFrame polar_frame({90,0},2451545);
    const auto polar_center=polar_frame.to_horizontal({90,0});
    const HorizonViewport polar_outside_view{polar_center.azimuth_deg,polar_center.altitude_deg+5.5e-10,1e-9,1e-12};
    const auto polar_outside=project_horizon_constellation_art_segment(equatorial_direction({88.9,0}),
        equatorial_direction({90.9,0}),polar_frame,polar_outside_view,1200,700);
    check(polar_outside.segments.empty(),"CAB segment just outside narrow viewport must be culled");
    check(polar_outside.evaluations<2049,"outside narrow CAB segment must not exhaust budget");
    HorizonSamplingLimits narrow_limits;narrow_limits.max_depth=1;
    const auto incomplete=project_horizon_constellation_art_segment(equatorial_direction({88.9,0}),
        equatorial_direction({90.9,0}),narrow_frame,blended_view,1200,700,narrow_limits);
    check(incomplete.omitted_intervals>0,"CAB intervals reaching morph depth limit must be reported");
    curve({359.9,10},{.1,10},nullptr);curve({20,80},{200,80},nullptr);curve({20,-80},{200,-80},nullptr);
    curve({0,10},{150,-20},nullptr);
    auto a=equatorial_direction({0,0}),b=equatorial_direction({150,60});
    HorizonSamplingLimits limits;limits.max_evaluations=5;
    auto shortBudget=project_sky_constellation_art_segment(a,b,{},1200,700,limits);
    check(shortBudget.evaluations<=5&&shortBudget.omitted_intervals>0&&shortBudget.segments.empty(),"budget invented chord");
    limits={};limits.max_depth=1;check(project_sky_constellation_art_segment(a,b,{},1200,700,limits).omitted_intervals>0,"depth not reported");
    rejects([&]{project_sky_constellation_art_segment({0,0,0},b,{},1200,700);});
    rejects([&]{project_sky_constellation_art_segment({1,0,0},{-1,0,0},{},1200,700);});
    const double nan=std::numeric_limits<double>::quiet_NaN();
    rejects([&]{project_sky_constellation_art_segment({nan,0,0},b,{},1200,700);});
    for(auto v:{SkyViewport{nan,0,1},{0,91,1},{0,0,0},{0,0,181}})rejects([&]{project_sky_constellation_art_segment(a,b,v,1200,700);});
    rejects([&]{project_sky_constellation_art_segment(a,b,{0,0,180},std::numeric_limits<double>::max(),700);});
    limits={};limits.max_evaluations=4;rejects([&]{project_sky_constellation_art_segment(a,b,{},1200,700,limits);});
    std::cout<<"CAB projection tests passed: "<<checks<<" checks\n";
}catch(const std::exception&e){std::cerr<<"FAIL: "<<e.what()<<'\n';return 1;}}
