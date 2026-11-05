#pragma once
#import "SolarSystemView.h"

namespace mitaka::gui {
struct SolarDateInput {
    double julian_date;
    ObserverSite site;
    SolarBodies bodies;
    bool refresh_orbits;
    SolarOrbits orbits;
    std::vector<Vec3> lunar_orbit;
    std::shared_ptr<const SmallBodySnapshot> small_bodies;
    std::shared_ptr<const SmallBodyDisplayModel> small_body_display;
    PreparedSatelliteScene satellites;
    std::shared_ptr<const SpacecraftSnapshot> spacecraft;
};
struct PreparedSolarDate;
}

@interface SolarSystemView (DateUpdate)
- (std::shared_ptr<mitaka::gui::PreparedSolarDate>)prepareDateUpdate:(const mitaka::gui::SolarDateInput&)input;
- (void)commitDateUpdate:(std::shared_ptr<mitaka::gui::PreparedSolarDate>)prepared;
- (void)finishDateUpdate;
- (void)invalidatePendingDateTerrain;
@end
