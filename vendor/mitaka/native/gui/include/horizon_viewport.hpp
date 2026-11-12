#pragma once

namespace mitaka::gui {
struct HorizonViewport {
    double center_azimuth_deg = 180;
    double center_altitude_deg = 0;
    double vertical_fov_deg = 180;
    double perspective_blend = 0;
    double roll_deg = 0;
    double perspective_fov_deg = 45;
};
}
