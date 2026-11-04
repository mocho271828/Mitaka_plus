#import "ConstellationArtRenderer.h"
#import "StarRenderer.h"
#include <algorithm>
#include <functional>
#include <iostream>
using namespace mitaka;
using namespace mitaka::gui;
namespace {
unsigned checks=0;
constexpr int width=720,height=460;
const NSRect map=NSMakeRect(30,30,width-60,height-60);
using Pixels=std::vector<unsigned char>;
void check(bool b,const char*m){++checks;if(!b)throw std::runtime_error(m);}
Pixels render(const std::function<void(CGContextRef)>&draw){
    NSBitmapImageRep* bitmap=[[NSBitmapImageRep alloc]initWithBitmapDataPlanes:nullptr pixelsWide:width pixelsHigh:height
        bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bitmapFormat:0
        bytesPerRow:width*4 bitsPerPixel:32];
    check(bitmap!=nil,"bitmap allocation failed");
    [NSGraphicsContext saveGraphicsState];NSGraphicsContext.currentContext=[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    auto c=NSGraphicsContext.currentContext.CGContext;CGContextSetRGBFillColor(c,0,0,0,1);CGContextFillRect(c,CGRectMake(0,0,width,height));draw(c);
    [NSGraphicsContext restoreGraphicsState];return {bitmap.bitmapData,bitmap.bitmapData+bitmap.bytesPerRow*bitmap.pixelsHigh};
}
void tests(const std::filesystem::path&data){
    auto sky=std::make_shared<SkyModel>(SkyModel::load(data));
    auto art=ConstellationArtModel::load(data,sky->constellations());
    const auto blank=render([](auto){});
    ConstellationDisplayOptions options;RendererDisplayOptions quality;ObservationFrame frame({35,139},2451545);
    const auto draw=[&](bool horizon,ConstellationArtRenderStats&stats){return render([&](auto context){
        stats=horizon?draw_horizon_constellation_art(context,art,options,quality,frame,{},map)
            :draw_sky_constellation_art(context,art,options,quality,{},map);
    });};
    const std::size_t bound=std::count_if(art.records().begin(),art.records().end(),[](const auto&r){return r.abbreviation.has_value();});
    for(bool horizon:{false,true}){
        ConstellationArtRenderStats stats;options={};check(draw(horizon,stats)==blank&&stats.artworks==0,"disabled art drew pixels");
        options.illustrations=true;const auto image=draw(horizon,stats);
        check(stats.artworks==bound,"bound art row dropped");
        if(bound){check(image!=blank&&stats.segments>0,"enabled art blank");check(stats.omitted_intervals==0,"local art intervals omitted");}
        for(int y=0;y<height;++y)for(int x=0;x<width;++x)if(x<30||x>=width-30||y<30||y>=height-30)
            for(int c=0;c<4;++c)check(image[(y*width+x)*4+c]==blank[(y*width+x)*4+c],"art escaped clip");
        options.default_visible=false;check(draw(horizon,stats)==blank&&stats.artworks==0,"membership off still drawn");
        std::size_t ser=std::count_if(art.records().begin(),art.records().end(),[](const auto&r){return r.abbreviation=="Ser";});
        if(ser){options.exceptions={"Ser"};check(draw(horizon,stats)!=blank&&stats.artworks==ser,"Ser figures did not share membership");}
        options={};options.illustrations=true;quality={};auto smooth=draw(horizon,stats);
        quality.line_smoothing=false;if(bound)check(draw(horizon,stats)!=smooth,"line quality did not affect art");
        quality={};quality.text_smoothing=false;quality.point_smoothing=false;check(draw(horizon,stats)==smooth,"unrelated quality affected art");
        quality={};quality.antialias=false;auto off=draw(horizon,stats);quality={true,false,false,false};check(draw(horizon,stats)==off,"quality master mismatch");quality={};
    }
    ConstellationArtRenderStats stats;options={};options.illustrations=true;const auto before=draw(true,stats),beforeSky=draw(false,stats);
    frame=ObservationFrame({-35,-40},2460000.25);if(bound)check(draw(true,stats)!=before,"horizon art did not follow site/date");
    check(draw(false,stats)==beforeSky,"sky art depends on site/date");
    check(render([&](auto){draw_sky_constellation_art(nullptr,art,options,quality,{},map);})==blank,"null context modified ambient pixels");

    auto names=std::make_shared<ExtendedCatalogs>();
    // 同じ恒星・同じ座標で固有名だけを切り替え、点やHIP番号への作用を検出する。
    check(!sky->stars().empty(),"no stars for label test");const auto hip=sky->stars().front().hip;
    names->star_names={{hip,true,"SelectedName","SelectedName"}};
    StarRenderer* renderer=[[StarRenderer alloc]initWithModel:sky catalogs:names];
    const auto target=sky->stars().front();
    const StarProjector projector=[&](EquatorialCoordinates coordinates)->std::optional<StarProjection>{
        if(coordinates.right_ascension_deg!=target.right_ascension_degrees
            ||coordinates.declination_deg!=target.declination_degrees)return std::nullopt;
        return StarProjection{{150,150},1};
    };
    StarDisplayOptions stars;stars.selected_proper_names_only=true;
    auto starImage=[&](){return render([&](auto){[renderer drawInRect:map magnitudeLimit:99 options:stars quality:quality
        projector:projector];});};
    const auto points=starImage();stars.proper_names=true;auto selected=starImage();check(selected!=points,"initial featured name not selected");
    [renderer setSelectedNameHIPs:std::set<std::int32_t>{}];check(starImage()==points,"empty selection did not hide proper name");
    stars.selected_proper_names_only=false;check(starImage()==selected,"master all proper names changed with membership");
    stars.selected_proper_names_only=true;stars.hip_labels=true;const auto numbered=starImage();
    stars.proper_names=false;check(starImage()==numbered,"HIP designation was filtered by proper-name membership");
    [renderer setSelectedNameHIPs:std::set<std::int32_t>{hip}];check(starImage()==numbered,"selection changed points or HIP designation");
}
}
int main(int argc,char**argv){@autoreleasepool{if(argc!=2)return 2;try{tests(argv[1]);std::cout<<"Art/selected-name renderer tests passed: "<<checks<<" checks\n";}
catch(const std::exception&e){std::cerr<<"FAIL: "<<e.what()<<'\n';return 1;}}}
