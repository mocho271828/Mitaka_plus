#pragma once

#include <filesystem>

namespace mitaka::gui {

// canonical済みの出典を各componentのNOFOLLOW openで固定するmacOS用接点。
// TerrainFileを生成し終えるまでこのleaseを保持し、FD番号の再利用を防ぐ。
class TerrainSourceLease {
public:
    TerrainSourceLease(const std::filesystem::path& canonical_root,
                       const std::filesystem::path& canonical_source);
    ~TerrainSourceLease();
    TerrainSourceLease(const TerrainSourceLease&)=delete;
    TerrainSourceLease& operator=(const TerrainSourceLease&)=delete;
    std::filesystem::path descriptor_path() const;
private:
    int descriptor_=-1;
};

} // namespace mitaka::gui
