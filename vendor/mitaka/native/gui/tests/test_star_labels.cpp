#include "star_labels.hpp"
#include <iostream>
#include <stdexcept>
using namespace mitaka;
using namespace mitaka::gui;
void check(bool value, const char* message) { if (!value) throw std::runtime_error(message); }
int main() {
    try {
        HipparcosRecord star{};
        star.hip = 32349; star.flamsteed_number = 9; star.bayer_id = 0;
        star.bayer_subscript = -1; star.constellation_id = 11; star.ads_component = ' ';
        StarDisplayOptions options;
        check(star_catalog_label(star, options).empty(), "default must omit designation");
        options.bayer_labels = true;
        check(star_catalog_label(star, options) == "αCMa", "HIP constellation ID mapping differs");
        options.flamsteed_labels = true;
        check(star_catalog_label(star, options) == "9αCMa", "combined name differs");
        star.bayer_subscript = 12; star.ads_component = 'B';
        check(star_catalog_label(star, options) == "9α¹²CMaB", "subscript/component lost");
        options.bayer_labels = false;
        check(star_catalog_label(star, options) == "9CMaB", "Flamsteed must work without Bayer");
        options.hip_labels = true;
        check(star_catalog_label(star, options) == "9CMaB · HIP 32349", "HIP label lost");
        star.flamsteed_number = -1; star.bayer_id = -1; options.bayer_labels = true;
        check(star_catalog_label(star, options) == "HIP 32349", "missing designation must not fabricate a name");
        star.bayer_id = 23; star.bayer_subscript = -1; star.constellation_id = 87; star.ads_component = ' ';
        options.hip_labels = false;
        check(star_catalog_label(star, options) == "ωAql", "last valid Greek/constellation ID differs");
        star.bayer_id = 24;
        check(star_catalog_label(star, options).empty(), "invalid Greek ID was indexed");
        star.bayer_id = 0; star.constellation_id = -1;
        check(star_catalog_label(star, options) == "α", "negative constellation ID was indexed");
        star.constellation_id = 127;
        check(star_catalog_label(star, options) == "α", "large constellation ID was indexed");
        check(!star_has_marking(star, StarMarking::binary, true), "host must not be marked in binary mode");
        star.is_double = true;
        check(star_has_marking(star, StarMarking::binary, false), "binary flag ignored");
        check(!star_has_marking(star, StarMarking::exoplanets, false), "binary leaked into host marking");
        check(star_has_marking(star, StarMarking::exoplanets, true), "host flag ignored");
        check(!star_has_marking(star, StarMarking::none, true), "none mode produced marking");
        options.marking = static_cast<StarMarking>(99);
        bool rejected = false;
        try { star_catalog_label(star, options); } catch (const std::invalid_argument&) { rejected = true; }
        check(rejected, "invalid mode must fail");
        std::cout << "star labels and markings passed\n";
    } catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
}
