# N01: 軌道 snapshot と非同期計算の独立検証

## 検証した範囲

2026-10-29。UNIT4 の commit `002adcf663fd5005e14ac86c343a3ec7e56fa706` 後、N01 の軌道計算を新規の model / controller として実装した。
本記録はこの境界の検証結果であり、App のメニュー、描画、Lua、状態保存を含む UNIT5 全体の完了判定ではない。
原典と native 契約の区別は [彗星軌道監査](comet-orbit-contracts.md)、接続方針は [N01 計画](n01-integration-plan.md)、既存 sampler / display の検証は [ヘルパー検証](comet-display-helper-validation.md) を参照する。

担当の新規ファイルは次の 7 点、合計 751 行。製品ファイルは最大 130 行、試験は最大 286 行である。

- `native/gui/include/small_body_orbit_model.hpp` / `src/small_body_orbit_model.cpp`
- `native/gui/include/SmallBodyOrbitController.h` / `src/SmallBodyOrbitController.mm`
- `native/gui/tests/small_body_orbit_test_fixture.hpp`
- `native/gui/tests/test_small_body_orbit_model.mm`
- `native/gui/tests/test_small_body_orbit_controller.mm`

## 実装した契約

model は元 SmallBodyModel / SmallBodyDisplayModel、固定 TDB 区間、原行と同じ長さの optional paths、要求数・完了数・未評価数・取消状態を保持する。
display の orbit が有効な行だけを既存 TDB sampler で計算する。legacy numeric JD の位置 evaluator へ切り替えず、時系・参照面・要素が不明な行も標本の診断付きで残す。
未評価数は、計算した要求行のうち一つ以上の標本に位置がない行数であり、区間内に一部欠損のある行を含む。

入力は計算前に検証する。モデルと dataset の同一性、有限で昇順の区間、丸め後も異なる時刻、2～4096 標本、要求行数 × 標本数が 524,288 以下という条件を満たさなければ、全要求を説明付きで拒否する。
上限超過による原行の削除・要求行の切り詰めはしない。取消は各行の計算前と最終行後に確認する。
成功した隣接標本だけを結ぶ既存 sampler の契約を維持する。

controller は main thread で要求を検証し、serial queue で計算する。
世代番号の一致する完了だけを main thread へ返す。取消・再要求・invalidate・破棄後の旧 callback は適用しない。
cancel は成功 cache を保持して再利用でき、invalidate は cache を破棄する終端操作である。

cache のキーはモデルの同一性、要求行列、区間の両端と標本数である。
ラベル等の変更だけで要求行が同じなら幾何を再利用し、snapshot.display は計算要求時の由来を保持する。
描画側は最新の display で可視性を判定する。保留中の同じ要求は completion を更新し、完成済み cache の通知も非同期で行う。
入力拒否は、進行中の正常な要求を取り消さない。

C++17、既存 evaluator / sampler、Foundation、dispatch を再利用し、新しい依存や軌道数学は追加していない。
原本へ書き込む処理はない。

## 実行結果

専用ディレクトリ `native/gui/build-unit5-orbit-pipeline{,-san,-x86}` を使った。
全構成に `-std=c++17 -Wall -Wextra -Wpedantic -Werror -mmacosx-version-min=13.0` とリンク時の `-Wl,-fatal_warnings` を指定した。
通常と sanitizer は arm64、x86_64 は Rosetta で実行した。macOS 13 実機での確認ではない。

| 構成 | ビルド | model | controller |
| --- | --- | --- | --- |
| 通常 arm64 | exit 0 | 30,882 checks / exit 0 | 59 checks / exit 0 |
| ASan + UBSan arm64 | exit 0 | 30,882 checks / exit 0 | 59 checks / exit 0 |
| x86_64 / Rosetta | exit 0 | 30,882 checks / exit 0 | 59 checks / exit 0 |

sanitizer は `ASAN_OPTIONS=halt_on_error=1 UBSAN_OPTIONS=halt_on_error=1` で実行した。LeakSanitizer の実行結果は含まない。
core と GUI の必要な source を同じ構成で専用ディレクトリへコンパイルし、他担当の build object を共有していない。

ローカル原本は `/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data` を既存 loader で読み取った。
全 19,475 行を保持し、彗星 2,457 行を要求、69 行を未評価・一部欠損として保持した。
これらの件数を fixture の固定期待値として置き換えていない。

主な試験は次のとおり。

- model: 既存 evaluator との位置一致、未知時系・参照面、欠損軌道、一部期間欠損、隣接成功線分、種類・集合ごとの要求、原 bytes 不変、null / dataset 不一致、NaN / Inf / 差の overflow / 隣接 double の丸め、空要求でも区間検証、129 行 × 4096 の全体拒否、128 行 × 4096 の境界受理、要求前・途中・最終行後・空要求の取消。
- controller: 保留中の重複要求、ラベルのみの cache 再利用、集合・区間・モデル変更、入力拒否の原子性、callback 内からの再要求、旧世代取消、cancel 後の再利用、invalidate の終端、破棄後 callback 抑止、背景 thread からの操作拒否、実 evaluator 接続。
- 失敗の回帰: 成功 cache を作成後、別区間の評価で非 UTF-8 の例外文字列を発生させる。null snapshot と明示した fallback error を返し、旧 cache を成功として返さない。元区間の cache は引き続き利用できる。

controller の順序試験では、private evaluator seam だけを差し替え、semaphore で worker の到達順を制御した。
実際の serial queue、世代管理、main completion の処理を通している。
Foundation の run loop だけで実行し、NSWindow や実画面の遮蔽状態は使っていない。

## ログとレビュー

最終の実行スクリプト、3 構成のビルドログ、6 本の試験ログを [logs/n01-orbit-pipeline](logs/n01-orbit-pipeline/) に保存した。
`SHA256SUMS` はこれら 10 ファイル、`SOURCE_SHA256SUMS` は担当の製品・試験 7 ファイルを記録する。
実行スクリプトは当環境の絶対 repo パスを含み、引数は `normal` / `san` / `x86` である。

root が製品 4 ファイルを独立して読み取りレビューした。
例外の `what()` を NSString に変換できない場合に旧 cache を成功として返す指摘を修正し、上記の回帰を含め 3 構成を再検証した。
その他は固定 TDB、原行保持、世代取消、要求行に基づく cache 契約に整合するとの報告を受けた。

App / UI / 描画の読取りレビューでは、集合・sampling の事前検証、再読込、最新 display による判定、欠損を跨がない線分を確認した。
別担当へ、地球・月モード中に軌道を設定してから「全体」へ戻ると要求が再開しない共有 callback の欠落を報告した。
その修正と統合回帰は本ログの範囲外であり、UNIT5 の最終判定に含めて別途確認する。

Git status、変更ファイル、差分量を確認した。共有作業ツリーには他担当の UNIT5 変更もある。
この担当では stage / commit、Makefile、既存 runtime、policy / gate の編集を行っていない。751 行の追加は親作業の commit 単位へ引き渡す。
`/simplifier-lai` という正確な名前の skill はこの環境の一覧にない。commit 前の品質改善・policy gate 判定は親作業が担当する。
