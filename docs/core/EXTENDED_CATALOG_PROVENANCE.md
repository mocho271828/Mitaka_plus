# 追加カタログの入力契約と由来

この文書は `extended_catalog.hpp` / `extended_catalog.cpp` の根拠を記録する。
元の配布データは読み取り専用で扱う。

## 参照した原典

表のパスは [公式 Mitaka 1.3.1](../sources/README.md) の ZIP 内の `mitaka_source/` を基準とする。
Windows ABI に依存する `fread(sizeof(...))` を移植せず、ファイル上の幅と
little-endian を明示して復号する。公式ソースの許諾表示を実装に保持する。

| ファイル | 使用箇所 | SHA-256 |
| --- | --- | --- |
| `Mitaka/mtk_planetarium.cpp` | `read_a_NGC_record` (157行目)、`read_NGC_data` | `6a6891d986c6efa09620a326d89899d6943d6af4a0a4352e8728917f419521be` |
| `common/astro/astrometry.h` | `RA_DEC`、`NGC_data` (191行目)、NGC分類enum | `37e5547d92c8788d21208ad00be30271d6571c6ccf2df7a2fbd505a301d1f13e` |
| `Mitaka/mtk_galaxies.cpp` | `load_distant_galaxies` (113行目)、`load_QSOs` (220行目) | `6affbe1710a6fb9c24b6dba956450cee0d0e9c0b9ac4f057f74945356099c89f` |
| `Mitaka/mtk_stars.cpp` | `load_exoplanet_list` (373行目) | `0d864869c5ffb570701c553ed7634bb885b425d22bcf9431b66a5c3fb8c547a9` |
| `Mitaka/mtk_draw_struct.h` | `scale` (70行目)、描画座標のpc単位 | `cfdac209ef7b843ad0fa718251f1a99da81e76f6f347bab17c64b2011139a980` |

## バイナリ形式

ヘッダーや件数フィールドはない。全体長をレコード幅で割った件数を読み、末尾の
不完全なレコードはファイル全体のエラーにする。IEEE 754 binary32 の有限値のみ受理する。

`ngc.dat` は21 bytes/record:

| byte offset | 幅 | 内容 |
| --- | --- | --- |
| 0 | 2 | 正のint16 NGC/IC番号 |
| 2 | 1 | NGCフラグ (0=IC、1=NGC) |
| 3 | 4 | J2000赤経 degree |
| 7 | 4 | J2000赤緯 degree |
| 11 | 1 | 原典enumの分類0〜11 |
| 12 | 4 | 最大視直径 arcminute |
| 16 | 4 | 視等級または写真等級 |
| 20 | 1 | 写真等級フラグ0/1 |

番号は `(is_ngc, number)` で一意。RAは `[0,360)`、Decは `[-90,90]`、
視直径は0以上。元データの大きさ0、等級0を欠落値に勝手に置換しない。
等級0には未記載が含まれるため、GUIで実測値と断定しない。

`SDSS_GAL.dat` / `SDSS_QSO.dat` は16 bytes/record:

| byte offset | 幅 | 内容 |
| --- | --- | --- |
| 0 | 4 | J2000赤経 degree |
| 4 | 4 | J2000赤緯 degree |
| 8 | 4 | 距離 parsec |
| 12 | 4 | GAL: eClass、QSO: redshift z |

距離の単位は、原典ローダーが `dist * eqPos.get_dirc_vec()` を単位変換なしで
pc単位の描画座標へ渡すことによる。赤経・赤緯の検証はNGCと共通。
距離は0以上。実際にある距離0を削除せず保持する。分類値は有限値検証のみとし、
原典の描画用の丸めや間引きはローダーでは行わない。SDSSには視等級フィールドはない。

## 恒星名称と系外惑星恒星

`star_names.dat` / `star_names_jp.dat` / `star_names_HIP.dat` のレイアウトは
この旧Plus配布物の `% HIP F Name` ヘッダーと実レコードを根拠にしている。
公式1.3.1に同じ旧Plus名称テキストのローダーがあるとは主張しない。

先頭6 bytesは正のHIP番号、第7 byteは空白または `*`、第8 byte以後は名称。
2個以上の連続スペースで英語名称と追加名称が分かれる。
英語名称内の単一スペースを保持する (例: `Al Na'ir`)。
追加名称は配布物のCP932 bytesのまま保持し、Cocoaでの変換はGUIに任せる。
HIP重複はエラー。空白行、`%` / `#` コメント、CRLF、最終改行なしを受理する。

| 入力ファイル | SHA-256 |
| --- | --- |
| `star_names.dat` | `209c9dade592d94cda01fa698dfbcafe0a07c6c9db5513aefec9f804824ab36a` |
| `star_names_jp.dat` | `e76941d8aea47da30363b93bdbc2c3591b1f7ec785c7e222e661a026711105d0` |
| `star_names_HIP.dat` | `5299a948422545caea29e1f8e81570c31ada14708e92fa6c7e2e5b2a2d8f17d5` |

`exoplanets_HIP_list.dat` は1行1個の正のHIP整数。
原典は読み込み後にsetで存在照合する。配布ファイルには同じHIPの反復があるため、
ローダーは全行をそのまま返し、GUIの存在照合で集合化する。
整数後のゴミや範囲外の値を原典のように黙って無視せず、入力エラーにする。

## 上限と失敗時の契約

- `CatalogLoadLimits` を全ローダーに適用する。既定は256 MiB、1,000,000レコード。
- テキストの1行は改行を除き最大4096 bytes。NULは禁止。
- 全ファイルを検証できた場合のみ結果を返す。途中までの結果は返さない。
- `CatalogError` は入力パスと読み取り位置のbyte offsetを持つ。
  テキストの内容エラーには1始まりの行番号も含む。
- `gui::load_extended_catalogs` は任意データの失敗をカタログ単位で隔離し、
  不正ファイルのパス・offset・理由を `warnings` に残す。欠落はまとめて警告する。
  日本語名称が存在すればそれを選択し、存在しなければ英語名称を選択する。
  日本語名称が壊れている場合は警告して名称一覧を空にする。

## 実データ検証

2026-10-29、既存の `mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data`
を変更せずに読み込み、次の件数を確認した。

| カタログ | 件数 |
| --- | ---: |
| NGC/IC | 10,213 |
| SDSS galaxies | 826,360 |
| SDSS quasars | 104,848 |
| 恒星名 (3形式それぞれ) | 174 |
| 系外惑星HIP一覧 (重複行保持) | 179 |

合成テストは全切断位置、boolean/type/座標の不正、NaN/Inf、負距離、重複、
byte/record/行長上限、CP932保持、改行、異常行、optional失敗隔離を含む。

## ローカル追加データの取り扱い

2026-10-29にローカルの `mitaka` と `mitaka_plus` 両方の `data/` を再帰的に
調査した。前者は39ファイル、後者は456ファイルで、Plusには星座境界・星座線の
`.cab` / `.cdf` が各89ファイル、`orbits/` 内の天体別 `.dat` がある。
ファイル名だけでは、配布時からのファイルとユーザー追加分を区別できない。
公式配布物との一致を根拠なく主張せず、どちらのローカルデータもそのまま保持する。

共通のファイル名のうち内容が異なるものは次のとおり。

| ファイル | `mitaka/data` のbytes | `mitaka_plus/data` のbytes | 扱い |
| --- | ---: | ---: | --- |
| `NBG.dat` | 210,699 | 64,017 | 形式が異なるため、本モジュールでは統合しない |
| `exoplanets_HIP_list.dat` | 2,676 | 1,255 | それぞれ382行、179行を読み込める |
| `places.dat` | 140,910 | 7,043 | 本モジュールの対象外 |

検証時は両アプリの data 内 495 ファイルを SHA-256 で再照合し、変更がないことを確認した。
この比較は作業前のローカル状態の保全を検証するもので、配布元との同一性を示さない。

ローダーはファイルの実際の長さまたは行数から全件を読み込む。既知のNGC番号上限、
既知のHIP集合、配布物の固定件数による絞り込みは行わない。形式の表現範囲内の
NGC番号32000、恒星名HIP999999、系外惑星HIP2147483647を受理する合成テストを追加した。
実データのテストも件数を配布物の値に固定せず、バイナリのファイル長との一致を検査する。
256 MiB / 1,000,000レコードは変更可能な入力上限であり、超過時に黙って切り捨てない。

GUIの `ExtendedCatalogLoadOptions` は `limits` とカタログごとのローカルパス
`ngc` / `galaxies` / `quasars` / `star_names` / `exoplanet_hosts` を受け取る。
空のパスは従来のファイル名を選び、相対パスは `data_directory` から解決する。
絶対パスは指定された場所を使う。形式は指定したフィールドで確定させ、拡張子から
推測しない。同じ形式の独自ファイルを別名で使用できるが、複数ファイルの自動結合や
別データディレクトリからの補充は行わない。公開カタログへの置換も行わない。

両ローカルデータディレクトリに対してcoreとGUIのテストを実行し、
`-Wall -Wextra -Wpedantic -Werror`、AddressSanitizer、UndefinedBehaviorSanitizer
で成功した。`mitaka/data` に存在しないNGC・恒星名は、GUIのoptional警告で通知される。

## 未検証の形式

旧Plusの `gc.dat` / `globular_cluster.dat` / `NBG.dat` はバイナリだが、
確認した公式1.3.1の球状星団・近傍銀河ローダーは別のテキスト形式である。
`mp.dat` / `mp2.dat` / `TNO.dat` / `TNO2.dat` の二進形式、`comets.dat` の
軌道要素からの位置計算についても、原典実装との対応が未検証である。
これらは本モジュールでは読み込まない。レコード幅や単位をデータ値から推測しない。
