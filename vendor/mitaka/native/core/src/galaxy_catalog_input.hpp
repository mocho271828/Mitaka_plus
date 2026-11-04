#pragma once

#include "mitaka/galaxy_catalog.hpp"

#include <cstring>
#include <limits>

namespace mitaka::galaxy_detail {

// この feature の可変長/固定長 reader が同じ境界検証を利用する。
class Input {
public:
    Input(const GalaxyCatalogSource& source, CatalogLoadLimits limits)
        : source_(source), limits_(limits) {}
    std::size_t offset() const noexcept { return offset_; }
    std::size_t remaining() const noexcept { return source_.bytes.size() - offset_; }
    void require(std::size_t count) const {
        if (count > remaining()) fail("truncated galaxy catalog");
    }
    void check_count(std::size_t count) const {
        if (count > limits_.max_records) fail("galaxy catalog exceeds record limit");
    }
    std::size_t fixed_count(std::size_t width) const {
        if (remaining() % width != 0) fail("truncated fixed-width galaxy record");
        const auto count = remaining() / width;
        check_count(count);
        return count;
    }
    std::uint8_t byte() { require(1); return source_.bytes[offset_++]; }
    std::uint32_t u32() {
        require(4);
        std::uint32_t result = 0;
        for (unsigned i = 0; i < 4; ++i) result |= std::uint32_t(byte()) << (8 * i);
        return result;
    }
    std::int32_t i32() {
        const auto bits = u32();
        std::int32_t result;
        std::memcpy(&result, &bits, sizeof(result));
        return result;
    }
    float f32() {
        static_assert(sizeof(float) == 4 && std::numeric_limits<float>::is_iec559);
        const auto bits = u32();
        float result;
        std::memcpy(&result, &bits, sizeof(result));
        return result;
    }
    [[noreturn]] void fail(const std::string& reason) const {
        throw CatalogError(source_.path, offset_, reason);
    }
private:
    const GalaxyCatalogSource& source_;
    CatalogLoadLimits limits_;
    std::size_t offset_ = 0;
};

} // namespace mitaka::galaxy_detail
