#include "star_name_selection.hpp"
#include <iostream>
#include <stdexcept>
using namespace mitaka;
using namespace mitaka::gui;
namespace {
unsigned checks=0;
void check(bool b,const char* message) {++checks;if(!b)throw std::runtime_error(message);}
template<class F> void rejects(F f) {try{f();}catch(const std::invalid_argument&){++checks;return;}throw std::runtime_error("expected rejection");}
}
int main(int argc,char**argv) {
    try {
        std::vector<StarNameRecord> records{{1,true,"a",""},{2,false,"b",""},{3,true,"c",""}};
        StarNameSelection s(records);
        check(s.selected_hips()==std::set<std::int32_t>({1,3}),"featured initialization");
        check(!s.membership(-1)&&!s.membership(99),"unknown HIP query");
        s.set_selected({2,2},true);check(s.selected_hips().size()==3,"additive idempotent selection");
        s.set_selected({1},false);check(!s.membership(1)&&s.membership(2)&&s.membership(3),"subtractive selection");
        const auto before=s.selected_hips();rejects([&]{s.set_selected({2,999},false);});check(s.selected_hips()==before,"partial update on invalid HIP");
        rejects([&]{s.set_selection({1,999});});check(s.selected_hips()==before,"partial replacement on invalid HIP");
        s.set_all(false);check(s.selected_hips().empty(),"deselect all");s.set_all(true);check(s.selected_hips()==s.known_hips(),"select all");
        s.set_selection({2,3});
        const auto report=s.rebind({{1,true,"changed",""},{2,false,"b",""},{4,true,"d",""},{5,false,"e",""}});
        check(report.removed_selected_hips==std::set<std::int32_t>{3},"removed report");
        check(s.selected_hips()==std::set<std::int32_t>({2,4}),"rebind membership/new defaults");
        rejects([&]{s.rebind({{1,true,"a",""},{1,false,"b",""}});});
        check(s.selected_hips()==std::set<std::int32_t>({2,4}),"rebind rejection not atomic");
        rejects([&]{StarNameSelection bad({{0,false,"a",""}});});
        s.set_selection({});check(s.selected_hips().empty(),"empty replacement");
        if(argc==2 && std::filesystem::exists(argv[1])) {
            const auto loaded=load_star_names(argv[1]);StarNameSelection local(loaded);
            for(const auto& r:loaded)check(local.membership(r.hip)==r.is_featured,"local raw flag initialization");
            local.set_all(true);check(local.selected_hips().size()==loaded.size(),"local all HIP selection");
        } else if(argc==2) std::cout<<"Optional star name catalog absent\n";
        std::cout<<"Star name selection tests passed: "<<checks<<" checks\n";
    }catch(const std::exception&e){std::cerr<<"FAIL: "<<e.what()<<'\n';return 1;}
}
