# 時間連続再生のソース差分

計測時刻: 2026-10-29T05:16:40.418069+00:00。変更前の `before/` は `source-snapshot.json` に記録した全 SHA256 と一致した。

対象は `native/core/`、`native/gui/`、`policy_gates/`、`IMPLEMENTATION_POLICY.md`。`build*` ディレクトリ、`investigation/` の証跡と `VALIDATION.md`、`temp_gates/` は除外した。

追加 7、変更 8、削除 0 ファイル。追加 1,099 行、削除 17 行、合計 1,116 行。各ファイルを `git diff --no-index --no-ext-diff --numstat` で計測した。

| ファイル | 状態 | 追加行 | 削除行 |
| --- | --- | ---: | ---: |
| `IMPLEMENTATION_POLICY.md` | 変更 | 3 | 1 |
| `native/gui/Info.plist` | 変更 | 2 | 2 |
| `native/gui/Makefile` | 変更 | 13 | 3 |
| `native/gui/README.md` | 変更 | 51 | 2 |
| `native/gui/include/AppController.h` | 変更 | 1 | 1 |
| `native/gui/include/PlaybackController.h` | 追加 | 25 | 0 |
| `native/gui/include/SolarSystemView.h` | 変更 | 1 | 0 |
| `native/gui/include/playback_clock.hpp` | 追加 | 48 | 0 |
| `native/gui/src/AppController.mm` | 変更 | 127 | 7 |
| `native/gui/src/PlaybackController.mm` | 追加 | 242 | 0 |
| `native/gui/src/SolarSystemView.mm` | 変更 | 5 | 1 |
| `native/gui/src/playback_clock.cpp` | 追加 | 61 | 0 |
| `native/gui/tests/test_playback_clock.cpp` | 追加 | 234 | 0 |
| `native/gui/tests/test_playback_controller.mm` | 追加 | 256 | 0 |
| `policy_gates/time_playback.md` | 追加 | 30 | 0 |

`native/core/` の 25 ファイルは開始時からパス集合と SHA256 がすべて一致し、変更はなかった。各 SHA256 と差分の変更前後の SHA256 は [`source-diff.json`](source-diff.json) に記録した。

作業ルートの `git status --short` は終了コード 128（Git リポジトリではない）だった。Git の新規初期化と commit は行っていない。
