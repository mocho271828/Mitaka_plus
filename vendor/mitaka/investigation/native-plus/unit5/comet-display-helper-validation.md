# N01: 彗星軌道・種類別表示ヘルパーの独立検証

## 範囲と状態

2026-10-29、UNIT4 の commit 前に許可された新規ファイルだけを実装した。既存 App / view / session / Makefile は変更していない。したがって、この記録は独立ヘルパーの検証であり、N01 の画面・Lua・保存復帰を含む実装完了報告ではない。

原版契約は [彗星軌道監査](comet-orbit-contracts.md) と [Lua 契約監査](lua-comet-satellite-contracts.md) に分けている。下記の初期値、kind master、source ID 集合、有限開軌道、上限は明示した native の新設計であり、旧 Plus の画素・標本化・初期状態との互換を主張しない。

## 実装した境界

| ファイル | 役割と契約 |
| --- | --- |
| native/core/include/mitaka/small_body_orbit_path.hpp / src/small_body_orbit_path.cpp | 元行、開始・終了 **TDB JD**、標本数から有限の開軌道を生成する。開始 < 終了、有限な差、2～4096 標本、丸め後も隣接 JD が狭義昇順という条件を先に検証する。 |
| 同上 | 各標本の位置は既存 evaluate_small_body だけで計算する。参照面・時系の未確定や評価不能を各標本の nullopt と診断で保持し、legacy numeric JD の時系を推定しない。成功位置は日心 J2000 黄道 AU。 |
| 同上 | 各標本の実際の JD、位置、診断、元 ID を保持する。線分は隣接した成功標本の組だけ。欠損を跨がず、終始点を自動接続しない。表示期間を科学的な精度保証期間として扱わず、unknown_accuracy_range を維持する。 |
| native/gui/include/small_body_display.hpp / src/small_body_display.cpp | asteroid / trans_neptunian / comet ごとに visible、labels、orbits、selected_only を持つ。native 初期値は true / false / false / false。全体の既存表示 master との接続は後続作業。 |
| 同上 | visible は kind 全体の master。body は visible AND (selected_only が false、または member)、label / orbit は body 判定に各設定を AND する。scene、位置評価の有効性、既存 global master は呼出側が重ねる。 |
| 同上 | 複数行の表示集合は source_key + record_ordinal で識別する。クリック選択・追尾・検索を所有しない。未登録・重複 ID の更新は全体を拒否し、元の集合を維持する。元の Visible 属性から集合を推定しない。 |
| 同上 | 再 bind は新 dataset 全体を先に検証し、同 ID、同 kind、**source 原 bytes 完全一致**のときだけ集合を保持する。解除した ID を報告し、エラーなら元状態を維持する。名前・番号・言語別定義を統合せず、bytes 比較は出典ごとに一度だけ行う。 |

既存標準 C++17 と小天体 evaluator を再利用し、新しい依存や軌道数学は追加していない。単一ファイルはいずれも 500 行未満。原本の読込は既存 loader 経由のみで、原データ・設定の書込はない。

## 検証結果

専用ディレクトリ native/core/build-unit5-orbit-path{,-san,-x86} と native/gui/build-unit5-small-body-display{,-san,-x86} を使用した。全構成 -std=c++17 -Wall -Wextra -Wpedantic -Werror -mmacosx-version-min=13.0、リンクは -Wl,-fatal_warnings。通常と sanitizer は arm64、x86_64 は Rosetta で実行した。macOS 13 実機での実行確認ではない。

| 対象 | 通常 arm64 | ASan + UBSan arm64 | x86_64 / Rosetta |
| --- | --- | --- | --- |
| ビルド | exit 0 | exit 0 | exit 0 |
| orbit path 合成 + ローカル全行 | 17,341 checks / exit 0 | 17,341 checks / exit 0 | 17,341 checks / exit 0 |
| display model 合成 + ローカル全行 | 19,772 checks / exit 0 | 19,772 checks / exit 0 | 19,772 checks / exit 0 |

合成部分は orbit path 141 checks、display model 295 checks。ローカル原本は /Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data を読んだ。彗星 2,457 行を全件保持し、J2000 付近の評価可能行は 2,388、未評価は 69（既存 loader の歴史暦未解明 65 行と個別定義 4 行）。display model は 67 source、19,475 行を全選択し、再読込後も元 bytes の一致する全 ID を保持した。件数を fixture に固定して通したものではない。

新規テストの主な検証条件は次のとおり。

- test_small_body_orbit_path.cpp: 円・楕円・放物線・双曲線、近日点の既知位置、昇順と端点、閉曲線を作らないこと、期間境界、内部欠損、未知時系・参照面、未知要素・計算失敗の診断保持、空/単一点の線分、NaN/Inf/差の overflow、0/1/上限超過の標本数、隣接 double の JD 丸め、最大標本数、元 raw bytes の不変。
- test_small_body_display.cpp: 全 3 kinds × 16 bool 組合せ、kind 間の独立性、空集合・複数集合・同名別行、非表示でも集合保持、未知/重複 ID の原子拒否、未知 kind/範囲外 row、不正 dataset の原子拒否、source/row の順序変更、同 ID でも元 bytes が異なる場合の解除、欠損 source、kind 変更、言語別/独自定義保持、全行の再 bind。

macOS の ASan は detect_leaks=1 をサポートせず、最初の sanitizer 起動はテスト前に exit 134 で終了した。この失敗ログを残し、サポートされる ASAN_OPTIONS=halt_on_error=1 UBSAN_OPTIONS=halt_on_error=1 で再実行した。ASan/UBSan は成功したが、LeakSanitizer によるリーク検査は未実施。

初回は既存 core archive に対して minOS 13 でリンクしたため、その archive の minOS 26 object に deployment 警告が出た。最終検証では既存 core の astronomy / catalog / small_body_catalog / small_body_text / small_body_orbit の 5 source を専用ディレクトリへ同じ minOS 13 指定で再コンパイルし、警告を許容せず検証した。共有 build や既存 Makefile は変更していない。

## 記録と独立レビュー

実行スクリプト、3 構成のビルドログ、6 本の成功テストログ、LeakSanitizer 非対応ログを [logs/n01-helpers](logs/n01-helpers/) に保存した。12 ファイルの SHA-256 を同ディレクトリの SHA256SUMS に記録し、全件一致を確認した。再現時は保存スクリプトへ normal / san / x86 を渡し、各テストの唯一の任意引数へ上記 data directory を指定する。スクリプトは当作業環境の絶対 repo パスを含む。

time_features がソース 4 ファイルを読み取りレビューし、必須修正なしと報告した。指摘された丸め、未知/重複 ID、bytes 変更、kind 不正時の原子性をテストで確認した。その後、bytes 比較を出典ごとに一度へまとめた変更と両テストを再レビューし、必須指摘なしと報告した。レビュー担当による追加実行はない。

## 残る接続と未確認

- GUI の複数行集合操作、表示と pick の同一判定、線描画、非表示時の計算抑制、非同期世代管理、描画期間の native UI 方針は未接続。
- Lua の旧英名の登録列・名前解決、show / hide / isVisible、session への静的設定と集合保存は未接続。
- 元データ全件保持は確認したが、packed asteroid / TNO と個別彗星の参照面・時系を解明したものではない。原版の軌道線期間・標本数・初期集合も未確定のまま。
- policy / gate / 全アプリ統合検証は親作業で行う。ここでは stage / commit を行っていない。
