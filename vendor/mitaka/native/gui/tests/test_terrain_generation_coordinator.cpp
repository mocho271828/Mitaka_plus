#include "terrain_generation_coordinator.hpp"

#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>

namespace {
struct Scene { int date; int camera; };
struct Result { int date; int camera; std::string status; };
using Coordinator = mitaka::gui::TerrainGenerationCoordinator<Scene, Result, 4>;
unsigned checks = 0;

void require(bool value, const char* message) {
    ++checks;
    if (!value) throw std::runtime_error(message);
}
std::shared_ptr<const Scene> scene(int generation) {
    return std::make_shared<const Scene>(Scene{generation, generation * 10});
}
Result result(int generation, const char* status = "ready") {
    return {generation, generation * 10, status};
}

void continuous_updates() {
    Coordinator coordinator;
    auto start = coordinator.submit(scene(1), Coordinator::Mask(0b1111));
    require(start.accepted && start.start && start.published.empty(), "A starts without publication");
    const auto a = start.start->ticket;
    require(coordinator.is_active(a), "A is active");
    require(!coordinator.complete(a + 1, 0, result(1)).accepted, "unknown ticket rejected");
    require(!coordinator.complete(a, 4, result(1)).accepted, "out-of-range slot rejected");
    require(coordinator.complete(a, 3, result(1, "unavailable")).accepted, "terminal unavailable accepted");
    require(!coordinator.complete(a, 3, result(1)).accepted, "duplicate slot rejected");
    auto b = coordinator.submit(scene(2), Coordinator::Mask(0b1111));
    auto c = coordinator.submit(scene(3), Coordinator::Mask(0b1111));
    require(b.accepted && c.accepted && !b.start && !c.start && coordinator.has_pending(), "only latest waits");
    require(coordinator.complete(a, 1, result(1, "failed")).accepted, "failure is terminal");
    require(coordinator.complete(a, 2, result(1)).accepted && !coordinator.published(), "partial result never published");
    auto finish = coordinator.complete(a, 0, result(1));
    require(finish.accepted && finish.published.size() == 1 && finish.start, "A publishes then latest starts");
    const auto published_a = finish.published.front();
    require(published_a->scene->date == 1 && published_a->scene->camera == 10, "A scene remains coherent");
    require(published_a->results[1]->status == "failed" && published_a->results[3]->status == "unavailable", "A retains terminal diagnostics");
    for (const auto& item : published_a->results)
        require(item && item->date == published_a->scene->date && item->camera == published_a->scene->camera, "all A results match displayed scene");
    const auto c_ticket = finish.start->ticket;
    require(finish.start->scene->date == 3 && coordinator.is_active(c_ticket), "B replaced by C");
    require(!coordinator.complete(a, 0, result(1)).accepted, "old A callback cannot alter C");
    coordinator.submit(scene(4), Coordinator::Mask(0b1111));
    require(coordinator.complete(c_ticket, 2, result(3)).accepted, "C completes in arbitrary order");
    require(coordinator.complete(c_ticket, 0, result(3)).accepted, "C completes next slot");
    require(coordinator.complete(c_ticket, 3, result(3)).accepted, "C completes another slot");
    require(coordinator.published()->scene->date == 1, "A remains displayed during C");
    const auto c_finish = coordinator.complete(c_ticket, 1, result(3));
    require(c_finish.published.size() == 1 && c_finish.published[0]->scene->date == 3 &&
        c_finish.start && c_finish.start->scene->date == 4, "C publishes while updates continue and D starts");
    require(published_a->scene->date == 1, "old publication stays alive for renderer");
}

void empty_and_invalidation() {
    Coordinator coordinator;
    auto immediate = coordinator.submit(scene(1), Coordinator::Mask{});
    require(immediate.accepted && !immediate.start && immediate.published.size() == 1 &&
        coordinator.published()->scene->date == 1, "empty scene publishes immediately");
    auto active = coordinator.submit(scene(2), Coordinator::Mask(0b0010));
    const auto ticket = active.start->ticket;
    require(!coordinator.complete(ticket, 0, result(2)).accepted, "unrequested slot rejected");
    coordinator.submit(scene(3), Coordinator::Mask{});
    const auto finish = coordinator.complete(ticket, 1, result(2));
    require(finish.published.size() == 2 && finish.published[0]->scene->date == 2 &&
        finish.published[1]->scene->date == 3 && !finish.start && coordinator.published()->scene->date == 3,
        "A and zero-work pending publish in order");
    require(!finish.published[0]->results[0] && finish.published[0]->results[1] &&
        !finish.published[0]->results[2], "unrequested slots stay empty");
    auto old = coordinator.submit(scene(4), Coordinator::Mask(1));
    coordinator.submit(scene(5), Coordinator::Mask(1));
    coordinator.invalidate();
    require(!coordinator.published() && !coordinator.has_active() && !coordinator.has_pending(), "invalidate clears all states");
    require(!coordinator.complete(old.start->ticket, 0, result(4)).accepted, "invalidated callback rejected");
    auto fresh = coordinator.submit(scene(6), Coordinator::Mask(1));
    require(fresh.start->ticket != old.start->ticket && !coordinator.is_active(old.start->ticket), "invalidated ticket never reused");
    require(!coordinator.complete(old.start->ticket, 0, result(4)).accepted &&
        coordinator.is_active(fresh.start->ticket), "old callback cannot poison new source");
    const auto accepted = coordinator.complete(fresh.start->ticket, 0, result(6));
    require(accepted.published.size() == 1 && coordinator.published()->scene->date == 6, "fresh source publishes");
    try { coordinator.submit(nullptr, Coordinator::Mask{}); }
    catch (const std::invalid_argument&) { ++checks; return; }
    throw std::runtime_error("null scene accepted");
}
}

int main() {
    try {
        continuous_updates();
        empty_and_invalidation();
        std::cout << "terrain generation coordinator: " << checks << " checks passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "terrain generation coordinator: " << error.what() << '\n';
        return 1;
    }
}
