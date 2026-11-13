# 彗星の軌道標本と種類別の表示設定

| ファイル | 役割と契約 |
| --- | --- |
| native/core/include/mitaka/small_body_orbit_path.hpp / src/small_body_orbit_path.cpp | 元行、開始・終了 **TDB JD**、標本数から有限の開軌道を生成する。開始 < 終了、有限な差、2～4096 標本、丸め後も隣接 JD が狭義昇順という条件を先に検証する。 |
| 同上 | 各標本の位置は既存 evaluate_small_body だけで計算する。参照面・時系の未確定や評価不能を各標本の nullopt と診断で保持し、legacy numeric JD の時系を推定しない。成功位置は日心 J2000 黄道 AU。 |
| 同上 | 各標本の実際の JD、位置、診断、元 ID を保持する。線分は隣接した成功標本の組だけ。欠損を跨がず、終始点を自動接続しない。表示期間を科学的な精度保証期間として扱わず、unknown_accuracy_range を維持する。 |
| native/gui/include/small_body_display.hpp / src/small_body_display.cpp | asteroid / trans_neptunian / comet ごとに visible、labels、orbits、selected_only を持つ。native 初期値は true / false / false / false。 |
| 同上 | visible は kind 全体の master。body は visible AND (selected_only が false、または member)、label / orbit は body 判定に各設定を AND する。scene、位置評価の有効性、既存 global master は呼出側が重ねる。 |
| 同上 | 複数行の表示集合は source_key + record_ordinal で識別する。クリック選択・追尾・検索を所有しない。未登録・重複 ID の更新は全体を拒否し、元の集合を維持する。元の Visible 属性から集合を推定しない。 |
| 同上 | 再 bind は新 dataset 全体を先に検証し、同 ID、同 kind、**source 原 bytes 完全一致**のときだけ集合を保持する。解除した ID を報告し、エラーなら元状態を維持する。名前・番号・言語別定義を統合せず、bytes 比較は出典ごとに一度だけ行う。 |

合成部分は orbit path 141 checks、display model 295 checks。ローカル原本は PLUS_ROOT/data を読んだ。彗星 2,457 行を全件保持し、J2000 付近の評価可能行は 2,388、未評価は 69（既存 loader の歴史暦未解明 65 行と個別定義 4 行）。display model は 67 source、19,475 行を全選択し、再読込後も元 bytes の一致する全 ID を保持した。件数を fixture に固定して通したものではない。
