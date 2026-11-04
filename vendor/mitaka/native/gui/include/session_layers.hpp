#pragma once

#include "constellation_display.hpp"
#include "small_body_display.hpp"
#include "satellite_display.hpp"
#include "mitaka/small_body_orbit_path.hpp"

#include <array>
#include <string_view>

namespace mitaka::gui {

// 原本そのものを状態ファイルに複製せず、読込済み snapshot の bytes を照合する。
struct SessionSourceIdentity {
    std::string source_key;
    std::size_t byte_count = 0;
    std::string sha256;
};

struct SmallBodySessionDisplay {
    bool visible = false;
    // SmallBodyKind の asteroid / trans_neptunian / comet と同じ順。
    std::array<SmallBodyKindDisplayOptions, 3> kinds{};
    std::vector<SmallBodyId> selected_ids;
    std::vector<SessionSourceIdentity> sources;
    SmallBodyOrbitSampling orbit_sampling{2451362.375, 2451727.625, 129};
};

struct SatelliteSessionDisplay {
    SatelliteDisplayOptions options;
    std::vector<SatelliteRecordId> selected_ids;
    // definition source だけを照合する。別の軌道出典の変更は行 ID を変更しない。
    std::vector<SessionSourceIdentity> sources;
};

struct SpacecraftSessionDisplay {
    bool visible = false;
    bool points = true;
    bool labels = false;
    bool orbits = false;
};

SessionSourceIdentity session_source_identity(std::string_view source_key, std::string_view bytes);
void validate_session_layers(const SmallBodySessionDisplay&, const SatelliteSessionDisplay&,
                             const ConstellationDisplayOptions&);

// capture / prepare は入出力や既存表示の変更を行わない。
// 不明な ID、重複、原出典不一致は全体を例外で拒否し、部分復元しない。
SmallBodySessionDisplay capture_small_body_session(const SmallBodyDisplayModel&, bool visible,
                                                  SmallBodyOrbitSampling);
SatelliteSessionDisplay capture_satellite_session(const SatelliteDisplayModel&);
std::shared_ptr<const SmallBodyDisplayModel> prepare_small_body_session(
    const SmallBodySessionDisplay&, const SmallBodyDisplayModel& current);
std::shared_ptr<const SatelliteDisplayModel> prepare_satellite_session(
    const SatelliteSessionDisplay&, const SatelliteDisplayModel& current);

} // namespace mitaka::gui
