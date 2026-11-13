# 星座絵と選択恒星名の描画

CAB の原 bytes・全点・全 index は既存 CatalogError / CatalogLoadLimits を通して保持する。負 index は strip の区切りとして残し、関連付けが不在・曖昧な図形も診断付きで保持する。Ser の頭・尾は共通 membership を使う別図形である。通常版にある別形式の星座資産へ暗黙に代用しない。

投影は原版から確定した方向変換の後、既存の全天・地平座標へ適応分割する。密な 4,001 点の独立標本による画素誤差、RA の継ぎ目、極、反対端点、予算・深さ不足、非有限値を確認した。未確定区間を結ばない。描画試験は Sky / Horizon の実 bitmap で clip、表示集合、Ser 二図形、line quality、観測地・日時、null context の不変を確認した。旧版の実行・画素一致は検証していない。

恒星名の型付き集合は既存 StarNameRecord の HIP と is_featured を使う。未知 HIP を含む一括更新の原子性、空集合、追加・削除・全件操作、再 bind の維持・新規・消失を検証した。実 bitmap では固有名だけを制限し、恒星の点と HIP designation が不変であることを確認した。主クリック選択とは独立している。

| 試験 | Plus の checks | 通常版の checks |
| --- | ---: | ---: |
| core test_constellation_art | 75,705、CAB 89 件 | 99、CAB 0 件 |
| test_star_name_selection | 191 | 16、任意名前表の欠損を表示 |
| test_constellation_art_model | 99 | 10 |
| test_constellation_art_projection | 120,699 | 120,699 |
| test_constellation_display | 112 | 112 |
| test_constellation_art_renderer | 537,658 | 537,644 |

データは監査文書の `PLUS/data` と `MITAKA_ROOT/data` を読み取り専用で渡した。データ試験で名前表が欠損していても合成データ の試験は継続する。
