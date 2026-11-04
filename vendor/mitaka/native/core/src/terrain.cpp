/*
Copyright (c) 2007-2014 Tsunehiko Kato

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#include "mitaka/terrain.hpp"

#include <algorithm>
#include <cerrno>
#include <cmath>
#include <cstring>
#include <fcntl.h>
#include <limits>
#include <stdexcept>
#include <sys/stat.h>
#include <unistd.h>
#include <utility>

namespace mitaka {
namespace {
static_assert(sizeof(float) == 4 && std::numeric_limits<float>::is_iec559,
              "Terrain headers require IEEE binary32");
constexpr std::size_t maximum_levels = 10;
constexpr std::int32_t maximum_grid_dimension = 256;

std::uint32_t u32(const std::uint8_t* bytes) {
    return std::uint32_t(bytes[0]) | (std::uint32_t(bytes[1]) << 8) |
           (std::uint32_t(bytes[2]) << 16) | (std::uint32_t(bytes[3]) << 24);
}
std::int32_t i32(const std::uint8_t* bytes) {
    const std::uint32_t value = u32(bytes);
    return static_cast<std::int32_t>(value <= 0x7fffffffU ? std::int64_t(value) :
                                    std::int64_t(value) - 0x100000000LL);
}
float f32(const std::uint8_t* bytes) {
    const auto bits = u32(bytes);
    float value;
    std::memcpy(&value, &bits, sizeof(value));
    return value;
}
TerrainSourceIdentity source_identity(const struct stat& info) {
    TerrainSourceIdentity identity;
    identity.device = static_cast<std::uint64_t>(info.st_dev);
    identity.inode = static_cast<std::uint64_t>(info.st_ino);
    identity.file_bytes = static_cast<std::uint64_t>(info.st_size);
#if defined(__APPLE__)
    identity.modification_seconds = info.st_mtimespec.tv_sec;
    identity.modification_nanoseconds = info.st_mtimespec.tv_nsec;
    identity.change_seconds = info.st_ctimespec.tv_sec;
    identity.change_nanoseconds = info.st_ctimespec.tv_nsec;
#else
    identity.modification_seconds = info.st_mtim.tv_sec;
    identity.modification_nanoseconds = info.st_mtim.tv_nsec;
    identity.change_seconds = info.st_ctim.tv_sec;
    identity.change_nanoseconds = info.st_ctim.tv_nsec;
#endif
    return identity;
}
bool unchanged(const TerrainSourceIdentity& a, const TerrainSourceIdentity& b) {
    return a.device == b.device && a.inode == b.inode && a.file_bytes == b.file_bytes &&
           a.modification_seconds == b.modification_seconds &&
           a.modification_nanoseconds == b.modification_nanoseconds &&
           a.change_seconds == b.change_seconds && a.change_nanoseconds == b.change_nanoseconds;
}
} // namespace

struct TerrainFile::Impl {
    std::filesystem::path path;
    TerrainLoadLimits limits;
    int descriptor = -1;
    TerrainSourceIdentity identity;
    TerrainHeader header;
    std::vector<TerrainPatch> patches;
    std::vector<TerrainGridDescriptor> grids;
    std::optional<TerrainGridWindow> window;
    std::size_t maximum_payload = 0;

    ~Impl() { if (descriptor >= 0) ::close(descriptor); }
    [[noreturn]] void fail(std::uint64_t offset, const char* reason) const {
        throw CatalogError(path, offset, reason);
    }
    TerrainSourceIdentity current_identity() const {
        struct stat info {};
        if (::fstat(descriptor, &info) != 0 || !S_ISREG(info.st_mode) || info.st_size < 0)
            fail(0, "terrain source is not a readable regular file");
        return source_identity(info);
    }
    void verify() const {
        if (!unchanged(identity, current_identity())) fail(0, "terrain source changed after indexing");
    }
    void read(std::uint64_t offset, std::uint8_t* output, std::size_t length) const {
        if (offset > identity.file_bytes || length > identity.file_bytes - offset)
            fail(offset, "truncated terrain record");
        std::size_t done = 0;
        while (done < length) {
            const auto count = ::pread(descriptor, output + done, length - done,
                                       static_cast<off_t>(offset + done));
            if (count < 0 && errno == EINTR) continue;
            if (count <= 0) fail(offset + done, "terrain read failed");
            done += static_cast<std::size_t>(count);
        }
    }
    template<std::size_t N> std::array<std::uint8_t, N> bytes(std::uint64_t offset) const {
        std::array<std::uint8_t, N> result{};
        read(offset, result.data(), result.size());
        return result;
    }
    void read_header() {
        header.raw_bytes = bytes<16>(0);
        const auto* raw = header.raw_bytes.data();
        header.elevation_unit_m = f32(raw);
        header.radius_m = f32(raw + 4);
        header.patch_columns = i32(raw + 8);
        header.patch_rows = i32(raw + 12);
        if (!std::isfinite(header.elevation_unit_m) || header.elevation_unit_m <= 0 ||
            !std::isfinite(header.radius_m) || header.radius_m <= 0 ||
            header.patch_columns <= 0 || header.patch_rows <= 0)
            fail(0, "invalid terrain sphere header");
    }
    std::size_t storage_bytes(std::size_t patch_count, std::size_t grid_count) const {
        if (patch_count > limits.max_index_bytes / sizeof(TerrainPatch))
            fail(0, "terrain patch index exceeds memory limit");
        const auto patch_bytes = patch_count * sizeof(TerrainPatch);
        if (grid_count > (limits.max_index_bytes - patch_bytes) / sizeof(TerrainGridDescriptor))
            fail(0, "terrain grid index exceeds memory limit");
        return patch_bytes + grid_count * sizeof(TerrainGridDescriptor);
    }
    // 最初は個数だけ調べる。巨大payloadを読まず、正確な個数の索引を一度だけ確保する。
    std::size_t scan(std::size_t patch_count, bool populate) {
        if (bytes<16>(0) != header.raw_bytes) fail(0, "terrain header changed during indexing");
        std::uint64_t offset = 16;
        std::size_t grid_count = 0;
        for (std::size_t patch_index = 0; patch_index < patch_count; ++patch_index) {
            TerrainPatch patch;
            patch.file_offset = offset;
            patch.raw_bytes = bytes<20>(offset);
            const auto* raw = patch.raw_bytes.data();
            patch.longitude_begin_deg = f32(raw);
            patch.longitude_end_deg = f32(raw + 4);
            patch.latitude_begin_deg = f32(raw + 8);
            patch.latitude_end_deg = f32(raw + 12);
            patch.maximum_level_index = i32(raw + 16);
            patch.first_grid = grid_count;
            if (!std::isfinite(patch.longitude_begin_deg) || !std::isfinite(patch.longitude_end_deg) ||
                !std::isfinite(patch.latitude_begin_deg) || !std::isfinite(patch.latitude_end_deg) ||
                patch.longitude_begin_deg >= patch.longitude_end_deg ||
                double(patch.longitude_end_deg) - patch.longitude_begin_deg > 360 ||
                patch.latitude_begin_deg > 90 || patch.latitude_end_deg < -90 ||
                patch.latitude_begin_deg <= patch.latitude_end_deg ||
                patch.maximum_level_index < 0 ||
                patch.maximum_level_index >= static_cast<std::int32_t>(maximum_levels))
                fail(offset, "invalid terrain patch header");
            offset += 20;
            for (std::int32_t level = 0; level <= patch.maximum_level_index; ++level) {
                TerrainGridDescriptor grid;
                grid.header_offset = offset;
                grid.raw_bytes = bytes<12>(offset);
                grid.stored_level = i32(grid.raw_bytes.data());
                grid.columns = i32(grid.raw_bytes.data() + 4);
                grid.rows = i32(grid.raw_bytes.data() + 8);
                if (grid.columns < 1 || grid.rows < 1 || grid.columns > maximum_grid_dimension ||
                    grid.rows > maximum_grid_dimension) fail(offset, "invalid terrain grid dimensions");
                grid.payload_bytes = std::size_t(grid.columns + 3) * std::size_t(grid.rows + 3) * 2;
                grid.payload_offset = offset + 12;
                if (grid.payload_bytes > limits.max_grid_bytes)
                    fail(offset, "terrain grid exceeds memory limit");
                if (grid.payload_offset > identity.file_bytes ||
                    grid.payload_bytes > identity.file_bytes - grid.payload_offset)
                    fail(grid.payload_offset, "truncated terrain grid payload");
                storage_bytes(patch_count, grid_count + 1);
                if (populate) {
                    if (grid_count >= grids.size()) fail(offset, "terrain grid count changed during indexing");
                    grids[grid_count] = grid;
                }
                ++grid_count;
                maximum_payload = std::max(maximum_payload, grid.payload_bytes);
                offset = grid.payload_offset + grid.payload_bytes;
            }
            if (populate) patches[patch_index] = patch;
        }
        if (offset != identity.file_bytes) fail(offset, "trailing bytes after terrain patches");
        return grid_count;
    }
};

TerrainFile::TerrainFile(std::unique_ptr<Impl> impl) : impl_(std::move(impl)) {}
TerrainFile::~TerrainFile() = default;
TerrainFile::TerrainFile(TerrainFile&&) noexcept = default;
TerrainFile& TerrainFile::operator=(TerrainFile&&) noexcept = default;

TerrainFile TerrainFile::open(const std::filesystem::path& path, TerrainLoadLimits limits) {
    auto impl = std::make_unique<Impl>();
    impl->path = path;
    impl->limits = limits;
    if (path.native().find('\0') != std::filesystem::path::string_type::npos)
        impl->fail(0, "terrain source path contains NUL");
    // NONBLOCKはFIFO等の明示pathで停止するのを防ぎ、直後にregular fileだけを許可する。
    impl->descriptor = ::open(path.c_str(), O_RDONLY | O_CLOEXEC | O_NONBLOCK);
    if (impl->descriptor < 0) impl->fail(0, "cannot open terrain source");
    impl->identity = impl->current_identity();
    if (impl->identity.file_bytes > limits.max_file_bytes ||
        impl->identity.file_bytes > static_cast<std::uint64_t>(std::numeric_limits<off_t>::max()))
        impl->fail(0, "terrain file exceeds byte limit");
    impl->read_header();
    const auto patch_count = std::uint64_t(impl->header.patch_columns) *
                             std::uint64_t(impl->header.patch_rows);
    if (patch_count > limits.max_patches || patch_count > std::numeric_limits<std::size_t>::max())
        impl->fail(8, "terrain patch count exceeds limit");
    const auto count = static_cast<std::size_t>(patch_count);
    impl->storage_bytes(count, 0);
    const auto grid_count = impl->scan(count, false);
    impl->verify();
    impl->patches.resize(count);
    impl->grids.resize(grid_count);
    impl->storage_bytes(impl->patches.capacity(), impl->grids.capacity());
    if (impl->scan(count, true) != grid_count) impl->fail(0, "terrain index changed during indexing");
    impl->verify();
    return TerrainFile(std::move(impl));
}

const std::filesystem::path& TerrainFile::path() const { return impl_->path; }
const TerrainSourceIdentity& TerrainFile::identity() const { return impl_->identity; }
const TerrainHeader& TerrainFile::header() const { return impl_->header; }
const std::vector<TerrainPatch>& TerrainFile::patches() const { return impl_->patches; }
const std::vector<TerrainGridDescriptor>& TerrainFile::grids() const { return impl_->grids; }
std::size_t TerrainFile::index_storage_bytes() const {
    return impl_->storage_bytes(impl_->patches.capacity(), impl_->grids.capacity());
}
std::size_t TerrainFile::resident_grid_bytes() const {
    return impl_->window ? impl_->window->bytes_.capacity() : 0;
}
std::size_t TerrainFile::maximum_grid_bytes() const { return impl_->maximum_payload; }
void TerrainFile::verify_source_unchanged() const { impl_->verify(); }
void TerrainFile::release_grid() noexcept { if (impl_) impl_->window.reset(); }

const TerrainGridWindow& TerrainFile::read_grid(std::size_t patch_index, std::size_t level_index) {
    if (patch_index >= impl_->patches.size() ||
        level_index > std::size_t(impl_->patches[patch_index].maximum_level_index))
        throw std::out_of_range("terrain patch or grid ordinal is outside index");
    try {
        impl_->verify();
        if (impl_->window && impl_->window->patch_index_ == patch_index &&
            impl_->window->level_index_ == level_index) return *impl_->window;
        release_grid();
        impl_->window.emplace();
        auto& window = *impl_->window;
        window.patch_index_ = patch_index;
        window.level_index_ = level_index;
        window.descriptor_ = impl_->grids[impl_->patches[patch_index].first_grid + level_index];
        window.bytes_.resize(window.descriptor_.payload_bytes);
        if (window.bytes_.capacity() > impl_->limits.max_grid_bytes)
            impl_->fail(window.descriptor_.payload_offset, "terrain grid allocation exceeds memory limit");
        impl_->read(window.descriptor_.payload_offset, window.bytes_.data(), window.bytes_.size());
        impl_->verify();
        return window;
    } catch (...) {
        // allocation失敗も含め、不完全なwindowをcacheとして公開しない。
        release_grid();
        throw;
    }
}

std::int16_t TerrainGridWindow::elevation_units(std::int32_t column, std::int32_t row) const {
    if (column < -1 || column > descriptor_.columns + 1 || row < -1 || row > descriptor_.rows + 1)
        throw std::out_of_range("terrain vertex is outside grid including halo");
    const auto offset = (std::size_t(row + 1) * std::size_t(descriptor_.columns + 3) +
                         std::size_t(column + 1)) * 2;
    if (offset + 2 > bytes_.size()) throw std::logic_error("terrain grid window is not loaded");
    const auto value = std::uint32_t(bytes_[offset]) | (std::uint32_t(bytes_[offset + 1]) << 8);
    return static_cast<std::int16_t>(value <= 32767 ? std::int32_t(value) : std::int32_t(value) - 65536);
}
} // namespace mitaka
