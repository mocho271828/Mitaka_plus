#pragma once

namespace mitaka::detail {
// 呼出元が離心率と平均近点角を検証する、内部専用の Kepler 方程式の解。
double eccentric_anomaly(double eccentricity, double mean_anomaly);
}
