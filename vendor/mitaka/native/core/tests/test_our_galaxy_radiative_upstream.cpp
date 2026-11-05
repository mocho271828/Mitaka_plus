#include "mitaka/our_galaxy_radiative.hpp"
#include "mtk_approx_func.h"
#include <algorithm>
#include <cmath>
#include <iostream>
#include <stdexcept>

struct vector2f {
    float x, y;
    vector2f(float a, float b) : x(a), y(b) {}
    float norm() const { return std::sqrt(x*x+y*y); }
};
vector2f operator-(vector2f a, vector2f b) { return {a.x-b.x, a.y-b.y}; }
struct vector3f {
    float x, y, z;
    vector3f() : x(0), y(0), z(0) {}
    vector3f(float a, float b, float c) : x(a), y(b), z(c) {}
    float norm2() const { return x*x+y*y+z*z; }
};
vector3f operator-(vector3f a, vector3f b) { return {a.x-b.x,a.y-b.y,a.z-b.z}; }
vector3f operator+(vector3f a, vector3f b) { return {a.x+b.x,a.y+b.y,a.z+b.z}; }
vector3f operator/(vector3f a, float n) { return {a.x/n,a.y/n,a.z/n}; }
vector3f operator*(float n, vector3f a) { return {n*a.x,n*a.y,n*a.z}; }
float norm(vector3f a) { return std::sqrt(a.norm2()); }
vector3f normalize(vector3f a) { return a/norm(a); }
float dot_product(vector3f a, vector3f b) { return a.x*b.x+a.y*b.y+a.z*b.z; }
float GalaxyRayStepLen = 40.0f;
const float R_gal = 8000, img_min_val = .3f;
const int imgN = 512, ExpTblN = 500;
const float ExpTblTauMax = 5, ExpTblFac = 100;
const float kpG_kpR = 1.33f, kpB_kpR = 1.78f;
float ExpTbl[501][3];
unsigned char thin_mdl[512][512], dust_mdl[512][512];
// Values obtained by compiling upstream color.cpp, not calculated by native code.
const float _r1=.941287339f, _g1=.997622490f, _b1=.999999940f;
const float _r2=.999999940f, _g2=.960182071f, _b2=.721082211f;
#include "our_galaxy_upstream.inc"

int main() {
    mitaka::OurGalaxyModel input;
    for (auto& map : input.maps) { map.width=512; map.height=512; map.values.resize(512*512); }
    for (int y=0; y<512; ++y) for (int x=0; x<512; ++x) {
        const float a = float((x*17+y*3)%256)/255;
        const float b = float((x*5+y*11)%256)/255;
        input.maps[0].values[y*512+x] = a; input.maps[1].values[y*512+x] = b;
        thin_mdl[y][x] = static_cast<unsigned char>(255 * std::min(a*(1-img_min_val)+img_min_val, 1.f));
        dust_mdl[y][x] = static_cast<unsigned char>(255 * std::min(b, 1.f));
    }
    for (int i=0; i<=500; ++i) for (int c=0; c<3; ++c) {
        const float ratio[] = {1, kpG_kpR, kpB_kpR};
        ExpTbl[i][c] = std::exp(-ratio[c] * (float(i)/ExpTblFac));
    }
    make_elliptical_table();
    const mitaka::OurGalaxyRadiativeModel model(input);
    int checks=0;
    struct Ray { vector3f p, n; };
    for (const auto& ray : {Ray{{8000,0,50},{1,0,0}}, Ray{{14999,0,0},{1,0,0}},
                            Ray{{5000,2000,500},{1,0,0}}, Ray{{8000,0,50},{.2f,.4f,.8f}}}) {
        const auto p = ray.p;
        const float nlen = std::hypot(ray.n.x, ray.n.y, ray.n.z);
        const vector3f n{ray.n.x/nlen, ray.n.y/nlen, ray.n.z/nlen};
        const float qlen = std::hypot(n.x,n.y,n.z/.3f);
        const vector3f qn{n.x/qlen,n.y/qlen,n.z/.3f/qlen};
        const vector3f qp{p.x,p.y,p.z/.3f};
        const float dot = qn.x*qp.x+qn.y*qp.y+qn.z*qp.z;
        const float c = qp.x*qp.x+qp.y*qp.y+qp.z*qp.z-15000.f*15000.f;
        const float end = -dot+std::sqrt(dot*dot-c);
        const float length = end/qlen;
        float r=0,g=0,b=0,tau=0;
        calc_our_Galaxy_ray(p,n,length,4,40,r,g,b,tau);
        const auto value = model.trace({p.x,p.y,p.z},{n.x,n.y,n.z});
        const float got[] = {value.intensity.r,value.intensity.g,value.intensity.b,value.optical_depth};
        const float expected[] = {std::min(1.f,r*.0035f),std::min(1.f,g*.0035f),std::min(1.f,b*.0035f),tau};
        for (int k=0; k<4; ++k) {
            ++checks;
            if (!std::isfinite(got[k]) || std::abs(got[k]-expected[k]) > 3e-5f)
                throw std::runtime_error("our galaxy differs from extracted official ray kernel");
        }
    }
    for (const auto& ray : {Ray{{8000,0,50},{9000,0,50}}, Ray{{8000,0,50},{-8000,0,50}},
                            Ray{{20000,0,0},{8000,0,500}}, Ray{{0,0,5000},{0,0,-5000}},
                            Ray{{20000,0,5000},{22000,0,5000}}, Ray{{5000,2000,500},{4000,6000,-500}}}) {
        const float expected = calc_galactic_optical_depth_g(ray.p,ray.n,3);
        const auto value = model.point_extinction({ray.p.x,ray.p.y,ray.p.z},{ray.n.x,ray.n.y,ray.n.z});
        ++checks;
        if (!std::isfinite(value.optical_depth) || std::abs(value.optical_depth-expected) > 3e-5f)
            throw std::runtime_error("point optical depth differs from extracted official kernel");
    }
    std::cout << "our galaxy upstream ray kernel: " << checks << " comparisons passed\n";
}
