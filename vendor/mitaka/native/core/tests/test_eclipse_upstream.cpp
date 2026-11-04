#include "mitaka/eclipse.hpp"
#include <algorithm>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <stdexcept>

#define calc_eclipse_fraction upstream_eclipse_fraction
#include "eclipse_upstream.inc"
#undef calc_eclipse_fraction

int main() {
    try {
        int checks=0;
        double maximum=0;
        for (double radius : {.1,.5,.9,1.,1.1,2.,5.,10.}) {
            const double lower=std::abs(1-radius), upper=1+radius;
            for (int i=1;i<1000;++i) {
                const double distance=lower+(upper-lower)*i/1000;
                const double reference=upstream_eclipse_fraction(radius,distance);
                const double actual=mitaka::eclipse_obscured_fraction(radius,distance);
                const double error=std::abs(reference-actual);
                maximum=std::max(maximum,error);
                ++checks;
                if (!std::isfinite(reference)||!std::isfinite(actual)||error>5e-13) {
                    std::cerr << std::setprecision(17) << "R=" << radius << " d=" << distance
                              << " reference=" << reference << " native=" << actual << '\n';
                    throw std::runtime_error("ordinary disk overlap differs from official expression");
                }
            }
        }
        ++checks;
        if (!std::isnan(upstream_eclipse_fraction(1,0))||mitaka::eclipse_obscured_fraction(1,0)!=1)
            throw std::runtime_error("concentric native boundary is not distinguished from original NaN");
        std::cout << "eclipse official reference: " << checks << " checks PASS; maximum absolute difference "
                  << std::setprecision(17) << maximum << '\n';
    } catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
}
