#pragma once

#include "extended_catalogs.hpp"
#include "galaxy_spatial_scene.hpp"

namespace mitaka::gui {

struct GalaxySpatialLoadResult {
    std::shared_ptr<const GalaxySpatialModel> model;
    // 既存読込の warning と、明示した Plus 出典の失敗を順序どおり保持する。
    std::vector<std::string> diagnostics;
    bool cancelled = false;
    // 明示的に要求した Plus 出典の少なくとも一つを読めなかった場合。
    bool plus_source_failed = false;
};

// SDSS は読込済みの配列を各1回コピーし、元ファイルを再読込しない。
// options は ExtendedCatalogs を読んだ際と同じ値を渡して出典を一致させる。
// Plus binary の選択は呼出し側が明示する。false では2出典へアクセスしない。
// true の場合も選択 root の globular_cluster.dat / NBG.dat だけを個別に読む。
// 取消時は部分 model を返さない。同期 I/O は既存 loader の容量制限内で完了し、
// その前後と SDSS の各評価行で取消を確認する。worker からの呼出しを想定する。
GalaxySpatialLoadResult load_galaxy_spatial_model(
    const std::filesystem::path& data_directory, const ExtendedCatalogs& catalogs,
    bool include_plus_binary, const ExtendedCatalogLoadOptions& options = {},
    std::function<bool()> should_cancel = {});

} // namespace mitaka::gui
