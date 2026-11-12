#include "mitaka/small_body_catalog.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstring>
#include <fstream>
#include <iostream>
#include <limits>
#include <set>
#include <sstream>

namespace {
int checks=0;
void expect(bool value,const std::string& label) { ++checks; if(!value) throw std::runtime_error(label); }
void near(double actual,double wanted,double tolerance,const std::string& label) {
    expect(std::isfinite(actual)&&std::abs(actual-wanted)<=tolerance,label);
}
struct Fixture {
    std::filesystem::path root=std::filesystem::temp_directory_path()/
        ("mitaka-small-body-"+std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    Fixture() { std::filesystem::create_directories(root/"orbits/asteroids"); std::filesystem::create_directories(root/"orbits/comets"); }
    ~Fixture() { std::error_code ec; std::filesystem::remove_all(root,ec); }
    void write(const std::string& key,const std::string& bytes) {
        std::ofstream out(root/key,std::ios::binary); out.write(bytes.data(),static_cast<std::streamsize>(bytes.size()));
        if(!out) throw std::runtime_error("fixture write failed");
    }
};
template<class Bits> void append_bits(std::string& bytes,Bits value) {
    for(std::size_t i=0;i<sizeof value;++i) bytes.push_back(static_cast<char>((value>>(i*8))&255));
}
template<class Float,class Bits> void append_float(std::string& bytes,Float value) {
    Bits bits; static_assert(sizeof bits==sizeof value); std::memcpy(&bits,&value,sizeof bits); append_bits(bytes,bits);
}
std::string packed(std::int32_t id,bool flagged,std::uint8_t flag=0,float eccentricity=0.1F) {
    std::string bytes; append_bits(bytes,static_cast<std::uint32_t>(id));
    if(flagged) bytes.push_back(static_cast<char>(flag));
    append_float<double,std::uint64_t>(bytes,2451000.5);
    for(float value : {25.0F,73.0F,80.0F,10.0F,eccentricity,0.2F}) append_float<float,std::uint32_t>(bytes,value);
    return bytes;
}
const std::string halley="  1P/Halley                              49400  0.58597811 0.96714291 162.26269 111.33249  58.42008 19860205.89532 JPL J863/77\r\n";
const std::string asteroid="Name: Ceres\r\nDisplayName: \x83\x5a\x83\x8c\x83\x58\r\nNo: 1\r\nType: Asteroid\r\nEpoch: 2451000.5\r\na: 2.766180\r\ne: 0.077887\r\nw: 73.799240\r\nM0: 249.600143\r\ni: 10.582927\r\nnode: 80.501633\r\nSize: 500 500 500\r\n";
bool diagnostic(const std::vector<mitaka::SmallBodyDiagnostic>& list,mitaka::SmallBodyDiagnosticCode code) {
    return std::any_of(list.begin(),list.end(),[=](const auto& d){return d.code==code;});
}
const mitaka::SmallBodySource& source(const mitaka::SmallBodyDataset& data,const std::string& key) {
    const auto found=std::find_if(data.sources.begin(),data.sources.end(),[&](const auto& value){return value.key==key;});
    if(found==data.sources.end()) throw std::runtime_error("source absent: "+key); return *found;
}

void preservation() {
    using namespace mitaka;
    Fixture f;
    f.write("mp.dat",packed(1,false)+packed(1,false));
    f.write("mp2.dat",packed(1,true,255));
    f.write("TNO.dat",packed(-1,false)+packed(-1,false));
    f.write("TNO2.dat",packed(-1,true,2));
    f.write("comets.dat","# source\r\n"+halley+halley);
    f.write("orbits/asteroids/a.dat",asteroid);
    f.write("orbits/asteroids/a_jp.dat",asteroid);
    f.write("orbits/comets/a.dat","Name: Mixed\nq: 1\ne: 1\nw: 0\nnode: 0\ni: 0\nTp: 2450539.63709\n");
    f.write("small_objects_name.dat","1 D*Ceres  \x83\x5a\x83\x8c\x83\x58\n1 repeated alias\n-1 unnumbered alias\n");
    const auto data=load_small_body_dataset(f.root);
    expect(data.diagnostics.empty(),"valid sources");
    expect(data.records.size()==11,"all duplicate records retained");
    expect(data.sources.size()==9,"all sources retained");
    std::set<std::pair<std::string,std::size_t>> ids;
    for(const auto& r:data.records) {
        expect(ids.emplace(r.id.source_key,r.id.record_ordinal).second,"unique source ordinal ID");
        const auto& s=source(data,r.id.source_key);
        expect(s.bytes.substr(r.source_offset,r.raw_record_bytes.size())==r.raw_record_bytes,"exact record slice");
        if(r.number&&*r.number==1) expect(r.alias_bytes.size()==2,"repeated metadata names retained");
    }
    expect(data.records[2].raw_flag==255,"unknown flag preserved");
    expect(data.records[3].number==-1&&data.records[4].number==-1,"repeated -1 preserved");
    const auto& old=std::get<OrbitalElements>(data.records[0].orbit);
    near(old.mean_anomaly_deg,25,0,"binary M0"); near(old.argument_of_periapsis_deg,73,0,"binary w");
    expect(!evaluate_small_body(data.records[0],2451545).state,"unresolved frame never guessed");
    auto flagged=data.records[2];
    flagged.frame=SmallBodyFrame::heliocentric_j2000_ecliptic;
    flagged.time_scale=SmallBodyTimeScale::tdb;
    const auto flagged_state=evaluate_small_body(flagged,2451545);
    expect(!flagged_state.state&&diagnostic(flagged_state.diagnostics,SmallBodyDiagnosticCode::invalid_source),
           "resolved metadata cannot route packed37 through generic evaluation");
    expect(flagged.raw_record_bytes==data.records[2].raw_record_bytes&&flagged.raw_flag==255,
           "packed37 rejection preserves original bytes and flag");
    expect(data.records[8].display_name_bytes==std::string("\x83\x5a\x83\x8c\x83\x58"),"CP932 retained");
    expect(diagnostic(data.records[10].diagnostics,SmallBodyDiagnosticCode::unresolved_perihelion_time),"mixed Tp diagnosed");
    expect(source(data,"mp.dat").bytes==packed(1,false)+packed(1,false),"entire original bytes");
}

void packed_37_contract() {
    using namespace mitaka;
    Fixture f;
    f.write("mp.dat", packed(12, false));
    f.write("TNO.dat", packed(12, false));
    const std::string mp37 = packed(12, true, 1);
    const std::string tno37 = packed(12, true, 2);
    for (const std::string& key : {std::string("mp2.dat"), std::string("TNO2.dat")}) {
        for (std::size_t trailing = 1; trailing < 37; ++trailing) {
            f.write("mp2.dat", mp37);
            f.write("TNO2.dat", tno37);
            const std::string malformed = mp37 + mp37.substr(0, trailing);
            f.write(key, malformed);
            const auto data = load_small_body_dataset(f.root);
            const auto& bad = source(data, key);
            expect(!bad.loaded && bad.record_count == 0 && bad.bytes == malformed,
                   "truncated 37-byte source rejected atomically and preserved");
            expect(data.records.size() == 3, "other packed sources still load");
            expect(std::none_of(data.records.begin(), data.records.end(), [&](const auto& r) {
                return r.id.source_key == key;
            }), "partial 37-byte source yields no rows");
            expect(std::any_of(data.diagnostics.begin(), data.diagnostics.end(), [&](const auto& d) {
                return d.source_key == key && d.code == SmallBodyDiagnosticCode::invalid_source;
            }), "truncated source diagnosed by identity");
        }
    }
    std::string flags;
    for (unsigned flag : {0U, 1U, 2U, 127U, 128U, 255U}) flags += packed(12, true, static_cast<std::uint8_t>(flag));
    f.write("mp2.dat", flags);
    f.write("TNO2.dat", tno37);
    const auto data = load_small_body_dataset(f.root);
    std::size_t ordinal = 0;
    for (auto record : data.records) {
        if (record.id.source_key != "mp2.dat") continue;
        expect(record.id.record_ordinal == ordinal, "duplicate numbers keep source ordinal identity");
        expect(record.raw_record_bytes == flags.substr(ordinal * 37, 37), "flag row retained byte for byte");
        expect(record.raw_flag && *record.raw_flag == static_cast<std::uint8_t>(flags[ordinal * 37 + 4]),
               "unsigned flag values retained without meaning inference");
        record.frame = SmallBodyFrame::heliocentric_j2000_ecliptic;
        record.time_scale = SmallBodyTimeScale::tdb;
        const auto result = evaluate_small_body(record, 2451545.0);
        expect(!result.state, "37-byte position remains unavailable even with caller-provided frame and time scale");
        expect(diagnostic(result.diagnostics, SmallBodyDiagnosticCode::invalid_source),
               "unresolved 37-byte position contract diagnosed");
        ++ordinal;
    }
    expect(ordinal == 6, "all raw flags retained");
}

void time_and_evaluation() {
    using namespace mitaka;
    Fixture f; f.write("comets.dat",halley);
    auto data=load_small_body_dataset(f.root);
    expect(data.records.size()==1,"Halley loads independently");
    auto r=data.records.front();
    near(*r.epoch_value,49400,0,"raw MJD retained");
    const auto orbit=std::get<PerihelionElements>(r.orbit);
    const double tp=julian_date({1986,2,5,0,0,0})+0.89532;
    near(orbit.perihelion_jd,tp,1e-10,"calendar Tp precision");
    const auto state=evaluate_small_body(r,tp);
    expect(state.state.has_value(),"confirmed comet evaluatable");
    near(std::hypot(state.state->position_au.x,std::hypot(state.state->position_au.y,state.state->position_au.z)),0.58597811,1e-12,"perihelion radius");
    expect(diagnostic(state.diagnostics,SmallBodyDiagnosticCode::unknown_accuracy_range),"accuracy interval disclosed");
    expect(!evaluate_small_body(r,std::numeric_limits<double>::infinity()).state,"infinite time rejected");
    r.declared_time_range=SmallBodyTimeRange{tp-1,tp+1};
    expect(evaluate_small_body(r,tp-1).state.has_value(),"range first inclusive");
    expect(evaluate_small_body(r,tp+1).state.has_value(),"range last inclusive");
    expect(diagnostic(evaluate_small_body(r,tp+2).diagnostics,SmallBodyDiagnosticCode::outside_time_range),"outside range diagnosed");
    r.declared_time_range=SmallBodyTimeRange{tp+1,tp-1};
    expect(!evaluate_small_body(r,tp).state,"invalid range rejected");
    auto old=halley; old.replace(100,14,"-1460628.00000"); old.insert(113,1,' ');
    f.write("comets.dat",old+halley);
    data=load_small_body_dataset(f.root);
    expect(data.records.size()==2,"historical record preserved");
    expect(!evaluate_small_body(data.records[0],2451545).state,"historical calendar not guessed");
    expect(diagnostic(data.records[0].diagnostics,SmallBodyDiagnosticCode::unresolved_historical_calendar),"historical calendar reason");
    expect(evaluate_small_body(data.records[1],2451545).state.has_value(),"historical row does not block known row");
}

void malformed_and_limits() {
    using namespace mitaka;
    Fixture f; f.write("mp.dat",packed(1,false)+"x"); f.write("mp2.dat",packed(2,true));
    f.write("orbits/asteroids/bad.dat",asteroid+"No: 2\n");
    f.write("orbits/asteroids/good.dat",asteroid);
    auto data=load_small_body_dataset(f.root);
    expect(data.records.size()==2,"invalid sources isolated");
    expect(!source(data,"mp.dat").loaded&&source(data,"mp.dat").bytes.size()==37,"invalid bytes retained");
    expect(diagnostic(data.diagnostics,SmallBodyDiagnosticCode::invalid_source),"invalid source reported");
    expect(diagnostic(data.diagnostics,SmallBodyDiagnosticCode::missing_source),"missing source reported");
    f.write("mp.dat",packed(1,false)+packed(1,false));
    data=load_small_body_dataset(f.root,{1024,1});
    expect(data.records.size()==1&&data.records[0].id.source_key=="mp2.dat","per-source atomic total record limit");
    data=load_small_body_dataset(f.root,{35,100});
    expect(data.records.empty(),"file byte limit");
    f.write("mp.dat",packed(1,false,false,std::numeric_limits<float>::quiet_NaN()));
    data=load_small_body_dataset(f.root);
    expect(!source(data,"mp.dat").loaded,"NaN binary rejected");
    f.write("small_objects_name.dat","1 valid alias\ninvalid\n");
    data=load_small_body_dataset(f.root);
    for(const auto& r:data.records) expect(r.alias_bytes.empty(),"name file failure atomic");
    auto bad=halley; bad.replace(100,14,"19860230.00000 "); f.write("comets.dat",halley+bad);
    data=load_small_body_dataset(f.root);
    expect(!source(data,"comets.dat").loaded&&source(data,"comets.dat").record_count==0,"bad calendar whole-source failure");
    f.write("comets.dat","");
    data=load_small_body_dataset(f.root);
    expect(source(data,"comets.dat").loaded,"empty source accepted");
}

void explicit_mean_motion() {
    using namespace mitaka;
    Fixture f;
    const std::string base = "Name: Custom\r\nType: Asteroid\r\nNo: -1\r\nEpoch: 2451545\r\n"
                             "a: 2\r\ne: 0\r\nw: 0\r\nM0: 0\r\ni: 0\r\nnode: 0\r\n";
    const std::string explicit_bytes = base + "n: 90\r\n";
    f.write("orbits/asteroids/good.dat", explicit_bytes);
    f.write("orbits/asteroids/derived.dat", base);
    auto data = load_small_body_dataset(f.root);
    expect(data.records.size() == 2, "explicit and derived motion rows load independently");
    for (const auto& record : data.records) {
        const bool explicit_n = record.id.source_key == "orbits/asteroids/good.dat";
        const auto& bytes = explicit_n ? explicit_bytes : base;
        expect(record.raw_record_bytes == bytes && source(data, record.id.source_key).bytes == bytes,
               "source and record bytes preserved");
        const auto& orbit = std::get<OrbitalElements>(record.orbit);
        near(orbit.mean_motion_deg_per_day, explicit_n ? 90 : 0.985607669 / 2 / std::sqrt(2),
             1e-15, "explicit n takes precedence; a alone retains derived motion");
        if (explicit_n) {
            expect(std::any_of(record.fields.begin(), record.fields.end(), [](const auto& field) {
                return field.key == "n" && field.value_bytes == "90";
            }), "explicit n original field retained");
            expect(std::none_of(record.diagnostics.begin(), record.diagnostics.end(), [](const auto& d) {
                return d.code == SmallBodyDiagnosticCode::unknown_field && d.field == "n";
            }), "supported n is not diagnosed as unknown");
        }
    }
    for (const std::string suffix : {"n: 0\r\n", "n: -1\r\n", "n: nan\r\n", "n: inf\r\n",
                                     "n: 1e999\r\n", "n: invalid\r\n", "n: 90 trailing\r\n",
                                     "n: 90\r\nn: 90\r\n"}) {
        const auto bad = base + suffix;
        f.write("orbits/asteroids/bad.dat", bad);
        data = load_small_body_dataset(f.root);
        const auto& input = source(data, "orbits/asteroids/bad.dat");
        expect(!input.loaded && input.record_count == 0 && input.bytes == bad,
               "invalid or duplicate n rejects source and retains bytes");
        expect(std::none_of(data.records.begin(), data.records.end(), [](const auto& record) {
            return record.id.source_key == "orbits/asteroids/bad.dat";
        }), "invalid source produces no record");
        expect(std::any_of(data.diagnostics.begin(), data.diagnostics.end(), [](const auto& d) {
            return d.source_key == "orbits/asteroids/bad.dat" && d.code == SmallBodyDiagnosticCode::invalid_source;
        }), "invalid n identified by source");
        expect(data.records.size() == 2, "invalid n does not block other sources");
    }
}

void derived_mean_motion_limits() {
    using namespace mitaka;
    Fixture f;
    f.write("orbits/asteroids/good.dat",asteroid);
    for (const std::string axis : {"1e-300", "1e300", "1e216"}) {
        auto bytes = asteroid;
        const auto start = bytes.find("a: 2.766180");
        bytes.replace(start, std::string("a: 2.766180").size(), "a: " + axis);
        f.write("orbits/asteroids/bad.dat",bytes);
        const auto data = load_small_body_dataset(f.root);
        const auto& bad = source(data,"orbits/asteroids/bad.dat");
        expect(!bad.loaded && bad.record_count == 0 && bad.bytes == bytes,
               "non-finite or zero derived motion rejects source but preserves bytes");
        expect(std::any_of(data.diagnostics.begin(),data.diagnostics.end(),[](const auto& d) {
            return d.source_key == "orbits/asteroids/bad.dat"
                && d.code == SmallBodyDiagnosticCode::invalid_source
                && d.message.find("derived mean motion") != std::string::npos;
        }),"derived motion failure identifies the bad source");
        expect(data.records.size() == 1 && data.records.front().id.source_key == "orbits/asteroids/good.dat",
               "invalid derived motion does not block the next source");
        const auto& good = data.records.front();
        const auto& orbit = std::get<OrbitalElements>(good.orbit);
        expect(good.raw_record_bytes == asteroid && std::isfinite(orbit.mean_motion_deg_per_day)
               && orbit.mean_motion_deg_per_day > 0,"ordinary axis retains original bytes and positive motion");
    }
}

void real_data(const std::filesystem::path& path) {
    using namespace mitaka;
    const auto data=load_small_body_dataset(path);
    for(const auto& d:data.diagnostics) std::cerr<<d.source_key<<": "<<d.message<<'\n';
    expect(data.diagnostics.empty(),"real sources complete");
    std::size_t evaluatable=0,elliptic=0,parabolic=0,hyperbolic=0,unresolved37=0;
    for(const auto& r:data.records) {
        const auto& s=source(data,r.id.source_key);
        expect(s.bytes.substr(r.source_offset,r.raw_record_bytes.size())==r.raw_record_bytes,"real record source match");
        if (r.encoding == SmallBodyEncoding::packed_37) {
            expect(r.raw_record_bytes.size() == 37 && r.raw_flag.has_value(), "real 37-byte row and flag retained");
            auto attempted = r;
            attempted.frame = SmallBodyFrame::heliocentric_j2000_ecliptic;
            attempted.time_scale = SmallBodyTimeScale::tdb;
            const auto evaluated = evaluate_small_body(attempted, 2451545.0);
            expect(!evaluated.state && diagnostic(evaluated.diagnostics, SmallBodyDiagnosticCode::invalid_source),
                   "real 37-byte row remains unresolved even after frame and time assignment");
            ++unresolved37;
        }
        if(const auto* e=std::get_if<PerihelionElements>(&r.orbit)) {
            const auto evaluated=evaluate_small_body(r,e->perihelion_jd);
            expect(evaluated.state.has_value(),"real comet perihelion calculation");
            ++evaluatable;
            if(e->eccentricity<1) ++elliptic; else if(e->eccentricity==1) ++parabolic; else ++hyperbolic;
            for(double jd:{2415020.5,2451545.0,2488069.5}) expect(evaluate_small_body(r,jd).state.has_value(),"real comet finite state across GUI interval");
        }
    }
    expect(unresolved37 > 0, "real 37-byte sources exercised");
    std::cout<<"small-body real data: sources="<<data.sources.size()<<" records="<<data.records.size()
             <<" unresolved37="<<unresolved37<<" evaluatable="<<evaluatable<<" elliptic="<<elliptic<<" parabolic="<<parabolic<<" hyperbolic="<<hyperbolic<<'\n';
}
} // namespace
int main(int argc,char** argv) {
    try {
        preservation(); packed_37_contract(); time_and_evaluation(); malformed_and_limits(); explicit_mean_motion(); derived_mean_motion_limits();
        if(argc==2) real_data(argv[1]);
        std::cout<<"small-body catalog: "<<checks<<" checks passed\n";
    } catch(const std::exception& error) { std::cerr<<"small-body catalog failure: "<<error.what()<<'\n'; return 1; }
}
