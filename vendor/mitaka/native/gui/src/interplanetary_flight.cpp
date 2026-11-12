#include "interplanetary_flight.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <stdexcept>

namespace mitaka::gui {
namespace {
constexpr double ascent_end = 4;
constexpr double cruise_end = 20;
struct Collision {};
Vec3 add(Vec3 a, Vec3 b) { return {a.x+b.x, a.y+b.y, a.z+b.z}; }
Vec3 sub(Vec3 a, Vec3 b) { return {a.x-b.x, a.y-b.y, a.z-b.z}; }
Vec3 mul(Vec3 a, double t) { return {a.x*t, a.y*t, a.z*t}; }
double dot(Vec3 a, Vec3 b) { return a.x*b.x+a.y*b.y+a.z*b.z; }
Vec3 cross(Vec3 a, Vec3 b) { return {a.y*b.z-a.z*b.y, a.z*b.x-a.x*b.z, a.x*b.y-a.y*b.x}; }
double length(Vec3 a) { return std::hypot(a.x, a.y, a.z); }
Vec3 unit(Vec3 a) { return mul(a, 1/length(a)); }
Vec3 mix(Vec3 a, Vec3 b, double t) { return add(mul(a, 1-t), mul(b, t)); }
double smooth(double t) { return t*t*(3-2*t); }
double cruise_fraction(double elapsed, bool from_surface) {
    if (from_surface) return smooth(std::clamp((elapsed-ascent_end)/16,0.0,1.0));
    return elapsed<=ascent_end ? 0.1*smooth(std::clamp(elapsed/ascent_end,0.0,1.0))
        : 0.1+0.9*smooth(std::clamp((elapsed-ascent_end)/16,0.0,1.0));
}
bool finite(Vec3 a) { return std::isfinite(a.x) && std::isfinite(a.y) && std::isfinite(a.z); }
Vec3 eye(const SolarCamera& camera) {
    return add(camera.target, mul(solar_camera_basis(camera).outward, camera.distance_au));
}
SolarCamera at(Vec3 position, SolarCameraBasis frame, double distance) {
    SolarCamera result;
    result.distance_au = distance;
    result.frame = frame;
    result.target = sub(position, mul(frame.outward, distance));
    solar_camera_basis(result);
    return result;
}
SolarCamera surface_camera(SurfaceSite site, const SolarBodies& bodies) {
    SurfaceNavigation navigation;
    navigation.set_site(site);
    return navigation.camera(bodies);
}
SurfaceSite upper_site(SurfaceSite site) {
    site.height_km = std::max(site.height_km, surface_body_info(site.body_index).radius_km*8);
    site.elevation_deg = -80;
    return site;
}
SurfaceSite interpolate_site(SurfaceSite a, SurfaceSite b, double fraction) {
    a.height_km = std::clamp(std::exp(std::log(a.height_km)*(1-fraction)
                                   +std::log(b.height_km)*fraction),
                                   minimum_surface_height_km, 1e9);
    a.elevation_deg += (b.elevation_deg-a.elevation_deg)*fraction;
    return fraction == 1 ? b : a;
}
Vec3 transform(SolarCameraBasis basis, Vec3 v) {
    return add(add(mul(basis.right,v.x),mul(basis.up,v.y)),mul(basis.outward,v.z));
}
Vec3 inverse_transform(SolarCameraBasis basis, Vec3 v) {
    return {dot(basis.right,v),dot(basis.up,v),dot(basis.outward,v)};
}
SolarCameraBasis relative_frame(SolarCameraBasis base, SolarCameraBasis frame) {
    return {inverse_transform(base,frame.outward),inverse_transform(base,frame.right),
            inverse_transform(base,frame.up)};
}
struct Quaternion { double w, x, y, z; };
Quaternion quaternion(SolarCameraBasis f) {
    const double m[3][3]{{f.right.x,f.up.x,f.outward.x},
                         {f.right.y,f.up.y,f.outward.y},
                         {f.right.z,f.up.z,f.outward.z}};
    Quaternion q{};
    const double trace=m[0][0]+m[1][1]+m[2][2];
    if (trace > 0) {
        const double s=std::sqrt(trace+1)*2;
        q={s/4,(m[2][1]-m[1][2])/s,(m[0][2]-m[2][0])/s,(m[1][0]-m[0][1])/s};
    } else {
        int i=0;
        if (m[1][1]>m[i][i]) i=1;
        if (m[2][2]>m[i][i]) i=2;
        const int j=(i+1)%3, k=(i+2)%3;
        const double s=std::sqrt(1+m[i][i]-m[j][j]-m[k][k])*2;
        double v[3]{};
        v[i]=s/4; v[j]=(m[j][i]+m[i][j])/s; v[k]=(m[k][i]+m[i][k])/s;
        q={(m[k][j]-m[j][k])/s,v[0],v[1],v[2]};
    }
    if (q.w<0) q={-q.w,-q.x,-q.y,-q.z};
    return q;
}
SolarCameraBasis fade_rotation(SolarCameraBasis relative, double fraction) {
    // 相対回転は巡航開始時に一度だけ決定する。再生中の180度通過で枝を変えない。
    auto q=quaternion(relative);
    const double angle=std::acos(std::clamp(q.w,-1.0,1.0));
    const double scale=angle<1e-12 ? 1-fraction : std::sin(angle*(1-fraction))/std::sin(angle);
    q={std::cos(angle*(1-fraction)),q.x*scale,q.y*scale,q.z*scale};
    const double x=q.x,y=q.y,z=q.z,w=q.w;
    return {{2*(x*z+w*y),2*(y*z-w*x),1-2*(x*x+y*y)},
            {1-2*(y*y+z*z),2*(x*y+w*z),2*(x*z-w*y)},
            {2*(x*y-w*z),1-2*(x*x+z*z),2*(y*z+w*x)}};
}
SolarCameraBasis compose(SolarCameraBasis base, SolarCameraBasis local) {
    return {transform(base,local.outward),transform(base,local.right),transform(base,local.up)};
}
struct Sphere { Vec3 center; double radius; };
std::array<Sphere,11> spheres(const SolarBodies& bodies) {
    std::array<Sphere,11> result{};
    for (std::size_t i=0;i<bodies.size();++i) {
        const auto& body=bodies[i];
        if (!finite(body.position_au)) throw std::invalid_argument("non-finite flight body position");
        if (i!=0) {
            SurfaceSite site;
            site.body_index=i;
            surface_camera(site,bodies);
        }
        // 太陽は公式1.3.1 mtk_sun.h の696000km、他は既存地表モデルの半径。
        result[i]={j2000_equatorial_to_ecliptic(body.position_au),
                   (i==0 ? 696000 : surface_body_info(i).radius_km)/astronomical_unit_km};
    }
    return result;
}
bool intersects(Vec3 a, Vec3 b, Sphere sphere) {
    const Vec3 delta=sub(b,a);
    const double squared=dot(delta,delta);
    const double t=squared>0 ? std::clamp(dot(sub(sphere.center,a),delta)/squared,0.0,1.0) : 0;
    return length(sub(mix(a,b,t),sphere.center)) < sphere.radius;
}
bool safe_segment(Vec3 a, Vec3 b, const std::array<Sphere,11>& obstacles) {
    return std::none_of(obstacles.begin(),obstacles.end(),
                        [&](Sphere sphere){ return intersects(a,b,sphere); });
}
std::vector<Vec3> plan_route(Vec3 a, Vec3 b, Vec3 normal,
                             const std::array<Sphere,11>& obstacles) {
    if (!safe_segment(a,a,obstacles) || !safe_segment(b,b,obstacles)) throw Collision{};
    std::vector<Vec3> points{a,b};
    for (std::size_t segment=0;segment+1<points.size();) {
        const Vec3 start=points[segment], end=points[segment+1];
        const auto blocked=std::find_if(obstacles.begin(),obstacles.end(),
                                       [&](Sphere s){return intersects(start,end,s);});
        if (blocked==obstacles.end()) { ++segment; continue; }
        if (points.size()>=96) throw Collision{};
        const Vec3 direction=unit(sub(end,start));
        Vec3 side=cross(normal,direction);
        if (length(side)<1e-8) side=cross(std::abs(direction.x)<0.8 ? Vec3{1,0,0} : Vec3{0,1,0},direction);
        const double clearance = blocked->radius * 2;
        Vec3 detour = add(blocked->center, mul(unit(side), clearance));
        // 地表近くで再開すると、横の迂回点に向かう最初の弦まで出発天体に潜ることがある。
        // この場合だけ元のカメラから半径方向に抜け、次の辺も他の天体を含めて検査する。
        const Vec3 outward = sub(start, blocked->center);
        if (segment == 0 && length(outward) < clearance && intersects(start, detour, *blocked))
            detour = add(blocked->center, mul(unit(outward), clearance));
        points.insert(points.begin()+static_cast<std::ptrdiff_t>(segment+1),detour);
    }
    return points;
}
} // namespace

bool InterplanetaryFlight::flying() const noexcept {
    return phase_==FlightPhase::ascent || phase_==FlightPhase::cruise || phase_==FlightPhase::descent;
}
void InterplanetaryFlight::interrupt() noexcept {
    if (!flying()) return;
    phase_=FlightPhase::interrupted;
    stop_reason_=FlightStopReason::user;
}
void InterplanetaryFlight::begin(SurfaceSite departure, SurfaceSite destination,
                                 const SolarBodies& bodies, double time) {
    SurfaceNavigation navigation;
    navigation.set_site(departure);
    start(navigation.site(),navigation.camera(bodies),destination,bodies,time);
}
void InterplanetaryFlight::begin_from_camera(const SolarCamera& camera, SurfaceSite destination,
                                             const SolarBodies& bodies, double time) {
    start(std::nullopt,camera,destination,bodies,time);
}
void InterplanetaryFlight::start(std::optional<SurfaceSite> departure, const SolarCamera& camera,
                                 SurfaceSite destination, const SolarBodies& bodies, double time) {
    if (!std::isfinite(time)) throw std::invalid_argument("flight time must be finite");
    SurfaceNavigation navigation;
    navigation.set_site(destination);
    destination=navigation.site();
    destination.height_km=minimum_surface_height_km;
    destination.elevation_deg=0;
    const auto obstacles=spheres(bodies);
    const auto position=eye(camera);
    if (!safe_segment(position,position,obstacles))
        throw std::invalid_argument("flight camera is inside a body");
    InterplanetaryFlight next;
    next.departure_=departure;
    next.destination_=destination;
    next.start_camera_=camera;
    next.camera_=camera;
    next.previous_time_=time;
    next.phase_=FlightPhase::ascent;
    const Vec3 delta=sub(eye(surface_camera(upper_site(destination),bodies)),position);
    if (length(delta)>1e-12) {
        const auto direction=unit(delta);
        next.route_normal_=unit(cross(direction,std::abs(direction.z)<0.8 ? Vec3{0,0,1} : Vec3{0,1,0}));
    }
    try { if (!departure) next.prepare_cruise(bodies); }
    catch (const Collision&) { throw std::invalid_argument("cannot plan a safe flight from this camera"); }
    *this=std::move(next);
}
void InterplanetaryFlight::prepare_cruise(const SolarBodies& bodies) {
    const auto from=departure_ ? surface_camera(upper_site(*departure_),bodies) : start_camera_;
    const auto to=surface_camera(upper_site(destination_),bodies);
    const auto a=eye(from), b=eye(to);
    const auto points=plan_route(a,b,route_normal_,spheres(bodies));
    double total=0;
    for (std::size_t i=1;i<points.size();++i) total+=length(sub(points[i],points[i-1]));
    double accumulated=0;
    route_.clear();
    for (std::size_t i=0;i<points.size();++i) {
        if (i>0) accumulated+=length(sub(points[i],points[i-1]));
        const double fraction=total>1e-15 ? accumulated/total : static_cast<double>(i)/(points.size()-1);
        route_.push_back({fraction,sub(points[i],mix(a,b,fraction))});
    }
    cruise_rotation_=relative_frame(solar_camera_basis(to),solar_camera_basis(from));
}
SolarCamera InterplanetaryFlight::evaluate(double elapsed, const SolarBodies& bodies) const {
    if (elapsed>=duration_seconds) return surface_camera(destination_,bodies);
    if (departure_ && elapsed<=ascent_end)
        return surface_camera(interpolate_site(*departure_,upper_site(*departure_),smooth(elapsed/ascent_end)),bodies);
    if (elapsed>=cruise_end)
        return surface_camera(interpolate_site(upper_site(destination_),destination_,
                                               smooth((elapsed-cruise_end)/4)),bodies);
    return cruise_camera(cruise_fraction(elapsed,departure_.has_value()),bodies);
}
SolarCamera InterplanetaryFlight::cruise_camera(double fraction, const SolarBodies& bodies) const {
    const auto from=departure_ ? surface_camera(upper_site(*departure_),bodies) : start_camera_;
    const auto to=surface_camera(upper_site(destination_),bodies);
    const auto next=std::upper_bound(route_.begin(),route_.end(),fraction,
                                    [](double t,const RoutePoint& point){return t<point.fraction;});
    const auto& end=next==route_.end() ? route_.back() : *next;
    const auto& start=next==route_.begin() ? route_.front() : *(next-1);
    const double part=end.fraction>start.fraction ? (fraction-start.fraction)/(end.fraction-start.fraction) : 0;
    const Vec3 position=add(mix(eye(from),eye(to),fraction),mix(start.offset,end.offset,part));
    const auto frame=compose(solar_camera_basis(to),fade_rotation(*cruise_rotation_,fraction));
    return at(position,frame,from.distance_au*(1-fraction)+to.distance_au*fraction);
}
bool InterplanetaryFlight::advance(double time, const SolarBodies& bodies) {
    if (!flying()) return false;
    if (!std::isfinite(time) || time<previous_time_ || time-previous_time_>1) {
        phase_=FlightPhase::interrupted;
        stop_reason_=FlightStopReason::clock_discontinuity;
        return false;
    }
    const auto obstacles=spheres(bodies);
    InterplanetaryFlight next=*this;
    next.elapsed_=std::min(duration_seconds,elapsed_+time-previous_time_);
    next.previous_time_=time;
    try {
        if (!next.cruise_rotation_ && next.elapsed_>=ascent_end) next.prepare_cruise(bodies);
        if (next.cruise_rotation_ && elapsed_<=cruise_end) {
            const double first=cruise_fraction(elapsed_,departure_.has_value());
            const double last=cruise_fraction(next.elapsed_,departure_.has_value());
            auto previous=eye(next.cruise_camera(first,bodies));
            // 標本間の折点を飛ばさず、今回進む折線の各辺も厳密に検査する。
            for (const auto& point : next.route_) {
                if (point.fraction<=first || point.fraction>=last) continue;
                const auto position=eye(next.cruise_camera(point.fraction,bodies));
                if (!safe_segment(previous,position,obstacles)) throw Collision{};
                previous=position;
            }
            if (!safe_segment(previous,eye(next.cruise_camera(last,bodies)),obstacles)) throw Collision{};
        }
        // 同じ天体位置・姿勢の中で経路を検査する。天体自身の公転移動を衝突と誤認しない。
        // 最大10ms刻みで離着陸曲線も調べ、最後の安全な表示姿勢を一括して保持する。
        const int steps=std::max(1,static_cast<int>(std::ceil((next.elapsed_-elapsed_)/0.01)));
        auto previous=eye(next.evaluate(elapsed_,bodies));
        if (!safe_segment(previous,previous,obstacles)) throw Collision{};
        for (int i=1;i<=steps;++i) {
            const double t=elapsed_+(next.elapsed_-elapsed_)*i/steps;
            const auto position=eye(next.evaluate(t,bodies));
            if (!safe_segment(previous,position,obstacles)) throw Collision{};
            previous=position;
        }
        next.camera_=next.evaluate(next.elapsed_,bodies);
    } catch (const Collision&) {
        phase_=FlightPhase::interrupted;
        stop_reason_=FlightStopReason::collision;
        return false;
    }
    next.phase_=next.elapsed_>=duration_seconds ? FlightPhase::completed
        : next.elapsed_>=cruise_end ? FlightPhase::descent
        : next.elapsed_>=ascent_end ? FlightPhase::cruise : FlightPhase::ascent;
    *this=std::move(next);
    return true;
}

} // namespace mitaka::gui
