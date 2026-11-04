#pragma once

#include "mitaka/spacecraft_trajectory.hpp"

namespace mitaka::spacecraft_detail {

class LimitError : public CatalogError { public: using CatalogError::CatalogError; };

std::string ascii_lower(std::string text);
std::vector<SpacecraftPathSample> parse_path(const SpacecraftSource& source,
    std::vector<SpacecraftDiagnostic>& diagnostics);
SpacecraftDefinition parse_definition(const SpacecraftSource& source, std::size_t source_index,
    const SpacecraftLoadLimits& limits, std::size_t remaining_fields,
    std::vector<SpacecraftDiagnostic>& diagnostics, bool& valid);
SpacecraftRegistrationList parse_registration_list(const SpacecraftSource& source,
    std::size_t source_index, const SpacecraftLoadLimits& limits, std::size_t remaining_records);

} // namespace mitaka::spacecraft_detail
