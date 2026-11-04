#include "spacecraft_trajectory_internal.hpp"

#include <algorithm>
#include <cmath>
#include <fstream>
#include <iterator>
#include <limits>
#include <map>

namespace mitaka {
namespace {
using Code = SpacecraftDiagnosticCode;
using Kind = SpacecraftSourceKind;
using spacecraft_detail::ascii_lower;

struct SourceIndex {
    std::map<std::string, std::size_t> exact;
    std::map<std::string, std::vector<std::size_t>> folded;

    void add(const std::string& key, std::size_t index) {
        exact.emplace(key, index);
        folded[ascii_lower(key)].push_back(index);
    }
    std::optional<std::size_t> resolve(const std::string& source_key, const std::string& value,
                                       bool& case_folded) const {
        case_folded = false;
        if (value.empty()) return std::nullopt;
        const std::filesystem::path reference(value);
        const auto target = (std::filesystem::path(source_key).parent_path() / reference).lexically_normal();
        if (reference.is_absolute() || std::any_of(target.begin(), target.end(), [](const auto& part) { return part == ".."; }))
            return std::nullopt;
        const auto key = target.generic_string();
        const auto match = exact.find(key);
        if (match != exact.end()) return match->second;
        const auto candidates = folded.find(ascii_lower(key));
        if (candidates == folded.end() || candidates->second.size() != 1) return std::nullopt;
        case_folded = true;
        return candidates->second.front();
    }
};

class Loader {
public:
    Loader(std::filesystem::path directory, const SpacecraftLoadLimits& limits)
        : data_(std::move(directory)), limits_(limits) {}

    SpacecraftDataset load() {
        std::vector<std::pair<std::string, Kind>> keys;
        discover(data_, "data", true, keys);
        discover(data_.parent_path() / "spacecraft", "spacecraft", false, keys);
        std::sort(keys.begin(), keys.end());
        for (const auto& [key, kind] : keys) load_source(key, kind);
        resolve_definitions();
        resolve_registration_lists();
        return std::move(result_);
    }

private:
    void diagnose(Code code, const std::string& key, const std::string& message,
                  std::uint64_t offset = 0) {
        result_.diagnostics.push_back({code, key, std::nullopt, offset, message});
    }

    void discover(const std::filesystem::path& path, const std::string& prefix, bool only_ppi,
                  std::vector<std::pair<std::string, Kind>>& keys) {
        std::error_code error;
        const auto status = std::filesystem::symlink_status(path, error);
        if (error || !std::filesystem::is_directory(status)) {
            diagnose(std::filesystem::exists(status) ? Code::invalid_source : Code::missing_source,
                prefix, "optional spacecraft source directory is unavailable or not a direct directory");
            return;
        }
        std::filesystem::directory_iterator it(path, error), end;
        for (; !error && it != end; it.increment(error)) {
            const auto extension = ascii_lower(it->path().extension().string());
            std::optional<Kind> kind;
            if (extension == ".ppi") kind = Kind::ppi_segments;
            else if (!only_ppi && extension == ".pth") kind = Kind::pth_samples;
            else if (!only_ppi && extension == ".dat")
                kind = ascii_lower(it->path().filename().string()) == "spacecraft.dat"
                    ? Kind::registration_list : Kind::definition;
            if (!kind) continue;
            if (keys.size() >= limits_.max_sources) {
                diagnose(Code::limit_exceeded, prefix, "source count limit exceeded; remaining sources were not read");
                break;
            }
            keys.emplace_back(prefix + "/" + it->path().filename().string(), *kind);
        }
        if (error) diagnose(Code::invalid_source, prefix, "source enumeration failed: " + error.message());
    }

    void read_bytes(SpacecraftSource& source) {
        std::error_code error;
        if (!std::filesystem::is_regular_file(std::filesystem::symlink_status(source.path, error)) || error)
            throw CatalogError(source.path, 0, "source is not a direct regular file");
        std::ifstream input(source.path, std::ios::binary | std::ios::ate);
        if (!input) throw CatalogError(source.path, 0, "cannot open spacecraft source");
        const auto length = input.tellg();
        if (length < 0) throw CatalogError(source.path, 0, "cannot determine spacecraft source size");
        const auto size = static_cast<std::uint64_t>(length);
        if (size > limits_.catalog.max_file_bytes || size > limits_.max_total_bytes - total_bytes_ ||
            size > source.bytes.max_size() || size > static_cast<std::uint64_t>(std::numeric_limits<std::streamsize>::max()))
            throw spacecraft_detail::LimitError(source.path, 0, "file or aggregate spacecraft byte limit exceeded");
        source.bytes.resize(static_cast<std::size_t>(size));
        total_bytes_ += size;
        input.seekg(0);
        if (size && !input.read(source.bytes.data(), static_cast<std::streamsize>(size))) {
            source.bytes.resize(static_cast<std::size_t>(input.gcount()));
            throw CatalogError(source.path, source.bytes.size(), "spacecraft source truncated during read");
        }
        if (input.peek() != std::char_traits<char>::eof() || input.bad())
            throw CatalogError(source.path, size, "spacecraft source changed or failed during read");
    }

    void parse_source(std::size_t source_index) {
        auto& source = result_.sources[source_index];
        const std::size_t width = source.kind == Kind::pth_samples ? 32 : 128;
        std::size_t count = source.kind == Kind::definition ? 1
            : source.kind == Kind::registration_list ? 0 : source.bytes.size() / width;
        if (count > limits_.catalog.max_records - total_records_)
            throw spacecraft_detail::LimitError(source.path, 0, "aggregate spacecraft record limit exceeded");
        std::vector<SpacecraftDiagnostic> diagnostics;
        bool valid = true;
        if (source.kind == Kind::definition) {
            auto definition = spacecraft_detail::parse_definition(source, source_index, limits_,
                limits_.max_fields - total_fields_, diagnostics, valid);
            total_fields_ += definition.fields.size();
            result_.definitions.push_back(std::move(definition));
        } else if (source.kind == Kind::registration_list) {
            auto list = spacecraft_detail::parse_registration_list(source, source_index, limits_,
                limits_.catalog.max_records - total_records_);
            count = list.entries.size();
            result_.registration_lists.push_back(std::move(list));
        } else {
            SpacecraftTrajectoryRecord record;
            record.source_index = source_index;
            if (source.kind == Kind::pth_samples) {
                record.path_samples = spacecraft_detail::parse_path(source, diagnostics);
            } else {
                // 原 bytes を直接評価器へ渡し、同じファイルを再読込して内容がずれることを避ける。
                record.ppi = Trajectory::load_bytes(source.bytes, source.path.string());
                diagnostics.push_back({Code::unresolved_spatial_contract, source.key, std::nullopt, 0,
                    "PPI origin and frame are not inferred from the filename"});
                diagnostics.push_back({Code::unresolved_time_scale, source.key, std::nullopt, 0,
                    "PPI physical time scale is unresolved; evaluation uses a numeric Julian date"});
            }
            result_.trajectories.push_back(std::move(record));
        }
        source.parsed = true;
        source.valid = valid;
        source.record_count = count;
        total_records_ += count;
        result_.diagnostics.insert(result_.diagnostics.end(),
            std::make_move_iterator(diagnostics.begin()), std::make_move_iterator(diagnostics.end()));
    }

    void load_source(const std::string& key, Kind kind) {
        const auto slash = key.find('/');
        const auto path = key.compare(0, slash, "data") == 0 ? data_ / key.substr(slash + 1)
            : data_.parent_path() / key;
        result_.sources.push_back({key, path, kind, {}, false, false, 0});
        const auto index = result_.sources.size() - 1;
        try {
            read_bytes(result_.sources[index]);
            parse_source(index);
        } catch (const spacecraft_detail::LimitError& error) {
            diagnose(Code::limit_exceeded, key, error.what(), error.offset());
        } catch (const CatalogError& error) {
            diagnose(Code::invalid_source, key, error.what(), error.offset());
        } catch (const std::runtime_error& error) {
            // 既存 PPI loader は source 名と byte offset を含む runtime_error を返す。
            diagnose(Code::invalid_source, key, error.what());
        }
    }

    void resolve_definitions() {
        SourceIndex trajectories;
        for (std::size_t i = 0; i < result_.trajectories.size(); ++i) {
            const auto& key = result_.sources[result_.trajectories[i].source_index].key;
            trajectories.add(key, i);
        }
        for (auto& definition : result_.definitions) {
            const auto& source = result_.sources[definition.source_index];
            const SpacecraftField* field = nullptr;
            std::size_t references = 0;
            for (const auto& candidate : definition.fields) {
                if (!candidate.section_bytes.empty() || (candidate.key != "Orbit" && candidate.key != "TRAJECTORY")) continue;
                field = &candidate;
                ++references;
            }
            bool folded = false;
            if (references == 1) definition.trajectory_index = trajectories.resolve(source.key, field->value_bytes, folded);
            if (folded) diagnose(Code::case_insensitive_reference, source.key,
                "trajectory resolved by a unique ASCII case-insensitive match; original reference retained", field->source_offset);
            if (!definition.trajectory_index) diagnose(Code::unresolved_orbit, source.key,
                "Orbit/TRAJECTORY has no unique loaded local trajectory; missing, duplicate or unsafe reference retained",
                field ? field->source_offset : 0);
        }
    }

    void resolve_registration_lists() {
        SourceIndex definitions;
        for (std::size_t i = 0; i < result_.definitions.size(); ++i)
            definitions.add(result_.sources[result_.definitions[i].source_index].key, i);
        for (auto& list : result_.registration_lists) {
            const auto& key = result_.sources[list.source_index].key;
            for (auto& entry : list.entries) {
                bool folded = false;
                entry.definition_index = definitions.resolve(key, entry.reference_bytes, folded);
                if (folded) diagnose(Code::case_insensitive_reference, key,
                    "definition resolved by a unique ASCII case-insensitive match; original reference retained", entry.source_offset);
                if (!entry.definition_index) diagnose(Code::unresolved_definition, key,
                    "registration has no unique loaded local definition; original entry retained", entry.source_offset);
            }
        }
    }

    std::filesystem::path data_;
    SpacecraftLoadLimits limits_;
    SpacecraftDataset result_;
    std::uint64_t total_bytes_ = 0;
    std::size_t total_records_ = 0, total_fields_ = 0;
};
} // namespace

SpacecraftDataset load_spacecraft_dataset(const std::filesystem::path& data_directory,
                                          SpacecraftLoadLimits limits) {
    // 末尾 slash でも spacecraft は data の子ではなく兄弟として解決する。
    auto directory = data_directory.lexically_normal();
    if (directory.filename().empty()) directory = directory.parent_path();
    return Loader(directory, limits).load();
}

SpacecraftTrajectoryEvaluation evaluate_spacecraft_trajectory(
    const SpacecraftDataset& dataset, std::size_t index, double jd) {
    SpacecraftTrajectoryEvaluation result;
    std::string key;
    const auto fail = [&](Code code, const std::string& message) {
        result.diagnostics.push_back({code, key, std::nullopt, 0, message});
        return result;
    };
    if (index >= dataset.trajectories.size()) return fail(Code::invalid_record_index, "trajectory index is outside dataset");
    const auto& record = dataset.trajectories[index];
    if (record.source_index >= dataset.sources.size()) return fail(Code::invalid_record_index, "trajectory source index is outside dataset");
    key = dataset.sources[record.source_index].key;
    if (!std::isfinite(jd)) return fail(Code::invalid_time, "numeric Julian date must be finite");
    if (!record.ppi) return fail(Code::unresolved_pth_contract,
        "PTH interpolation, units and spatial contract are unresolved; samples remain available without a computed position");
    try { result.native_position_km = record.ppi->position_km(jd); }
    catch (const std::out_of_range& error) { return fail(Code::outside_coverage, error.what()); }
    catch (const std::overflow_error& error) { return fail(Code::numerical_range, error.what()); }
    catch (const std::invalid_argument& error) { return fail(Code::invalid_time, error.what()); }
    result.diagnostics.push_back({Code::unresolved_spatial_contract, key, std::nullopt, 0,
        "native PPI coordinates in km; origin and frame remain unresolved"});
    return fail(Code::unresolved_time_scale, "numeric Julian date used without physical time-scale conversion");
}

} // namespace mitaka
