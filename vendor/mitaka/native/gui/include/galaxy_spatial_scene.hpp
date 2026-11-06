#pragma once

#include "galaxy_camera.hpp"
#include "mitaka/galaxy_catalog.hpp"

#include <variant>

namespace mitaka::gui {

enum class GalaxySpatialFamily { sdss_galaxy, sdss_quasar, globular_cluster, nearby_galaxy };
struct GalaxySpatialRecordId {
    GalaxySpatialFamily family = GalaxySpatialFamily::sdss_galaxy;
    std::size_t source_index = 0, ordinal = 0;
};
bool operator==(GalaxySpatialRecordId left, GalaxySpatialRecordId right) noexcept;

// 既存 snapshot の位置/原行は共有し、約93万行の配列を複製しない。
struct GalaxySdssSource {
    std::shared_ptr<const SdssSpatialSnapshot> snapshot;
    std::size_t source_index = 0;
};
using GalaxySpatialSource = std::variant<GalaxySdssSource,
    PlusGlobularClusterCatalog, PlusNearbyGalaxyCatalog>;
enum class GalaxyIssueDomain { sdss, galaxy_catalog };
struct GalaxySpatialRow {
    GalaxySpatialRecordId id;
    std::optional<NativeEclipticPositionPc> position;
    GalaxyIssueDomain issue_domain;
    // 各 domain の既存 issue bit を変更せず返す。
    std::uint16_t issues;
};

// 出典順/全行/重複と raw source を保持する immutable 表示モデル。
// 形式の自動推定、名前表の結合、OurGalaxy の未知座標系の投影は行わない。
class GalaxySpatialModel {
public:
    explicit GalaxySpatialModel(std::vector<GalaxySpatialSource> sources);
    GalaxySpatialModel(const GalaxySpatialModel&) = delete;
    GalaxySpatialModel(GalaxySpatialModel&&) = delete;
    GalaxySpatialModel& operator=(const GalaxySpatialModel&) = delete;
    GalaxySpatialModel& operator=(GalaxySpatialModel&&) = delete;
    const std::vector<GalaxySpatialSource>& sources() const noexcept { return sources_; }
    std::size_t size() const noexcept { return row_count_; }
    std::size_t source_size(std::size_t source) const;
    GalaxySpatialFamily family(std::size_t source) const;
    const std::filesystem::path& source_path(std::size_t source) const;
    GalaxySpatialRecordId record_id(std::size_t row) const;
    std::size_t row_index(GalaxySpatialRecordId id) const;
    GalaxySpatialRow row(GalaxySpatialRecordId id) const;
private:
    std::vector<GalaxySpatialSource> sources_;
    std::vector<std::size_t> offsets_;
    std::size_t row_count_ = 0;
};

struct GalaxySpatialVisibility {
    bool sdss_galaxies = true, sdss_quasars = true, globular_clusters = true, nearby_galaxies = true;
    bool visible(GalaxySpatialFamily family) const;
};

// 完成画像の円とプレビューの矩形の寸法を描画側・選択側で共有する。
constexpr double galaxy_spatial_point_radius(GalaxySpatialFamily family) noexcept {
    return family == GalaxySpatialFamily::globular_cluster ? 2.0 : 1.25;
}
constexpr double galaxy_spatial_preview_size = 1.5;
bool galaxy_spatial_point_contains(GalaxySpatialFamily family, double center_x, double center_y,
                                   double x, double y, bool preview) noexcept;

// 描画図形の内部は最後に描画された点を選び、それ以外は radius 内の最も近い点を選ぶ。
// 同一画面距離では手前の depth、同じ投影座標では後描きを優先。密度削減はしない。
// 取消は出典間・256行ごと・終了時に確認し、途中の候補は返さない。
std::optional<GalaxySpatialRecordId> pick_galaxy_spatial_row(
    const GalaxySpatialModel& model, const GalaxyProjector& projector,
    GalaxySpatialVisibility visibility, double x, double y, double radius,
    std::function<bool()> should_cancel = {});

class GalaxySpatialScene {
public:
    // 同じ immutable model の再設定は選択を保持。別 instance/reload は解除。
    void set_model(std::shared_ptr<const GalaxySpatialModel> model);
    const std::shared_ptr<const GalaxySpatialModel>& model() const noexcept { return model_; }
    std::optional<GalaxySpatialRecordId> selection() const noexcept { return selection_; }
    // 不正 ID は選択を変える前に拒否。位置を持たない原行も検査目的で選択できる。
    void select(std::optional<GalaxySpatialRecordId> id);
    // 位置のない選択は false で camera を保持。距離/角度は変えず注視点だけを移す。
    bool focus_selection(GalaxyCameraPc& camera) const;
private:
    std::shared_ptr<const GalaxySpatialModel> model_;
    std::optional<GalaxySpatialRecordId> selection_;
};

} // namespace mitaka::gui
