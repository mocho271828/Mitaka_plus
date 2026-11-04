CXX = xcrun clang++
export DATA_ROOT ?= $(abspath ../../../../resources/data)
BUILD_DIR ?= build
CXXFLAGS ?= -O2 -g
CPPFLAGS += -Iinclude -I../core/include
CXXFLAGS += -std=c++17 -Wall -Wextra -Wpedantic -Werror -mmacosx-version-min=13.0
CORE_BUILD = $(abspath $(BUILD_DIR)/core)
CORE_LIBRARY = $(CORE_BUILD)/libmitaka_core.a
APP = $(BUILD_DIR)/Mitaka Native.app
EXECUTABLE = $(APP)/Contents/MacOS/MitakaNative
SCRIPT_HELPER = $(BUILD_DIR)/MitakaScript
LUA_BUILD = $(abspath $(BUILD_DIR)/lua)
LUA_LIBRARY = $(LUA_BUILD)/liblua.a
OBJECTS = $(addprefix $(BUILD_DIR)/,main.o AppController.o AppWindow.o AppObserverCommands.o observer_places.o gui_file_io.o AppPlusCommands.o AppDisplayCommands.o AppTimeCommands.o AppSmallBodyCommands.o AppSmallBodySmokeTests.o MediaController.o MediaImageView.o media_catalog.o SmallBodyController.o small_body_model.o SmallBodyRenderer.o SolarSmallBodies.o AppSessionCommands.o AppScripting.o CatalogBrowserController.o catalog_browser_model.o DisplayOutputController.o ScriptController.o script_transport.o HorizonView.o extended_catalogs.o session_state.o SkyCatalogRenderer.o StarRenderer.o RendererQuality.o star_labels.o sky_catalog_index.o AppSmokeTests.o AppPlusSmokeTests.o AppScriptSmokeTests.o AppFlightSmokeTests.o PlaybackController.o SkyView.o SolarSystemView.o SolarSystemNavigation.o SolarSystemSmokeTests.o SolarSceneRenderer.o GridRenderer.o grid_geometry.o distance_scales.o sky_model.o solar_camera.o planet_surface.o planet_textures.o local_image.o sky_background.o calendar_time.o playback_clock.o surface_navigation.o interplanetary_flight.o)
MEDIA_FRAMEWORKS = -framework AVKit -framework AVFoundation
WEB_FRAMEWORKS = -framework WebKit
IMAGE_FRAMEWORKS = -framework Foundation -framework ImageIO -framework CoreGraphics
OBJECTS += $(addprefix $(BUILD_DIR)/,AppWindowCommands.o WindowPresentationController.o html_bridge_policy.o HtmlBrowserController.o satellite_browser_model.o SatelliteController.o AppSatelliteCommands.o SatelliteRenderer.o SolarSatellites.o satellite_scene.o)
OBJECTS += $(BUILD_DIR)/AppSatelliteSmokeTests.o
OBJECTS += $(addprefix $(BUILD_DIR)/,SpacecraftController.o SpacecraftRenderer.o spacecraft_browser_model.o SolarSpacecraft.o AppSpacecraftCommands.o small_body_display.o satellite_display.o constellation_display.o horizon_segments.o AppConstellationCommands.o small_body_orbit_model.o SmallBodyOrbitController.o)
OBJECTS += $(BUILD_DIR)/ConstellationRenderer.o
OBJECTS += $(addprefix $(BUILD_DIR)/,satellite_orbit_geometry.o session_layers.o session_layers_json.o)
OBJECTS += $(BUILD_DIR)/AppSessionSmokeTests.o $(BUILD_DIR)/AppGalaxySmokeTests.o
OBJECTS += $(BUILD_DIR)/AppStarCommands.o
OBJECTS += $(BUILD_DIR)/earth_layers.o $(BUILD_DIR)/atmosphere_renderer.o
OBJECTS += $(addprefix $(BUILD_DIR)/,star_brightness.o StarBrightnessController.o AppStarNameCommands.o star_name_selection.o constellation_art_model.o constellation_art_projection.o ConstellationArtRenderer.o)
OBJECTS += $(addprefix $(BUILD_DIR)/,plus_time_step.o plus_time_playback.o place_display_model.o landscape_geometry.o sdss_spatial_model.o)
LANDSCAPE_OBJECTS = $(addprefix $(BUILD_DIR)/,landscape_selection.o earth_landscapes.o landscape_projection.o HorizonLandscapeRenderer.o)
OBJECTS += $(LANDSCAPE_OBJECTS)
ECLIPSE_OBJECTS = $(addprefix $(BUILD_DIR)/,eclipse_surface.o eclipse_display.o eclipse_cone_renderer.o)
OBJECTS += $(ECLIPSE_OBJECTS)
GALAXY_OBJECTS = $(addprefix $(BUILD_DIR)/,galaxy_camera.o galaxy_spatial_scene.o galaxy_spatial_load.o GalaxyRenderer.o GalaxyView.o GalaxyController.o)
TERRAIN_OBJECTS = $(addprefix $(BUILD_DIR)/,terrain_mesh.o terrain_surface.o terrain_snapshot.o terrain_source_lease.o)
OBJECTS += $(GALAXY_OBJECTS) $(TERRAIN_OBJECTS)
OBJECTS += $(addprefix $(BUILD_DIR)/,AppGalaxyCommands.o surface_depth.o TerrainSurfaceController.o SolarTerrain.o plus_time_calendar.o plus_time_animation.o AppScriptingTime.o radius_display.o RadiusDisplayController.o)

ifneq ($(ARCH),)
CXXFLAGS += -arch $(ARCH)
LDFLAGS += -arch $(ARCH)
endif
ifneq ($(SANITIZE),)
CXXFLAGS += -O1 -fno-omit-frame-pointer -fsanitize=$(SANITIZE)
LDFLAGS += -fsanitize=$(SANITIZE)
endif

.PHONY: all core test controller-test system-occlusion-test system-fullscreen-test script-test data-test smoke run
all: core $(OBJECTS) $(SCRIPT_HELPER)
	mkdir -p "$(APP)/Contents/MacOS"
	$(CXX) $(CXXFLAGS) $(OBJECTS) "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit -framework UniformTypeIdentifiers $(IMAGE_FRAMEWORKS) $(MEDIA_FRAMEWORKS) $(WEB_FRAMEWORKS) -o "$(EXECUTABLE)"
	cp "$(SCRIPT_HELPER)" "$(APP)/Contents/MacOS/MitakaScript"
	cp Info.plist "$(APP)/Contents/Info.plist"
	mkdir -p "$(APP)/Contents/Resources"
	cp THIRD_PARTY_NOTICES.txt "$(APP)/Contents/Resources/THIRD_PARTY_NOTICES.txt"
	cp LUA_LICENSE.txt "$(APP)/Contents/Resources/LUA_LICENSE.txt"

$(LUA_LIBRARY): tools/build_lua.sh vendor/lua-5.4.9.tar.gz
	bash tools/build_lua.sh "$(LUA_BUILD)" "$(ARCH)" "$(SANITIZE)"

$(SCRIPT_HELPER): src/ScriptWorker.mm $(BUILD_DIR)/script_transport.o $(BUILD_DIR)/star_brightness.o $(BUILD_DIR)/plus_time_step.o $(BUILD_DIR)/plus_time_playback.o $(BUILD_DIR)/plus_time_calendar.o $(BUILD_DIR)/radius_display.o $(LUA_LIBRARY) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -I"$(LUA_BUILD)/include" -fobjc-arc $< $(BUILD_DIR)/script_transport.o $(BUILD_DIR)/star_brightness.o $(BUILD_DIR)/plus_time_step.o $(BUILD_DIR)/plus_time_playback.o $(BUILD_DIR)/plus_time_calendar.o $(BUILD_DIR)/radius_display.o "$(CORE_LIBRARY)" "$(LUA_LIBRARY)" $(LDFLAGS) -framework Foundation -o "$@"

$(BUILD_DIR)/test_script_controller: tests/test_script_controller.mm $(BUILD_DIR)/ScriptController.o $(BUILD_DIR)/script_transport.o $(BUILD_DIR)/star_brightness.o $(BUILD_DIR)/plus_time_step.o $(BUILD_DIR)/plus_time_playback.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -framework Foundation -o "$@"

script-test: $(BUILD_DIR)/test_script_controller $(SCRIPT_HELPER)
	"$(BUILD_DIR)/test_script_controller" "$(abspath $(SCRIPT_HELPER))"

core:
	$(MAKE) -C ../core BUILD_DIR="$(CORE_BUILD)" ARCH="$(ARCH)" SANITIZE="$(SANITIZE)" CXXFLAGS="$(CXXFLAGS)" "$(CORE_LIBRARY)"

$(BUILD_DIR)/%.o: src/%.mm
	mkdir -p "$(BUILD_DIR)"
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc -MMD -MP -c $< -o "$@"

$(BUILD_DIR)/%.o: src/%.cpp
	mkdir -p "$(BUILD_DIR)"
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -MMD -MP -c $< -o "$@"

$(BUILD_DIR)/test_grid_geometry: tests/test_grid_geometry.cpp $(BUILD_DIR)/grid_geometry.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $< $(BUILD_DIR)/grid_geometry.o "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"

$(BUILD_DIR)/test_distance_scales: tests/test_distance_scales.cpp $(BUILD_DIR)/distance_scales.o $(BUILD_DIR)/grid_geometry.o $(BUILD_DIR)/solar_camera.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $< $(BUILD_DIR)/distance_scales.o $(BUILD_DIR)/grid_geometry.o $(BUILD_DIR)/solar_camera.o "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"

$(BUILD_DIR)/test_grid_renderer: tests/test_grid_renderer.mm $(BUILD_DIR)/GridRenderer.o $(BUILD_DIR)/RendererQuality.o $(BUILD_DIR)/grid_geometry.o $(BUILD_DIR)/distance_scales.o $(BUILD_DIR)/sky_model.o $(BUILD_DIR)/solar_camera.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(BUILD_DIR)/GridRenderer.o $(BUILD_DIR)/RendererQuality.o $(BUILD_DIR)/grid_geometry.o $(BUILD_DIR)/distance_scales.o $(BUILD_DIR)/sky_model.o $(BUILD_DIR)/solar_camera.o "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit -o "$@"

$(BUILD_DIR)/test_renderer_quality: tests/test_renderer_quality.mm $(BUILD_DIR)/RendererQuality.o
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $^ $(LDFLAGS) -framework AppKit -o "$@"

$(BUILD_DIR)/test_window_presentation: tests/test_window_presentation.mm $(BUILD_DIR)/WindowPresentationController.o
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $^ $(LDFLAGS) -framework AppKit -o "$@"

$(BUILD_DIR)/test_html_bridge_policy: tests/test_html_bridge_policy.mm $(BUILD_DIR)/html_bridge_policy.o
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $^ $(LDFLAGS) -framework Foundation -o "$@"

$(BUILD_DIR)/test_html_browser: tests/test_html_browser.mm $(BUILD_DIR)/HtmlBrowserController.o $(BUILD_DIR)/html_bridge_policy.o $(BUILD_DIR)/ScriptController.o $(BUILD_DIR)/script_transport.o $(BUILD_DIR)/star_brightness.o $(BUILD_DIR)/plus_time_step.o $(BUILD_DIR)/plus_time_playback.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit -framework UniformTypeIdentifiers $(WEB_FRAMEWORKS) -o "$@"

.PHONY: html-browser-test
html-browser-test: $(BUILD_DIR)/test_html_browser $(SCRIPT_HELPER)
	"$(BUILD_DIR)/test_html_browser" "$(abspath $(SCRIPT_HELPER))"

$(BUILD_DIR)/test_satellite_browser_model: tests/test_satellite_browser_model.mm $(BUILD_DIR)/satellite_browser_model.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(BUILD_DIR)/satellite_browser_model.o "$(CORE_LIBRARY)" $(LDFLAGS) -framework Foundation -o "$@"

$(BUILD_DIR)/test_satellite_scene: tests/test_satellite_scene.mm $(BUILD_DIR)/satellite_scene.o $(BUILD_DIR)/satellite_browser_model.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(BUILD_DIR)/satellite_scene.o $(BUILD_DIR)/satellite_browser_model.o "$(CORE_LIBRARY)" $(LDFLAGS) -framework Foundation -o "$@"

$(BUILD_DIR)/test_satellite_controller: tests/test_satellite_controller.mm $(BUILD_DIR)/SatelliteController.o $(BUILD_DIR)/satellite_browser_model.o $(BUILD_DIR)/satellite_display.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(BUILD_DIR)/SatelliteController.o $(BUILD_DIR)/satellite_browser_model.o $(BUILD_DIR)/satellite_display.o "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit -o "$@"

$(BUILD_DIR)/test_solar_spacecraft: tests/test_solar_spacecraft.mm $(filter-out $(BUILD_DIR)/main.o,$(OBJECTS)) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(filter-out $(BUILD_DIR)/main.o,$(OBJECTS)) "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit -framework UniformTypeIdentifiers $(IMAGE_FRAMEWORKS) $(MEDIA_FRAMEWORKS) $(WEB_FRAMEWORKS) -o "$@"

$(BUILD_DIR)/test_solar_satellites: tests/test_solar_satellites.mm $(filter-out $(BUILD_DIR)/main.o,$(OBJECTS)) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(filter-out $(BUILD_DIR)/main.o,$(OBJECTS)) "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit -framework UniformTypeIdentifiers $(IMAGE_FRAMEWORKS) $(MEDIA_FRAMEWORKS) $(WEB_FRAMEWORKS) -o "$@"

$(BUILD_DIR)/test_star_labels: tests/test_star_labels.cpp $(BUILD_DIR)/star_labels.o
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $^ $(LDFLAGS) -o "$@"

$(BUILD_DIR)/test_sky_model: tests/test_sky_model.cpp $(BUILD_DIR)/sky_model.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $< $(BUILD_DIR)/sky_model.o "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"

$(BUILD_DIR)/test_solar_model: tests/test_solar_model.cpp $(BUILD_DIR)/sky_model.o $(BUILD_DIR)/solar_camera.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $< $(BUILD_DIR)/sky_model.o $(BUILD_DIR)/solar_camera.o "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"

$(BUILD_DIR)/test_planet_surface: tests/test_planet_surface.cpp $(BUILD_DIR)/planet_surface.o $(BUILD_DIR)/solar_camera.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"

$(BUILD_DIR)/test_planet_textures: tests/test_planet_textures.mm $(BUILD_DIR)/planet_textures.o $(BUILD_DIR)/local_image.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) $(IMAGE_FRAMEWORKS) -o "$@"

$(BUILD_DIR)/test_playback_clock: tests/test_playback_clock.cpp $(BUILD_DIR)/playback_clock.o
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $^ $(LDFLAGS) -o "$@"

$(BUILD_DIR)/test_surface_navigation: tests/test_surface_navigation.cpp $(BUILD_DIR)/surface_navigation.o $(BUILD_DIR)/solar_camera.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $< $(BUILD_DIR)/surface_navigation.o $(BUILD_DIR)/solar_camera.o "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"

$(BUILD_DIR)/test_interplanetary_flight: tests/test_interplanetary_flight.cpp $(BUILD_DIR)/interplanetary_flight.o $(BUILD_DIR)/surface_navigation.o $(BUILD_DIR)/solar_camera.o $(BUILD_DIR)/sky_model.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $< $(BUILD_DIR)/interplanetary_flight.o $(BUILD_DIR)/surface_navigation.o $(BUILD_DIR)/solar_camera.o $(BUILD_DIR)/sky_model.o "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"

$(BUILD_DIR)/test_playback_controller: tests/test_playback_controller.mm $(BUILD_DIR)/PlaybackController.o $(BUILD_DIR)/playback_clock.o $(BUILD_DIR)/plus_time_step.o $(BUILD_DIR)/plus_time_playback.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit -o "$@"


$(BUILD_DIR)/test_observer_places: tests/test_observer_places.cpp $(BUILD_DIR)/observer_places.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $< $(BUILD_DIR)/observer_places.o "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"

$(BUILD_DIR)/test_gui_file_io: tests/test_gui_file_io.mm $(BUILD_DIR)/gui_file_io.o
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $^ $(LDFLAGS) -framework Foundation -o "$@"

$(BUILD_DIR)/test_catalog_browser_controller: tests/test_catalog_browser_controller.mm $(BUILD_DIR)/CatalogBrowserController.o $(BUILD_DIR)/catalog_browser_model.o $(BUILD_DIR)/sky_model.o $(BUILD_DIR)/constellation_display.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(BUILD_DIR)/CatalogBrowserController.o $(BUILD_DIR)/catalog_browser_model.o $(BUILD_DIR)/sky_model.o $(BUILD_DIR)/constellation_display.o "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit -o "$@"

$(BUILD_DIR)/test_extended_catalogs: tests/test_extended_catalogs.cpp $(BUILD_DIR)/extended_catalogs.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $< $(BUILD_DIR)/extended_catalogs.o "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"

$(BUILD_DIR)/test_sky_catalog_index: tests/test_sky_catalog_index.cpp $(BUILD_DIR)/sky_catalog_index.o $(BUILD_DIR)/sky_model.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $< $(BUILD_DIR)/sky_catalog_index.o $(BUILD_DIR)/sky_model.o "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"

SESSION_TEST_OBJECTS = $(BUILD_DIR)/session_state.o $(BUILD_DIR)/plus_time_step.o $(BUILD_DIR)/plus_time_playback.o $(BUILD_DIR)/solar_camera.o $(BUILD_DIR)/playback_clock.o $(BUILD_DIR)/calendar_time.o $(BUILD_DIR)/session_layers.o $(BUILD_DIR)/session_layers_json.o $(BUILD_DIR)/small_body_display.o $(BUILD_DIR)/satellite_display.o $(BUILD_DIR)/star_brightness.o $(BUILD_DIR)/atmosphere_renderer.o $(BUILD_DIR)/planet_surface.o $(BUILD_DIR)/earth_layers.o
SESSION_TEST_OBJECTS += $(BUILD_DIR)/eclipse_surface.o $(BUILD_DIR)/surface_depth.o $(BUILD_DIR)/radius_display.o

$(BUILD_DIR)/test_session_state: tests/test_session_state.mm $(SESSION_TEST_OBJECTS) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -framework Foundation -o "$@"

$(BUILD_DIR)/test_session_plus_state: tests/test_session_plus_state.mm $(SESSION_TEST_OBJECTS) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -framework Foundation -o "$@"

.PHONY: session-plus-test
session-plus-test: $(BUILD_DIR)/test_session_plus_state
	"$(BUILD_DIR)/test_session_plus_state"
test: session-plus-test

$(BUILD_DIR)/test_calendar_time: tests/test_calendar_time.cpp $(BUILD_DIR)/calendar_time.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $< $(BUILD_DIR)/calendar_time.o "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"

$(BUILD_DIR)/test_sky_background: tests/test_sky_background.mm $(BUILD_DIR)/sky_background.o $(BUILD_DIR)/grid_geometry.o $(BUILD_DIR)/local_image.o $(BUILD_DIR)/sky_model.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(BUILD_DIR)/sky_background.o $(BUILD_DIR)/grid_geometry.o $(BUILD_DIR)/local_image.o $(BUILD_DIR)/sky_model.o "$(CORE_LIBRARY)" $(LDFLAGS) $(IMAGE_FRAMEWORKS) -o "$@"

$(BUILD_DIR)/test_catalog_browser_model: tests/test_catalog_browser_model.mm $(BUILD_DIR)/catalog_browser_model.o $(BUILD_DIR)/extended_catalogs.o $(BUILD_DIR)/sky_model.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(BUILD_DIR)/catalog_browser_model.o $(BUILD_DIR)/extended_catalogs.o $(BUILD_DIR)/sky_model.o "$(CORE_LIBRARY)" $(LDFLAGS) -framework Foundation -o "$@"

$(BUILD_DIR)/test_display_output: tests/test_display_output.mm $(BUILD_DIR)/DisplayOutputController.o
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $^ $(LDFLAGS) -framework AppKit -o "$@"

SKY_VIEW_OBJECTS = $(addprefix $(BUILD_DIR)/,SkyView.o SkyCatalogRenderer.o StarRenderer.o RendererQuality.o star_labels.o sky_catalog_index.o sky_model.o sky_background.o local_image.o ConstellationRenderer.o constellation_display.o horizon_segments.o GridRenderer.o grid_geometry.o distance_scales.o solar_camera.o radius_display.o)
SKY_VIEW_OBJECTS += $(addprefix $(BUILD_DIR)/,star_brightness.o constellation_art_model.o constellation_art_projection.o ConstellationArtRenderer.o)
$(BUILD_DIR)/test_sky_view: tests/test_sky_view.mm $(SKY_VIEW_OBJECTS) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(SKY_VIEW_OBJECTS) "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit $(IMAGE_FRAMEWORKS) -o "$@"

DISPLAY_TEST_OBJECTS = $(SKY_VIEW_OBJECTS) $(addprefix $(BUILD_DIR)/,HorizonView.o SolarSceneRenderer.o SatelliteRenderer.o satellite_browser_model.o SmallBodyRenderer.o small_body_model.o small_body_display.o small_body_orbit_model.o satellite_display.o satellite_orbit_geometry.o SpacecraftRenderer.o spacecraft_browser_model.o planet_surface.o surface_navigation.o)
HORIZON_LANDSCAPE_TEST_OBJECTS = $(LANDSCAPE_OBJECTS) $(addprefix $(BUILD_DIR)/,observer_places.o place_display_model.o landscape_geometry.o)
DISPLAY_TEST_OBJECTS += $(BUILD_DIR)/earth_layers.o $(BUILD_DIR)/atmosphere_renderer.o $(HORIZON_LANDSCAPE_TEST_OBJECTS)
DISPLAY_TEST_OBJECTS += $(ECLIPSE_OBJECTS) $(BUILD_DIR)/satellite_scene.o $(BUILD_DIR)/surface_depth.o $(TERRAIN_OBJECTS)
$(BUILD_DIR)/test_display_rendering: tests/test_display_rendering.mm $(DISPLAY_TEST_OBJECTS) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(DISPLAY_TEST_OBJECTS) "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit $(IMAGE_FRAMEWORKS) -o "$@"

$(BUILD_DIR)/test_horizon_view: tests/test_horizon_view.mm $(BUILD_DIR)/HorizonView.o $(SKY_VIEW_OBJECTS) $(HORIZON_LANDSCAPE_TEST_OBJECTS) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit $(IMAGE_FRAMEWORKS) -o "$@"

$(BUILD_DIR)/test_small_body_model: tests/test_small_body_model.mm $(BUILD_DIR)/small_body_model.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(BUILD_DIR)/small_body_model.o "$(CORE_LIBRARY)" $(LDFLAGS) -framework Foundation -o "$@"

$(BUILD_DIR)/test_small_body_controller: tests/test_small_body_controller.mm $(BUILD_DIR)/SmallBodyController.o $(BUILD_DIR)/small_body_model.o $(BUILD_DIR)/small_body_display.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(BUILD_DIR)/SmallBodyController.o $(BUILD_DIR)/small_body_model.o $(BUILD_DIR)/small_body_display.o "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit -o "$@"

$(BUILD_DIR)/test_solar_small_bodies: tests/test_solar_small_bodies.mm $(filter-out $(BUILD_DIR)/main.o,$(OBJECTS)) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(filter-out $(BUILD_DIR)/main.o,$(OBJECTS)) "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit -framework UniformTypeIdentifiers $(IMAGE_FRAMEWORKS) $(MEDIA_FRAMEWORKS) $(WEB_FRAMEWORKS) -o "$@"

$(BUILD_DIR)/test_media_catalog: tests/test_media_catalog.mm $(BUILD_DIR)/media_catalog.o
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $^ $(LDFLAGS) -framework Foundation -o "$@"

$(BUILD_DIR)/test_media_controller: tests/test_media_controller.mm $(BUILD_DIR)/MediaController.o $(BUILD_DIR)/MediaImageView.o $(BUILD_DIR)/media_catalog.o $(BUILD_DIR)/local_image.o
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $^ $(LDFLAGS) -framework AppKit -framework UniformTypeIdentifiers $(IMAGE_FRAMEWORKS) $(MEDIA_FRAMEWORKS) -o "$@"

system-occlusion-test: $(BUILD_DIR)/test_display_output
	"$(BUILD_DIR)/test_display_output" --system-occlusion

system-fullscreen-test: $(BUILD_DIR)/test_window_presentation
	"$(BUILD_DIR)/test_window_presentation" --system-fullscreen

controller-test: $(BUILD_DIR)/test_spacecraft_controller $(BUILD_DIR)/test_solar_spacecraft $(BUILD_DIR)/test_satellite_controller $(BUILD_DIR)/test_solar_satellites $(BUILD_DIR)/test_small_body_controller $(BUILD_DIR)/test_solar_small_bodies $(BUILD_DIR)/test_media_controller $(BUILD_DIR)/test_catalog_browser_controller $(BUILD_DIR)/test_playback_controller $(BUILD_DIR)/test_display_output $(BUILD_DIR)/test_window_presentation script-test
	"$(BUILD_DIR)/test_spacecraft_controller"
	"$(BUILD_DIR)/test_solar_spacecraft"
	"$(BUILD_DIR)/test_satellite_controller"
	"$(BUILD_DIR)/test_solar_satellites"
	"$(BUILD_DIR)/test_small_body_controller"
	"$(BUILD_DIR)/test_solar_small_bodies"
	"$(BUILD_DIR)/test_media_controller"
	"$(BUILD_DIR)/test_catalog_browser_controller"
	"$(BUILD_DIR)/test_playback_controller"
	"$(BUILD_DIR)/test_display_output"
	"$(BUILD_DIR)/test_window_presentation"

test: $(BUILD_DIR)/test_spacecraft_browser_model $(BUILD_DIR)/test_spacecraft_renderer $(BUILD_DIR)/test_small_body_display $(BUILD_DIR)/test_satellite_display $(BUILD_DIR)/test_satellite_scene $(BUILD_DIR)/test_satellite_browser_model $(BUILD_DIR)/test_grid_geometry $(BUILD_DIR)/test_distance_scales $(BUILD_DIR)/test_grid_renderer $(BUILD_DIR)/test_renderer_quality $(BUILD_DIR)/test_html_bridge_policy $(BUILD_DIR)/test_display_rendering $(BUILD_DIR)/test_star_labels $(BUILD_DIR)/test_small_body_model $(BUILD_DIR)/test_media_catalog $(BUILD_DIR)/test_calendar_time $(BUILD_DIR)/test_sky_background $(BUILD_DIR)/test_gui_file_io $(BUILD_DIR)/test_observer_places $(BUILD_DIR)/test_catalog_browser_model $(BUILD_DIR)/test_extended_catalogs $(BUILD_DIR)/test_sky_catalog_index $(BUILD_DIR)/test_session_state $(BUILD_DIR)/test_sky_model $(BUILD_DIR)/test_solar_model $(BUILD_DIR)/test_planet_surface $(BUILD_DIR)/test_planet_textures $(BUILD_DIR)/test_playback_clock $(BUILD_DIR)/test_surface_navigation $(BUILD_DIR)/test_interplanetary_flight $(BUILD_DIR)/test_constellation_display $(BUILD_DIR)/test_horizon_segments $(BUILD_DIR)/test_satellite_orbit_geometry $(BUILD_DIR)/test_session_layers $(BUILD_DIR)/test_small_body_orbit_model $(BUILD_DIR)/test_small_body_orbit_controller
	"$(BUILD_DIR)/test_constellation_display"
	"$(BUILD_DIR)/test_horizon_segments"
	"$(BUILD_DIR)/test_satellite_orbit_geometry"
	"$(BUILD_DIR)/test_session_layers"
	"$(BUILD_DIR)/test_small_body_orbit_model"
	"$(BUILD_DIR)/test_small_body_orbit_controller"
	"$(BUILD_DIR)/test_spacecraft_browser_model"
	"$(BUILD_DIR)/test_spacecraft_renderer"
	"$(BUILD_DIR)/test_small_body_display"
	"$(BUILD_DIR)/test_satellite_display"
	"$(BUILD_DIR)/test_satellite_scene"
	"$(BUILD_DIR)/test_satellite_browser_model"
	"$(BUILD_DIR)/test_grid_geometry"
	"$(BUILD_DIR)/test_distance_scales"
	"$(BUILD_DIR)/test_grid_renderer"
	"$(BUILD_DIR)/test_renderer_quality"
	"$(BUILD_DIR)/test_html_bridge_policy"
	"$(BUILD_DIR)/test_display_rendering"
	"$(BUILD_DIR)/test_star_labels"
	"$(BUILD_DIR)/test_small_body_model"
	"$(BUILD_DIR)/test_media_catalog"
	"$(BUILD_DIR)/test_calendar_time"
	"$(BUILD_DIR)/test_sky_background"
	"$(BUILD_DIR)/test_gui_file_io"
	"$(BUILD_DIR)/test_observer_places"
	"$(BUILD_DIR)/test_catalog_browser_model"
	"$(BUILD_DIR)/test_extended_catalogs"
	"$(BUILD_DIR)/test_sky_catalog_index"
	"$(BUILD_DIR)/test_session_state"
	"$(BUILD_DIR)/test_sky_model"
	"$(BUILD_DIR)/test_solar_model"
	"$(BUILD_DIR)/test_planet_surface"
	"$(BUILD_DIR)/test_planet_textures"
	"$(BUILD_DIR)/test_playback_clock"
	"$(BUILD_DIR)/test_surface_navigation"
	"$(BUILD_DIR)/test_interplanetary_flight"

data-test: $(BUILD_DIR)/test_spacecraft_browser_model $(BUILD_DIR)/test_spacecraft_renderer $(BUILD_DIR)/test_satellite_scene $(BUILD_DIR)/test_satellite_browser_model $(BUILD_DIR)/test_display_rendering $(BUILD_DIR)/test_small_body_model $(BUILD_DIR)/test_media_catalog $(BUILD_DIR)/test_sky_background $(BUILD_DIR)/test_observer_places $(BUILD_DIR)/test_catalog_browser_model $(BUILD_DIR)/test_extended_catalogs $(BUILD_DIR)/test_sky_view $(BUILD_DIR)/test_horizon_view $(BUILD_DIR)/test_sky_model $(BUILD_DIR)/test_solar_model $(BUILD_DIR)/test_planet_textures $(BUILD_DIR)/test_interplanetary_flight $(BUILD_DIR)/test_constellation_renderer $(BUILD_DIR)/test_satellite_orbit_geometry $(BUILD_DIR)/test_small_body_orbit_model
	"$(BUILD_DIR)/test_constellation_renderer" "$${DATA_ROOT:?Set DATA_ROOT}"
	"$(BUILD_DIR)/test_satellite_orbit_geometry" "$${DATA_ROOT:?Set DATA_ROOT}"
	"$(BUILD_DIR)/test_small_body_orbit_model" "$${DATA_ROOT:?Set DATA_ROOT}"
	"$(BUILD_DIR)/test_spacecraft_browser_model" "$${DATA_ROOT:?Set DATA_ROOT}"
	"$(BUILD_DIR)/test_spacecraft_renderer" "$${DATA_ROOT:?Set DATA_ROOT}"
	"$(BUILD_DIR)/test_satellite_scene" "$${DATA_ROOT:?Set DATA_ROOT}"
	"$(BUILD_DIR)/test_satellite_browser_model" "$${DATA_ROOT:?Set DATA_ROOT}"
	"$(BUILD_DIR)/test_display_rendering" "$${DATA_ROOT:?Set DATA_ROOT}"
	"$(BUILD_DIR)/test_small_body_model" "$${DATA_ROOT:?Set DATA_ROOT}"
	"$(BUILD_DIR)/test_media_catalog" "$${DATA_ROOT:?Set DATA_ROOT}"
	"$(BUILD_DIR)/test_sky_background" "$${DATA_ROOT:?Set DATA_ROOT}"
	"$(BUILD_DIR)/test_observer_places" "$${DATA_ROOT:?Set DATA_ROOT}"
	"$(BUILD_DIR)/test_catalog_browser_model" "$${DATA_ROOT:?Set DATA_ROOT}"
	"$(BUILD_DIR)/test_extended_catalogs" "$${DATA_ROOT:?Set DATA_ROOT}"
	"$(BUILD_DIR)/test_sky_view" "$${DATA_ROOT:?Set DATA_ROOT}"
	"$(BUILD_DIR)/test_horizon_view" "$${DATA_ROOT:?Set DATA_ROOT}"
	"$(BUILD_DIR)/test_sky_model" "$${DATA_ROOT:?Set DATA_ROOT to the directory containing hip.dat and cf96.dat}"
	"$(BUILD_DIR)/test_solar_model" "$${DATA_ROOT:?Set DATA_ROOT to the directory containing hip.dat and cf96.dat}"
	"$(BUILD_DIR)/test_planet_textures" "$${DATA_ROOT:?Set DATA_ROOT to the directory containing hip.dat and cf96.dat}"
	"$(BUILD_DIR)/test_interplanetary_flight" "$${DATA_ROOT:?Set DATA_ROOT to the directory containing hip.dat and cf96.dat}"

smoke: all
	"$(EXECUTABLE)" --data-root "$${DATA_ROOT:?Set DATA_ROOT to the directory containing hip.dat and cf96.dat}" --smoke-test

run: all
	open -n "$(APP)" --args --data-root "$${DATA_ROOT:?Set DATA_ROOT to the directory containing hip.dat and cf96.dat}"

-include $(OBJECTS:.o=.d)

$(BUILD_DIR)/test_spacecraft_browser_model: tests/test_spacecraft_browser_model.mm $(BUILD_DIR)/spacecraft_browser_model.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(BUILD_DIR)/spacecraft_browser_model.o "$(CORE_LIBRARY)" $(LDFLAGS) -framework Foundation -o "$@"

$(BUILD_DIR)/test_spacecraft_renderer: tests/test_spacecraft_renderer.mm $(BUILD_DIR)/SpacecraftRenderer.o $(BUILD_DIR)/spacecraft_browser_model.o $(BUILD_DIR)/RendererQuality.o $(BUILD_DIR)/solar_camera.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(BUILD_DIR)/SpacecraftRenderer.o $(BUILD_DIR)/spacecraft_browser_model.o $(BUILD_DIR)/RendererQuality.o $(BUILD_DIR)/solar_camera.o "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit -o "$@"

$(BUILD_DIR)/test_spacecraft_controller: tests/test_spacecraft_controller.mm $(BUILD_DIR)/SpacecraftController.o $(BUILD_DIR)/spacecraft_browser_model.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(BUILD_DIR)/SpacecraftController.o $(BUILD_DIR)/spacecraft_browser_model.o "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit -o "$@"

$(BUILD_DIR)/test_small_body_display: tests/test_small_body_display.cpp $(BUILD_DIR)/small_body_display.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS)  $< $(BUILD_DIR)/small_body_display.o "$(CORE_LIBRARY)" $(LDFLAGS)  -o "$@"

$(BUILD_DIR)/test_satellite_display: tests/test_satellite_display.cpp $(BUILD_DIR)/satellite_display.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS)  $< $(BUILD_DIR)/satellite_display.o "$(CORE_LIBRARY)" $(LDFLAGS)  -o "$@"

$(BUILD_DIR)/test_constellation_display: tests/test_constellation_display.cpp $(BUILD_DIR)/constellation_display.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $< $(BUILD_DIR)/constellation_display.o "$(CORE_LIBRARY)" $(LDFLAGS)  -o "$@"

$(BUILD_DIR)/test_horizon_segments: tests/test_horizon_segments.cpp $(BUILD_DIR)/horizon_segments.o $(BUILD_DIR)/sky_model.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $< $(BUILD_DIR)/horizon_segments.o $(BUILD_DIR)/sky_model.o "$(CORE_LIBRARY)" $(LDFLAGS)  -o "$@"

$(BUILD_DIR)/test_constellation_renderer: tests/test_constellation_renderer.mm $(BUILD_DIR)/ConstellationRenderer.o $(BUILD_DIR)/RendererQuality.o $(BUILD_DIR)/horizon_segments.o $(BUILD_DIR)/sky_model.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(BUILD_DIR)/ConstellationRenderer.o $(BUILD_DIR)/RendererQuality.o $(BUILD_DIR)/horizon_segments.o $(BUILD_DIR)/sky_model.o "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit -o "$@"

$(BUILD_DIR)/test_satellite_orbit_geometry: tests/test_satellite_orbit_geometry.mm $(BUILD_DIR)/satellite_orbit_geometry.o $(BUILD_DIR)/satellite_browser_model.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(BUILD_DIR)/satellite_orbit_geometry.o $(BUILD_DIR)/satellite_browser_model.o "$(CORE_LIBRARY)" $(LDFLAGS) -framework Foundation -o "$@"

$(BUILD_DIR)/test_session_layers: tests/test_session_layers.mm $(BUILD_DIR)/session_layers.o $(BUILD_DIR)/small_body_display.o $(BUILD_DIR)/satellite_display.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(BUILD_DIR)/session_layers.o $(BUILD_DIR)/small_body_display.o $(BUILD_DIR)/satellite_display.o "$(CORE_LIBRARY)" $(LDFLAGS) -framework Foundation -o "$@"

$(BUILD_DIR)/test_small_body_orbit_model: tests/test_small_body_orbit_model.mm $(BUILD_DIR)/small_body_orbit_model.o $(BUILD_DIR)/small_body_display.o $(BUILD_DIR)/small_body_model.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(BUILD_DIR)/small_body_orbit_model.o $(BUILD_DIR)/small_body_display.o $(BUILD_DIR)/small_body_model.o "$(CORE_LIBRARY)" $(LDFLAGS) -framework Foundation -o "$@"

$(BUILD_DIR)/test_small_body_orbit_controller: tests/test_small_body_orbit_controller.mm $(BUILD_DIR)/SmallBodyOrbitController.o $(BUILD_DIR)/small_body_orbit_model.o $(BUILD_DIR)/small_body_display.o $(BUILD_DIR)/small_body_model.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(BUILD_DIR)/SmallBodyOrbitController.o $(BUILD_DIR)/small_body_orbit_model.o $(BUILD_DIR)/small_body_display.o $(BUILD_DIR)/small_body_model.o "$(CORE_LIBRARY)" $(LDFLAGS) -framework Foundation -o "$@"

$(BUILD_DIR)/test_planet_surface: $(BUILD_DIR)/earth_layers.o
$(BUILD_DIR)/test_planet_surface $(BUILD_DIR)/test_earth_layers $(BUILD_DIR)/test_atmosphere_renderer: $(BUILD_DIR)/eclipse_surface.o

$(BUILD_DIR)/test_earth_layers: tests/test_earth_layers.cpp $(BUILD_DIR)/earth_layers.o $(BUILD_DIR)/planet_surface.o $(BUILD_DIR)/solar_camera.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"

.PHONY: earth-layer-test
earth-layer-test: $(BUILD_DIR)/test_earth_layers
	"$(BUILD_DIR)/test_earth_layers"
test: earth-layer-test

$(BUILD_DIR)/test_star_brightness: tests/test_star_brightness.cpp $(BUILD_DIR)/star_brightness.o
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $^ $(LDFLAGS) -o "$@"

$(BUILD_DIR)/test_star_brightness_controller: tests/test_star_brightness_controller.mm $(BUILD_DIR)/StarBrightnessController.o $(BUILD_DIR)/star_brightness.o
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $^ $(LDFLAGS) -framework Foundation -o "$@"

$(BUILD_DIR)/test_star_name_selection: tests/test_star_name_selection.cpp $(BUILD_DIR)/star_name_selection.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"

$(BUILD_DIR)/test_constellation_art_model: tests/test_constellation_art_model.cpp $(BUILD_DIR)/constellation_art_model.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"

$(BUILD_DIR)/test_constellation_art_projection: tests/test_constellation_art_projection.cpp $(BUILD_DIR)/constellation_art_projection.o $(BUILD_DIR)/sky_model.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"

$(BUILD_DIR)/test_constellation_art_renderer: tests/test_constellation_art_renderer.mm $(BUILD_DIR)/ConstellationArtRenderer.o $(BUILD_DIR)/constellation_art_model.o $(BUILD_DIR)/constellation_art_projection.o $(BUILD_DIR)/RendererQuality.o $(BUILD_DIR)/StarRenderer.o $(BUILD_DIR)/star_labels.o $(BUILD_DIR)/star_brightness.o $(BUILD_DIR)/sky_model.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit -o "$@"

$(BUILD_DIR)/test_horizon_background_view: tests/test_horizon_background_view.mm $(BUILD_DIR)/HorizonView.o $(SKY_VIEW_OBJECTS) $(HORIZON_LANDSCAPE_TEST_OBJECTS) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit $(IMAGE_FRAMEWORKS) -o "$@"

.PHONY: star-art-test
star-art-test: $(BUILD_DIR)/test_star_brightness $(BUILD_DIR)/test_star_brightness_controller $(BUILD_DIR)/test_star_name_selection $(BUILD_DIR)/test_constellation_art_model $(BUILD_DIR)/test_constellation_art_projection $(BUILD_DIR)/test_horizon_background_view
	"$(BUILD_DIR)/test_star_brightness"
	"$(BUILD_DIR)/test_star_brightness_controller"
	"$(BUILD_DIR)/test_star_name_selection"
	"$(BUILD_DIR)/test_constellation_art_model"
	"$(BUILD_DIR)/test_constellation_art_projection"
	"$(BUILD_DIR)/test_horizon_background_view"
test: star-art-test

$(BUILD_DIR)/test_earth_layer_scene: tests/test_earth_layer_scene.mm $(DISPLAY_TEST_OBJECTS) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(DISPLAY_TEST_OBJECTS) "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit $(IMAGE_FRAMEWORKS) -o "$@"

.PHONY: earth-scene-test
earth-scene-test: $(BUILD_DIR)/test_earth_layer_scene
	"$(BUILD_DIR)/test_earth_layer_scene"
test: earth-scene-test

$(BUILD_DIR)/test_atmosphere_renderer: tests/test_atmosphere_renderer.cpp $(BUILD_DIR)/atmosphere_renderer.o $(BUILD_DIR)/planet_surface.o $(BUILD_DIR)/earth_layers.o $(BUILD_DIR)/solar_camera.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $< $(filter-out core,$(filter %.o,$^)) "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"

.PHONY: atmosphere-renderer-test
atmosphere-renderer-test: $(BUILD_DIR)/test_atmosphere_renderer
	"$(BUILD_DIR)/test_atmosphere_renderer"
test: atmosphere-renderer-test

.PHONY: star-art-data-test
star-art-data-test: $(BUILD_DIR)/test_star_name_selection $(BUILD_DIR)/test_constellation_art_model $(BUILD_DIR)/test_constellation_art_renderer
	"$(BUILD_DIR)/test_star_name_selection" "$${DATA_ROOT:?Set DATA_ROOT}/star_names_jp.dat"
	"$(BUILD_DIR)/test_constellation_art_model" "$${DATA_ROOT:?Set DATA_ROOT}"
	"$(BUILD_DIR)/test_constellation_art_renderer" "$${DATA_ROOT:?Set DATA_ROOT}"
data-test: star-art-data-test

$(BUILD_DIR)/test_plus_time_step: tests/test_plus_time_step.cpp $(BUILD_DIR)/plus_time_step.o $(BUILD_DIR)/plus_time_playback.o $(BUILD_DIR)/calendar_time.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"

$(BUILD_DIR)/test_place_display_model: tests/test_place_display_model.cpp $(BUILD_DIR)/place_display_model.o $(BUILD_DIR)/observer_places.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"

$(BUILD_DIR)/test_landscape_geometry: tests/test_landscape_geometry.cpp $(BUILD_DIR)/landscape_geometry.o
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $^ $(LDFLAGS) -o "$@"

$(BUILD_DIR)/test_sdss_spatial_model: tests/test_sdss_spatial_model.cpp $(BUILD_DIR)/sdss_spatial_model.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"

.PHONY: plus-spatial-time-test plus-spatial-data-test
plus-spatial-time-test: $(BUILD_DIR)/test_plus_time_step $(BUILD_DIR)/test_place_display_model $(BUILD_DIR)/test_landscape_geometry $(BUILD_DIR)/test_sdss_spatial_model
	"$(BUILD_DIR)/test_plus_time_step"
	"$(BUILD_DIR)/test_place_display_model"
	"$(BUILD_DIR)/test_landscape_geometry"
	"$(BUILD_DIR)/test_sdss_spatial_model"
test: plus-spatial-time-test

plus-spatial-data-test: $(BUILD_DIR)/test_place_display_model $(BUILD_DIR)/test_sdss_spatial_model
	"$(BUILD_DIR)/test_place_display_model" "$${DATA_ROOT:?Set DATA_ROOT}"
	"$(BUILD_DIR)/test_sdss_spatial_model" "$${DATA_ROOT:?Set DATA_ROOT}"
data-test: plus-spatial-data-test

$(BUILD_DIR)/test_earth_landscapes: tests/test_earth_landscapes.mm $(HORIZON_LANDSCAPE_TEST_OBJECTS) $(addprefix $(BUILD_DIR)/,sky_model.o local_image.o RendererQuality.o) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit $(IMAGE_FRAMEWORKS) -o "$@"

.PHONY: earth-landscape-test earth-landscape-data-test
earth-landscape-test: $(BUILD_DIR)/test_earth_landscapes
	"$(BUILD_DIR)/test_earth_landscapes"
earth-landscape-data-test: $(BUILD_DIR)/test_earth_landscapes
	"$(BUILD_DIR)/test_earth_landscapes" "$${DATA_ROOT:?Set DATA_ROOT}"
test: earth-landscape-test
data-test: earth-landscape-data-test

$(BUILD_DIR)/test_eclipse_surface: tests/test_eclipse_surface.cpp $(addprefix $(BUILD_DIR)/,planet_surface.o earth_layers.o eclipse_surface.o solar_camera.o) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"

$(BUILD_DIR)/test_eclipse_display: tests/test_eclipse_display.mm $(addprefix $(BUILD_DIR)/,eclipse_display.o eclipse_surface.o satellite_scene.o satellite_browser_model.o surface_navigation.o sky_model.o solar_camera.o) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -framework Foundation -o "$@"

$(BUILD_DIR)/test_eclipse_cone_renderer: tests/test_eclipse_cone_renderer.cpp $(addprefix $(BUILD_DIR)/,eclipse_cone_renderer.o planet_surface.o earth_layers.o eclipse_surface.o solar_camera.o) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"

$(BUILD_DIR)/test_eclipse_scene: tests/test_eclipse_scene.mm $(DISPLAY_TEST_OBJECTS) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(DISPLAY_TEST_OBJECTS) "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit $(IMAGE_FRAMEWORKS) -o "$@"

.PHONY: eclipse-renderer-test
eclipse-renderer-test: $(BUILD_DIR)/test_eclipse_surface $(BUILD_DIR)/test_eclipse_display $(BUILD_DIR)/test_eclipse_cone_renderer $(BUILD_DIR)/test_eclipse_scene
	"$(BUILD_DIR)/test_eclipse_surface"
	"$(BUILD_DIR)/test_eclipse_display"
	"$(BUILD_DIR)/test_eclipse_cone_renderer"
	"$(BUILD_DIR)/test_eclipse_scene"
test: eclipse-renderer-test

# UNIT8: 原版の純計算と画面接続を別々に検証する。
$(BUILD_DIR)/test_script_controller $(BUILD_DIR)/test_html_browser: $(BUILD_DIR)/plus_time_calendar.o
$(BUILD_DIR)/test_script_controller $(BUILD_DIR)/test_html_browser $(BUILD_DIR)/test_script_time: $(BUILD_DIR)/radius_display.o
$(BUILD_DIR)/test_playback_controller: $(BUILD_DIR)/plus_time_animation.o $(BUILD_DIR)/plus_time_calendar.o
$(BUILD_DIR)/test_planet_surface $(BUILD_DIR)/test_earth_layers $(BUILD_DIR)/test_atmosphere_renderer $(BUILD_DIR)/test_eclipse_surface $(BUILD_DIR)/test_eclipse_cone_renderer: $(BUILD_DIR)/surface_depth.o

$(BUILD_DIR)/test_galaxy_camera: tests/test_galaxy_camera.cpp $(BUILD_DIR)/galaxy_camera.o $(BUILD_DIR)/solar_camera.o
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $^ $(LDFLAGS) -o "$@"
$(BUILD_DIR)/test_galaxy_spatial_scene: tests/test_galaxy_spatial_scene.cpp $(addprefix $(BUILD_DIR)/,galaxy_spatial_scene.o galaxy_camera.o solar_camera.o sdss_spatial_model.o) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"
$(BUILD_DIR)/test_galaxy_spatial_load: tests/test_galaxy_spatial_load.cpp $(addprefix $(BUILD_DIR)/,galaxy_spatial_load.o galaxy_spatial_scene.o galaxy_camera.o solar_camera.o sdss_spatial_model.o) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"
$(BUILD_DIR)/test_galaxy_renderer: tests/test_galaxy_renderer.mm $(addprefix $(BUILD_DIR)/,GalaxyRenderer.o galaxy_spatial_scene.o galaxy_camera.o solar_camera.o sdss_spatial_model.o RendererQuality.o) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit -o "$@"
$(BUILD_DIR)/test_galaxy_controller: tests/test_galaxy_controller.mm $(GALAXY_OBJECTS) $(addprefix $(BUILD_DIR)/,solar_camera.o sdss_spatial_model.o RendererQuality.o) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit -o "$@"

$(BUILD_DIR)/test_terrain_surface: tests/test_terrain_surface.cpp $(addprefix $(BUILD_DIR)/,terrain_mesh.o terrain_surface.o solar_camera.o) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"
$(BUILD_DIR)/test_terrain_snapshot: tests/test_terrain_snapshot.cpp $(TERRAIN_OBJECTS) $(BUILD_DIR)/solar_camera.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"
$(BUILD_DIR)/test_terrain_surface_controller: tests/test_terrain_surface_controller.mm $(TERRAIN_OBJECTS) $(addprefix $(BUILD_DIR)/,TerrainSurfaceController.o solar_camera.o) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -framework Foundation -o "$@"
$(BUILD_DIR)/test_terrain_compositing: tests/test_terrain_compositing.cpp $(addprefix $(BUILD_DIR)/,terrain_mesh.o terrain_surface.o surface_depth.o planet_surface.o atmosphere_renderer.o earth_layers.o solar_camera.o eclipse_surface.o) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"

$(BUILD_DIR)/test_plus_time_calendar: tests/test_plus_time_calendar.cpp $(addprefix $(BUILD_DIR)/,plus_time_calendar.o plus_time_step.o) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"
$(BUILD_DIR)/test_plus_time_animation: tests/test_plus_time_animation.cpp $(BUILD_DIR)/plus_time_animation.o core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -o "$@"
$(BUILD_DIR)/test_time_animation_controller: tests/test_time_animation_controller.mm $(addprefix $(BUILD_DIR)/,PlaybackController.o playback_clock.o plus_time_step.o plus_time_playback.o plus_time_calendar.o plus_time_animation.o) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit -o "$@"
$(BUILD_DIR)/test_script_time: tests/test_script_time.mm $(addprefix $(BUILD_DIR)/,ScriptController.o script_transport.o star_brightness.o plus_time_step.o plus_time_playback.o plus_time_calendar.o) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $(filter-out core,$^) "$(CORE_LIBRARY)" $(LDFLAGS) -framework Foundation -o "$@"
$(BUILD_DIR)/test_radius_display: tests/test_radius_display.cpp $(BUILD_DIR)/radius_display.o
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $^ $(LDFLAGS) -o "$@"
$(BUILD_DIR)/test_radius_display_controller: tests/test_radius_display_controller.mm $(addprefix $(BUILD_DIR)/,RadiusDisplayController.o radius_display.o)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $^ $(LDFLAGS) -framework AppKit -o "$@"

.PHONY: unit8-test galaxy-controller-test script-time-test
unit8-test: $(addprefix $(BUILD_DIR)/,test_galaxy_camera test_galaxy_spatial_scene test_galaxy_spatial_load test_galaxy_renderer test_terrain_surface test_terrain_snapshot test_terrain_surface_controller test_terrain_compositing test_plus_time_calendar test_plus_time_animation test_time_animation_controller test_radius_display test_radius_display_controller)
	@for binary in $^; do "$$binary" || exit $$?; done
test: unit8-test
galaxy-controller-test: $(BUILD_DIR)/test_galaxy_controller
	"$(BUILD_DIR)/test_galaxy_controller"
script-time-test: $(BUILD_DIR)/test_script_time $(SCRIPT_HELPER)
	"$(BUILD_DIR)/test_script_time" "$(abspath $(SCRIPT_HELPER))"

$(BUILD_DIR)/test_solar_terrain: tests/test_solar_terrain.mm $(DISPLAY_TEST_OBJECTS) core
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -fobjc-arc $< $(DISPLAY_TEST_OBJECTS) "$(CORE_LIBRARY)" $(LDFLAGS) -framework AppKit $(IMAGE_FRAMEWORKS) -o "$@"
.PHONY: solar-terrain-test
solar-terrain-test: $(BUILD_DIR)/test_solar_terrain
	"$(BUILD_DIR)/test_solar_terrain"
test: solar-terrain-test
