#pragma once
#import <AppKit/AppKit.h>
#include "spacecraft_browser_model.hpp"
#include "solar_camera.hpp"
#include "renderer_options.hpp"

namespace mitaka::gui {

// native の初期値。原版の表示既定値や画素一致を表さない。
// points は点・選択リング・hit のみ。labels と orbits はそれぞれ独立。
struct SpacecraftDisplayOptions {
    bool points = true;
    bool labels = false;
    bool orbits = false;
};

struct VisibleSpacecraft { std::size_t index; SolarProjection point; };
struct SpacecraftPathSegment {
    std::size_t definition_index;
    std::size_t first_record_index;
    std::size_t second_record_index;
    SolarProjection first;
    SolarProjection second;
};

// 描画・focus・追尾で共有する境界。同じ日時と参照先の確認済み PTH 位置だけを返す。
std::optional<Vec3> spacecraft_scene_position(const SpacecraftSnapshot& snapshot, std::size_t index);

// 点または名称が有効なときの画面内位置。遠方から手前の順で重複定義も保持する。
std::vector<VisibleSpacecraft> visible_spacecraft(const SpacecraftSnapshot& snapshot,
    const SolarCamera& camera, NSRect map, const SpacecraftDisplayOptions& options);
std::optional<std::size_t> pick_spacecraft(const SpacecraftSnapshot& snapshot,
    const SolarCamera& camera, NSRect map, NSPoint point, const SpacecraftDisplayOptions& options);

// 原定義順・原標本順。両端とも投影可能な隣接標本だけを渡す。
// 画面外の線分を含むため描画側で map に clip する。全線分の大配列は作らない。
void visit_spacecraft_path_segments(const SpacecraftSnapshot& snapshot, const SolarCamera& camera,
    NSRect map, const SpacecraftDisplayOptions& options,
    const std::function<void(const SpacecraftPathSegment&)>& visitor);

void draw_spacecraft(CGContextRef context, const SpacecraftSnapshot& snapshot,
    const SolarCamera& camera, NSRect map, std::optional<std::size_t> selection,
    const SpacecraftDisplayOptions& options, const RendererDisplayOptions& quality);

} // namespace mitaka::gui
