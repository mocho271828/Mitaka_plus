CXX = xcrun clang++
export DATA_ROOT ?= $(abspath ../../../../resources)
export CF96_DATA ?= $(abspath ../../../../resources/data/cf96.dat)
AR = xcrun ar
BUILD_DIR ?= build
CXXFLAGS ?= -O2 -g
CPPFLAGS += -Iinclude
CXXFLAGS += -std=c++17 -Wall -Wextra -Wpedantic -Werror
UPSTREAM ?= ../../sources/official/mitaka_source
# 原本の CP932 コメントと vector3 の無名 struct は、比較用ビルドだけ許容する。
REFERENCE_FLAGS = -Wno-invalid-utf8 -Wno-gnu-anonymous-struct -Wno-nested-anon-types

ifneq ($(ARCH),)
CXXFLAGS += -arch $(ARCH)
LDFLAGS += -arch $(ARCH)
endif
ifneq ($(SANITIZE),)
CXXFLAGS += -O1 -fno-omit-frame-pointer -fsanitize=$(SANITIZE)
LDFLAGS += -fsanitize=$(SANITIZE)
endif

SOURCES = src/astronomy.cpp src/catalog.cpp src/ephemeris.cpp src/rotation.cpp src/lunar.cpp src/observation.cpp src/extended_catalog.cpp src/place_catalog.cpp src/small_body_catalog.cpp src/small_body_text.cpp src/small_body_orbit.cpp src/satellite_catalog.cpp src/satellite_catalog_parser.cpp src/satellite_position.cpp src/satellite_rotation.cpp src/satellite_model.cpp src/satellite_registration.cpp src/satellite_absolute.cpp src/spacecraft_trajectory.cpp src/spacecraft_trajectory_parser.cpp src/spacecraft_position.cpp src/minor_planet_position.cpp src/small_body_orbit_path.cpp
SOURCES += src/atmosphere.cpp src/atmosphere_multiple.cpp src/atmosphere_emission_map.cpp
SOURCES += src/constellation_art.cpp src/eclipse.cpp src/terrain.cpp src/terrain_sampling.cpp
SOURCES += src/galaxy_catalog.cpp src/our_galaxy_model.cpp
OBJECTS = $(patsubst src/%.cpp,$(BUILD_DIR)/%.o,$(SOURCES))
LIBRARY = $(BUILD_DIR)/libmitaka_core.a
TESTS = $(addprefix $(BUILD_DIR)/test_,astronomy catalog ephemeris rotation lunar observation extended_catalog place_catalog small_body_orbit small_body_catalog satellite_catalog satellite_position satellite_rotation satellite_model satellite_absolute spacecraft_trajectory spacecraft_position minor_planet_position small_body_orbit_path)

TESTS += $(BUILD_DIR)/test_atmosphere
TESTS += $(BUILD_DIR)/test_constellation_art
TESTS += $(BUILD_DIR)/test_eclipse $(BUILD_DIR)/test_terrain
TESTS += $(BUILD_DIR)/test_galaxy_catalog $(BUILD_DIR)/test_our_galaxy_model

.PHONY: all test data-test reference-test rotation-reference-test lunar-reference-test universal
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

# 原本は比較用バイナリにだけリンクする。ライブラリの実行時依存にはしない。
$(BUILD_DIR)/reference_cf96.o: $(UPSTREAM)/common/astro/cf96.cpp | $(BUILD_DIR)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(REFERENCE_FLAGS) -Wno-unused-variable -c $< -o $@

$(BUILD_DIR)/test_upstream: tests/test_upstream.cpp $(BUILD_DIR)/reference_cf96.o $(LIBRARY)
	$(CXX) $(CPPFLAGS) -I$(UPSTREAM)/common/astro $(CXXFLAGS) $(REFERENCE_FLAGS) $< $(BUILD_DIR)/reference_cf96.o $(LIBRARY) $(LDFLAGS) -o $@

reference-test: $(BUILD_DIR)/test_upstream
	$(BUILD_DIR)/test_upstream "$${CF96_DATA:?Set CF96_DATA to an existing cf96.dat}"

# Windows/OpenGL 層から独立した三関数のみ、本文を変えず比較用に取り出す。
$(BUILD_DIR)/reference_rotation.cpp: $(UPSTREAM)/Mitaka/mtk_planet_orientation.cpp tests/extract_rotation.awk | $(BUILD_DIR)
	LC_ALL=C awk -f tests/extract_rotation.awk "$<" > "$@.tmp"
	mv "$@.tmp" "$@"

$(BUILD_DIR)/test_rotation_upstream: tests/test_rotation_upstream.cpp $(BUILD_DIR)/reference_rotation.cpp $(LIBRARY)
	$(CXX) $(CPPFLAGS) -I$(UPSTREAM)/common/math -I$(UPSTREAM)/common/astro $(CXXFLAGS) $(REFERENCE_FLAGS) $< $(BUILD_DIR)/reference_rotation.cpp $(LIBRARY) $(LDFLAGS) -o $@

rotation-reference-test: $(BUILD_DIR)/test_rotation_upstream
	$(BUILD_DIR)/test_rotation_upstream

$(BUILD_DIR)/reference_lunar_pos.o: $(UPSTREAM)/Mitaka/mtk_lunar_pos.cpp | $(BUILD_DIR)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(REFERENCE_FLAGS) -Wno-missing-braces -c $< -o $@

$(BUILD_DIR)/reference_lunar_orientation.cpp: $(UPSTREAM)/Mitaka/mtk_satellite_orientation.cpp tests/extract_lunar_orientation.awk | $(BUILD_DIR)
	LC_ALL=C awk -f tests/extract_lunar_orientation.awk "$<" > "$@.tmp"
	mv "$@.tmp" "$@"

$(BUILD_DIR)/test_lunar_upstream: tests/test_lunar_upstream.cpp $(BUILD_DIR)/reference_lunar_pos.o $(BUILD_DIR)/reference_lunar_orientation.cpp $(LIBRARY)
	$(CXX) $(CPPFLAGS) -I$(UPSTREAM)/common/math -I$(UPSTREAM)/common/astro $(CXXFLAGS) $(REFERENCE_FLAGS) $< $(BUILD_DIR)/reference_lunar_pos.o $(BUILD_DIR)/reference_lunar_orientation.cpp $(LIBRARY) $(LDFLAGS) -o $@

lunar-reference-test: $(BUILD_DIR)/test_lunar_upstream
	$(BUILD_DIR)/test_lunar_upstream

universal:
	$(MAKE) BUILD_DIR=build/arm64 ARCH=arm64 all
	$(MAKE) BUILD_DIR=build/x86_64 ARCH=x86_64 all
	mkdir -p build/universal
	xcrun lipo -create build/arm64/libmitaka_core.a build/x86_64/libmitaka_core.a -output build/universal/libmitaka_core.a
	xcrun lipo -create build/arm64/core_probe build/x86_64/core_probe -output build/universal/core_probe

-include $(OBJECTS:.o=.d)

# N12: 大気の単一散乱・多重散乱と原 emmap の保持。

.PHONY: atmosphere-reference-test
$(BUILD_DIR)/reference_atmosphere.cpp: $(UPSTREAM)/Mitaka/mtk_atmosphere.cpp tests/extract_atmosphere.awk | $(BUILD_DIR)
	LC_ALL=C awk -f tests/extract_atmosphere.awk "$<" > "$@.tmp"
	mv "$@.tmp" "$@"

$(BUILD_DIR)/reference_atmosphere.o: $(BUILD_DIR)/reference_atmosphere.cpp $(UPSTREAM)/Mitaka/mtk_approx_func.h $(UPSTREAM)/common/math/vector3.h
	$(CXX) $(CPPFLAGS) -I$(UPSTREAM)/common/math -I$(UPSTREAM)/Mitaka $(CXXFLAGS) $(REFERENCE_FLAGS) -Wno-unused-variable -c $< -o $@

$(BUILD_DIR)/test_atmosphere_upstream: tests/test_atmosphere_upstream.cpp $(BUILD_DIR)/reference_atmosphere.o $(LIBRARY)
	$(CXX) $(CPPFLAGS) -I$(UPSTREAM)/common/math $(CXXFLAGS) $(REFERENCE_FLAGS) $< $(BUILD_DIR)/reference_atmosphere.o $(LIBRARY) $(LDFLAGS) -o $@

atmosphere-reference-test: $(BUILD_DIR)/test_atmosphere_upstream
	$(BUILD_DIR)/test_atmosphere_upstream

.PHONY: eclipse-reference-test
$(BUILD_DIR)/eclipse_upstream.inc: $(UPSTREAM)/Mitaka/mtk_eclipse.cpp tests/extract_eclipse.awk | $(BUILD_DIR)
	LC_ALL=C awk -f tests/extract_eclipse.awk "$<" > "$@.tmp"
	mv "$@.tmp" "$@"

$(BUILD_DIR)/test_eclipse_upstream: tests/test_eclipse_upstream.cpp $(BUILD_DIR)/eclipse_upstream.inc $(LIBRARY)
	$(CXX) $(CPPFLAGS) -I"$(BUILD_DIR)" $(CXXFLAGS) $< $(LIBRARY) $(LDFLAGS) -o $@

eclipse-reference-test: $(BUILD_DIR)/test_eclipse_upstream
	$(BUILD_DIR)/test_eclipse_upstream
