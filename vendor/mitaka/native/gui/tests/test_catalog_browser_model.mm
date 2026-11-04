#include "catalog_browser_model.hpp"
#import <Foundation/Foundation.h>
#include <chrono>
#include <iostream>
#include <stdexcept>

using namespace mitaka::gui;
namespace {
unsigned checks = 0;
void require(bool value, const char *message) {
    ++checks;
    if (!value) throw std::runtime_error(message);
}
template<class Exception, class Function> void rejects(Function test, const char *message) {
    try { test(); } catch (const Exception&) { require(true, message); return; }
    require(false, message);
}
void syntheticTests() {
    auto catalogs = std::make_shared<ExtendedCatalogs>();
    catalogs->ngc.push_back({224, true, {10.5, 41.3}, mitaka::DeepSkyKind::galaxy, 20, 4, false});
    catalogs->ngc.push_back({224, false, {20, 10}, mitaka::DeepSkyKind::galaxy, 10, 7, false});
    catalogs->galaxies.resize(1'000'037);
    catalogs->quasars.resize(12);
    const auto galaxyCount = catalogs->galaxies.size();
    const auto total = catalogs->ngc.size() + galaxyCount + catalogs->quasars.size();
    const std::weak_ptr<const ExtendedCatalogs> source = catalogs;
    CatalogBrowserModel model({}, catalogs);
    catalogs.reset();
    require(!source.expired(), "model shares the source catalog lifetime");
    require(model.size() == total, "model retains every record including beyond one million");
    auto page = model.search({});
    require(page.total_objects == total && page.total_matches == total, "empty search counts all catalogs");
    require(page.rows.size() == 500 && page.rows.capacity() <= 500, "empty search holds one reference page");
    require(page.rows[0].kind == BrowserObjectKind::nebula && page.rows[2].kind == BrowserObjectKind::galaxy,
        "page spans catalog boundaries without a combined copy");
    BrowserSearchQuery query;
    query.offset = total - 1;
    page = model.search(query);
    require(page.rows.size() == 1 && page.rows.front().kind == BrowserObjectKind::quasar
        && page.rows.front().index == 11, "last overall row is reachable");
    query.offset = total + 1;
    require(model.search(query).rows.empty(), "offset after end produces no fabricated rows");
    query = {};
    query.kind = BrowserObjectKind::galaxy;
    query.offset = galaxyCount - 37;
    page = model.search(query);
    require(page.rows.size() == 37 && page.total_matches == galaxyCount
        && page.rows.back().index == galaxyCount - 1, "last galaxy page retains the entire catalog count");
    query.offset = 0;
    query.text = "SdSs GAL " + std::to_string(galaxyCount);
    const auto start = std::chrono::steady_clock::now();
    page = model.search(query);
    const auto milliseconds = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - start).count();
    require(page.total_matches == 1 && page.rows.front().index == galaxyCount - 1,
        "numeric search scans to the last loaded galaxy");
    const auto last = model.entry(page.rows.front());
    require(last.title == "SDSS GAL " + std::to_string(galaxyCount)
        && last.identifier == static_cast<std::int64_t>(galaxyCount - 1), "display sequence is one based and callback ID is zero based");
    query.text = "SDSS galaxy";
    require(model.search(query).total_matches == galaxyCount, "catalog alias search is not truncated to page size");
    query.text = "1";
    page = model.search(query);
    std::size_t expected = 0;
    for (std::size_t i = 1; i <= galaxyCount; ++i) if (std::to_string(i).find('1') != std::string::npos) ++expected;
    require(page.total_matches == expected && page.rows.size() == 500, "substring search counts every match while keeping one page");
    std::size_t cancellationChecks = 0;
    page = model.search(query, [&] { return ++cancellationChecks > 5; });
    require(page.cancelled && page.rows.empty() && cancellationChecks == 6, "superseded search stops and clears partial results");
    query = {};
    require(model.search(query, [] { return true; }).cancelled, "empty search also respects cancellation");
    query.text = "ＮＧＣ２２４";
    page = model.search(query);
    require(page.total_matches == 1 && page.rows.front().kind == BrowserObjectKind::nebula && page.rows.front().index == 0,
        "width and case folding support compact NGC identifiers");
    require(model.entry(page.rows.front()).title == "NGC 224", "NGC identifier retains catalog prefix");
    query.text = "ic224";
    require(model.search(query).rows.front().index == 1, "IC and NGC numbers remain distinct");
    query.text = "SDSS QSO 12";
    page = model.search(query);
    require(page.total_matches == 1 && page.rows.front().kind == BrowserObjectKind::quasar
        && page.rows.front().index == 11, "QSO sequence search is independent of galaxy sequence");
    query.text = "unmatched name";
    require(model.search(query).total_matches == 0, "unmatched query has no fabricated records");
    query.page_size = 0;
    rejects<std::invalid_argument>([&] { model.search(query); }, "zero page size is rejected");
    query.page_size = 5001;
    rejects<std::invalid_argument>([&] { model.search(query); }, "oversized page size is rejected");
    rejects<std::out_of_range>([&] { model.entry({BrowserObjectKind::galaxy, galaxyCount}); }, "invalid row reference is rejected");
    CatalogBrowserModel empty({}, {});
    require(empty.size() == 0 && empty.search({}).rows.empty(), "missing catalogs are valid empty state");
    std::cout << "Synthetic last-record search: " << galaxyCount << " galaxies, " << milliseconds << " ms\n";
}
void localTests(const char *path) {
    auto sky = std::make_shared<SkyModel>(SkyModel::load(path));
    auto catalogs = std::make_shared<ExtendedCatalogs>(load_extended_catalogs(path));
    CatalogBrowserModel model(sky, catalogs);
    const auto count = 11 + sky->stars().size() + sky->constellations().size() + catalogs->ngc.size()
        + catalogs->galaxies.size() + catalogs->quasars.size();
    require(model.size() == count && model.search({}).total_matches == count, "local totals derive from loaded catalogs");
    const auto finds = [&](const std::string& text, BrowserObjectKind kind, std::size_t index) {
        BrowserSearchQuery query{text, kind};
        for (;;) {
            const auto page = model.search(query);
            for (const auto reference : page.rows) if (reference.index == index) return true;
            query.offset += page.rows.size();
            if (query.offset >= page.total_matches || page.rows.empty()) return false;
        }
    };
    if (!sky->stars().empty()) {
        const auto index = sky->stars().size() - 1;
        const auto hip = sky->stars()[index].hip;
        require(finds("HIP" + std::to_string(hip), BrowserObjectKind::star, index), "local HIP search reaches its source row");
        require(model.entry({BrowserObjectKind::star, index}).identifier == hip, "star callback uses HIP rather than row index");
    }
    // 独自カタログで特定の恒星・星座が削除されても、実際に含まれる名前を検証する。
    for (auto name = catalogs->star_names.rbegin(); name != catalogs->star_names.rend(); ++name) {
        const auto index = sky->star_index(name->hip);
        if (!index) continue;
        NSString *english = [[NSString alloc] initWithBytes:name->name_bytes.data() length:name->name_bytes.size() encoding:NSUTF8StringEncoding];
        const auto encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese);
        NSString *japanese = [[NSString alloc] initWithBytes:name->localized_name_bytes.data() length:name->localized_name_bytes.size() encoding:encoding];
        if (!english.length || [english isEqualToString:@"*"] || !japanese.length || [japanese isEqualToString:@"*"]) continue;
        require(finds(english.UTF8String, BrowserObjectKind::star, *index), "local English common name search");
        require(finds(japanese.UTF8String, BrowserObjectKind::star, *index), "local CP932 common name search");
        break;
    }
    if (!sky->constellations().empty())
        require(finds(sky->constellations().front().english_name, BrowserObjectKind::constellation, 0), "local constellation name search");
    for (const auto kind : {BrowserObjectKind::galaxy, BrowserObjectKind::quasar}) {
        const auto count = kind == BrowserObjectKind::galaxy ? catalogs->galaxies.size() : catalogs->quasars.size();
        if (count == 0) continue;
        const std::string prefix = kind == BrowserObjectKind::galaxy ? "SDSS GAL " : "SDSS QSO ";
        const auto page = model.search({prefix + std::to_string(count), kind});
        require(page.total_matches == 1 && page.rows.front().index == count - 1, "local last SDSS record is searchable");
    }
    std::cout << "Local browser rows: " << count << ", retained page: " << model.search({}).rows.size() << '\n';
}
}
int main(int argc, char **argv) {
    @autoreleasepool {
        try {
            syntheticTests();
            if (argc > 1) localTests(argv[1]);
            std::cout << "Catalog browser model tests passed: " << checks << " checks\n";
            return 0;
        } catch (const std::exception& error) {
            std::cerr << "FAIL: " << error.what() << '\n';
            return 1;
        }
    }
}
