#pragma once
#include "mitaka/constellation_art.hpp"
#include <optional>

namespace mitaka::gui {
struct BoundConstellationArt {
    ConstellationArt art;
    std::optional<std::string> abbreviation;
    std::vector<Vec3> directions;
};
class ConstellationArtModel {
public:
    // data/constellations/*.cab を名前順で全件読み取る。原版と同じ ASCII
    // 大小文字非依存の basename 対応と SerH/SerT 対応を使う。曖昧一致は描かない。
    // 欠損ディレクトリは空、個別の破損・未対応は warnings へ残し、他を維持する。
    static ConstellationArtModel load(const std::filesystem::path& data_directory,
        const std::vector<ConstellationRecord>& constellations, CatalogLoadLimits limits = {});
    const std::vector<BoundConstellationArt>& records() const noexcept { return records_; }
    const std::vector<std::string>& warnings() const noexcept { return warnings_; }
private:
    std::vector<BoundConstellationArt> records_;
    std::vector<std::string> warnings_;
};
}
