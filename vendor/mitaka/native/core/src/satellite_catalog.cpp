#include "satellite_catalog_internal.hpp"

#include <algorithm>
#include <fstream>
#include <limits>
#include <unordered_map>

namespace mitaka {

const SatelliteField* unique_satellite_field(const std::vector<SatelliteField>& fields,
                                             std::string_view key) noexcept {
    const SatelliteField* found = nullptr;
    for (const auto& field : fields) {
        if (field.key != key) continue;
        if (found) return nullptr;
        found = &field;
    }
    return found;
}

std::optional<double> satellite_scalar(const std::vector<SatelliteField>& fields,
                                       std::string_view key) noexcept {
    const auto* field = unique_satellite_field(fields, key);
    if (!field || !field->numbers || field->numbers->size() != 1) return std::nullopt;
    return field->numbers->front();
}

namespace {

class Loader {
public:
    Loader(const std::filesystem::path& directory, const SatelliteLoadLimits& limits)
        : directory_(directory), limits_(limits) {}

    SatelliteDataset load() {
        std::vector<std::string> definitions;
        discover(directory_, true, definitions);
        for (const auto* key : {"ssystem.dat", "ssystem_jp.dat"}) {
            if (std::find(definitions.begin(), definitions.end(), key) == definitions.end()) {
                diagnose(SatelliteDiagnosticCode::missing_source, key, "optional system definition is missing");
            }
        }
        std::sort(definitions.begin(), definitions.end());
        for (const auto& key : definitions) load_source(key, SatelliteSourceKind::system_definition);
        std::vector<std::string> orbits;
        discover(directory_ / "orbits", false, orbits);
        std::sort(orbits.begin(), orbits.end());
        for (const auto& key : orbits) load_source(key, SatelliteSourceKind::orbit);
        resolve_orbits();
        return std::move(result_);
    }

private:
    void diagnose(SatelliteDiagnosticCode code, const std::string& key, const std::string& message) {
        result_.diagnostics.push_back({code, key, std::nullopt, 0, 0, {}, message});
    }

    void discover(const std::filesystem::path& directory, bool definitions,
                  std::vector<std::string>& keys) {
        std::error_code error;
        const auto status = std::filesystem::symlink_status(directory, error);
        const auto directory_key = definitions ? std::string(".") : std::string("orbits");
        if (error || !std::filesystem::is_directory(status)) {
            diagnose(std::filesystem::exists(status) ? SatelliteDiagnosticCode::invalid_source
                                                     : SatelliteDiagnosticCode::missing_source,
                     directory_key, "source directory unavailable or not a direct directory");
            return;
        }
        std::filesystem::directory_iterator it(directory, error), end;
        if (error) {
            diagnose(SatelliteDiagnosticCode::invalid_source, directory_key, "cannot enumerate source directory");
            return;
        }
        for (; it != end; it.increment(error)) {
            if (error) break;
            const auto name = it->path().filename().string();
            if (definitions && (name.compare(0, 7, "ssystem") != 0 || it->path().extension() != ".dat")) continue;
            const auto entry_status = it->symlink_status(error);
            if (error) break;
            if (std::filesystem::is_directory(entry_status)) continue;
            if (!std::filesystem::is_regular_file(entry_status) && !std::filesystem::is_symlink(entry_status)) continue;
            if (keys.size() >= limits_.max_sources - result_.sources.size()) {
                diagnose(SatelliteDiagnosticCode::limit_exceeded, directory_key,
                         "total source count limit exceeded; remaining sources were not read");
                break;
            }
            keys.push_back(definitions ? name : "orbits/" + name);
        }
        if (error) diagnose(SatelliteDiagnosticCode::invalid_source, directory_key,
                            "source enumeration failed: " + error.message());
    }

    void read_bytes(SatelliteSource& source) {
        std::error_code error;
        if (!std::filesystem::is_regular_file(std::filesystem::symlink_status(source.path, error)) || error) {
            throw CatalogError(source.path, 0, "source is not a direct regular file");
        }
        std::ifstream input(source.path, std::ios::binary | std::ios::ate);
        if (!input) throw CatalogError(source.path, 0, "cannot open source");
        const auto length = input.tellg();
        if (length < 0) throw CatalogError(source.path, 0, "cannot determine source size");
        const auto size = static_cast<std::uint64_t>(length);
        if (size > limits_.catalog.max_file_bytes || size > limits_.max_total_bytes - total_bytes_ ||
            size > static_cast<std::uint64_t>(std::numeric_limits<std::streamsize>::max()) ||
            size > source.bytes.max_size()) {
            throw CatalogError(source.path, 0, "file or total byte limit exceeded");
        }
        source.bytes.resize(static_cast<std::size_t>(size));
        total_bytes_ += size;
        input.seekg(0);
        if (size && !input.read(source.bytes.data(), static_cast<std::streamsize>(size))) {
            source.bytes.resize(static_cast<std::size_t>(input.gcount()));
            throw CatalogError(source.path, source.bytes.size(), "source truncated while reading");
        }
        if (input.peek() != std::char_traits<char>::eof() || input.bad()) {
            throw CatalogError(source.path, size, "source changed or failed while reading");
        }
    }

    void load_source(const std::string& key, SatelliteSourceKind kind) {
        result_.sources.push_back({key, directory_ / key, kind, {}, false, false, false, 0});
        auto& source = result_.sources.back();
        try {
            read_bytes(source);
            source.read_complete = true;
            const auto records = result_.definitions.size() + result_.orbits.size();
            auto parsed = satellite_detail::parse_source(source, limits_,
                limits_.catalog.max_records - records, limits_.max_fields - total_fields_);
            source.parsed = true;
            source.valid = parsed.valid;
            source.record_count = parsed.definitions.size() + parsed.orbits.size();
            total_fields_ += parsed.field_count;
            result_.definitions.insert(result_.definitions.end(),
                std::make_move_iterator(parsed.definitions.begin()), std::make_move_iterator(parsed.definitions.end()));
            result_.orbits.insert(result_.orbits.end(),
                std::make_move_iterator(parsed.orbits.begin()), std::make_move_iterator(parsed.orbits.end()));
            result_.diagnostics.insert(result_.diagnostics.end(),
                std::make_move_iterator(parsed.diagnostics.begin()), std::make_move_iterator(parsed.diagnostics.end()));
        } catch (const CatalogError& error) {
            const auto offset = std::min<std::uint64_t>(error.offset(), source.bytes.size());
            const auto line = source.bytes.empty() ? 0 : 1 + static_cast<std::size_t>(std::count(
                source.bytes.begin(), source.bytes.begin() + static_cast<std::ptrdiff_t>(offset), '\n'));
            result_.diagnostics.push_back({SatelliteDiagnosticCode::invalid_source, key,
                std::nullopt, error.offset(), line, {}, error.what()});
        }
    }

    std::optional<std::string> orbit_key(const std::string& reference) const {
        // 原版の ./data/... は app root 基準。指定された data の外は自動的に読まない。
        const std::filesystem::path path(reference);
        if (path.empty() || path.is_absolute()) return std::nullopt;
        const auto target = (directory_.parent_path() / path).lexically_normal();
        const auto relative = target.lexically_relative(directory_.lexically_normal());
        if (relative.empty()) return std::nullopt;
        for (const auto& component : relative) if (component == "..") return std::nullopt;
        return relative.generic_string();
    }

    void resolve_orbits() {
        std::unordered_map<std::string, std::size_t> indexes;
        std::unordered_map<std::string, std::size_t> sources;
        for (std::size_t i = 0; i < result_.orbits.size(); ++i) indexes.emplace(result_.orbits[i].id.source_key, i);
        for (std::size_t i = 0; i < result_.sources.size(); ++i)
            if (result_.sources[i].kind == SatelliteSourceKind::orbit && result_.sources[i].read_complete)
                sources.emplace(result_.sources[i].key, i);
        for (auto& definition : result_.definitions) {
            const auto* field = unique_satellite_field(definition.fields, "Orbit");
            if (!field) continue;
            const auto key = orbit_key(field->value_bytes);
            if (key) {
                const auto source = sources.find(*key);
                if (source != sources.end()) definition.orbit_source_index = source->second;
                const auto found = indexes.find(*key);
                if (found != indexes.end()) {
                    definition.orbit_index = found->second;
                    continue;
                }
            }
            result_.diagnostics.push_back({SatelliteDiagnosticCode::unresolved_orbit,
                definition.id.source_key, definition.id.record_ordinal, field->source_offset,
                field->source_line, field->key, "orbit reference has no unique parsed source in the selected data directory"});
        }
    }

    std::filesystem::path directory_;
    SatelliteLoadLimits limits_;
    SatelliteDataset result_;
    std::uint64_t total_bytes_ = 0;
    std::size_t total_fields_ = 0;
};

} // namespace

SatelliteDataset load_satellite_dataset(const std::filesystem::path& data_directory,
                                        SatelliteLoadLimits limits) {
    auto directory = data_directory.lexically_normal();
    if (directory.has_relative_path() && directory.filename().empty()) directory = directory.parent_path();
    return Loader(directory, limits).load();
}

} // namespace mitaka
