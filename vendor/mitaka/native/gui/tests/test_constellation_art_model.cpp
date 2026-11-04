#include "constellation_art_model.hpp"
#include <fstream>
#include <cstring>
#include <iostream>
#include <unistd.h>
using namespace mitaka;
using namespace mitaka::gui;
namespace {
unsigned checks=0;
void check(bool b,const char*m){++checks;if(!b)throw std::runtime_error(m);}
void write(const std::filesystem::path&p,bool valid=true) {
    std::ofstream out(p,std::ios::binary);
    const auto u=[&](std::uint32_t v){for(unsigned i=0;i<4;++i)out.put(static_cast<char>(v>>(8*i)));};
    for(float v:{1.f,0.f,0.f,.5f,0.f}){std::uint32_t bits;std::memcpy(&bits,&v,4);u(bits);}
    if(valid){u(0);u(0);}
}
}
int main(int argc,char**argv){
    const auto dir=std::filesystem::temp_directory_path()/("mitaka-art-model-"+std::to_string(getpid()));
    try{
        std::vector<ConstellationRecord> records(3);records[0].abbreviation="And";records[1].abbreviation="Ser";records[2].abbreviation="Ser";
        check(ConstellationArtModel::load(dir,records).records().empty(),"missing optional directory");
        std::filesystem::create_directories(dir/"constellations");
        for(const auto name:{"AND.cab","serh.cab","sert.cab","unknown.CAB"})write(dir/"constellations"/name);
        write(dir/"constellations"/"bad.cab",false);
        const auto model=ConstellationArtModel::load(dir,records);
        check(model.records().size()==4&&model.warnings().size()==2,"partial valid files or diagnostics lost");
        unsigned ser=0,unknown=0;
        for(const auto&r:model.records()){if(r.abbreviation=="Ser")++ser;if(!r.abbreviation)++unknown;check(r.art.source_bytes.size()==28,"source bytes not preserved");}
        check(ser==2&&unknown==1,"Ser duplicates or unknown association changed");
        records.push_back({});records.back().abbreviation="AND";
        const auto ambiguous=ConstellationArtModel::load(dir,records);
        check(!ambiguous.records().front().abbreviation,"ambiguous case-insensitive ID guessed");
        if(argc==2){
            const auto path=std::filesystem::path(argv[1]);
            std::vector<ConstellationRecord> constels;
            if(std::filesystem::exists(path/"constellation_HIP.dat"))
                constels=load_constellations(path/"constellation_HIP.dat");
            const auto local=ConstellationArtModel::load(path,constels);
            check(local.warnings().empty(),"local CAB load or association warning");
            std::size_t expected=0;
            if(std::filesystem::exists(path/"constellations"))
                for(const auto&e:std::filesystem::directory_iterator(path/"constellations"))if(e.path().extension()==".cab")++expected;
            check(local.records().size()==expected,"local CAB files dropped");
            for(const auto&r:local.records())check(r.abbreviation&&r.directions.size()==r.art.points.size(),"local source point not preserved");
        }
        std::filesystem::remove_all(dir);std::cout<<"Constellation art model tests passed: "<<checks<<" checks\n";
    }catch(const std::exception&e){std::filesystem::remove_all(dir);std::cerr<<"FAIL: "<<e.what()<<'\n';return 1;}
}
