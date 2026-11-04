# N16 銀河・星団の原値保持 reader と pc 座標契約

記録日: 2026-10-30。UNIT7 の独立 core 実装と純粋試験の記録である。3D 描画、カメラ、Lua、名前解決、保存状態への接続は含まない。
先行する [原典監査](n16-galaxy-catalog-contracts.md) は静的解析前の調査結果であり、そこで未確定とした GC/NBG のレコード形式について、以下の追加証拠を得た。
SDSS/QSO は別の [N16a 検証記録](n16-sdss-spatial-validation.md) を参照する。最初の分割案の N16d と N16e の読取部分を今回追加し、N16b の pc カメラは実装していない。

## 原典と方法

- P: `/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka`。Mitaka_plus 1.5.4 build 101013。同梱 API 文書の表記は 1.3.0 であり、製品版と区別する。
- R: `/Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka`。利用者が保持する通常版データ。
- O: `sources/official/mitaka_source/`。公式 Mitaka 1.3.1 ソース。形式と式の参照だけに使用し、P/R の置換元にしない。

P `mitakaPlus.exe` の SHA-256 は `48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457`、PE32 の ImageBase は `0x400000`。
今回の証拠は Apple LLVM 21 の `/usr/bin/objdump` による範囲を限定した静的解析と、原本 bytes の読取結果である。
REA の詳細解析 provider が利用できなかったため native shell を使用した。REA の解析結果とは扱わない。provider の導入や設定変更、旧実行ファイルの起動はしていない。
解析範囲、VA と file offset の対応、定数、原本・公式ソースのハッシュは [static-evidence-metadata.txt](logs/n16-galaxy-core/static-evidence-metadata.txt) に記録した。

## 確定した読取形式

| 入力 | 根拠 | 今回の読取契約 |
| --- | --- | --- |
| P `data/globular_cluster.dat` | ファイル名 VA `0xc2f288` を `0x4f2a5b` で渡し、`0x4f2a7e` 以降で 12 bytes と 7 個の 4 bytes を読む。[GC 抜粋](logs/n16-galaxy-core/plus-gc-loader.txt)。全 5,560 bytes は 139 行に一致。 | 12 byte 名、float32 の RA 度・Dec 度・距離 pc・core radius pc・half-light radius pc・B−V・V−R。little-endian、40 bytes/行。 |
| P `data/NBG.dat` | ファイル名 VA `0xc2eea8` を `0x4da6aa` で渡す。[open](logs/n16-galaxy-core/plus-nbg-open.txt) → [dispatch](logs/n16-galaxy-core/plus-nbg-dispatch.txt) → `0x4db868` の [reader](logs/n16-galaxy-core/plus-nbg-record.txt)。5 個の 4 bytes、3 個の 1 byte、1 個の 4 bytes を読む。全 64,017 bytes は 2,371 行に一致。 | float32 の RA 度・Dec 度・距離 pc・角直径 arcmin・短長軸比、3 個の raw code、int32 catalog number。little-endian、27 bytes/行。 |
| P/R `data/ourgalaxy_model.dat` | P ファイル名 VA `0xc31b80`、reader `0x51ef30`。[OurGalaxy 抜粋](logs/n16-galaxy-core/plus-ourgalaxy-loader.txt)。O `Mitaka/mtk_our_galaxy_rt.cpp:115–169` と全 bytes を照合。 | 2 枚の map は int32 width/height と float32 列。その後 4 群に各 int32 count と xyz float32 列。全体 little-endian。 |
| P 名前 table 3 個 | P の `nearby_galaxy_names.dat` 文字列 VA `0xc2eeb0` は `0x4da6eb` から参照される。他 2 名の exact string は確認できず、locale 変換の有無は未確定。 | 3 ファイルとも別の原本として物理行・bytes を保持する native reader。原版の名前解決や優先順位の再現ではない。 |

GC の 12 byte 名には NUL 後の非ゼロ bytes がある。先頭行は `NGC 104` の後にも値を持つため C string に切り詰めない。
O の通常版 `Mitaka/mtk_globular_clusters.cpp:115–160` は複数形 `globular_clusters.dat` のテキストを読む。
同ソースの列名と P の全行を照合したうえで GC の列を命名した。通常版テキストの parser は今回追加していない。

NBG の `0x4db921–0x4db94c` は角直径・距離・VA `0xc2ea68` の `π/21600` を乗じ、半径に相当する pc 値を作る。
RA/Dec に使う VA `0xc2ea70` は `π/180` である。O `Mitaka/mtk_nearby_galaxies.cpp:132–196` の列と式も参照した。
ただし P の code と通常版の morphology/bar は一致しない。`render_class_code`・`auxiliary_code`・`catalog_code` は raw 値の保持名であり、未知 code を既知の形態へ読み替えない。

P `gc.dat` は 4,170 bytes、`NBG2.dat` は 59,275 bytes だが、サイズの割り切れだけでは形式を確定できない。両ファイルの parser は未実装。
P の binary `NBG.dat` と R の text `NBG.dat` は同名でも別形式である。今回の Plus reader は形式を指定する API であり、任意ファイルの形式を自動判定する API ではない。
バイト数が偶然レコード幅で割り切れる別形式を見破る契約もない。後続 loader は出典ごとの形式選択を省略してはいけない。

## 所有・検証・診断

実装ファイルは core の `galaxy_catalog.hpp/.cpp`、private `galaxy_catalog_input.hpp`、`our_galaxy_model.hpp/.cpp` と 2 個の専用 test である。
`GalaxyCatalogSource` は呼出し側が指定した path と全 raw bytes を値所有する。全原行、元の順序、重複、未知 code、float の元 bits を保持する。
ファイルへの書込、再保存、文字コード変換、オンライン読込、公開データへの fallback はない。

既存 `CatalogError` と `CatalogLoadLimits` を使用し、file size、streamsize、size_t、行数、残り bytes を allocation 前に確認する。
新しい一般 parser ライブラリは不要な固定長入力であり、C++17 標準ライブラリと既存 core を使う。
不足・余剰 bytes、負の count、非正の map dimensions、上限超過は path/offset/reason 付きで全体拒否する。成功した部分だけを完成結果として返さない。
読取中の末尾追加も拒否するが、同じ長さの同時書換えを検出する保証はない。

構造が正しい行の NaN/Inf や範囲外値は、元の行から削除しない。GC/NBG の位置評価は別 API `evaluate_galaxy_position_pc` が担う。
RA `[0,360)`、Dec `[-90,90]`、非負距離と各有限性を検査し、複合不正はすべての理由を保持する。
距離 ±0 は原点の位置と専用理由を持つ。別列も不正なら位置を作らず、zero-distance 理由は残す。
色・形状・分類の異常値は位置の入力ではないため、位置評価の成否を変えない。

`GalaxyEquatorialPositionPc` と `GalaxyNativeEclipticPositionPc` は double の単位付き別型で、AU 型への暗黙変換はない。
既存 `equatorial_direction` と `j2000_equatorial_to_ecliptic` を再利用する。
native の傾斜は `84381.448 / 3600` 度、O `common/astro/astrometry.cpp:128–141` は `23.43870583` 度である。
P reader に九要素の変換行列を使う経路は確認できたが、その runtime 行列値は未確認。native 座標を旧 Plus と逐値一致だとは扱わない。

## OurGalaxy の保持範囲

map はヘッダーの dimensions を尊重する。O が `mtk_our_galaxy_rt.cpp:126,140` で 512 に上書きし、`:131–146` で 8 bit に変換する挙動を reader には持ち込まない。
各 float は元 bits のまま保持し、非有限数と `[0,1]` 外の値を別件数で報告する。負数の clamp や色・alpha の再生成はない。
4 群の順序は O 同ファイル `:99–104` の disk1/disk2/diskOB/bulge に対応する。
map sample 総数と point 総数はそれぞれ独立に `max_records` 以下であることを確認し、合計 byte 数は `max_file_bytes` で制限する。

P/R の 3,321,184 bytes は同一で、map は 512×512 が 2 枚、点群は 30,000 / 12,000 / 30,000 / 30,000、合計 102,000 点。
全値は有限だが、第 4 群には x が −310,323、y が 356,330.25 などの値もあり、外れ値として削除しない。

位置型は `OurGalaxyRawPositionPc` とし、参照面と原点を確定した日心・銀河中心座標とは呼ばない。
pc 単位は O `mtk_our_galaxy.h:44–45` の `R_gal = 8000 pc`、`mtk_our_galaxy.cpp:76–77`、`mtk_our_galaxy_rt.cpp:945–955,1068–1091` の同じ量を使う座標演算を根拠とする。
raw 点と `M_G2E`・`rge`・呼出し元 `rpos` の完全な関係は未確定であり、native 黄道変換や renderer へは接続していない。

## 名前 table の native 契約

`nearby_galaxies_name.dat`、`nearby_galaxy_names.dat`、`nearby_galaxy_names_jp.dat` は各 66 entry を持つ。
同じ T58/T445 でも `SMC/LMC` と `SmallMagellanicCloud/LargeMagellanicCloud` のように表記が異なるため、統合や先勝ち解決をしない。

`GalaxyNameLine` は物理行番号・byte offset・LF を除く raw 行を保持する。CRLF の CR、CP932 の 2 byte 目 `0x5c`、重複、未知 key も保持する。
ASCII の先行空白を除いて空行・`%/#` comment を分類し、それ以外は最初の空白区切り token を key とする。
key 後の空白と任意の `*` を識別し、残りは未正規化 payload とする。`featured` はその marker の記録であり、原版の可視性や優先度を再現する意味は与えていない。
非 comment 行の NUL と欠損 payload は raw 行を残して unresolved と診断する。英名・日本語名・ルビの境界は推測しない。
全 raw source から改行も復元できるが、ファイルへ書き戻す機能はない。

## 試験と結果

`-std=c++17 -Wall -Wextra -Wpedantic -Werror`、macOS target 13.0 で独立 build directory を使用した。
通常 arm64 は `-O2`、ASan+UBSan arm64 は `-O1 -fno-omit-frame-pointer -fsanitize=address,undefined`、x86_64 は `-O2 -arch x86_64`。
x86_64 は Apple Silicon 上で Rosetta を使用した。GUI/window や旧 executable は起動していない。

| 試験 | 通常 | ASan+UBSan | x86_64 |
| --- | --- | --- | --- |
| GC/NBG/name 合成境界 | 1,275 checks PASS | 1,275 checks PASS | 1,275 checks PASS |
| OurGalaxy 合成境界 | 330 checks PASS | 330 checks PASS | 330 checks PASS |
| Plus GC/NBG/name 全原行 | 19,452 checks PASS | 19,452 checks PASS | 19,452 checks PASS |
| Plus/通常 OurGalaxy 全原値 | 1,660,946 checks PASS | 1,660,946 checks PASS | 1,660,946 checks PASS |

GC/NBG は全列の little-endian bits、12 byte 名の NUL 後、未知 code、INT_MIN、重複、source の値所有、途中の全切断位置、上限境界を試験した。
名前 table は blank/comment を含む全物理行の復元、CRLF、CP932、NUL、欠損 payload、重複、行数制限を確認した。
pc 位置は軸・極・RA 継ぎ目・±0・float 最大有限距離を含む 125 組と複合不正理由を検査し、production の変換関数を使わない long double の独立式と照合した。
OurGalaxy は合成ファイルの全 byte 切断、負/過大 count、dimension 積、累積上限、余剰末尾、非有限・範囲外・signed zero を検査した。
P/R の全 524,288 map samples と 102,000×3 座標の各 bits・群順・EOF・元 bytes を別読取で照合した。

全構成の command と出力は [logs/n16-galaxy-core/](logs/n16-galaxy-core/) に保存した。
入力ハッシュは static evidence metadata、実装ハッシュは [implementation-sha256.txt](logs/n16-galaxy-core/implementation-sha256.txt)、ログのハッシュは [SHA256SUMS](logs/n16-galaxy-core/SHA256SUMS) を参照する。
独立読取レビューを `time_features` が実施し、必須修正なしと判定した。全 bytes / 原行保持、未確定座標系の型分離、allocation 前の残 bytes / 累積 count 検証、trailing 拒否、不正値の保持と位置診断の分離、既存天文変換の再利用、独立 oracle と全切断長の回帰を確認した。レビュー担当は追加実行・編集を行っていない。親担当の core 全 test 成功報告は受領したが、上表は担当自身が実行した独立試験だけを示す。

## 残件と変更管理

pc camera・空間索引・3D 描画・表示フラグ・選択・Lua・JSON・アプリからの load は次単位である。
通常版 GC/NBG text、未知 `gc.dat/NBG2.dat`、名前解決、OurGalaxy 原点/参照面/描画式、Plus の画素互換は未対応として残す。
後続の案は [n16-parsec-rendering-seam.md](n16-parsec-rendering-seam.md) に分け、実装完了の項目と混在させない。

この担当は新規 7 ソース・test ファイルと UNIT7 文書・ログだけを追加した。Makefile への登録は親担当が実施した。
既存依存を再利用し、新規外部依存はない。各製品ファイルは 139 行以下であり、固定形式 input のみ private helper に分離した。
Git の status・対象ファイル・差分量を確認済み。対象 7 ファイルは合計 750 行で、親担当が作業単位を commit する指示のため、この担当は stage/commit を行っていない。
`/simplifier-lai` はこの担当では実行していない。自己レビューと別担当による独立レビューで確認する。
機能範囲に閉じた追加のため、この担当による `IMPLEMENTATION_POLICY.md` と policy gates の変更はない。
