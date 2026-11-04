# UNIT5: 星座の個別表示と地平図

2026-10-29。UNIT4 source `002adcf663fd5005e14ac86c343a3ec7e56fa706` からの N05 実装・検証記録。
原本は読み取り専用とし、カタログ・画像の書換え、公開データへの置換、旧アプリの起動は行っていない。
本書は native の契約を記録する。未確定の旧 Lua 入力規則や星座絵まで対応済みとは扱わない。

## 原典と採用範囲

`PLUS` は `/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka`。
対象原版は Windows Plus 1.5.4 build101013、同梱 API 文書は 1.3.0 表示である。
原典の詳しい照合は [星座契約監査](../local-constels-contract-audit.md) に記録済み。

| 原典 | 今回使う根拠 | 今回確定しない内容 |
| --- | --- | --- |
| `doc/script_jp/constels.html:12–31,42–63` | 名称・線・境界の独立 bool、略号を使った show/hide、単一略号の isVisible | 大小文字、未知略号、空入力、区切り、重複、全体 bool と集合の厳密な優先順位 |
| `scripts/gui_jp.lua:164–168` | 名称・線・絵・境界が別メニュー | 絵の投影・配置式 |
| `ui/scripts/12constels.lua:1–5`、`orion3d.lua:1–5` | hide("All") 後に特定略号を show する用途 | All と個別指定の混在、isVisible("All") |
| `data/constellation_HIP.dat` | 89 原行・88 略号。Ser は頭と尾の 2 行 | 89 を将来の上限・必須件数にしない |

Ser の原行は offset 94,690 の `Ser1` / Serpens(Caput) と 95,602 の `Ser2` / Serpens(Cauda)。
表示集合の ID は両方とも元の `Ser` なので、1 回の表示切替を両図形へ適用する。
CDF/CAB の 89 資産と名称位置の対応は確認済みだが、絵の軸・元期・尺度は未確定のため本単位の renderer へ接続しない。

## native の表示契約

`ConstellationDisplayModel` は元の全行を保持し、カタログ略号の raw bytes を ID にする。
大小文字を変換せず、文字列 `All` に特殊な意味を追加しない。
全体操作は専用の `set_all_visible(bool)` で行う。
3 個の全体表示フラグと、`default_visible` / 例外 ID 集合を分離する。
各行の実効可視性は、該当レイヤーの全体フラグとその略号の membership の論理積である。
全表示・全非表示は例外集合を空にし、名称・線・境界のフラグを保持する。

複数 ID 更新と設定全体の更新は、すべての ID を検証してから一括適用する。
未知 ID は `invalid_argument`、範囲外の原行 index は `out_of_range` とし、部分適用しない。
モデル再読込では残存 ID の例外を保持し、新しい ID は既定値を使い、消失した例外を結果として報告する。
手動 Session 復元は再bindとは異なり、不明な ID を含む保存状態全体を拒否する。
Session v5 の接続担当とは、raw ID を canonical base64 の `exceptions_base64` として保存する境界を合意した。
同じ略号が継続すれば元ファイル全体の SHA が変わっても ID は維持できる。

App の共通 setter が検証済み設定を SkyView、HorizonView、ブラウザへ渡す。
ブラウザのチェック列は星座行だけに表示し、元行 index を渡す。
Ser の一方を操作すると両方のチェック状態が揃う。
全表示・全非表示は検索ページの外も含めた全カタログが対象で、検索結果の件数に依存しない。
チェック変更は視点・観測対象の単一選択を変更しない。
星座の選択・中央表示を明示した場合だけ、その ID と線・名称を表示対象にし、地平図では現在の観測地・JD で中心を求める。
星座以外の既存カタログの選択、検索世代管理、ページングは保持する。

## 天空図と地平図の共通描画

既存の星座線・境界・名称を `ConstellationRenderer` に集約した。
原行の重複排除を行わず、HIP が欠ける区間を跨いで結ばない。
線・文字には既存 RendererQuality の局所 scope と地図 clip を使う。
名称の CP932 解釈、既存の色・線幅・フォント、Bayer など恒星ラベルの別経路を保持する。

天空図の線は既存と同じ、最短の赤経差と赤緯の線形補間である。
地平図もこの同じ天球上の線を、既存 `ObservationFrame` で観測地・JD の地平座標へ変換する。
独自の恒星時・歳差・大気差計算は追加しない。
画面用の経度は `360° − azimuth` とする。

`horizon_segments` は端点・1/4・中央・3/4 点の画面誤差と元角度幅を使って区間を分割する。
既定値は元角度幅 2° 以下、標本点の画面誤差 0.25 px 以下、最大 8,193 評価、最大深さ 20。
これは標本誤差の制限であり、曲線全体に対する解析的誤差保証とは説明しない。
天頂・天底と方位角の継ぎ目を分離し、予算が不足した区間は結ばず omitted 件数に残す。
HorizonView は omitted の存在を画面に示す。
地平線の下の部分も投影し、屈折や視差による補正は行わない。

## 検証

専用 build は `build-unit5-time`、`build-unit5-time-san`、`build-unit5-time-x86`。
通常、ASan+UBSan、Rosetta x86_64 の各構成を `-Werror` でビルドした。
GUI を使う browser 試験は他担当と実行枠を調整し、同時にアプリを起動していない。

| 試験 | 通常 | ASan+UBSan | x86_64 | 対象 |
| --- | ---: | ---: | ---: | --- |
| constellation_display + Plus 原本 | 7,897 | 7,897 | 7,897 | 89 行/88 ID、全レイヤー組合せ、Ser、追加 raw ID、原子的拒否、再bind |
| horizon_segments | 101,337 | 101,337 | 101,341 | dense oracle、赤経継ぎ目、180°差、両極、拡大、評価不足、非有限値 |
| constellation_renderer + Plus 原本 | 4,300,935 | 4,300,935 | 4,300,935 | 実画素、8 組のレイヤー、clip、Ser、品質設定、観測地/JD |
| catalog_browser_controller + Plus 原本 | 46 | 46 | 46 | 原行対応、検索外への全表示、非星座行、空カタログ、選択維持 |

地平区間の check 数は受理された区間数を含むため構成間で差がある。判定条件は同じ。
通常版のローカル data には `constellation_HIP.dat` が存在せず、SkyModel の既存の optional 欠損経路になる。
この状態は失敗にせず、空集合の更新と Sky/Horizon 両方・全 8 レイヤー組合せの空描画、欠損 warning を確認した。
通常版の別形式 JSON をこの単位で自動代用しない。
最終ログは [logs/n05-constellations](logs/n05-constellations/) に保存する。

独立レビューでは helper の入力境界・原子的更新・極と budget 不足時の非接続、App/ブラウザの原行・世代管理、実描画試験を確認し、修正必須の指摘はなかった。
新依存は追加せず、既存 core のカタログ、投影、ObservationFrame と AppKit/Core Graphics を再利用した。
全体の Session・Lua・メニュー・アプリ smoke・policy gate は root の統合検証で判定する。
この文書と担当差分は親担当がまとめて commit するため、子担当では stage/commit していない。
