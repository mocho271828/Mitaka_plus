#include "constellation_pick.hpp"
#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace mitaka::gui {
std::optional<ConstellationHit> pick_horizon_constellation(
    const std::vector<ConstellationRecord>& records, const ConstellationStarLookup& star,
    const ConstellationDisplayOptions& options, const ObservationFrame& frame,
    const HorizonViewport& viewport, double width, double height, ScreenPoint point,
    double tolerance, const ConstellationPointVisible& visible) {
    if (!star || !visible || !std::isfinite(width) || !std::isfinite(height) || width <= 0 || height <= 0 ||
        !std::isfinite(point.x) || !std::isfinite(point.y) || !std::isfinite(tolerance) || tolerance < 0)
        throw std::invalid_argument("invalid constellation pick request");
    if (point.x < 0 || point.x >= width || point.y < 0 || point.y >= height || !visible(point)) return std::nullopt;
    std::optional<ConstellationHit> result;
    double nearest = tolerance;
    for (std::size_t index = 0; index < records.size(); ++index) {
        const auto& record = records[index];
        if (options.default_visible == (options.exceptions.count(record.abbreviation) != 0)) continue;
        const auto consider = [&](EquatorialCoordinates start, EquatorialCoordinates end) {
            const auto projected = project_equatorial_segment_to_horizon(start, end, frame, viewport, width, height);
            for (const auto& segment : projected.segments) {
                const double dx = segment.end.x - segment.start.x, dy = segment.end.y - segment.start.y;
                const double length2 = dx * dx + dy * dy;
                const double t = length2 == 0 ? 0 : std::clamp(((point.x - segment.start.x) * dx +
                    (point.y - segment.start.y) * dy) / length2, 0.0, 1.0);
                const ScreenPoint candidate{segment.start.x + t * dx, segment.start.y + t * dy};
                const double distance = std::hypot(point.x - candidate.x, point.y - candidate.y);
                if (distance <= nearest && visible(candidate)) {
                    nearest = distance;
                    result = ConstellationHit{index, candidate, distance};
                }
            }
        };
        if (options.lines) for (const auto& line : record.hip_lines) {
            std::optional<EquatorialCoordinates> previous;
            for (auto hip : line) {
                const auto current = star(hip);
                if (!current) { previous.reset(); continue; }
                if (previous) consider(*previous, *current);
                previous = current;
            }
        }
        if (options.boundaries && record.boundary.size() > 1) {
            for (std::size_t i = 0; i < record.boundary.size(); ++i) {
                const auto& start = record.boundary[i];
                const auto& end = record.boundary[(i + 1) % record.boundary.size()];
                consider({start.right_ascension_hours * 15, start.declination_degrees},
                         {end.right_ascension_hours * 15, end.declination_degrees});
            }
        }
    }
    return result;
}
}
