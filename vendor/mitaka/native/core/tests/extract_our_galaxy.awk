# Extract only the 1.3.1 constants and pure ray kernel for a comparison binary.
/^const float h1r =/ { copying = 1 }
/^int GalaxyRayNum/ { copying = 0 }
/^const vector2f[ \t]+img_gc/ { copying = 1 }
/^const RGBf col1/ { copying = 0 }
/^const float qe2 =/ { copying = 1 }
/^calc_our_Galaxy_ray\(/ { copying = 1 }
copying { print }
copying && /^\}/ && seen_point { exit }
copying && /^\}/ && seen_ray { copying = 0 }
/^calc_our_Galaxy_ray\(/ { seen_ray = 1 }
/^calc_galactic_optical_depth_g\(/ { print "float"; print; copying = 1; seen_point = 1 }
