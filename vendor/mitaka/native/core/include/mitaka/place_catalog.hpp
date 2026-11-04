#pragma once

#include "mitaka/catalog.hpp"

#include <array>
#include <optional>

namespace mitaka {

struct PlaceRecord {
    // 原文のターゲットIDとCP932などの名称bytesを保持する。
    std::string target_name;
    std::string name_bytes;
    double longitude_degrees; // 東経が正。360度を超える入力も正規化せず保持する。
    double latitude_degrees;  // 北緯が正、[-90, 90]。
    std::string label_group;
    std::string landscape;
};

struct PlaceLabelGroup {
    std::string name;
    double display_distance; // 原典の値。距離単位は未確認のため変換しない。
    double size;
    std::array<double, 4> rgba;
};

struct PlaceLandscape {
    std::string target_name;
    std::string name;
    std::string image_path_bytes; // 参照文字列だけを保持し、ファイルを開かない。
    double vertical_scale;
    // 旧説明書は引数の順序と本文が不整合。第5・第6引数を順序どおり保持する。
    std::array<double, 2> offset_arguments;
};

struct PlaceCatalog {
    std::vector<PlaceRecord> places;
    std::vector<PlaceLabelGroup> label_groups;
    std::vector<PlaceLandscape> landscapes;
};

// 解釈できない独自記述があっても、同じ読み取りで得た原文を残す。
// catalog はファイル全体が有効な場合だけ存在し、部分適用はしない。
struct PlaceCatalogSource {
    std::filesystem::path path;
    std::vector<char> bytes;
    std::optional<PlaceCatalog> catalog;
    std::optional<CatalogError> error;
};

PlaceCatalogSource load_plus_place_source(const std::filesystem::path& path,
                                         CatalogLoadLimits limits = {});

// 旧Plusの3種のPlaces:add*呼出しを、文字列・数値リテラルだけのデータとして読む。
// Luaを実行しない。式、変数、未対応の呼出しはCatalogError。元の順序と重複を保持する。
// 同名の定義は利用側で後勝ちに適用する。空のgroup/landscapeはDefault参照を表す。
PlaceCatalog load_plus_place_catalog(const std::filesystem::path& path,
                                     CatalogLoadLimits limits = {});

} // namespace mitaka
