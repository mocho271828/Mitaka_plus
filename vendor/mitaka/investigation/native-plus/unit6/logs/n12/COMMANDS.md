# N12 局所試験の再現と証跡

2026-10-29、`/Users/kota/mitaka/repositories/Mitaka` の共有作業ツリーで実行。原本は読み取りのみ。ここには最終の build / test ログ 18 本を保存する。ログはコンパイラ呼出しと試験集計のみで、原データ本文や認証情報を含まない。

各構成で以下と同じターゲット・変数を指定し、各コマンドの exit 0 を確認した。build ディレクトリは構成別に分離する。

| 構成 | suffix | 追加 make 変数 |
| --- | --- | --- |
| 通常 arm64 | 空 | なし |
| ASan/UBSan arm64 | `-san` | `SANITIZE=address,undefined` |
| x86_64 | `-x86` | `ARCH=x86_64` |

通常構成の再実行例（他構成は上表の suffix と変数を追加）:

```sh
cd /Users/kota/mitaka/repositories/Mitaka/native/core
make -j2 BUILD_DIR=build-unit6-atmosphere build-unit6-atmosphere/test_atmosphere build-unit6-atmosphere/test_atmosphere_upstream
build-unit6-atmosphere/test_atmosphere
build-unit6-atmosphere/test_atmosphere_upstream --emmap '/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data/emmap.dat'
build-unit6-atmosphere/test_atmosphere_upstream --emmap '/Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data/emmap.dat'
cd /Users/kota/mitaka/repositories/Mitaka/native/gui
make -j2 BUILD_DIR=build-unit6-atmosphere-gui build-unit6-atmosphere-gui/test_atmosphere_renderer
build-unit6-atmosphere-gui/test_atmosphere_renderer
```

製品側は C++17 / `-Wall -Wextra -Wpedantic -Werror`。SAN は `address,undefined`、`-O1 -fno-omit-frame-pointer`。公式抽出参照だけに既存の CP932 / anonymous struct 許容フラグと `-Wno-unused-variable` を用い、原関数を修正しない。

## 結果

| ログ接頭辞 | core | 純 renderer | Plus / 通常版の参照 |
| --- | --- | --- | --- |
| `normal` | 733 checks PASS | 4,259 checks PASS | 各 single 12,606 成分完全一致、multiple 1,584 中 1,385 完全一致、許容差内 |
| `san` | 733 checks PASS | 4,259 checks PASS | 同上、ASan/UBSan 診断なし |
| `x86` | 733 checks PASS | 4,259 checks PASS | 各 single 12,606 / multiple 1,584 成分すべて完全一致 |

各原本のヘッダー・全半径・全 RGB ノードも公式 loader と完全一致。地表内向きは別検証で各 64 rays が native の厳密 0。通常の数値比較とこの遮蔽境界を混ぜない。詳細は [core provenance](../../../../../native/core/ATMOSPHERE_PROVENANCE.md) と [描画契約](../../../../../native/gui/ATMOSPHERE_RENDERING.md)を参照。

`*-build.log` は core と参照 build、`*.log` は core 試験、`*-reference-{plus,regular}.log` は原本別比較、`*-renderer-build.log` / `*-renderer.log` は GUI の純描画 build / 試験。これらは UNIT6 全体のアプリ試験とは別の局所証跡。

独立レビュー担当 `plus_scripting` が core 入力保持・数値境界・原式と renderer の座標変換・最短遮蔽終端・加算合成を読み取り、修正必須指摘なしと報告した。レビュー時に検討した極小正半径の二乗 underflow は入力境界で拒否する回帰を追加済み。担当は同じ局所結果を利用し、試験を独立再実行していない。

`SOURCE_SHA256SUMS` はこの局所実装・試験と原公式ファイルの固定 hash。共有 Makefile や SolarSceneRenderer は他機能の統合作業が続くためここでは固定せず、UNIT6 全体の最終検証で固定する。`SHA256SUMS` はこのディレクトリの記録の hash。
