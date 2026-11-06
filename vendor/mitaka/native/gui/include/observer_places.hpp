#pragma once

#include "mitaka/place_catalog.hpp"

namespace mitaka::gui {

struct ObserverPlaceOrigin {
    std::size_t source;
    std::size_t place;
};

struct ObserverPlaces {
    // 上書きされた行、ラベル群、風景、解釈不能な記述も原本単位で保持する。
    std::vector<PlaceCatalogSource> sources;
    // 存在確認で選んだ唯一の実効元。解釈失敗でも別ファイルへ戻さない。
    std::optional<std::size_t> selected_source;
    std::vector<PlaceRecord> places;
    std::vector<ObserverPlaceOrigin> origins;
    std::vector<std::string> warnings;
    std::vector<std::string> missing_files;
    std::size_t source_place_count = 0;
};

enum class ObserverPlacesLanguage { japanese, english };

// user が存在すれば単独採用し、不存在時だけ default を使う。
// 日本語は各 _jp を優先し、欠損時に無接尾辞へ戻る。4候補の原文は独立に保持する。
// 未対応の記述は実行・変換せず診断を保持し、既知の完全地点IDだけを後勝ちにする。
ObserverPlaces load_observer_places(const std::filesystem::path& data_directory,
                                   CatalogLoadLimits limits = {},
                                   ObserverPlacesLanguage language = ObserverPlacesLanguage::japanese);

// 地上移動に対応する正規の地球・火星・月の地点だけを天体インデックスに解決する。
// 対応外の天体や不完全な地点IDは解決しない。
std::optional<std::size_t> observer_place_body_index(const PlaceRecord& place);

// 地点IDはPlanet.Earth.*。似た別ターゲットを地球上の地点として扱わない。
bool observer_place_is_earth(const PlaceRecord& place);

// 原座標と地点UIの12有効桁表示が一致する座標だけを同一地点とする（JSON往復を含む）。
// 経度は360°周期（±180°同値）。任意の距離・epsilonで近傍地点を同一視しない。
bool observer_place_matches(const PlaceRecord& place, double latitude, double longitude);

} // namespace mitaka::gui
