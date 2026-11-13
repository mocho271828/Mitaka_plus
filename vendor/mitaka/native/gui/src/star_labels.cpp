#include "star_labels.hpp"
#include <array>

namespace mitaka::gui {
namespace {
// ID対応は公式1.3.1 common/astro/constellation.cpp。帰属は docs/gui/STAR_DISPLAY_PROVENANCE.md。
constexpr std::array<const char*, 88> abbreviations{{
    "And", "Mon", "Sgr", "Del", "Ind", "Psc", "Lep", "Boo", "Hya", "Eri",
    "Tau", "CMa", "Lup", "UMa", "Vir", "Ari", "Ori", "Pic", "Cas", "Dor",
    "Cnc", "Com", "Cha", "Crv", "CrB", "Tuc", "Aur", "Cam", "Pav", "Cet",
    "Cep", "Cen", "Mic", "CMi", "Equ", "Vul", "UMi", "LMi", "Crt", "Lyr",
    "Cir", "Ara", "Sco", "Tri", "Leo", "Nor", "Sct", "Cae", "Scl", "Gru",
    "Men", "Lib", "Lac", "Hor", "Vol", "Pup", "Mus", "Cyg", "Oct", "Col",
    "Aps", "Gem", "Peg", "Ser", "Oph", "Her", "Per", "Vel", "Tel", "Phe",
    "Ant", "Aqr", "Hyi", "Cru", "PsA", "CrA", "TrA", "Sge", "Cap", "Lyn",
    "Pyx", "Dra", "Car", "CVn", "Ret", "For", "Sex", "Aql"
}};
constexpr std::array<const char*, 24> greek{{
    "α", "β", "γ", "δ", "ε", "ζ", "η", "θ", "ι", "κ", "λ", "μ",
    "ν", "ξ", "ο", "π", "ρ", "σ", "τ", "υ", "φ", "χ", "ψ", "ω"
}};
std::string superscript(int value) {
    constexpr std::array<const char*, 10> digits{{"⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹"}};
    std::string result;
    for (const char digit : std::to_string(value)) result += digits[digit - '0'];
    return result;
}
}
std::string star_catalog_label(const HipparcosRecord& star, const StarDisplayOptions& options) {
    validate_star_display(options);
    std::string result;
    if (options.flamsteed_labels && star.flamsteed_number >= 0)
        result = std::to_string(star.flamsteed_number);
    if (options.bayer_labels && star.bayer_id >= 0 && star.bayer_id < static_cast<int>(greek.size())) {
        result += greek[star.bayer_id];
        if (star.bayer_subscript >= 0) result += superscript(star.bayer_subscript);
    }
    if (!result.empty()) {
        if (star.constellation_id >= 0 && star.constellation_id < static_cast<int>(abbreviations.size()))
            result += abbreviations[star.constellation_id];
        if (star.ads_component >= '!' && star.ads_component <= '~') result += static_cast<char>(star.ads_component);
    }
    if (options.hip_labels) {
        if (!result.empty()) result += " · ";
        result += "HIP " + std::to_string(star.hip);
    }
    return result;
}
bool star_has_marking(const HipparcosRecord& star, StarMarking marking, bool exoplanet_host) {
    switch (marking) {
        case StarMarking::none: return false;
        case StarMarking::binary: return star.is_double;
        case StarMarking::exoplanets: return exoplanet_host;
    }
    throw std::invalid_argument("invalid star marking mode");
}
}
