#include "mitaka/atmosphere.hpp"

#include <cmath>
#include <cstring>
#include <fstream>
#include <limits>
#include <utility>

namespace mitaka {
struct AtmosphereEmissionMap::Data {
    AtmosphereEmissionGrid grid;
    std::vector<AtmosphereRgb> nodes;
    std::vector<double> radii;
};

namespace {
constexpr double pi = 3.141592653589793238462643383279502884;
class Reader {
public:
    Reader(std::string_view bytes, const std::filesystem::path& source)
        : bytes_(bytes), source_(source) {}
    template<class Value, class Bits> Value real() {
        static_assert(sizeof(Value) == sizeof(Bits) && std::numeric_limits<Value>::is_iec559);
        const auto bits = integer<Bits>();
        Value value;
        std::memcpy(&value, &bits, sizeof(value));
        if (!std::isfinite(value)) fail("non-finite atmosphere value");
        return value;
    }
    template<class Bits> Bits integer() {
        if (bytes_.size() - offset_ < sizeof(Bits)) fail("truncated atmosphere map");
        Bits bits = 0;
        for (std::size_t i = 0; i < sizeof(Bits); ++i)
            bits |= Bits{static_cast<unsigned char>(bytes_[offset_++])} << (i * 8);
        return bits;
    }
    [[noreturn]] void fail(const std::string& reason) const { throw CatalogError(source_, offset_, reason); }
private:
    std::string_view bytes_;
    const std::filesystem::path& source_;
    std::uint64_t offset_ = 0;
};

void parse_source(AtmosphereEmissionSource& source, CatalogLoadLimits limits) {
    if (source.bytes.size() > limits.max_file_bytes) {
        source.diagnostics.push_back({AtmosphereLoadFailure::limit_exceeded, 0,
                                      "atmosphere map exceeds byte limit"});
        return;
    }
    try { source.map = AtmosphereEmissionMap::parse(source.bytes, source.path, limits); }
    catch (const CatalogError& error) {
        source.diagnostics.push_back({AtmosphereLoadFailure::invalid_format, error.offset(), error.what()});
    }
}
} // namespace

AtmosphereEmissionMap::AtmosphereEmissionMap(std::shared_ptr<const Data> data) : data_(std::move(data)) {}
const AtmosphereEmissionGrid& AtmosphereEmissionMap::grid() const noexcept { return data_->grid; }
const std::vector<AtmosphereRgb>& AtmosphereEmissionMap::nodes() const noexcept { return data_->nodes; }
const std::vector<double>& AtmosphereEmissionMap::radii_m() const noexcept { return data_->radii; }

AtmosphereEmissionMap AtmosphereEmissionMap::parse(std::string_view bytes,
    const std::filesystem::path& source, CatalogLoadLimits limits) {
    Reader reader(bytes, source);
    if (bytes.size() > limits.max_file_bytes) reader.fail("atmosphere map exceeds byte limit");
    auto data = std::make_shared<Data>();
    auto& grid = data->grid;
    grid.radial_count = reader.integer<std::uint32_t>();
    grid.angle_count = reader.integer<std::uint32_t>();
    if (grid.radial_count < 2 || grid.angle_count < 2 ||
        grid.radial_count > static_cast<std::size_t>(std::numeric_limits<std::int32_t>::max()) ||
        grid.angle_count > static_cast<std::size_t>(std::numeric_limits<std::int32_t>::max()))
        reader.fail("atmosphere grid dimensions must be signed positive counts of at least two");
    if (grid.radial_count > limits.max_records / grid.angle_count)
        reader.fail("atmosphere grid exceeds node limit");
    const auto count = grid.radial_count * grid.angle_count;
    if (bytes.size() < 48 || count > (bytes.size() - 48) / 12 || bytes.size() - 48 != count * 12)
        reader.fail("atmosphere map must contain a 48-byte header and exact RGB32 grid");
    grid.ground_radius_m = reader.real<double, std::uint64_t>();
    grid.outer_radius_m = reader.real<double, std::uint64_t>();
    grid.scale_height_m = reader.real<double, std::uint64_t>();
    grid.surface_number_density_per_m3 = reader.real<double, std::uint64_t>();
    grid.maximum_sun_zenith_angle_rad = reader.real<double, std::uint64_t>();
    if (grid.ground_radius_m <= 0 || grid.outer_radius_m <= grid.ground_radius_m ||
        grid.scale_height_m <= 0 || grid.surface_number_density_per_m3 < 0 ||
        grid.maximum_sun_zenith_angle_rad <= 0 || grid.maximum_sun_zenith_angle_rad > pi)
        reader.fail("invalid atmosphere radius, scale height, number density or angular extent");
    if (grid.ground_radius_m*grid.ground_radius_m == 0 ||
        !std::isfinite(grid.outer_radius_m*grid.outer_radius_m) ||
        grid.maximum_sun_zenith_angle_rad/(grid.angle_count-1) == 0)
        reader.fail("atmosphere grid exceeds numerical range");
    data->radii.reserve(grid.radial_count);
    for (std::size_t i = 0; i < grid.radial_count; ++i) {
        const double radius = grid.ground_radius_m + (grid.outer_radius_m - grid.ground_radius_m) *
            static_cast<double>(i) / (grid.radial_count - 1);
        if (!std::isfinite(radius) || (!data->radii.empty() && radius <= data->radii.back()))
            reader.fail("atmosphere radial grid is not finite and strictly increasing");
        data->radii.push_back(radius);
    }
    data->nodes.reserve(count);
    for (std::size_t i = 0; i < count; ++i) {
        AtmosphereRgb node{reader.real<float, std::uint32_t>(), reader.real<float, std::uint32_t>(),
                           reader.real<float, std::uint32_t>()};
        if (node.r < 0 || node.g < 0 || node.b < 0) reader.fail("negative atmosphere emission");
        data->nodes.push_back(node);
    }
    return AtmosphereEmissionMap(std::move(data));
}

AtmosphereEmissionSource parse_atmosphere_emission_map(std::string bytes,
    const std::filesystem::path& source, CatalogLoadLimits limits) {
    AtmosphereEmissionSource result;
    result.path = source;
    result.file_size = bytes.size();
    result.bytes = std::move(bytes);
    result.read_complete = true;
    parse_source(result, limits);
    return result;
}

AtmosphereEmissionSource load_atmosphere_emission_map(const std::filesystem::path& path,
                                                     CatalogLoadLimits limits) {
    AtmosphereEmissionSource result;
    result.path = path;
    std::ifstream input(path, std::ios::binary | std::ios::ate);
    const auto size = input ? input.tellg() : std::streampos(-1);
    if (size < 0) {
        result.diagnostics.push_back({AtmosphereLoadFailure::unreadable, 0,
                                      "cannot open or determine atmosphere map size"});
        return result;
    }
    result.file_size = static_cast<std::uint64_t>(size);
    if (result.file_size > limits.max_file_bytes ||
        result.file_size > static_cast<std::uint64_t>(std::numeric_limits<std::streamsize>::max()) ||
        result.file_size > result.bytes.max_size()) {
        result.diagnostics.push_back({AtmosphereLoadFailure::limit_exceeded, 0,
                                      "atmosphere map exceeds byte limit"});
        return result;
    }
    result.bytes.resize(static_cast<std::size_t>(result.file_size));
    input.seekg(0);
    input.read(result.bytes.data(), static_cast<std::streamsize>(result.bytes.size()));
    if (!input || input.peek() != std::char_traits<char>::eof()) {
        if (!input) result.bytes.resize(static_cast<std::size_t>(input.gcount()));
        result.diagnostics.push_back({AtmosphereLoadFailure::unreadable, result.bytes.size(),
                                      "atmosphere map changed or failed while reading"});
        return result;
    }
    result.read_complete = true;
    parse_source(result, limits);
    return result;
}
} // namespace mitaka
