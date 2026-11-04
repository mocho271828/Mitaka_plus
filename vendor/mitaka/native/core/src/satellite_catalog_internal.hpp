#pragma once

#include "mitaka/satellite_catalog.hpp"

namespace mitaka::satellite_detail {

struct ParsedSource {
    std::vector<SatelliteDefinition> definitions;
    std::vector<SatelliteOrbitRecord> orbits;
    std::vector<SatelliteDiagnostic> diagnostics;
    std::size_t field_count = 0;
    bool valid = true;
};

ParsedSource parse_source(const SatelliteSource& source, const SatelliteLoadLimits& limits,
                          std::size_t remaining_records, std::size_t remaining_fields);

} // namespace mitaka::satellite_detail
