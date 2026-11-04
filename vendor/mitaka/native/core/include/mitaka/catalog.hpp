#pragma once

#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <stdexcept>
#include <string>
#include <vector>

namespace mitaka {

// バイナリ形式の生値を保持し、表示向けの視差フィルタを適用しない。
struct HipparcosRecord {
    std::int32_t hip;
    float right_ascension_degrees;
    float declination_degrees;
    float parallax_mas;
    float parallax_error_mas;
    float proper_motion_ra_mas_per_year;
    float proper_motion_dec_mas_per_year;
    float apparent_v_magnitude;
    float color_b_minus_v;
    std::int8_t spectral_type;
    std::int8_t spectral_subtype;
    bool is_double;
    std::int16_t flamsteed_number;
    std::int8_t bayer_id;
    std::int8_t bayer_subscript;
    std::int8_t constellation_id;
    std::int8_t ads_component;
};

struct ConstellationBoundaryPoint {
    float right_ascension_hours;
    float declination_degrees;
};

struct ConstellationRecord {
    // 名前は元ファイルのバイト列。CP932をUTF-8と誤認して変換しない。
    std::string abbreviation;
    std::string boundary_abbreviation;
    std::string english_name;
    std::string english_genitive;
    std::string japanese_hiragana_bytes;
    std::string japanese_kanji_bytes;
    float right_ascension_degrees;
    float declination_degrees;
    std::vector<std::vector<std::int32_t>> hip_lines;
    std::vector<ConstellationBoundaryPoint> boundary;
};

// 大規模な独自データでは呼び出し側が上限を明示して変更できる。
struct CatalogLoadLimits {
    std::uint64_t max_file_bytes = 256ULL * 1024 * 1024;
    std::size_t max_records = 1'000'000;
};

class CatalogError : public std::runtime_error {
public:
    CatalogError(const std::filesystem::path& path, std::uint64_t offset,
                 const std::string& reason);
    const std::filesystem::path& path() const noexcept { return path_; }
    std::uint64_t offset() const noexcept { return offset_; }

private:
    std::filesystem::path path_;
    std::uint64_t offset_;
};

// ファイルを読み取り専用で開く。空ファイルは空カタログとして扱う。
// 不完全なレコード、不正値、制限超過はCatalogErrorで通知し部分結果を返さない。
std::vector<HipparcosRecord> load_hipparcos(
    const std::filesystem::path& path, CatalogLoadLimits limits = {});
std::vector<ConstellationRecord> load_constellations(
    const std::filesystem::path& path, CatalogLoadLimits limits = {});

} // namespace mitaka
