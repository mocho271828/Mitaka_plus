#pragma once

#include "mitaka/extended_catalog.hpp"

namespace mitaka::gui {

struct ExtendedCatalogs {
    std::vector<NgcRecord> ngc;
    std::vector<SdssRecord> galaxies;
    std::vector<SdssRecord> quasars;
    std::vector<StarNameRecord> star_names;
    std::vector<std::int32_t> exoplanet_hosts;
    std::vector<std::string> warnings;
};

struct ExtendedCatalogLoadOptions {
    CatalogLoadLimits limits;
    // 空なら既定名。相対パスはdata_directory基準、絶対パスは指定先をそのまま使う。
    // 拡張子から形式を推測せず、各フィールドに対応する形式として検証する。
    std::filesystem::path ngc, galaxies, quasars, star_names, exoplanet_hosts;
};

// 各カタログを個別に検証し、失敗したカタログの理由をwarningsに残す。
// 恒星名は日本語版が存在すれば採用し、なければ英語版を使う。
ExtendedCatalogs load_extended_catalogs(const std::filesystem::path& data_directory,
                                       const ExtendedCatalogLoadOptions& options = {});

} // namespace mitaka::gui
