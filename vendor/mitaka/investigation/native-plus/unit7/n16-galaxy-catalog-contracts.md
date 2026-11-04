# N16 銀河・星団・3D カタログの原典監査

2026-10-30（調査開始 10 月 29 日）。UNIT6 の製品コードを変更せずに行った読取調査である。N16（GAL-02 / GAL-03）の実装準備資料であり、対応済みの宣言ではない。旧アプリの起動、原本の再保存・変換、公開データへの置換、実行ファイルの逆解析は行っていない。

## 結論と実装可能な境界

- SDSS 銀河・QSO は、既存ローダーが全行の赤経・赤緯・距離 pc を保持している。距離付き 3D snapshot は既存型を再利用して実装できる。カメラの単位と表示範囲を明示する新しい境界が必要で、既存の太陽系 AU カメラにそのまま渡せない。
- `ourgalaxy_model.dat` は手元の Plus / 通常版で bytes が一致し、公式 1.3.1 の読取順で末尾まで復号できた。ただし、ローダーの移植可能性と Plus の銀河描画互換は別である。原版の座標変換・吸収・表示密度・色を省略した点群を「銀河系の完全対応」とは扱わない。
- Plus の `gc.dat` / `globular_cluster.dat` / `NBG.dat` / `NBG2.dat` は、公式 1.3.1 のテキスト読取契約と一致しない。ファイル長の割り切れ方だけでレコード幅を決めず、独立した未確定形式として保持する。
- NGC/IC には距離フィールドがない。視直径や等級から距離を創作しない。近傍銀河や球状星団との名称一致を根拠に同一行へ統合しない。

次の最小単位は「SDSS/QSO の全行 3D snapshot と単位付き投影契約」である。OurGalaxy の読取モデルは別単位に分離できる。近傍銀河・球状星団・名前解決は追加証拠が必要。

## 原典と読み方

以下の接頭辞は実ファイルのルートを表す。行番号は当該ローカルファイルを CP932 で復号した物理行である。bytes の観測に行番号は付けず、サイズ・ハッシュ・オフセット契約を示す。

| 接頭辞 | ローカルルート / 版 |
| --- | --- |
| P | `/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka`。Windows Plus 1.5.4 build101013。 |
| R | `/Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka`。手元の通常版データ。 |
| O | リポジトリ内 `sources/official/mitaka_source/`。公式 Mitaka 1.3.1 のソース。 |
| N | リポジトリ内 `native/`。UNIT6 作業中のネイティブ実装。 |

P の同梱 API 説明書は 1.3.0 表記であり、1.5.4 実行結果そのものではない。O も別系統・別版である。P の同梱メニューと一致する API、P/R の bytes 一致、O の数式をそれぞれ別の根拠として扱う。版の出典は `PLUS_FEATURE_MATRIX.md:5–8,196–205` と `SOURCE_AVAILABILITY.md:7,17,29` を参照。

## Plus に記載された表示 API

P `scripts/gui_jp.lua:156–162` は次の 6 表示を独立したメニュー項目として登録している。

| 表示 | bool / alias | toggle | P `doc/script_jp/galaxies.html` |
| --- | --- | --- | --- |
| 銀河系 | `ourGalaxy` | `toggleOurGalaxy` | 12–19 |
| 球状星団 | `globularClusters` / `GCs` | `toggleGlobularClusters` / `toggleGCs` | 20–35 |
| NGC 天体 | `NGCs` | `toggleNGCs` | 36–43 |
| 近傍銀河 | `nearbyGalaxies` | `toggleNearbyGalaxies` | 44–51 |
| SDSS 銀河 | `distantGalaxies` / `SDSS` | `toggleDistantGalaxies` / `toggleSDSS` | 52–67 |
| クエーサー | `quasars` / `QSOs` | `toggleQuasars` / `toggleQSOs` | 68–83 |

同じ行の alias は相互に同じ値へ変化するとの記述がある。bool の初期値、密度、点サイズ、カメラ距離の単位はこの説明書だけでは確定しない。toggle の戻り値も定義されていない。

説明書には `toggleNHCs`（39 行）、NGC 節の見出し `toggleGCs`（40 行）、`distanceGalaxies`（59 行）の誤記がある。実例・anchor と 1.5.4 同梱メニューが一致する上表を採用候補とし、誤記を新 alias にしない。

`ourGalaxy` は 3D の銀河系モデルであり、P `scripts/gui_jp.lua:169–173` の `Milkyway.type` 4 モードとは別項目である。UNIT6 の全天・地平図の天の川背景を追加しても `ourGalaxy` 対応には数えない。

対象指定は P `doc/script_jp/abouttargets.html:44–52` に以下が記載される。

- `Galaxy.<固有英語名>`。参照ファイルとして `data/nearby_galaxies_name.dat` が明記される。
- `GC.<固有英語名>`。例は `GC.Terzan 1`。この節には入力ファイルや衝突時の解決順がない。
- `Other.OurGalaxyCenter`, `Other.OurGalaxy`, `Other.M31`, `Other.M87`, `Other.M13`, `Other.LSS`。

これらの名前解決・target/look 操作は N18 のレジストリ境界にも関わる。大文字小文字、空白、重複、別ファイルとの優先順を推測実装しない。

## 現在のネイティブ実装

| 既存境界 | 利用できるもの / 現在の限界 |
| --- | --- |
| `N/core/include/mitaka/extended_catalog.hpp` と `src/extended_catalog.cpp:170–188` | SDSS の 16 byte little-endian 行を全件読む。RA/Dec、有限・非負の距離、有限の分類値を検証。SDSS の ID や等級を創作しない。 |
| `N/core/EXTENDED_CATALOG_PROVENANCE.md` | NGC 21 byte / SDSS 16 byte の由来、件数、上限、異常入力の原子的拒否。既存の入力境界を再利用する。 |
| `N/gui/include/extended_catalogs.hpp:7–25` | 銀河と QSO を別 vector で保持。明示パスと原本ローカル data の解決、任意カタログ失敗の warning。 |
| `N/gui/include/sky_catalog_index.hpp` / `src/SkyCatalogRenderer.mm` | 全天用の角位置索引と画面密度描画。全データ行の保持と表示密度は分離している。距離を使う 3D 表示はない。 |
| `N/gui/src/ScriptWorker.mm` / `src/AppScripting.mm` | `NGCs`、`distantGalaxies/SDSS`、`quasars/QSOs` の bool を現行全天表示へ接続。OurGalaxy / GC / nearby は未接続。 |
| `N/gui/src/solar_camera.cpp:11–12,31–37,82–89` | `distance_au` は最大 1000 AU、位置・target・奥行も AU。pc の値を渡すと単位が誤る。上限だけの拡大で済ませない。 |

既存ローダーの 256 MiB / 1,000,000 行という入力上限を表示密度制限に転用しない。件数が大きいだけの理由で原行を切り捨てず、要求が上限を超えた場合は理由付きで拒否する。

## ローカルファイルの照合

次表のサイズは bytes、ハッシュは SHA-256。配布時からの内容と独自追加分を識別できないため、すべて既存ローカル原本として保全する。P/R が一致するファイルも、自動で公開データへ置き換える理由にはしない。

| `data/` 以下 | P サイズ | P SHA-256 | R との関係 |
| --- | ---: | --- | --- |
| `SDSS_GAL.dat` | 13,221,760 | `5ae86c8ca46ea441b64dfb4154339dc7ed129b5f5d6e3fcaa257c042dd221e8a` | bytes 一致 |
| `SDSS_QSO.dat` | 1,677,568 | `863ff128b811c2d6363ea4b5eca876e6cc872dc1f3bddcf001b738dd143c21ff` | bytes 一致 |
| `ourgalaxy_model.dat` | 3,321,184 | `2666bd37ce185b966bd7bab6cb1279d7adc049c6b0140e569d933f9eb742b87a` | bytes 一致 |
| `ngc.dat` | 214,473 | `0c9478032ccfd742a632081c52ec61ada8029a94aa100382098be9de95f67d95` | NGC 専用契約を維持 |
| `gc.dat` | 4,170 | `14562e2c9efa487aa329a302c8ea05732e2fd1c6949f1301e4a72d9d6b97cdec` | O の複数形ファイルと非同一 |
| `globular_cluster.dat` | 5,560 | `d0d35773f7fcc55f78513665c56a2925041285453ab37f40085d7ea99ccc816d` | 同上、単数形 |
| `NBG.dat` | 64,017 | `6db1e9c30796c7ed5fa9f3c5d7ac3f5d39ea40fc7c8e4a82dda93e461ef122a9` | R のテキストと非同一 |
| `NBG2.dat` | 59,275 | `43edbb9d9b609e9c04df5bab59ffe6d4409adc031c05a2ed9839d5895c742e6d` | 別の原本として保持 |
| `nearby_galaxies_name.dat` | 2,163 | `ef970c472f93ae83a86a4011fb6294a328ac77645c0381c7df4134b0155dce8b` | API 説明書で指定される名前 |
| `nearby_galaxy_names.dat` | 1,320 | `aaf1383894565e0ea612ed601c2a85246adbf0d09b23e7ed434381a3fcdff62c` | 別名表 |
| `nearby_galaxy_names_jp.dat` | 2,038 | `5b53a776f327b1d3876e1c48fa0adef58f55b8a6f7d1407469fc3a4e9b66eea1` | 別名表、日本語あり |

R の `NBG.dat` は 210,699 bytes、SHA-256 `4b1928bf0ed139ab27cba5a00231dfe5223128e9a435301c0ce7ac8adfd4d859`。R の `globular_clusters.dat` は 12,794 bytes、SHA-256 `70d5f67156b50ecb63f25d2bb778c7d656af73bbb47ebe8f1f0048682ca265d0`。どちらもテキストであり、Plus の同種名ファイルにテキスト parser を適用して失敗時に別形式へ黙って切り替える根拠はない。

近傍銀河の 3 名称表はそれぞれコメント・空行以外に 66 行ある。原キー `N224`、`N598`、`T58`、`T445`、`U5364`、`*1` などと名称を保持する。`T58` は `SMC` と `Small Magellanic Cloud`、`T445` は `LMC` と `Large Magellanic Cloud` の違いがあり、日本語表にはルビ表記がある。表間ではコメントを含む物理行番号も異なる。物理行番号を共通 ID とみなしたり、空白・全角空白・英名を正規化して同一視したりしない。起動時にどの表を採用するかは今回未確定。

## SDSS の確定形式と 3D 座標

O `Mitaka/mtk_galaxies.cpp:113–164,220–272` は、GAL/QSO について 4 個の float（RA degree、Dec degree、距離、分類値）を読み、`M_R2E * (dist * direction)` を位置にする。O `Mitaka/mtk_draw_struct.h:70` は描画 scale を pc と記す。既存 provenance と一致する。

| 種類 | 行数 | 距離 0 の行数 | 距離の最小 / 最大 pc |
| --- | ---: | ---: | --- |
| SDSS 銀河 | 826,360 | 7 | 0 / 2,646,451,456 |
| QSO | 104,848 | 0 | 6,451,979 / 2,663,052,544 |

距離 0 は削除しない。3D 原点に重なる場合の描画・pick は別の表示契約として決め、2D の角位置と元行を保持する。分類値は銀河で eClass、QSO で赤方偏移 z であり、等級ではない。

座標変換には版の差がある。O `common/astro/astrometry.cpp:128–141` の `M_R2E` は黄道傾斜 `23.43870583` degree を使う。一方 N `core/include/mitaka/astronomy.hpp:47–52` の J2000 変換は `84381.448 / 3600` degree。既存関数を使った結果を公式 1.3.1 の逐値互換とは説明しない。実装前に「既存 native の J2000 座標へ統一」または「出典固有の変換を保持」のどちらかを明示し、同じ snapshot 内で暗黙混在させない。

O の表示閾値は参照資料であり、Plus の確定仕様ではない。`mtk_galaxies.cpp:376–424` には 3D/scale 条件、5e7 pc 以下の非表示、5e8/3e9 を使う fade、alpha と間引きがある。原データから行を削除する処理として移植しない。Plus の点数・色・表示閾値の一致は未検証。

## OurGalaxy モデルの復号結果と未確定部分

O `Mitaka/mtk_our_galaxy_rt.cpp:115–162` は `ourgalaxy_model.dat` を以下の順で読む。P/R の両方を Python 標準 `struct` の明示 little-endian 読取で照合した。

| 順序 | 観測した内容 |
| --- | --- |
| 1 | int32 幅・高さ = 512,512、続く 262,144 float。有限、範囲 0–1。 |
| 2 | int32 幅・高さ = 512,512、続く 262,144 float。有限、範囲 0–1。 |
| 3 | int32 count と count 個の float xyz を 4 回。count = 30,000 / 12,000 / 30,000 / 30,000。 |
| 4 | 全 102,000 点の成分は有限。総読取 3,321,184 bytes、末尾余剰 0。 |

O の順序名は `DISK1`, `DISK2`, `DISKOB`, `BULGE`（99–100 行）。画像の float は描画準備でそれぞれ別の変換を受ける（130–145 行）。ネイティブ reader が原値を残す前に 8-bit 化する必要はない。原版の unchecked `fread` やヘッダーを無視して 512 に固定する動作は模倣せず、長さ・dimensions・counts・積の overflow・有限値を先に検証する。

点群の第 4 群には x 最小 -310,323、y 最大 356,330.25 の点がある。想定半径から外れるという理由で切り捨てない。列挙順と群を保持する。

O `Mitaka/mtk_our_galaxy.h:44–45` は `R_gal=8000` pc、`mtk_our_galaxy.cpp:76–77` は銀河中心・名称位置を `M_G2E` で変換する。描画側では生の点を `pos - rge + rpos` として渡し、`rge=M_G2E*{R_gal,0,0}` を使う（`mtk_our_galaxy_rt.cpp:952–955,1068–1091`）。生 xyz をそのまま銀河中心原点の銀河座標と断定する根拠にはならない。

さらに同ファイルには camera の逆変換（945–955 行）、光学的厚さ（1070–1079 行）、4 群の B−V 色（802–805 行）、camera 距離による表示条件（770–785 行）がある。公式ソースに点群を読み取れることだけを根拠として、これらを省略した新しい点描を Plus と等価とは扱わない。今回の監査では呼出し元を含む `rpos` の全座標契約、Plus バイナリの対応、旧画面の一致は確定していない。

## 球状星団・近傍銀河の追加証拠が必要な箇所

O `Mitaka/mtk_globular_clusters.cpp:115–160` は複数形 `globular_clusters.dat` をテキストで読む。原キー、カタログ名・番号、RA/Dec、距離 pc、Rc/Rh、B−V/V−R を持ち、位置は `M_R2E*(distance*direction)`。名称登録は 183–191 行、星団の模様用の 500 個の乱数点は 201 行以降にある。これを P の単数形ファイルや `gc.dat` の parser と同一視しない。

O `Mitaka/mtk_nearby_galaxies.cpp:132–196` は key と 10 個の値を持つテキスト行を読む。カタログ種別・番号、RA/Dec、距離、視直径、軸比、形態、bar、group の処理があり、半径は視直径 arcminute と距離から算出される。O `:289–312` が読む `NBG.dat` と `galaxy_class.png` は、P の `NBG.dat` と同じ名前でも同じ入力契約とは証明できない。

次に必要な読取調査は以下である。

1. P の実行ファイル内の各ファイル名参照と loader を照合し、読み取る幅・順・単位・符号・名前参照を特定する。ファイル長の割り切れ方は補助証拠にとどめる。
2. `NBG2.dat` と `NBG.dat`、2 つの球状星団ファイルを両方読むか、選択するかを確認する。新旧という名称だけの推測で優先順を決めない。
3. 3 名称表の起動時選択と CP932/ルビ/空白の扱い、同一キーの重複を追跡する。未解決行も診断付きで保持する。
4. 描画 texture の探索名・種類対応と、点群/texture/label の表示条件を区別する。

## 提案する実装単位と受入条件

以下は新設計の提案であり、旧 Plus の確定仕様でも実装完了記録でもない。

| 単位 | 最小契約 | 試験条件 |
| --- | --- | --- |
| N16a SDSS 3D snapshot | 既存 `SdssRecord` を入力。source 種別＋原行 index、元 RA/Dec/pc/分類値を保持し、明示された座標系の double xyz を別途生成。入力データを再取得しない。 | 既知軸・極・RA 継ぎ目・距離 0・最大距離、分類値を座標へ使わないこと、全 931,208 行の順序と件数、独自追加行、空/破損入力の診断。 |
| N16b pc カメラ/投影 | 単位付き camera/snapshot 境界を新設。既存 projection の数学を再利用可能か確認し、AU と pc の暗黙変換を禁止。適用する原点・near plane・距離上下限を型と検証に表す。 | 単位変換の既知値、原点/前後/画面外、非常に近い点・数十億 pc、有限性と相対差分の精度、既存 AU カメラの回帰不変。 |
| N16c 空間索引・描画 | 元の全行を保持し、可視候補の探索と描画密度を別層へ。バックグラウンド計算の generation/cancel を既存様式で管理。2D/3D のチェック状態の関係は明示して設計。 | 全行 oracle と索引候補の一致、同位置複数行、モデル交換時の古い結果拒否、null context と clip、品質設定、非表示時の不要再計算なし。 |
| N16d OurGalaxy reader | 検証済み 2 map + 4 点群の原値を保持する独立モデル。初期段階では描画互換を主張しない。 | 合成ファイルの全切断境界、負/過大 count、dimension 不整合、NaN/Inf、末尾余剰、P/R 全 bytes と全件読取、原本ハッシュ不変。 |
| N16e GC / nearby | 原版 loader の証拠取得後に別 parser と provenance を追加。通常版テキストと Plus 形式を別の入力型にする。 | 全原行と原名保持、形式混同拒否、optional 失敗の個別診断、重複・名前衝突・未知キー、対応 texture 欠損、追加データ保持。 |

SDSS の既存全件読み込みと数式は C++ 標準ライブラリ、既存天文型、既存 CoreGraphics 描画で実現可能な範囲である。単なる座標変換のための新規依存は不要。約 93 万行の索引構築・メモリ・キャンセルを計測してから、既存索引方式の拡張か別の空間索引を判断する。画像を別形式で再保存したり、新しい catalog を配布したりしない。

ユーザーの追加判断がなくても N16a/N16d の独立モデルを準備できる。座標系の選択は既存 native 契約との整合をレビューして明記する。原版不明の API・名前解決・表示仕様を同名で公開することは保留し、必要な事実確認を先に行う。

## この調査で実施した検証

以下は読み取り監査時点の記録である。その後の N16a 純モデル実装と試験結果は [n16-sdss-spatial-validation.md](n16-sdss-spatial-validation.md) に分けて記録した。N16b〜N16e はこの時点で未実装である。

- ローカル P/R の対象ファイルのサイズ・SHA-256 と、同一と記した 3 ファイルの bytes を確認した。
- SDSS の明示 16 byte 読取で全行数・距離 0・最小最大を集計した。
- OurGalaxy は明示 little-endian の 2 map / 4 群で全体を読取し、dimensions・件数・有限性・末尾を確認した。
- 同梱 API/Lua、公式 1.3.1 の reader/変換/描画条件、現在の native loader/camera を読み取った。
- 製品コード、元データ、policy gate は変更していない。新機能の build・GUI 試験・Plus 実行比較は未実施である。
