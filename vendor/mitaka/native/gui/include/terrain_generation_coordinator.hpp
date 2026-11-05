#pragma once

#include <array>
#include <bitset>
#include <cstdint>
#include <limits>
#include <memory>
#include <optional>
#include <stdexcept>
#include <utility>
#include <vector>

namespace mitaka::gui {

// All methods must be called on the same thread. Work and notification callbacks
// are deliberately kept outside this class, so neither can reenter it mid-update.
template<class Scene, class Result, std::size_t N>
class TerrainGenerationCoordinator {
public:
    using Mask = std::bitset<N>;

    struct Start {
        std::uint64_t ticket;
        std::shared_ptr<const Scene> scene;
        Mask requested;
    };
    struct Publication {
        std::uint64_t ticket;
        std::shared_ptr<const Scene> scene;
        std::array<std::optional<Result>, N> results;
    };
    struct Transition {
        bool accepted = false;
        std::optional<Start> start;
        std::vector<std::shared_ptr<const Publication>> published;
    };

    TerrainGenerationCoordinator() = default;
    TerrainGenerationCoordinator(const TerrainGenerationCoordinator&) = delete;
    TerrainGenerationCoordinator& operator=(const TerrainGenerationCoordinator&) = delete;

    // A running generation is never cancelled by input updates. Only the most
    // recent pending scene survives until the running generation is terminal.
    Transition submit(std::shared_ptr<const Scene> scene, Mask requested) {
        if (!scene) throw std::invalid_argument("terrain generation requires a scene");
        Transition transition;
        transition.accepted = true;
        Candidate candidate{std::move(scene), requested};
        if (active_) pending_ = std::move(candidate);
        else start(std::move(candidate), transition);
        return transition;
    }

    // An error or unavailable source is a terminal Result supplied by the
    // caller, just like a successful surface; slots outside the mask stay empty.
    Transition complete(std::uint64_t ticket, std::size_t slot, Result result) {
        Transition transition;
        if (!active_ || active_->ticket != ticket || slot >= N ||
            !active_->requested.test(slot) || active_->results[slot]) return transition;
        active_->results[slot].emplace(std::move(result));
        active_->remaining.reset(slot);
        transition.accepted = true;
        if (active_->remaining.none()) {
            publish(std::move(*active_), transition);
            active_.reset();
            if (pending_) {
                auto candidate = std::move(*pending_);
                pending_.reset();
                start(std::move(candidate), transition);
            }
        }
        return transition;
    }

    // Source changes, explicit reloads and incompatible viewport changes
    // discard all three states; old tickets never become valid again.
    void invalidate() {
        active_.reset();
        pending_.reset();
        published_.reset();
    }

    std::shared_ptr<const Publication> published() const { return published_; }
    bool has_active() const { return active_.has_value(); }
    bool has_pending() const { return pending_.has_value(); }
    bool is_active(std::uint64_t ticket) const { return active_ && active_->ticket == ticket; }

private:
    struct Candidate {
        std::shared_ptr<const Scene> scene;
        Mask requested;
    };
    struct Active {
        std::uint64_t ticket;
        std::shared_ptr<const Scene> scene;
        Mask requested;
        Mask remaining;
        std::array<std::optional<Result>, N> results{};
    };

    std::uint64_t next_ticket() {
        if (last_ticket_ == std::numeric_limits<std::uint64_t>::max())
            throw std::overflow_error("terrain generation tickets exhausted");
        return ++last_ticket_;
    }
    void start(Candidate candidate, Transition& transition) {
        const auto ticket = next_ticket();
        Active active{ticket, std::move(candidate.scene), candidate.requested, candidate.requested, {}};
        if (active.remaining.none()) {
            publish(std::move(active), transition);
            return;
        }
        transition.start = Start{ticket, active.scene, active.requested};
        active_ = std::move(active);
    }
    void publish(Active active, Transition& transition) {
        auto publication = std::make_shared<const Publication>(
            Publication{active.ticket, std::move(active.scene), std::move(active.results)});
        published_ = publication;
        transition.published.push_back(std::move(publication));
    }

    std::uint64_t last_ticket_ = 0;
    std::optional<Active> active_;
    std::optional<Candidate> pending_;
    std::shared_ptr<const Publication> published_;
};
}
