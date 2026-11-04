#pragma once

#include <array>
#include <cstddef>
#include <filesystem>
#include <memory>
#include <string>
#include <string_view>
#include <utility>

namespace mitaka {

struct EphemerisState {
    std::array<double, 3> position_au;
    std::array<double, 3> velocity_au_per_day;
};

// CF96 の太陽中心 J2000 赤道座標。地球・冥王星の衛星重心補正は含まない。
// JD は暦表の時刻引数であり、UTC からの時系変換は行わない。
class Cf96Ephemeris {
public:
    static Cf96Ephemeris load(const std::filesystem::path& path);
    std::size_t planet_count() const noexcept;
    std::pair<double, double> time_range(std::size_t planet) const;
    // 範囲外・不正添字は out_of_range、非有限 JD は invalid_argument。
    EphemerisState state(std::size_t planet, double julian_date) const;

private:
    struct Data;
    explicit Cf96Ephemeris(std::shared_ptr<const Data> data);
    std::shared_ptr<const Data> data_;
};

// .ppi の四点補間。座標系・原点はファイルの作成元に従い、距離は km。
class Trajectory {
public:
    static Trajectory load(const std::filesystem::path& path);
    // bytes は呼出中だけ参照し、検証したセグメントを独立して所有する。
    static Trajectory load_bytes(std::string_view bytes, std::string source_name);
    std::size_t segment_count() const noexcept;
    std::pair<double, double> time_range() const noexcept;
    // 範囲外やセグメント間の空隙は out_of_range。暗黙の端点固定はしない。
    std::array<double, 3> position_km(double julian_date) const;

private:
    struct Data;
    explicit Trajectory(std::shared_ptr<const Data> data);
    std::shared_ptr<const Data> data_;
};

} // namespace mitaka
