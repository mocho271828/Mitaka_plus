#pragma once

#include "mitaka/astronomy.hpp"

namespace mitaka {

// 球面地球上の地点。緯度は [-90,90]、東経は [-180,180]、単位は度。
struct ObserverSite {
    double latitude_deg;
    double longitude_deg;
};

// 方位は真北=0、東=90 の [0,360)、高度は [-90,90]、単位は度。
// 天頂・天底では方位が定まらないため、数値上の方位を 0 とする。
struct HorizontalCoordinates {
    double azimuth_deg;
    double altitude_deg;
};

// 一つの地点・JD の変換基底を保持し、多数の恒星で歳差・自転を再計算しない。
// planet_orientation(earth, JD) と同じ公式 Mitaka の表示用歳差・自転を使う。
// 入出力は J2000 赤道方向。屈折・視差・章動・極運動・時系変換は含まない。
// JD の数値範囲は先発 Gregorian 年 -4712..9999（精度保証範囲ではない）。
// 不正地点/非有限値は std::invalid_argument、JD 範囲外は std::out_of_range。
class ObservationFrame {
public:
    ObservationFrame(ObserverSite site, double julian_date);
    HorizontalCoordinates to_horizontal(EquatorialCoordinates coordinates) const;
    EquatorialCoordinates to_equatorial(HorizontalCoordinates coordinates) const;

private:
    Vec3 east_, north_, up_;
};

HorizontalCoordinates equatorial_to_horizontal(EquatorialCoordinates coordinates,
                                                ObserverSite site, double julian_date);
EquatorialCoordinates horizontal_to_equatorial(HorizontalCoordinates coordinates,
                                                ObserverSite site, double julian_date);

// USNO の平均恒星時近似。UT1=TT とみなす単一 JD、返値は度で [0,360)。
// 視恒星時ではなく、上記の旧 Mitaka 地平変換で用いる自転角とも異なる。
// JD 範囲・例外は ObservationFrame と同じ。長期間の精度は保証しない。
double greenwich_mean_sidereal_time_deg(double julian_date);
double local_mean_sidereal_time_deg(double julian_date, double east_longitude_deg);

} // namespace mitaka
