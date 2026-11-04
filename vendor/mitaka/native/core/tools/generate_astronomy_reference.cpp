#include <cstdio>
#include "astro/cele_mech.h"
#include "astro/astrometry.h"
int main() {
 const double rows[][6] = {
 {0.38710,0.20563,7.0050,48.3665,77.5028,55.4500},
 {0.72333,0.00677,3.3947,76.7069,131.6058,137.1556},
 {1.00000,0.01671,0.0000,0.0000,102.9889,100.2431},
 {1.52368,0.09340,1.8497,49.5812,336.1155,209.5529},
 {5.20260,0.04850,1.3031,100.4950,14.3796,125.4198},
 {9.55491,0.05554,2.4888,113.6918,93.1161,86.7744},
 {19.21845,0.04638,0.7732,74.0216,173.0499,326.9480},
 {30.11039,0.00946,1.7697,131.8171,48.1631,310.9437},
 {39.54044,0.24901,17.1449,110.3587,224.1833,242.8665}};
 for (auto& row: rows) {
 const double n=0.985607669/pow(row[0],1.5);
 const vector3d position=calc_orbital_pos(row[0],row[1],row[5]-row[4],n,2452640.5,2451545.0);
 const vector3d velocity=calc_orbital_velocity(position,row[0],row[1],n);
 const matrix3d rotation=calc_trans_matrix(row[3],row[2],row[4]-row[3]);
 const vector3d p=rotation*position, v=rotation*velocity;
 printf("{{%.17g, %.17g, %.17g}, {%.17g, %.17g, %.17g}},\n",p.x,p.y,p.z,v.x,v.y,v.z);
 }
 const auto equatorial=B1950_to_J2000(RA_DEC(123.4f,-35.6f),0.1f,-0.4f,25.f,0.02f);
 printf("B1950 %.17g %.17g\n",equatorial.RAdeg,equatorial.DEdeg);
}
