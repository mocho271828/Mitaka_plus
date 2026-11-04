#include "terrain_source_lease.hpp"

#include <cerrno>
#include <fcntl.h>
#include <stdexcept>
#include <sys/stat.h>
#include <unistd.h>

namespace mitaka::gui {
namespace {
struct Descriptor {
    int value=-1;
    explicit Descriptor(int descriptor):value(descriptor) {}
    Descriptor(const Descriptor&)=delete;
    Descriptor& operator=(const Descriptor&)=delete;
    ~Descriptor() { if(value>=0) ::close(value); }
    void replace(int next) { if(value>=0) ::close(value);value=next; }
};
[[noreturn]] void fail(const std::filesystem::path& path,const char* message) {
    throw std::filesystem::filesystem_error(message,path,std::error_code(errno,std::generic_category()));
}
void descend(Descriptor& directory,const std::filesystem::path& component,
             const std::filesystem::path& source) {
    const int next=::openat(directory.value,component.c_str(),O_RDONLY|O_CLOEXEC|O_DIRECTORY|O_NOFOLLOW);
    if(next<0) fail(source,"terrain source directory changed or is not accessible");
    directory.replace(next);
}
bool safe(const std::filesystem::path& path) {
    for(const auto& component:path) if(component=="."||component==".."||component.empty()) return false;
    return path.native().find('\0')==std::string::npos;
}
}

TerrainSourceLease::TerrainSourceLease(const std::filesystem::path& root,const std::filesystem::path& source) {
    const auto relative=source.lexically_relative(root);
    if(!root.is_absolute()||!source.is_absolute()||relative.empty()||relative.is_absolute()||
       !safe(root)||!safe(source)||!safe(relative))
        throw std::invalid_argument("terrain lease requires canonical paths within one data root");
    Descriptor directory{::open("/",O_RDONLY|O_CLOEXEC|O_DIRECTORY|O_NOFOLLOW)};
    if(directory.value<0) fail(source,"cannot open terrain filesystem root");
    // root自体の祖先も辿り直さない。検査後にsymlinkへ差し替えられたcomponentは拒否する。
    for(const auto& component:root.relative_path()) descend(directory,component,source);
    for(const auto& component:relative.parent_path()) descend(directory,component,source);
    Descriptor file{::openat(directory.value,relative.filename().c_str(),O_RDONLY|O_CLOEXEC|O_NONBLOCK|O_NOFOLLOW)};
    if(file.value<0) fail(source,"terrain source changed or is not accessible");
    struct stat info{};
    if(::fstat(file.value,&info)!=0) fail(source,"cannot identify terrain source");
    if(!S_ISREG(info.st_mode)) throw std::invalid_argument("terrain source is not a regular file");
    descriptor_=file.value;file.value=-1;
}
TerrainSourceLease::~TerrainSourceLease() { if(descriptor_>=0) ::close(descriptor_); }
std::filesystem::path TerrainSourceLease::descriptor_path() const {
    // macOS fd(4): このpathのopenは既存FDの複製。ファイル名を再解決しない。
    return std::filesystem::path("/dev/fd")/std::to_string(descriptor_);
}

} // namespace mitaka::gui
