#include "mitaka/satellite_absolute.hpp"
#include "mitaka/lunar.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstring>
#include <fstream>
#include <iostream>
#include <limits>
#include <set>
#include <stdexcept>

namespace {
using namespace mitaka;
constexpr double jd = 2451545;
int checks = 0;
void expect(bool value, const std::string& label) {
    ++checks;
    if (!value) throw std::runtime_error(label);
}
void near(double a, double b, const std::string& label) {
    expect(std::isfinite(a) && std::abs(a-b) <= 2e-12 * std::max(1.0, std::abs(b)), label);
}
void position(const std::optional<Vec3>& actual, Vec3 expected, const std::string& label) {
    expect(actual.has_value(), label + " available");
    near(actual->x, expected.x, label + " x");
    near(actual->y, expected.y, label + " y");
    near(actual->z, expected.z, label + " z");
}
Vec3 add(Vec3 a, Vec3 b) { return {a.x+b.x,a.y+b.y,a.z+b.z}; }
Vec3 scale(Vec3 a, double factor) { return {a.x*factor,a.y*factor,a.z*factor}; }
// 独立な既知の X 軸回転で、CF96 赤道出力からの符号・単位を検証する。
Vec3 ecliptic(Vec3 a) {
    const double angle = 23.43929111111111 * std::acos(-1.0) / 180;
    return {a.x,a.y*std::cos(angle)+a.z*std::sin(angle),-a.y*std::sin(angle)+a.z*std::cos(angle)};
}
bool has(const std::vector<SatelliteAbsoluteDiagnostic>& items, SatelliteAbsoluteDiagnosticCode code) {
    return std::any_of(items.begin(),items.end(),[=](const auto& item) { return item.code == code; });
}
void integer(std::string& bytes, std::uint32_t n) {
    for (int i=0;i<4;++i) bytes.push_back(static_cast<char>((n >> (i*8)) & 255));
}
void real(std::string& bytes, double n) {
    std::uint64_t bits; std::memcpy(&bits,&n,sizeof(bits));
    for (int i=0;i<8;++i) bytes.push_back(static_cast<char>((bits >> (i*8)) & 255));
}
std::string cf96(const std::vector<Vec3>& parents, double start=jd-1, double span=2) {
    std::string bytes = "CF96"; integer(bytes,static_cast<std::uint32_t>(parents.size()));
    for (const auto p : parents) {
        real(bytes,start); real(bytes,span); integer(bytes,0); integer(bytes,1); integer(bytes,1);
        integer(bytes,0);
        for (const double axis : {p.x,p.y,p.z}) {
            integer(bytes,2); real(bytes,axis*1e10); real(bytes,0);
            integer(bytes,1); integer(bytes,0);
        }
    }
    return bytes;
}
std::string orbit(char plane='E', int node=0) {
    return "Epoch: 2451545\na: 100\ne: 0\nM0: 0\nn: 90\nw: 0\ni: 0\nnode: " +
        std::to_string(node) + "\nPw: 0\nPnode: 0\nRefPlane: " + plane + "\n";
}
std::string satellite(const std::string& name, const std::string& file="e.dat") {
    return "Satellite\n{\nName: " + name + "\nOrbit: ./data/orbits/" + file + "\n}\n";
}
std::string planet(const std::string& name, const std::string& satellites) {
    return "Planet\n{\nName: " + name + "\nOrbit: ./data/orbits/parent.dat\n" + satellites + "}\n";
}
std::string system(const std::string& planets) { return "Ssystem\n{\nSun\n{\nName: Sun\n"+planets+"}\n}\n"; }
struct Fixture {
    std::filesystem::path root = std::filesystem::temp_directory_path() /
        ("mitaka-satellite-absolute-"+std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    Fixture() {
        std::filesystem::create_directories(root/"data/orbits");
        write("orbits/parent.dat",""); write("orbits/e.dat",orbit());
        write("orbits/rotated.dat",orbit('E',90)); write("orbits/l.dat",orbit('L'));
        write("orbits/c.dat",orbit('C'));
    }
    ~Fixture() { std::error_code error; std::filesystem::remove_all(root,error); }
    void write(const std::string& key,const std::string& bytes) const {
        std::ofstream output(root/"data"/key,std::ios::binary);
        output.write(bytes.data(),static_cast<std::streamsize>(bytes.size()));
        if (!output) throw std::runtime_error("fixture write failed");
    }
    Cf96Ephemeris ephemeris(std::vector<Vec3> parents={{1,2,3},{10,20,30},{100,200,300}}) const {
        write("cf96.dat",cf96(parents)); return Cf96Ephemeris::load(root/"data/cf96.dat");
    }
    SatelliteDataset data() const { return load_satellite_dataset(root/"data"); }
};
SatelliteModel model(SatelliteDataset data) {
    std::set<std::string> keys;
    for (const auto& definition : data.definitions) keys.insert(definition.id.source_key);
    std::vector<VerifiedSatelliteRegistration> registrations;
    for (const auto& key : keys) {
        auto candidate = make_isolated_satellite_registration(data,key);
        expect(candidate.registration.has_value(),"fixture native registration resolved");
        registrations.push_back(std::move(*candidate.registration));
    }
    return SatelliteModel(std::move(data),std::move(registrations));
}
SatelliteAbsoluteContext context(double time=jd) {
    return {"ssystem.dat","fixture channels deliberately use successful Planet registration order",
        SatelliteAbsoluteMoonInput{time,{0,200,300},"fixture analytic Moon vector; scale 1"}};
}
void fixture_pairs() {
    Fixture f;
    const auto bytes = system(planet("Earth",satellite("Moon")+satellite("Other"))+
        planet("Pluto",satellite("Charon")+satellite("Charon","rotated.dat")+
            satellite("Nix","c.dat")+satellite("Hydra"))+planet("Jupiter",satellite("Io")));
    f.write("ssystem.dat",bytes); f.write("ssystem_jp.dat",bytes);
    const auto m = model(f.data()); const auto ephem = f.ephemeris();
    const auto result = evaluate_satellite_absolute(m,ephem,jd,context());
    expect(result.positions.size()==m.records().size() && result.positions.size()==14,"all source rows retained");
    expect(result.planets.size()==3,"selected source Planet container only");
    expect(result.registration && result.registration->origin==SatelliteRegistrationOrigin::isolated_native_source &&
        !result.registration->evidence.empty(),"owned registration provenance retained");
    expect(result.relative.positions.size()==result.positions.size(),"relative diagnostics retained");
    const auto earth = ecliptic({1,2,3}), pluto=ecliptic({10,20,30});
    const auto moon=scale({0,200,300},1/satellite_km_per_au), x=scale({100,0,0},1/satellite_km_per_au);
    position(result.planets[0].uncorrected_position_au,earth,"raw Earth not pre-corrected");
    position(result.planets[0].position_au,add(earth,scale(moon,-legacy_earth_moon_mass_fraction)),"Earth correction once");
    position(result.positions[0].position_au,add(earth,scale(moon,1-legacy_earth_moon_mass_fraction)),"Moon correction once");
    position(result.positions[1].position_au,add(earth,x),"other Earth satellite keeps uncorrected parent");
    position(result.planets[1].uncorrected_position_au,pluto,"raw Pluto retained");
    position(result.planets[1].position_au,add(pluto,scale(x,-2.0/27)),"Pluto correction once");
    position(result.positions[2].position_au,add(pluto,scale(x,25.0/27)),"first Charon corrected");
    position(result.positions[3].position_au,add(pluto,scale({0,100,0},1/satellite_km_per_au)),"duplicate Charon remains uncorrected");
    position(result.positions[4].position_au,add(pluto,x),"Nix C basis and uncorrected center");
    position(result.positions[5].position_au,add(pluto,x),"Hydra uncorrected center");
    position(result.positions[6].position_au,add(ecliptic({100,200,300}),x),"ordinary parent axes");
    for (std::size_t i=0;i<result.positions.size();++i) {
        expect(result.positions[i].definition_index==m.records()[i].definition_index,"definition index correspondence");
        expect(result.positions[i].pair_correction_applied==(i==0 || i==2),"only first named satellites corrected");
        if (i>=7) expect(!result.positions[i].position_au && has(result.positions[i].diagnostics,
            SatelliteAbsoluteDiagnosticCode::unselected_source),"unselected language source diagnosed");
    }
    const auto again=evaluate_satellite_absolute(m,ephem,jd,context());
    position(again.positions[2].position_au,*result.positions[2].position_au,"repeat is pure and idempotent");
    auto jp=context(); jp.source_key="ssystem_jp.dat";
    const auto translated=evaluate_satellite_absolute(m,ephem,jd,jp);
    position(translated.positions[9].position_au,*result.positions[2].position_au,"source independently selected");
    expect(!translated.positions[2].position_au,"previous source not implicitly combined");
    expect(has(result.diagnostics,SatelliteAbsoluteDiagnosticCode::unresolved_time_scale) &&
        has(result.diagnostics,SatelliteAbsoluteDiagnosticCode::unknown_accuracy_range),"successful results retain limits");
    expect(!result.relative.positions[0].relative_position_km,"Moon never supplied by Kepler");
}
void partial_failures() {
    Fixture f;
    f.write("ssystem.dat",system(planet("Earth",satellite("Moon")+satellite("Other"))+
        planet("Pluto",satellite("Charon","l.dat")+satellite("Nix"))+planet("Jupiter",satellite("Io"))));
    const auto m=model(f.data()); const auto ephem=f.ephemeris();
    auto c=context(); c.moon.reset();
    const auto result=evaluate_satellite_absolute(m,ephem,jd,c);
    expect(!result.positions[0].position_au && !result.planets[0].position_au,"missing Moon does not invent Earth center");
    expect(result.planets[0].uncorrected_position_au.has_value(),"missing Moon leaves raw Earth for ordinary satellites");
    expect(!result.positions[2].position_au && !result.planets[1].position_au,"unresolved Charon does not invent Pluto center");
    expect(result.positions[1].position_au && result.positions[3].position_au && result.positions[4].position_au,
        "independent ordinary satellites survive failed pairs");
    expect(has(result.planets[1].diagnostics,SatelliteAbsoluteDiagnosticCode::unavailable_pair_correction),"failed pair diagnosed");
    for (int invalid=0;invalid<3;++invalid) {
        c=context();
        if (invalid==0) c.moon->legacy_julian_date+=1;
        if (invalid==1) c.moon->evidence.clear();
        if (invalid==2) c.moon->geocentric_j2000_ecliptic_km.x=std::numeric_limits<double>::quiet_NaN();
        const auto rejected=evaluate_satellite_absolute(m,ephem,jd,c);
        expect(has(rejected.diagnostics,SatelliteAbsoluteDiagnosticCode::invalid_moon) &&
            !rejected.positions[0].position_au && rejected.positions[4].position_au,"invalid Moon isolated to affected pair");
    }
    f.write("ssystem.dat",system(planet("Pluto",satellite("Nix"))+planet("Earth",satellite("Other"))));
    const auto no_pair=evaluate_satellite_absolute(model(f.data()),ephem,jd,context());
    position(no_pair.planets[0].position_au,ecliptic({1,2,3}),"absent Charon means no original pair correction");
    position(no_pair.planets[1].position_au,ecliptic({10,20,30}),"absent Moon means no original pair correction");
    expect(!no_pair.planets[0].pair_correction_applied,"absent pair not marked applied");
    f.write("ssystem.dat",system(planet("Jupiter",satellite("Charon"))+planet("Pluto",satellite("Nix"))));
    const auto missing_parent=evaluate_satellite_absolute(model(f.data()),f.ephemeris({{1,2,3}}),jd,context());
    expect(missing_parent.relative.positions[0].relative_position_km.has_value(),"Charon relative is available before failed correction");
    expect(!missing_parent.positions[0].position_au &&
        has(missing_parent.positions[0].diagnostics,SatelliteAbsoluteDiagnosticCode::unavailable_pair_correction),
        "failed named Pluto pair never exposes uncorrected Charon as final position");
    f.write("ssystem.dat",system(planet("Pluto",satellite("Charon")+satellite("Nix"))+planet("Jupiter",satellite("Io"))));
    auto incomplete=f.data();
    for (auto& definition : incomplete.definitions) {
        if (definition.kind!=SatelliteDefinitionKind::planet) continue;
        const auto* name=unique_satellite_field(definition.fields,"Name");
        if (!name || name->value_bytes!="Jupiter") continue;
        definition.fields.erase(std::remove_if(definition.fields.begin(),definition.fields.end(),
            [](const auto& field) {return field.key=="Name";}),definition.fields.end());
    }
    const auto uncertain=evaluate_satellite_absolute(model(std::move(incomplete)),ephem,jd,context());
    expect(!uncertain.positions[0].position_au && uncertain.positions[1].position_au,
        "uncertain named lookup suppresses first Charon but preserves Nix pre-center");
    expect(!uncertain.planets[1].position_au && uncertain.planets[1].uncorrected_position_au,
        "unknown planet identifier is not published as a corrected center");
}
void names_and_boundaries() {
    Fixture f;
    // Moon 専用経路の Earth 検索と重複名の先頭一致は構造親とは別。
    f.write("ssystem.dat",system(planet("Earth",satellite("Other"))+planet("Pluto",satellite("Moon"))+
        planet("Earth",satellite("Moon"))));
    const auto m=model(f.data()); const auto ephem=f.ephemeris();
    const auto result=evaluate_satellite_absolute(m,ephem,jd,context());
    const auto moon=scale({0,200,300},1/satellite_km_per_au);
    position(result.positions[1].position_au,add(ecliptic({1,2,3}),scale(moon,1-legacy_earth_moon_mass_fraction)),"Moon uses first Earth despite structural Pluto");
    position(result.positions[2].position_au,add(ecliptic({1,2,3}),moon),"second Moon remains uncorrected");
    position(result.planets[2].position_au,ecliptic({100,200,300}),"second Earth remains uncorrected");
    auto incomplete=f.data();
    auto& fields=incomplete.definitions[result.planets[2].definition_index].fields;
    fields.erase(std::remove_if(fields.begin(),fields.end(),[](const auto& field) {return field.key=="Name";}),fields.end());
    const auto unknown=evaluate_satellite_absolute(model(std::move(incomplete)),ephem,jd,context());
    expect(has(unknown.diagnostics,SatelliteAbsoluteDiagnosticCode::unresolved_special_lookup),"missing name prevents assumed first lookup");
    expect(!unknown.planets[0].position_au && !unknown.positions[1].position_au,"unknown identifier prevents special correction");
    expect(unknown.positions[0].position_au.has_value(),"ordinary record survives incomplete special-name lookup");
    for (const double time : {jd-1,jd+1}) {
        const auto edge=evaluate_satellite_absolute(m,ephem,time,context(time));
        expect(edge.positions[0].position_au.has_value(),"CF96 coverage endpoint included");
    }
    for (const double time : {jd-1.01,jd+1.01}) {
        const auto outside=evaluate_satellite_absolute(m,ephem,time,context(time));
        for (const auto& p : outside.positions) expect(!p.position_au,"no extrapolated absolute outside CF96");
        expect(has(outside.planets[0].diagnostics,SatelliteAbsoluteDiagnosticCode::outside_ephemeris),"range failure diagnosed");
    }
    auto c=context(); c.cf96_binding_evidence.clear();
    expect(has(evaluate_satellite_absolute(m,ephem,jd,c).diagnostics,SatelliteAbsoluteDiagnosticCode::invalid_context),"no guessed CF96 binding");
    c=context(); c.source_key="absent.dat";
    expect(has(evaluate_satellite_absolute(m,ephem,jd,c).diagnostics,SatelliteAbsoluteDiagnosticCode::unresolved_registration),"unknown source unresolved");
    const SatelliteModel no_proof(f.data());
    const auto unverified=evaluate_satellite_absolute(no_proof,ephem,jd,context());
    expect(unverified.positions.size()==m.records().size() && unverified.planets.empty() &&
        has(unverified.diagnostics,SatelliteAbsoluteDiagnosticCode::unresolved_registration),"registration never inferred by absolute evaluator");
    const auto invalid=evaluate_satellite_absolute(m,ephem,std::numeric_limits<double>::infinity(),context());
    expect(invalid.positions.size()==m.records().size() && has(invalid.diagnostics,SatelliteAbsoluteDiagnosticCode::invalid_context),"nonfinite time retains rows and diagnostic");
    const auto missing=evaluate_satellite_absolute(m,f.ephemeris({{1,2,3}}),jd,context());
    expect(!missing.planets[2].position_au && missing.positions[0].position_au,"missing CF96 channel isolated by registered index");
}
void legacy_branch_boundaries() {
    constexpr double minimum=2415020.5, maximum=2487980.5;
    expect(legacy_satellite_cf96_minimum_jd==minimum && legacy_satellite_cf96_maximum_jd==maximum,
        "audited legacy CF96 endpoints are retained exactly");
    Fixture f;
    f.write("ssystem.dat",system(planet("Earth",satellite("Moon")+satellite("Other"))+
        planet("Pluto",satellite("Charon")+satellite("Nix"))));
    const std::vector<Vec3> raw{{1,2,3},{10,20,30}};
    f.write("cf96.dat",cf96(raw,minimum-2,maximum-minimum+4));
    const auto ephem=Cf96Ephemeris::load(f.root/"data/cf96.dat");
    const auto m=model(f.data());
    // 係数ブロックが広くても既存 CF96 の利用期間制限と旧分岐の診断を維持する。
    expect(ephem.time_range(0)==std::make_pair(minimum,maximum),"CF96 already restricts wider coefficient coverage");
    for (const double boundary : {minimum,maximum}) {
        for (const double time : {std::nextafter(boundary,-std::numeric_limits<double>::infinity()),
                                 boundary,std::nextafter(boundary,std::numeric_limits<double>::infinity())}) {
            const bool inside=time>=minimum && time<=maximum;
            const auto result=evaluate_satellite_absolute(m,ephem,time,context(time));
            expect(result.registration.has_value() && result.planets.size()==raw.size() &&
                result.positions.size()==m.records().size(),"branch boundary preserves source and row identities");
            expect(has(result.diagnostics,SatelliteAbsoluteDiagnosticCode::unverified_ephemeris_branch)==!inside,
                "branch refusal is distinct from file coverage");
            for (std::size_t i=0;i<raw.size();++i) {
                if (inside) {
                    const auto file_position=ephem.state(i,time).position_au;
                    near(file_position[0],raw[i].x,"included adjacent representable date has CF96 position");
                } else {
                    bool rejected=false;
                    try { (void)ephem.state(i,time); }
                    catch (const std::out_of_range&) { rejected=true; }
                    expect(rejected,"CF96 independently rejects outside adjacent representable date");
                }
                const auto& parent=result.planets[i];
                expect(!has(parent.diagnostics,SatelliteAbsoluteDiagnosticCode::outside_ephemeris),
                    "legacy branch refusal is diagnosed before generic coverage failure");
                expect(has(parent.diagnostics,SatelliteAbsoluteDiagnosticCode::unverified_ephemeris_branch)==!inside,
                    "parent carries exact branch refusal reason");
                if (inside) {
                    position(parent.uncorrected_position_au,ecliptic(raw[i]),"included branch endpoint retains raw CF96");
                    expect(parent.position_au.has_value(),"included branch endpoint publishes corrected parent");
                } else expect(!parent.uncorrected_position_au && !parent.position_au,
                    "unverified branch never publishes raw or corrected absolute parent");
            }
            for (std::size_t i=0;i<m.records().size();++i) {
                const auto& p=result.positions[i];
                expect(p.definition_index==m.records()[i].definition_index,
                    "branch boundary preserves satellite record mapping");
                expect(p.position_au.has_value()==inside,"only included branch dates publish absolute satellites");
                if (!inside) expect(has(p.diagnostics,SatelliteAbsoluteDiagnosticCode::unresolved_parent),
                    "unverified parent leaves satellite diagnostic");
            }
        }
    }
}
void local_data(const std::filesystem::path& data_root) {
    const auto m=model(load_satellite_dataset(data_root));
    const auto ephem=Cf96Ephemeris::load(data_root/"cf96.dat");
    const auto lunar=scale(j2000_equatorial_to_ecliptic(lunar_position(jd)),satellite_km_per_au);
    for (const auto& registration : m.registration_contexts()) {
        SatelliteAbsoluteContext c{registration.source_key,"integration test binds selected input Planet order to local CF96 channels",
            SatelliteAbsoluteMoonInput{jd,lunar,"native Mitaka 1.3.1 lunar_position, physical distance scale 1; not old Plus settings"}};
        const auto result=evaluate_satellite_absolute(m,ephem,jd,c);
        expect(result.positions.size()==m.records().size(),"local rows retained independently of position success");
        for (std::size_t i=0;i<result.planets.size();++i) {
            const auto& p=result.planets[i];
            if (p.registration_index.value>=ephem.planet_count()) continue;
            const auto raw=ephem.state(p.registration_index.value,jd).position_au;
            position(p.uncorrected_position_au,ecliptic({raw[0],raw[1],raw[2]}),"local uncorrected CF96 parent");
        }
        std::size_t evaluated=0;
        for (std::size_t i=0;i<m.records().size();++i) {
            const auto& record=m.records()[i]; const auto& p=result.positions[i];
            expect(p.definition_index==record.definition_index,"local source-row identity retained");
            if (m.dataset().definitions[record.definition_index].id.source_key!=c.source_key)
                expect(!p.position_au,"other local source never implicitly merged");
            if (p.position_au) ++evaluated;
            else expect(!p.diagnostics.empty() || !result.diagnostics.empty(),"unavailable local row has diagnostic");
        }
        std::cout<<"satellite absolute source="<<c.source_key<<" retained="<<result.positions.size()<<" positions="<<evaluated<<'\n';
    }
}
} // namespace
int main(int argc,char** argv) {
    try {
        fixture_pairs(); partial_failures(); names_and_boundaries(); legacy_branch_boundaries();
        if (argc>1) local_data(argv[1]);
        std::cout<<"satellite absolute: "<<checks<<" checks passed\n";
    } catch (const std::exception& error) {
        std::cerr<<"satellite absolute test: "<<error.what()<<'\n'; return 1;
    }
}
