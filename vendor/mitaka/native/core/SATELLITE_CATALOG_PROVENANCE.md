# Plus 衛星定義・軌道データの保持

2026-10-29。対象はローカルの Mitaka Plus 1.5.4 build101013 に同梱された入力である。
ローダーは新規の C++17 実装で、実行時依存は標準ライブラリのみ。位置・回転の計算は含まない。
元データと参照ソースは読み取り専用とし、公開データへの置換、原本への修正、言語別の統合を行っていない。

## 根拠と対象

原本のアプリルートは `/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka`。
版の根拠は `ReadmeWin_J.txt:3`、基になった本体の記載は `Readme1st_J.txt:2`。
入力の一覧と計算上の未確定事項は [orbit-contracts-audit.md](../../investigation/native-plus/orbit-contracts-audit.md) に記録されている。

| 入力 | 読み取りで確認した形式 |
| --- | --- |
| `data/ssystem.dat`, `data/ssystem_jp.dat` | `Ssystem` → `Sun` → `Planet` → `Satellite` の名前付きブロック。名前と単独行の `{` / `}`、ブロック内の `key: value` |
| 定義内のキー | `Name, Radius, Magnitude, Orbit, Color, Texture, Visible, Ring, RingTexture` |
| `data/orbits/` 直下の衛星168ファイル | `Planet, Epoch, a, e, w, M0, i, node, n, P, Pw, Pnode, RA, Decl, RefPlane`。RA/Decl がないファイルもある |
| 同じ場所の惑星9ファイル | `Epoch, a, e, T, i, node, w, L`。衛星と単位を共通扱いしない |

各言語の定義は181ブロック（Ssystem 1、Sun 1、Planet 9、Satellite 170）。
Orbit フィールドは各179件で、異なる参照先は177件ある。
定義と軌道の数を合わせるための重複排除は行わない。
`ssystem.dat:37–46` の月、58–67行の Phobos の参照は `./data/orbits/...` で、起点は data の親にあるアプリルートである。

公式 Mitaka 1.3.1 の `mtk_satellite.cpp` は別形式の `satellites.dat` を読む。
このローダーは公式ファイル形式を Plus の形式へ当てはめていない。
通常版1.7.4aの bundle にも対象の `ssystem*.dat` / `orbits` ディレクトリはないため、欠損を診断する。

## 保持と解決の契約

API は [satellite_catalog.hpp](include/mitaka/satellite_catalog.hpp) にある。
呼び出し側が選んだ data ディレクトリ直下の `ssystem*.dat` と `orbits` 直下の全 regular file を読む。
独自の定義ファイル、拡張子が異なる軌道ファイルも、この範囲では標準件数に制限しない。
`orbits/asteroids` などの子ディレクトリは既存の小天体ローダーが扱うため、この API では探索しない。
別名の定義ファイルや異なるディレクトリは自動探索の対象に含めない。

- `sources.bytes` はコメント、空行、CRLF、CP932を含む全原バイト列。`fields.value_bytes` だけは構文上の前後空白を除く。原行は offset / size で取得できる。
- `definitions` は既知・未知を含む全ブロックを開いた順に保持する。ID は source key と source 内の ordinal。親も同じ source 内の ordinal で表す。
- ブロックは source offset / size、フィールドは offset / size / 1始まりの行番号を持つ。構文エラーにも出典パス・byte offset・行番号がある。
- `orbits` は空でないキー形式ファイルにつき1レコード。全原文は対応する source にある。コメントだけの空ファイルは0レコードとして構文読取を成功とする。
- 同名の衛星、同じ軌道を参照する定義、言語別、重複フィールドは残す。`unique_satellite_field` と `satellite_scalar` は重複キーに値を返さない。
- 未知のブロック、キー、RefPlane は診断して保持する。未知の文字を E 等へ代用しない。
- `Orbit` の参照は原文を残したうえで、選択された data 内の source を `orbit_source_index`、構文読取済みの軌道レコードを `orbit_index` に接続する。空ファイルや構文不正ファイルでも、前者によって読み取り結果を追跡できる。大小文字を補正せず、近い名前や別 bundle で補完しない。絶対パス・data 外の参照・symlink を追跡しない。
- 再読込の結果は独立して原文を所有する。保存済み ID を新しい読込へ再接続するときは、呼び出し側が source bytes を比較する必要がある。

構文が不正なファイルは、そのファイルの原 bytes と診断だけを残し、途中まで読んだレコードを採用しない。
他のファイルは継続する。数値不正・重複キーでは構文レコードを保持し、`parsed=true, valid=false` とする。
`read_complete` は上限内で原 bytes を EOF まで読めた状態、`parsed` は構文の読取結果、`valid` はこのローダーの数値・重複検査結果である。空・構文不正のファイルでも EOF まで読めた場合は `read_complete=true` になる。これらの値は位置計算の可否を表さない。
旧版が空の Orbit ファイルでも登録する条件と、native の数値妥当性を分離するため、この3状態を持つ。symlink 拒否、上限超過、外部参照による未読を、旧版の `fopen` 失敗の証拠にはしない。

既知の数値キーは classic locale で有限値を検査する。軌道の数値キー、Magnitude、Visible は単一数値を要求する。
Radius / Color / Ring は有限値の列としてのみ保持し、独自データの成分数や物理的意味を推測して切り詰めない。
単位変換、Mars の node 補正、月の特別な軌道計算、親天体中心・連星重心の解決は行わない。
`P` の単位、物理的な時系、精度保証期間などの未確定事項も、この数値読取では確定しない。

## 上限と安全性

`CatalogLoadLimits` の file bytes / record 数に加え、総 bytes、source 数、field 数、行の bytes、ブロック深さに変更可能な上限を設けた。
既定値は各ファイル256 MiB、総入力512 MiB、source 10,000件、全ブロックと軌道レコード計1,000,000件、field 1,000,000件、改行を含む1行65,536 bytes、深さ64。
これらは安全上の上限であり、既知の170衛星などの件数に合わせた抽出条件ではない。
上限超過は診断に残し、無言の切り詰めを行わない。元ファイルの自動修復、スクリプトの実行、原本への書込みはない。

## 検証

既存 Makefile を変更せず、次の独立ビルドを行った。

```sh
clang++ -std=c++17 -Wall -Wextra -Wpedantic -Werror \
  -fsanitize=address,undefined -fno-omit-frame-pointer -I native/core/include \
  native/core/src/catalog.cpp native/core/src/satellite_catalog.cpp \
  native/core/src/satellite_catalog_parser.cpp native/core/tests/test_satellite_catalog.cpp \
  -o /tmp/mitaka-test-satellite-catalog-sanitize
```

- Plus実データ: 179 sources、362 definitions、177 orbit records、診断0件。1013 checks PASS。
- 通常版実データ: 対象形式0件、欠損診断3件。111 checks PASS。別 bundle への代替なし。
- RefPlane の全件分布: L 96、E 38、Q 31、C 2、I 1。参照フィールド358件を保持して解決。
- fixture: 独自401定義、同名・言語別・重複キー、未知キー/ブロック/RefPlane、CP932 の `0x5c` 後続バイト、CRLF、再読込の独立性、全上限、NaN/Inf/overflow、構文破損、NUL、外部参照、symlink、空/不正構文/未読の状態分離を検証。
- AddressSanitizer / UndefinedBehaviorSanitizer は上記両 bundle と fixture で異常なし。
- 同じ試験の前後で原本179ファイルのサイズ・mtime_ns・SHA-256を比較し、全件不変を確認。

GUI 接続、既存集約モデルへの接続、回転・位置評価はこのローダーの検証に含めない。
原版との実画面比較や全 API 互換を完了したという意味でもない。
