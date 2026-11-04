#pragma once
#include "display_options.hpp"
#include "mitaka/catalog.hpp"
#include <string>

namespace mitaka::gui {
// hip.dat の星座IDは公式固定順であり、任意 constellation_HIP.dat の行順ではない。
std::string star_catalog_label(const HipparcosRecord& star, const StarDisplayOptions& options);
bool star_has_marking(const HipparcosRecord& star, StarMarking marking, bool exoplanet_host);
}
