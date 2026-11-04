#pragma once

#include "mitaka/astronomy.hpp"
#include "mitaka/spacecraft_trajectory.hpp"

namespace mitaka {

inline constexpr std::string_view spacecraft_pth_position_contract =
    "mitaka-plus-1.5.4-pth-native-au-v1";

enum class SpacecraftSamplingKind {
    exact_record, interpolated, clamped_before, clamped_after
};

struct SpacecraftPositionSampling {
    SpacecraftSamplingKind kind;
    std::size_t first_record_index;
    std::size_t second_record_index;
    double u; // 補間は first*(1-u)+second*u。一致・端点固定では両 index が同じで u=0。
};

struct SpacecraftPositionEvaluation {
    std::size_t trajectory_index = 0;
    std::optional<std::size_t> source_index;
    double legacy_julian_date = 0;
    std::optional<Vec3> heliocentric_j2000_ecliptic_au;
    std::optional<SpacecraftPositionSampling> sampling;
    // 位置成功時のみ設定。原版の旧 pc 換算・binary32 係数の丸め一致は主張しない。
    std::string_view contract;
    std::vector<SpacecraftDiagnostic> diagnostics;
};

// 原 bytes・定義・全原記録を所有し、構築時に PTH の全記録を検査する。
// 以後の評価は O(log N)。移譲後の dataset とファイルの変更に依存しない。
// PPI は既存 Trajectory の km 評価とは別の未確定空間契約なので描画位置を返さない。
class SpacecraftPositionModel {
public:
    explicit SpacecraftPositionModel(SpacecraftDataset dataset);

    const SpacecraftDataset& dataset() const noexcept { return dataset_; }
    SpacecraftPositionEvaluation evaluate(std::size_t trajectory_index,
                                         double legacy_julian_date) const;

private:
    SpacecraftDataset dataset_;
    std::vector<std::optional<SpacecraftDiagnostic>> validation_errors_;
};

} // namespace mitaka
