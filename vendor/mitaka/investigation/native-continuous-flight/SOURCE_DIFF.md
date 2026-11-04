# 連続惑星間飛行のソース差分

計測時刻: 2026-10-29T06:27:33.889946Z。`before/` の全ファイルは `source-snapshot.json` に記録した SHA256 と一致した。

対象は `native/core/`、`native/gui/`、`policy_gates/`、`IMPLEMENTATION_POLICY.md`。`build*`、`investigation/` の証跡・検証文書、`temp_gates/` は除外した。

追加 8、変更 18、削除 0 ファイル。追加 1638 行、削除 473 行、合計 2111 行。各ファイルを `git diff --no-index --no-ext-diff --numstat` で計測した。

| ファイル | 状態 | 追加行 | 削除行 |
| --- | --- | ---: | ---: |
| `IMPLEMENTATION_POLICY.md` | 変更 | 5 | 2 |
| `native/gui/Info.plist` | 変更 | 2 | 2 |
| `native/gui/Makefile` | 変更 | 8 | 3 |
| `native/gui/README.md` | 変更 | 60 | 9 |
| `native/gui/include/AppControllerInternal.h` | 変更 | 5 | 0 |
| `native/gui/include/SolarSceneRenderer.h` | 変更 | 1 | 0 |
| `native/gui/include/SolarSystemView.h` | 変更 | 13 | 3 |
| `native/gui/include/interplanetary_flight.hpp` | 追加 | 55 | 0 |
| `native/gui/include/planet_surface.hpp` | 変更 | 17 | 0 |
| `native/gui/src/AppController.mm` | 変更 | 26 | 6 |
| `native/gui/src/AppFlightSmokeTests.mm` | 追加 | 79 | 0 |
| `native/gui/src/AppSmokeTests.mm` | 変更 | 1 | 1 |
| `native/gui/src/SolarSceneRenderer.mm` | 変更 | 56 | 11 |
| `native/gui/src/SolarSystemNavigation.mm` | 追加 | 230 | 0 |
| `native/gui/src/SolarSystemSmokeTests.mm` | 追加 | 346 | 0 |
| `native/gui/src/SolarSystemView.mm` | 変更 | 31 | 411 |
| `native/gui/src/SolarSystemViewInternal.h` | 追加 | 52 | 0 |
| `native/gui/src/interplanetary_flight.cpp` | 追加 | 283 | 0 |
| `native/gui/src/planet_surface.cpp` | 変更 | 56 | 21 |
| `native/gui/tests/test_interplanetary_flight.cpp` | 追加 | 229 | 0 |
| `native/gui/tests/test_planet_surface.cpp` | 変更 | 48 | 0 |
| `policy_gates/continuous_flight.md` | 追加 | 31 | 0 |
| `policy_gates/moon_surface_navigation.md` | 変更 | 1 | 1 |
| `policy_gates/planet_textures.md` | 変更 | 1 | 1 |
| `policy_gates/solar_view.md` | 変更 | 1 | 1 |
| `policy_gates/time_playback.md` | 変更 | 1 | 1 |

変更前後の SHA256 は [source-diff.json](source-diff.json) に記録した。`native/core/` の変更ファイルは 0 件。

作業ルートの `git status --short` は終了コード 128（Git リポジトリではない）。Git の新規初期化と commit は行っていない。
