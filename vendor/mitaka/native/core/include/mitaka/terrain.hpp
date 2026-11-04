#pragma once

#include "mitaka/catalog.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <memory>
#include <optional>
#include <vector>

namespace mitaka {

// 全ファイルの常駐を避け、索引と格子1枚を別々に制限する。
// 上限は native の資源契約であり、原版の自動選択規則ではない。
struct TerrainLoadLimits {
    std::uint64_t max_file_bytes = 2ULL * 1024 * 1024 * 1024;
    std::size_t max_patches = 65'536;
    std::size_t max_index_bytes = 32 * 1024 * 1024;
    std::size_t max_grid_bytes = 256 * 1024;
};

struct TerrainHeader {
    float elevation_unit_m = 0;
    float radius_m = 0;
    std::int32_t patch_columns = 0;
    std::int32_t patch_rows = 0;
    std::array<std::uint8_t, 16> raw_bytes{};
};

struct TerrainPatch {
    float longitude_begin_deg = 0;
    float longitude_end_deg = 0;
    float latitude_begin_deg = 0;
    float latitude_end_deg = 0;
    std::int32_t maximum_level_index = 0;
    std::size_t first_grid = 0;
    std::uint64_t file_offset = 0;
    std::array<std::uint8_t, 20> raw_bytes{};
};

struct TerrainGridDescriptor {
    // 原readerは stored_level を使用しない。配列順とは別に生値を保持する。
    std::int32_t stored_level = 0;
    std::int32_t columns = 0;
    std::int32_t rows = 0;
    std::uint64_t header_offset = 0;
    std::uint64_t payload_offset = 0;
    std::size_t payload_bytes = 0;
    std::array<std::uint8_t, 12> raw_bytes{};
};

// 開いたdescriptorが参照する原本の識別子。全体SHAやコピー済みsnapshotではない。
struct TerrainSourceIdentity {
    std::uint64_t device = 0;
    std::uint64_t inode = 0;
    std::uint64_t file_bytes = 0;
    std::int64_t modification_seconds = 0;
    std::int64_t modification_nanoseconds = 0;
    std::int64_t change_seconds = 0;
    std::int64_t change_nanoseconds = 0;
};

class TerrainGridWindow {
public:
    const TerrainGridDescriptor& descriptor() const noexcept { return descriptor_; }
    const std::vector<std::uint8_t>& raw_bytes() const noexcept { return bytes_; }
    std::size_t patch_index() const noexcept { return patch_index_; }
    std::size_t level_index() const noexcept { return level_index_; }

    // 有効頂点は [0,N]。法線用halo [-1,N+1] も原値を返す。
    std::int16_t elevation_units(std::int32_t column, std::int32_t row) const;

private:
    friend class TerrainFile;
    TerrainGridDescriptor descriptor_;
    std::vector<std::uint8_t> bytes_;
    std::size_t patch_index_ = 0;
    std::size_t level_index_ = 0;
};

// 明示pathだけを読み取り専用で開く。天体名/データ源の探索や代替を行わない。
// 全headerを2回走査して妥当性を確認し、payloadは要求された格子1枚だけ保持する。
// ファイル不正・変更・上限超過は CatalogError。部分的な索引は公開しない。
// 同時利用不可。同一instanceへの呼出しはcallerが直列化する。
class TerrainFile {
public:
    static TerrainFile open(const std::filesystem::path& path, TerrainLoadLimits limits = {});
    ~TerrainFile();
    TerrainFile(TerrainFile&&) noexcept;
    TerrainFile& operator=(TerrainFile&&) noexcept;
    TerrainFile(const TerrainFile&) = delete;
    TerrainFile& operator=(const TerrainFile&) = delete;

    const std::filesystem::path& path() const;
    const TerrainSourceIdentity& identity() const;
    const TerrainHeader& header() const;
    const std::vector<TerrainPatch>& patches() const;
    const std::vector<TerrainGridDescriptor>& grids() const;
    std::size_t index_storage_bytes() const;
    std::size_t resident_grid_bytes() const;
    std::size_t maximum_grid_bytes() const;

    // level_index はファイル内のordinal。2倍解像度やstored_level値を仮定しない。
    // 返す借用参照・bytesの参照は次のread/release/move/destructionまでだけ有効。
    // 別gridの読込前に旧bufferを解放し、一時的にもpayload2枚を所有しない。
    // 原本変更/読込失敗時には旧windowも破棄する。
    const TerrainGridWindow& read_grid(std::size_t patch_index, std::size_t level_index);
    void release_grid() noexcept;
    void verify_source_unchanged() const;

private:
    struct Impl;
    explicit TerrainFile(std::unique_ptr<Impl> impl);
    std::unique_ptr<Impl> impl_;
};

// 原ファイルの東経・北緯による区画内の双線形補間。区画外/非有限は拒否する。
// 原版get_elevationのshort切り捨てを行わず、meter値をdoubleで返すnative契約。
// header/patch/gridは同一TerrainFileの対応する組をcallerが渡す。出典の同一性は検査しない。
double terrain_elevation_m(const TerrainHeader& header, const TerrainPatch& patch,
                           const TerrainGridWindow& grid, double longitude_deg,
                           double latitude_deg);

// 地形倍率は描画専用。元標高を変更せず、原版の半径式 R0+unit*height*factor を適用。
// x=赤道・東経0, y=赤道・東経90, z=北極の物体ローカル座標（meter）。
// J2000への自転/経度シフトはcallerが明示して適用する。
// header/patch/gridの対応はterrain_elevation_mと同じcaller契約。
std::array<double, 3> terrain_surface_point_m(const TerrainHeader& header,
    const TerrainPatch& patch, const TerrainGridWindow& grid,
    double longitude_deg, double latitude_deg, double elevation_factor = 1);

} // namespace mitaka
