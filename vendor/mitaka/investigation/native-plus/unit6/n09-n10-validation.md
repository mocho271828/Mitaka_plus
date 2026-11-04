# N09 星座絵・N10 恒星名集合: 局所検証

2026-10-29。UNIT5 `5dd3409f8c551ff94666d84f4504f6f92f7047c7` 後の UNIT6 作業ツリーを対象とする。これは loader / model / projection / renderer の記録であり、App・Lua・全体の機能完了を判定するものではない。原典の命令・数値根拠と未確定事項は [契約監査](constellation-art-star-selection-contracts.md)、コアの出典は [CONSTELLATION_ART_PROVENANCE.md](../../../native/core/CONSTELLATION_ART_PROVENANCE.md) に記録した。

## 実装と試験範囲

CAB の原 bytes・全点・全 index は既存 CatalogError / CatalogLoadLimits を通して保持する。負 index は strip の区切りとして残し、関連付けが不在・曖昧な図形も診断付きで保持する。Ser の頭・尾は共通 membership を使う別図形である。通常版にある別形式の星座資産へ暗黙に代用しない。

投影は原版から確定した方向変換の後、既存の全天・地平座標へ適応分割する。密な 4,001 点の独立標本による画素誤差、RA の継ぎ目、極、反対端点、予算・深さ不足、非有限値を確認した。未確定区間を結ばない。描画試験は Sky / Horizon の実 bitmap で clip、表示集合、Ser 二図形、line quality、観測地・日時、null context の不変を確認した。旧版の実行・画素一致は検証していない。

恒星名の型付き集合は既存 StarNameRecord の HIP と is_featured を使う。未知 HIP を含む一括更新の原子性、空集合、追加・削除・全件操作、再 bind の維持・新規・消失を検証した。実 bitmap では固有名だけを制限し、恒星の点と HIP designation が不変であることを確認した。主クリック選択とは独立している。

追加依存はない。C++17、既存のカタログ・座標・ObservationFrame、AppKit、RendererQuality を再利用した。画像や原天文ファイルの複製・変換・書戻しはない。

## 三構成と両データでの結果

専用 build directory は `native/core/build-unit6-time{,-san,-x86}` と `native/gui/build-unit6-time{,-san,-x86}`。既存 Makefile の `-Wall -Wextra -Wpedantic -Werror` を使い、SAN は `SANITIZE=address,undefined`、x86 は `ARCH=x86_64` と Rosetta 実行を使用した。ウィンドウは開いていない。

下表の全試験は **通常・ASan+UBSan・Rosetta x86_64 の各構成で exit 0** となった。件数は今回のローカル入力で得た観測値であり、製品の上限や将来の必須件数ではない。

| 試験 | Plus の checks | 通常版の checks |
| --- | ---: | ---: |
| core test_constellation_art | 75,705、CAB 89 件 | 99、CAB 0 件 |
| test_star_name_selection | 191 | 16、任意名前表の欠損を表示 |
| test_constellation_art_model | 99 | 10 |
| test_constellation_art_projection | 120,699 | 120,699 |
| test_constellation_display | 112 | 112 |
| test_constellation_art_renderer | 537,658 | 537,644 |

データは監査文書の `PLUS/data` と `/Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data` を読み取り専用で渡した。データ試験で名前表が欠損していても合成 fixture の試験は継続する。

初回の通常版試験では、試験側が任意の CAB directory・constellation_HIP.dat・star_names_jp.dat の存在を前提にして失敗した。製品の欠損処理を変更せず、試験を任意資産の契約へ修正して両データを再実行した。製品 parser の不正ファイル拒否は維持している。

最終 build / test の実ログは [logs/n09-n10/validation-normal.log](logs/n09-n10/validation-normal.log)、[validation-san.log](logs/n09-n10/validation-san.log)、[validation-x86.log](logs/n09-n10/validation-x86.log)。build は増分を含む。元の実行ログは `/tmp/mitaka-unit6-n09-final-{normal,san,x86}-test.log`。保管ログは同 directory の SHA256SUMS に追加した。

## レビューと統合境界

plus_spec_audit が raw bytes、座標残差回転、適応分割、HIP の原子更新と再 bind、実画素試験を読み取りレビューし、修正必須の指摘なしと報告した。レビュー担当による追加実行はしていない。

Sky / Horizon の App 接続、ブラウザ、Lua、全体状態復元は統合担当の試験で確定する。Session v6 の codec 局所試験は [別記録](session-v6-validation.md)。3D の星座絵、selection.dat による起動後上書き、原版の reload 規則は本実装の完成範囲に含めない。

担当差分の git status / diff stat と `git diff --check` を確認した。共有ツリー全体の品質改善・policy gate・300 行以上の commit は統合担当が実施するため、この担当では stage / commit を行っていない。IMPLEMENTATION_POLICY と policy_gates はここでは変更していない。
