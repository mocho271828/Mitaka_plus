CXX = xcrun clang++
export DATA_ROOT ?= $(abspath ../../../../resources)
AR = xcrun ar
BUILD_DIR ?= build
CXXFLAGS ?= -O2 -g
CPPFLAGS += -Iinclude
CXXFLAGS += -std=c++17 -Wall -Wextra -Wpedantic -Werror

ifneq ($(ARCH),)
CXXFLAGS += -arch $(ARCH)
LDFLAGS += -arch $(ARCH)
endif
ifneq ($(SANITIZE),)
CXXFLAGS += -O1 -fno-omit-frame-pointer -fsanitize=$(SANITIZE)
LDFLAGS += -fsanitize=$(SANITIZE)
endif

SOURCES = src/astronomy.cpp src/catalog.cpp src/ephemeris.cpp src/rotation.cpp src/lunar.cpp src/observation.cpp src/extended_catalog.cpp src/place_catalog.cpp src/small_body_catalog.cpp src/small_body_text.cpp src/small_body_orbit.cpp src/satellite_catalog.cpp src/satellite_catalog_parser.cpp src/satellite_position.cpp src/satellite_rotation.cpp src/satellite_model.cpp src/satellite_registration.cpp src/satellite_absolute.cpp src/spacecraft_trajectory.cpp src/spacecraft_trajectory_parser.cpp src/spacecraft_position.cpp src/minor_planet_position.cpp src/minor_planet_orbit_path.cpp src/small_body_orbit_path.cpp
SOURCES += src/atmosphere.cpp src/atmosphere_multiple.cpp src/atmosphere_emission_map.cpp
SOURCES += src/constellation_art.cpp src/eclipse.cpp src/terrain.cpp src/terrain_sampling.cpp
SOURCES += src/galaxy_catalog.cpp src/our_galaxy_model.cpp src/our_galaxy_radiative.cpp
OBJECTS = $(patsubst src/%.cpp,$(BUILD_DIR)/%.o,$(SOURCES))
LIBRARY = $(BUILD_DIR)/libmitaka_core.a
TESTS = $(addprefix $(BUILD_DIR)/test_,astronomy catalog ephemeris rotation lunar observation extended_catalog place_catalog small_body_orbit small_body_catalog satellite_catalog satellite_position satellite_rotation satellite_model satellite_absolute spacecraft_trajectory spacecraft_position minor_planet_position minor_planet_orbit_path small_body_orbit_path)

TESTS += $(BUILD_DIR)/test_atmosphere
TESTS += $(BUILD_DIR)/test_constellation_art
TESTS += $(BUILD_DIR)/test_eclipse $(BUILD_DIR)/test_terrain
TESTS += $(BUILD_DIR)/test_galaxy_catalog $(BUILD_DIR)/test_our_galaxy_model $(BUILD_DIR)/test_our_galaxy_radiative

.PHONY: all test data-test universal
all: $(LIBRARY) $(BUILD_DIR)/core_probe

$(BUILD_DIR):
	mkdir -p "$@"

$(BUILD_DIR)/%.o: src/%.cpp | $(BUILD_DIR)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -MMD -MP -c $< -o $@

$(LIBRARY): $(OBJECTS)
	$(AR) rcs $@ $^

$(BUILD_DIR)/core_probe: tools/core_probe.cpp $(LIBRARY)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $< $(LIBRARY) $(LDFLAGS) -o $@

$(BUILD_DIR)/test_%: tests/test_%.cpp $(LIBRARY)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $< $(LIBRARY) $(LDFLAGS) -o $@

test: $(TESTS)
	@set -e; for test in $(TESTS); do "$$test"; done

data-test: $(BUILD_DIR)/test_data
	$(BUILD_DIR)/test_data "$${DATA_ROOT:?Set DATA_ROOT to an existing Mitaka application data root}"

universal:
	$(MAKE) BUILD_DIR=build/arm64 ARCH=arm64 all
	$(MAKE) BUILD_DIR=build/x86_64 ARCH=x86_64 all
	mkdir -p build/universal
	xcrun lipo -create build/arm64/libmitaka_core.a build/x86_64/libmitaka_core.a -output build/universal/libmitaka_core.a
	xcrun lipo -create build/arm64/core_probe build/x86_64/core_probe -output build/universal/core_probe

-include $(OBJECTS:.o=.d)
