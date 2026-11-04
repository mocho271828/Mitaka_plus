#pragma once

#include <filesystem>
#include <optional>
#include <string>
#include <vector>

namespace mitaka::gui {

enum class MediaKind { image, movie, audio, unknown };

struct MediaEntry {
    MediaKind kind = MediaKind::unknown;
    std::string raw_type, menu_title, display_title;
    std::filesystem::path registry;
    std::size_t line = 0;
    std::string descriptor, secondary_descriptor;
    std::vector<std::string> media_paths;
    std::optional<std::filesystem::path> resolved_path;
    std::vector<std::string> diagnostics;
};

struct MediaCatalog {
    std::vector<MediaEntry> entries;
    std::vector<std::string> diagnostics;
};

// dataの隣のmediaを読み取る。各mvpの最終行を単独PCの参照先に使う。
// 名前が完全一致しない項目も保持し、URL・外部参照・未知形式を自動実行しない。
MediaCatalog load_media_catalog(const std::filesystem::path& data_directory);

// 明示的なファイル選択時に使う分類。内容の可読性はデコーダが別途検証する。
MediaKind media_kind_for_extension(const std::filesystem::path& path);

} // namespace mitaka::gui
