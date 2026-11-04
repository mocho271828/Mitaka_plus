#import <Foundation/Foundation.h>
#include "small_body_orbit_test_fixture.hpp"

#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
unsigned checks = 0;
void require(bool value, const char* message) {
    ++checks;
    if (!value) throw std::runtime_error(message);
}
template<class Exception = std::invalid_argument, class Function>
void rejects(Function action, const char* message) {
    try { action(); } catch (const Exception&) { require(true, message); return; }
    require(false, message);
}
bool has_diagnostic(const SmallBodyOrbitSample& sample, SmallBodyDiagnosticCode code) {
    for (const auto& value : sample.evaluation.diagnostics) if (value.code == code) return true;
    return false;
}
void evaluation_and_visibility() {
    auto data = orbit_test::dataset(6);
    data->records[1].frame = SmallBodyFrame::unresolved;
    data->records[2].time_scale = SmallBodyTimeScale::unresolved;
    data->records[3].declared_time_range = SmallBodyTimeRange{2451540, 2451550};
    data->records[4].kind = SmallBodyKind::asteroid;
    data->records[4].encoding = SmallBodyEncoding::packed_36;
    data->records[4].raw_record_bytes = std::string(36, '\0');
    data->records[4].time_scale = SmallBodyTimeScale::unresolved;
    data->records[5].orbit = std::monostate{};
    const auto original_bytes = data->sources.front().bytes;
    auto model = std::make_shared<SmallBodyModel>(data);
    auto display = orbit_test::display(data);
    const auto frame = evaluate_small_body_orbit_snapshot(model, display, orbit_test::sampling);
    require(frame->model == model && frame->display == display, "immutable provenance is retained");
    require(frame->paths.size() == 6 && frame->requested_count == 5
        && frame->completed_count == 5 && frame->unresolved_count == 4 && !frame->cancelled,
        "all original rows and requested partial failures are counted separately");
    require(!frame->paths[4], "disabled kind is not sampled or removed from original index space");
    for (std::size_t row : {0u, 1u, 2u, 3u, 5u}) {
        const auto& path = *frame->paths[row];
        require(path.id.source_key == data->records[row].id.source_key
            && path.id.record_ordinal == row && path.samples.size() == 5, "repeated names keep source row identity");
        require(path.samples.front().julian_date == 2451535 && path.samples.back().julian_date == 2451555,
            "absolute TDB interval endpoints are exact");
    }
    for (const auto& sample : frame->paths[0]->samples) {
        const auto expected = evaluate_small_body(data->records[0], sample.julian_date);
        const auto actual = sample.evaluation.state;
        require(actual && expected.state && actual->position_au.x == expected.state->position_au.x
            && actual->position_au.y == expected.state->position_au.y && actual->position_au.z == expected.state->position_au.z,
            "TDB evaluator position is reused without another transform");
    }
    require(has_diagnostic(frame->paths[1]->samples.front(), SmallBodyDiagnosticCode::unresolved_frame),
        "unresolved frame is retained at its requested source row");
    require(has_diagnostic(frame->paths[2]->samples.front(), SmallBodyDiagnosticCode::unresolved_time_scale),
        "unresolved physical time is not treated as TDB");
    require(has_diagnostic(frame->paths[5]->samples.front(), SmallBodyDiagnosticCode::unresolved_perihelion_time),
        "missing orbit is retained with its diagnostic");
    const auto segments = small_body_orbit_segments(*frame->paths[3]);
    require(segments == std::vector<std::array<std::size_t, 2>>{{1, 2}, {2, 3}},
        "partial declared interval neither bridges missing endpoints nor closes the curve");
    display = std::make_shared<SmallBodyDisplayModel>(*display);
    display->set_selected_ids({data->records[1].id, data->records[4].id});
    display->set_kind_options(SmallBodyKind::comet, {true, true, true, true});
    display->set_kind_options(SmallBodyKind::asteroid, {true, false, true, true});
    const auto chosen = evaluate_small_body_orbit_snapshot(model, display, orbit_test::sampling);
    require(chosen->requested_count == 2 && chosen->paths[1] && chosen->paths[4] && !chosen->paths[0],
        "kind options and source identity membership control orbit requests");
    require(!chosen->paths[4]->samples.front().evaluation.state
        && has_diagnostic(chosen->paths[4]->samples.front(), SmallBodyDiagnosticCode::unresolved_time_scale),
        "legacy numeric JD row never enters the TDB orbit path through the position model");
    display = std::make_shared<SmallBodyDisplayModel>(*display);
    display->set_kind_options(SmallBodyKind::comet, {false, true, true, true});
    require(small_body_orbit_requested_rows(*model, *display, orbit_test::sampling) == std::vector<std::size_t>{4},
        "hidden kind suppresses its label and orbit requirements");
    require(data->sources.front().bytes == original_bytes && data->records[1].frame == SmallBodyFrame::unresolved
        && data->records[4].time_scale == SmallBodyTimeScale::unresolved,
        "sampling leaves local original bytes and unresolved metadata unchanged");
}
void invalid_requests_and_limits() {
    const auto empty = orbit_test::dataset(0);
    const auto model = std::make_shared<SmallBodyModel>(empty);
    const auto display = orbit_test::display(empty);
    const auto evaluate = [&](SmallBodyOrbitSampling sampling) {
        return evaluate_small_body_orbit_snapshot(model, display, sampling);
    };
    rejects([&] { evaluate_small_body_orbit_snapshot(nullptr, display, orbit_test::sampling); }, "null model rejected");
    rejects([&] { evaluate_small_body_orbit_snapshot(model, nullptr, orbit_test::sampling); }, "null display rejected");
    auto other = orbit_test::display(orbit_test::dataset(0));
    rejects([&] { evaluate_small_body_orbit_snapshot(model, other, orbit_test::sampling); },
        "equal but independently loaded dataset is rejected");
    for (const auto bad : {SmallBodyOrbitSampling{0, 0, 2}, {1, 0, 2}, {0, 1, 0}, {0, 1, 1}, {0, 1, 4097},
            {std::numeric_limits<double>::quiet_NaN(), 1, 2}, {0, std::numeric_limits<double>::infinity(), 2},
            {-std::numeric_limits<double>::max(), std::numeric_limits<double>::max(), 2},
            {2451545, std::nextafter(2451545., INFINITY), 3}})
        rejects([&] { evaluate(bad); }, "invalid or indistinguishable sampling is rejected even with no rows");
    const auto frame = evaluate(orbit_test::sampling);
    require(frame->paths.empty() && frame->requested_count == 0 && frame->completed_count == 0
        && !frame->cancelled, "empty source is an explicit valid empty result");
    auto data = orbit_test::dataset(129);
    auto many = std::make_shared<SmallBodyModel>(data);
    auto options = orbit_test::display(data);
    const SmallBodyOrbitSampling maximum{2451535, 2451555, 4096};
    std::size_t cancellation_calls = 0;
    bool message = false;
    try {
        evaluate_small_body_orbit_snapshot(many, options, maximum, [&] { ++cancellation_calls; return false; });
    } catch (const std::length_error& error) {
        message = std::string(error.what()).find("524288") != std::string::npos
            && std::string(error.what()).find("129 requested rows x 4096") != std::string::npos;
    }
    require(message && cancellation_calls == 0, "whole oversized request is explained and rejected before sampling");
    require(data->records.size() == 129 && options->dataset()->records.size() == 129,
        "cap does not truncate originals or the display model");
    std::vector<SmallBodyId> ids;
    for (std::size_t index = 0; index < 128; ++index) ids.push_back(data->records[index].id);
    options->set_selected_ids(ids);
    options->set_kind_options(SmallBodyKind::comet, {true, false, true, true});
    require(small_body_orbit_requested_rows(*many, *options, maximum).size() == 128,
        "exact 524288 total sample boundary is accepted");
    options->set_selected_ids({data->records.back().id});
    const auto maximum_path = evaluate_small_body_orbit_snapshot(many, options, maximum);
    require(maximum_path->paths.back()->samples.size() == 4096 && maximum_path->requested_count == 1,
        "per-row maximum keeps every requested sample at its original row");
}
void cancellation() {
    auto data = orbit_test::dataset(4);
    const auto model = std::make_shared<SmallBodyModel>(data);
    const auto display = orbit_test::display(data);
    auto frame = evaluate_small_body_orbit_snapshot(model, display, orbit_test::sampling, [] { return true; });
    require(frame->cancelled && frame->completed_count == 0 && frame->requested_count == 4
        && frame->paths.size() == 4 && !frame->paths.front(), "pre-cancel retains original shape without work");
    std::size_t calls = 0;
    frame = evaluate_small_body_orbit_snapshot(model, display, orbit_test::sampling, [&] { return ++calls == 3; });
    require(frame->cancelled && frame->completed_count == 2 && frame->paths[1] && !frame->paths[2],
        "cancellation between rows reports a partial result explicitly");
    calls = 0;
    frame = evaluate_small_body_orbit_snapshot(model, display, orbit_test::sampling, [&] { return ++calls == 5; });
    require(frame->cancelled && frame->completed_count == 4, "last-row cancellation is not mistaken for completed work");
    const auto empty = orbit_test::dataset(0);
    frame = evaluate_small_body_orbit_snapshot(std::make_shared<SmallBodyModel>(empty), orbit_test::display(empty),
        orbit_test::sampling, [] { return true; });
    require(frame->cancelled && frame->paths.empty(), "empty request still observes cancellation");
}
void local_data(const char* directory) {
    const auto data = std::make_shared<const SmallBodyDataset>(load_small_body_dataset(directory));
    const auto model = std::make_shared<SmallBodyModel>(data);
    const auto display = orbit_test::display(data);
    const SmallBodyOrbitSampling sampling{2451545 - 182.625, 2451545 + 182.625, 129};
    const auto frame = evaluate_small_body_orbit_snapshot(model, display, sampling);
    require(frame->paths.size() == data->records.size(), "all local original rows remain addressable");
    std::size_t requested = 0, unresolved = 0;
    for (std::size_t row = 0; row < data->records.size(); ++row) {
        const bool visible = data->records[row].kind == SmallBodyKind::comet;
        require(frame->paths[row].has_value() == visible, "local native initial orbit request covers every comet and no other kind");
        if (!visible) continue;
        ++requested;
        const auto& path = *frame->paths[row];
        require(path.id.source_key == data->records[row].id.source_key
            && path.id.record_ordinal == data->records[row].id.record_ordinal && path.samples.size() == 129,
            "local source identity and full requested sample count are retained");
        bool missing = false;
        for (const auto& sample : path.samples) {
            if (!sample.evaluation.state) {
                missing = true;
                require(!sample.evaluation.diagnostics.empty(), "unresolved local samples explain why no position is drawn");
            }
        }
        if (missing) ++unresolved;
    }
    require(frame->requested_count == requested && frame->completed_count == requested
        && frame->unresolved_count == unresolved && !frame->cancelled, "local counts derive from the actual full source");
    std::cout << "Local orbit rows=" << data->records.size() << " requested=" << requested
              << " unresolved=" << unresolved << '\n';
}
}
int main(int argc, char** argv) {
    @autoreleasepool {
        try {
            evaluation_and_visibility(); invalid_requests_and_limits(); cancellation();
            if (argc == 2) local_data(argv[1]);
            else if (argc != 1) throw std::invalid_argument("usage: test_small_body_orbit_model [data_directory]");
            std::cout << "Small-body orbit model tests passed: " << checks << " checks\n";
            return 0;
        } catch (const std::exception& error) { std::cerr << "FAIL: " << error.what() << '\n'; return 1; }
    }
}
