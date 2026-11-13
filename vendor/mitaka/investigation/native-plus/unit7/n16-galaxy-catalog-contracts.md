# 銀河・星団カタログと3D座標

P は Windows 版 Plus 1.5.4、R は通常版の配布データ、O は通常版 Mitaka 1.3.1 ソース。GC/NBG の確定したレコード形式は [銀河カタログの読取](n16-galaxy-core-validation.md) に記載する。

P の同梱 API 説明書は 1.3.0 表記であり、1.5.4 実行結果そのものではない。O も別系統・別版である。P の同梱メニューと一致する API、P/R の bytes 一致、O の数式をそれぞれ別の根拠として扱う。版の出典は [機能対応表の版による仕様の違い](../../../PLUS_FEATURE_MATRIX.md#版による仕様の違い)と[ソースの出典](../../../SOURCE_AVAILABILITY.md) を参照。

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

`ourGalaxy` は 3D の銀河系モデルであり、P `scripts/gui_jp.lua:169–173` の `Milkyway.type` 4 モードとは別項目である。全天図・地平図の天の川背景は独立に切り替える。

対象指定は P `doc/script_jp/abouttargets.html:44–52` に以下が記載される。

- `Galaxy.<固有英語名>`。参照ファイルとして `data/nearby_galaxies_name.dat` が明記される。
- `GC.<固有英語名>`。例は `GC.Terzan 1`。この節には入力ファイルや衝突時の解決順がない。
- `Other.OurGalaxyCenter`, `Other.OurGalaxy`, `Other.M31`, `Other.M87`, `Other.M13`, `Other.LSS`。

これらの名前解決・target/look 操作は 対象名の登録規則にも関わる。大文字小文字、空白、重複、別ファイルとの優先順を推測実装しない。

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

近傍銀河の 3 名称表はそれぞれコメント・空行以外に 66 行ある。原キー `N224`、`N598`、`T58`、`T445`、`U5364`、`*1` などと名称を保持する。`T58` は `SMC` と `Small Magellanic Cloud`、`T445` は `LMC` と `Large Magellanic Cloud` の違いがあり、日本語表にはルビ表記がある。表間ではコメントを含む物理行番号も異なる。物理行番号を共通 ID とみなしたり、空白・全角空白・英名を正規化して同一視したりしない。起動時にどの表を採用するかは未確定。

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
