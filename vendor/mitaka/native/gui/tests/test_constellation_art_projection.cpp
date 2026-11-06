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
void curve(EquatorialCoordinates a,EquatorialCoordinates b,const ObservationFrame*frame,SkyViewport viewport={}){
    auto start=equatorial_direction(a),end=equatorial_direction(b);
    const double width=1200,height=700;
    auto result=frame?project_horizon_constellation_art_segment(start,end,*frame,{360-viewport.center_ra_deg,viewport.center_dec_deg,viewport.zoom},width,height)
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
        auto screen=frame?project_horizon(p,viewport,width,height):project_sky(p,viewport,width,height);if(!screen)continue;
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
