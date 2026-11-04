# 月表示・地表移動のソース差分

計測時刻: 2026-10-29T05:50:28.906343+00:00。変更前の `before/` は `source-snapshot.json` に記録した全 SHA256 と一致した。

対象は `native/core/`、`native/gui/`、`policy_gates/`、`IMPLEMENTATION_POLICY.md`。`build*` ディレクトリ、`investigation/` の証跡と `VALIDATION.md`、`temp_gates/` は除外した。

追加 14、変更 28、削除 0 ファイル。追加 3,000 行、削除 531 行、合計 3,531 行。各ファイルを `git diff --no-index --no-ext-diff --numstat` で計測した。

| ファイル | 状態 | 追加行 | 削除行 |
| --- | --- | ---: | ---: |
| `IMPLEMENTATION_POLICY.md` | 変更 | 5 | 2 |
| `native/core/LUNAR_PROVENANCE.md` | 追加 | 108 | 0 |
| `native/core/Makefile` | 変更 | 16 | 3 |
| `native/core/README.md` | 変更 | 29 | 2 |
| `native/core/include/mitaka/lunar.hpp` | 追加 | 22 | 0 |
| `native/core/src/lunar.cpp` | 追加 | 310 | 0 |
| `native/core/tests/extract_lunar_orientation.awk` | 追加 | 52 | 0 |
| `native/core/tests/test_lunar.cpp` | 追加 | 166 | 0 |
| `native/core/tests/test_lunar_upstream.cpp` | 追加 | 144 | 0 |
| `native/gui/Info.plist` | 変更 | 2 | 2 |
| `native/gui/Makefile` | 変更 | 6 | 2 |
| `native/gui/README.md` | 変更 | 67 | 28 |
| `native/gui/THIRD_PARTY_NOTICES.txt` | 変更 | 3 | 1 |
| `native/gui/include/AppControllerInternal.h` | 追加 | 59 | 0 |
| `native/gui/include/SolarSceneRenderer.h` | 追加 | 29 | 0 |
| `native/gui/include/SolarSystemView.h` | 変更 | 11 | 0 |
| `native/gui/include/planet_surface.hpp` | 変更 | 14 | 0 |
| `native/gui/include/planet_textures.hpp` | 変更 | 3 | 3 |
| `native/gui/include/sky_model.hpp` | 変更 | 13 | 8 |
| `native/gui/include/solar_camera.hpp` | 変更 | 11 | 4 |
| `native/gui/include/surface_navigation.hpp` | 追加 | 59 | 0 |
| `native/gui/src/AppController.mm` | 変更 | 80 | 194 |
| `native/gui/src/AppSmokeTests.mm` | 追加 | 197 | 0 |
| `native/gui/src/SkyView.mm` | 変更 | 7 | 5 |
| `native/gui/src/SolarSceneRenderer.mm` | 追加 | 268 | 0 |
| `native/gui/src/SolarSystemView.mm` | 変更 | 314 | 194 |
| `native/gui/src/planet_surface.cpp` | 変更 | 108 | 11 |
| `native/gui/src/planet_textures.mm` | 変更 | 2 | 2 |
| `native/gui/src/sky_model.cpp` | 変更 | 57 | 22 |
| `native/gui/src/solar_camera.cpp` | 変更 | 64 | 8 |
| `native/gui/src/surface_navigation.cpp` | 追加 | 155 | 0 |
| `native/gui/tests/test_planet_surface.cpp` | 変更 | 141 | 0 |
| `native/gui/tests/test_planet_textures.mm` | 変更 | 36 | 5 |
| `native/gui/tests/test_sky_model.cpp` | 変更 | 53 | 16 |
| `native/gui/tests/test_solar_model.cpp` | 変更 | 56 | 8 |
| `native/gui/tests/test_surface_navigation.cpp` | 追加 | 294 | 0 |
| `policy_gates/moon_surface_navigation.md` | 追加 | 28 | 0 |
| `policy_gates/native_gui.md` | 変更 | 1 | 1 |
| `policy_gates/planet_rotation.md` | 変更 | 1 | 1 |
| `policy_gates/planet_textures.md` | 変更 | 4 | 4 |
| `policy_gates/solar_view.md` | 変更 | 2 | 2 |
| `policy_gates/time_playback.md` | 変更 | 3 | 3 |

差分の変更前後の SHA256 は [`source-diff.json`](source-diff.json) に記録した。

作業ルートの `git status --short` は終了コード 128（Git リポジトリではない）だった。Git の新規初期化と commit は行っていない。
