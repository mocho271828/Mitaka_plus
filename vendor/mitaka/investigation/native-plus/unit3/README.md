# Plus 機能追加・単位3の範囲と検証記録

確認日: 2026-10-29。基準 commit は単位2の `ae300e1e396c5ed0e6eb5129ad8a6f0069489597`。
この記録は共通表示設定、座標格子・距離目盛、月間カレンダー、日時情報、JSON v3 と追加 Lua API を対象とする。

**通常・ASan / UBSan・x86_64 の `test` と最終 `controller-test`、実データ試験、全 4 構成の smoke、原本保全は成功した。14 policy gate の138条件も確認し、すべて YES と判定した。実 OS の完全遮蔽通知は未通過である。** 最終 controller 試験は遮蔽状態を制御する fixture で timer の停止・復帰を検証した。実 OS 通知の成功とは扱わない。stage 済み差分からの clean build も成功したが、最終 window factory 追加前の差分が対象である。
原版の全機能完成を示す記録ではない。未対応の機能と受入条件は [機能対応表](../../../PLUS_FEATURE_MATRIX.md) に残す。

## 実装した接続

| 対象 | 接続と状態の契約 | 範囲・残る制約 |
| --- | --- | --- |
| 惑星 4 項目 | `PlanetDisplayOptions` に本体・名称・軌道・自転軸を保持し、メニュー・Lua・状態復元を共通適用へ接続する。 | 軌道と軸は太陽系 3D の 9 惑星・月。本体の可視性と軌道は独立。太陽の軸は含めない。 |
| 恒星 5 項目 | `StarDisplayOptions` に本体・固有名・Bayer・Flamsteed・HIP を保持し、全天図と地平図で共有する。 | 名前は読み込み済みのローカル名称と HIP 項目を使う。明るさや像の倍率など、原版の全設定を含むものではない。 |
| 恒星マーク 3 種 | None / Binary / ExoPlanets を型付き列挙値で保持する。 | 連星は HIP の `is_double`、系外惑星はローカルのホスト HIP リストを使う。未登録の対象を推測しない。 |
| 格子・距離目盛 6 項目 | 赤道・黄道・銀河・地平と、円・四角の目盛を独立に保持する。 | 方向格子と物理距離の目盛は別の描画契約。円・四角の目盛は太陽系 3D で扱う。 |
| 月間カレンダー | 日曜始まり 7 列 × 6 週の 42 セル、日選択、前後月移動を数値入力と共有する。 | 当月外の空欄は選べない。操作は入力候補だけを更新し、適用までは表示 JD を変更しない。 |
| 日時情報 | メニュー・Lua の `Time.timeInfo`・状態復元で日付欄と地平図・太陽系 3D の表示を共有する。 | 表示の切替で JD・通常再生・時計追従を変更しない。 |
| JSON v3 | 惑星・恒星・格子・日時情報を既存の検証済み状態モデルへ追加する。 | 本番投入前の設計変更として v1 / v2 を拒否し、暗黙変換しない。旧 Lua 状態ファイルの互換実装ではない。 |
| Lua | Time 2 項目、Stars 5 項目、Planets 4 項目、Grids 6 項目の真偽値を取得・設定・トグルに接続する。 | `Stars.markingType` は 3 種、`Milkyway.type` は 4 種の取得・設定に対応。列挙値の循環順序は未確定なので、その toggle API の対応を主張しない。 |

`AppDisplayCommands.mm` が共通表示設定を各ビューへ適用する。非表示にしても原データと既存選択は保持し、クリック判定・名称・マーク・選択リングを抑止する。選択した天体への移動や追従を解除する操作とは区別する。
恒星の等級・画面上の可視域による描画制限を、読み込み記録の削除に使わない。

## 原典と新 GUI の契約

恒星名の星座 ID は、公式の `ConstellationAbbr` の固定順で解釈する。利用者の星座データの並び替えを Bayer / Flamsteed の意味変更に使わない。名称、連星マーク、軸の根拠と許諾は [STAR_DISPLAY_PROVENANCE.md](../../../native/gui/STAR_DISPLAY_PROVENANCE.md) に記載する。

赤道・黄道・銀河の方向格子は J2000 の固定基底を使い、地平格子は地球上の観測地と表示 JD に依存する。全天図・地平図の黄道は大円、太陽系 3D の黄道は太陽中心の ±100 AU の平面枠と主軸である。
太陽系 3D の赤道・銀河・地平格子はカメラ中心の方向球として扱い、地球以外の地表座標を計算したものではない。地平方位線は 45° 間隔とし、標準版の 30° の格子線とは異なる。

円形目盛は黄道面の AU 尺度 5 種と銀河面の光年尺度 16 種、方形目盛は注視点を中心としてカメラへ正面を向く 10⁰〜10²⁷ m の 28 種を定義する。視点距離による透明度と既存カメラの距離制限があるため、すべての尺度を現行ビューで表示できるわけではない。
標準版の式を参照していても、旧 `ds.scale` と新カメラ距離の意味や、旧 Plus の表示画素との一致は未検証である。初期値は標準版に従い円形目盛だけを有効にするが、Plus の ini と初期化スクリプトの最終値を再現したとは扱わない。
数式・単位・既存変換の再利用・相違点は [GRID_PROVENANCE.md](../../../native/gui/GRID_PROVENANCE.md) に記録する。

月移動は時分秒・固定 UTC 時差を保ち、移動先に同じ日がない場合は月末へ収める。カレンダー入力には既存の先発グレゴリオ暦と JD 範囲の検証を使う。これらは新 GUI の明示した契約であり、旧 Plus の全日時 API や時系補正の再現ではない。

原典の API と描画範囲の調査は [local-lua-next-audit.md](../local-lua-next-audit.md)、[local-rendering-audit.md](../local-rendering-audit.md) を参照する。公式標準版 1.3.1、Plus 1.5.4 build101013、同梱 API 文書の 1.3.0 表示を同一版と扱わない。

## 境界と依存

表示設定は GUI 層の C++17 型にまとめ、AppKit / Foundation と既存の core 座標変換を使う。新しい描画ライブラリや別の天文暦を導入していない。
Lua は既存の公式 5.4.9 helper を使用し、getter / toggle は呼び出し時点のホスト状態から結果を作る。真偽値、列挙値、引数数を厳密に検証し、ホスト拒否を Lua エラーとして返す。
`Time.realtime` は既存の OS 時計追従を使う。未対応 API を空の成功として返すことや、旧スクリプト全体の実行互換を保証することはない。詳細は [SCRIPTING.md](../../../native/gui/SCRIPTING.md) に記載する。

状態ファイルの最大 1 MiB、原本を保全する出力先制限、復元前の入力検証を維持する。復元時は再生・時計追従・飛行を停止し、保存時の動作を自動再開しない。
旧アプリ・ローカルデータ・公式参照ソースは読み取り対象であり、この単位の機能実装のために変換・再保存しない。

## 試験とレビューの記録

以下は 2026-10-29 の単位3の実行記録である。通常、ASan / UBSan、x86_64 のログを別々に保存する。

| 確認箇所 | 主な対象 | 最終結果 |
| --- | --- | --- |
| `test_star_labels.cpp` | Bayer / Flamsteed / HIP、固定星座 ID、欠損値 | 通常・ASan / UBSan・x86_64 成功 |
| `test_display_rendering.mm` | 本体・ラベル・マーク・自転軸の切替と描画 | 通常・ASan / UBSan・x86_64 成功 |
| `test_grid_geometry.cpp` | 基底、閉曲線、極、観測地・日時、異常入力 | 通常・ASan / UBSan・x86_64 成功 |
| `test_distance_scales.cpp` | 単位・候補尺度・中心・向き・減衰 | 各構成 127 checks 成功 |
| `test_grid_renderer.mm` | 描画対象ごとの格子と距離目盛 | 各構成 87 checks 成功 |
| `test_calendar_time.cpp` | 42 セル、曜日、閏年、BCE、上下限 | 各構成 333 checks 成功 |
| `test_session_state.mm` | JSON v3 の往復、旧版・不正型・列挙値の拒否 | 各構成 865 checks 成功 |
| `test_script_controller.mm` | 真偽値・列挙値の検証、最新状態、ホスト拒否 | 通常・ASan / UBSan・x86_64 成功 |
| `AppPlusSmokeTests.mm` | メニュー同期、カレンダー候補と適用、日時情報 | 通常 Plus / 標準版、ASan / UBSan Plus、x86_64 Plus の計 4 回成功 |
| `AppScriptSmokeTests.mm` | Lua からの実画面設定、getter / toggle、復元 | 通常 Plus / 標準版、ASan / UBSan Plus、x86_64 Plus の計 4 回成功 |

| 統合確認 | 結果と証拠 |
| --- | --- |
| 通常 `test` / `controller-test` | 成功。[通常ログ](logs/mitaka-unit3-normal.log) |
| ASan / UBSan `test` | 成功。[sanitizer ログ](logs/mitaka-unit3-sanitize.log) |
| x86_64 `test` | 成功。[x86_64 ログ](logs/mitaka-unit3-x86.log) |
| 最終 `controller-test` | 通常 → ASan / UBSan → x86_64 の逐次実行で 3 構成とも exit 0。Script、small-body 23、solar small-body 19、media 43、catalog browser 23、Playback、DisplayOutput 46 checks を確認。[通常](logs/mitaka-unit3-controller-suite-normal.log)、[ASan / UBSan](logs/mitaka-unit3-controller-suite-san.log)、[x86_64](logs/mitaka-unit3-controller-suite-x86.log) |
| Plus / 通常版の実データ | 両方の `data-test` が成功。[Plus](logs/mitaka-unit3-plus-data.log)、[通常版](logs/mitaka-unit3-regular-data.log) |
| 通常構成の全体 smoke | Plus / 標準版とも exit 0。Plus は小天体 19,475 行・評価可能 2,388 行、標準版は 0 行と欠損診断を保ったまま通過。[Plus smoke](logs/mitaka-unit3-plus-smoke.log)、[標準版 smoke](logs/mitaka-unit3-regular-smoke.log) |
| clean build | stage 済み単位3だけを `/tmp/mitaka-unit3-clean.5ljHod` へ展開し、core と GUI の `all test` が exit 0。未追跡の単位4コードを含めない。[clean ログ](logs/mitaka-unit3-clean.log)。最終 window factory 追加前の差分が対象であり、最終 controller / smoke の結果も含めない |
| 原本保全 | 16,365 files、6,622,642,667 bytes、465 symlinks。追加・削除・変更はすべて 0、公式 zip との不一致 0、参照リポジトリの HEAD / status も基準一致。[最終結果](../preservation-final.json)、[ログ](logs/mitaka-unit3-preservation.log) |
| 実 GUI 操作 | CUA で 42 セル、2000-01-31 → 02-29 → 01-29 の月移動、年・時間刻みに桁区切りが入らないことを確認。UTC+00:15 で適用後 JD `2451603.989583` を確認。これは主担当の操作記録であり、全画面の網羅試験とは扱わない |
| ASan / UBSan・x86_64 の Plus smoke | 両方とも exit 0、全項目成功。[ASan / UBSan smoke](logs/mitaka-unit3-sanitize-smoke.log)、[x86_64 smoke](logs/mitaka-unit3-x86-smoke.log) |
| 最終 policy gate | 14 YES、138条件確認。[最終判定記録](../../../temp_gates/2026-10-29-20-01-49/VALIDATION.md) |
| 実 OS の遮蔽通知 | 未通過、exit 1。`--system-occlusion` / `make system-occlusion-test` に分離して残した。既定試験は private window factory から試験 NSWindow の `occlusionState` を注入し、timer の停止・再開条件と assert を維持する。[OS 試験ログ](logs/mitaka-unit3-occlusion-system.log)、[制約と切分け](occlusion-environment.md) |

格子の回帰試験は、修正を除いた隔離コピーで極を横断する偽線と near-plane の巨大な線分に対する試験が失敗することも確認した。[回帰ログ](logs/mitaka-unit3-grids-regression.log)。作業ツリーの修正を取り消して試したものではない。

`logs/` は `/tmp/mitaka-unit3-*.log` の収集時点のコピーである。失敗した遮蔽 fixture の調査ログも残し、後続の成功で失敗記録を消さない。各ファイルの SHA-256 は [SHA256SUMS](logs/SHA256SUMS) に記録する。検証中に追加されるログは、主担当の最終結果に合わせて別途収集する。

Lua 接続の独立した読み取りレビューでは、worker / controller の入力検証、ホスト拒否の伝播、最新 snapshot と共通 setter の経路を確認し、修正必須の指摘はなかった。このレビュー担当は統合試験との競合を避けて試験を再実行しておらず、レビュー結果を実行成功と扱わない。
通常・sanitizer・実データ・controller・全体 smoke・アーキテクチャ別の実行結果と、実際に実施した GUI 操作を上記の表で区別する。以前の単位のログを今回の変更の検証結果として流用していない。

## 方針・Git と残る確認

`IMPLEMENTATION_POLICY.md` と既存の `native_gui`、`plus_compatibility`、`time_playback` gate に、共通表示設定、固定 ID、格子の基底・尺度、月間カレンダー、日時情報、JSON v3、Lua の最新状態取得を追加した。
gate テンプレートのチェックは埋めず、`temp_gates/2026-10-29-20-01-49/` の時刻付きコピーで実際に確認して判定した。判定対象は単位3の index とし、並行する単位4の未 stage 差分と未追跡コードを含めない。

文書担当はテキストだけを変更し、stage / commit は行わない。単位3の source / wrapper commit と最終差分量は主担当の実施後に追記する。
指定名 `/simplifier-lai` は利用可能なスキルに存在しない。別名の `simplify-lai` は LobbyAI 用であり、代わりに実行したとは扱わない。実装担当の手動レビューと独立レビューを区別して記録する。
この文書には `japanese-writing` を適用した。全 Plus 機能、旧版との画素一致、全ローカル Lua の無変更実行、時系補正、巨大尺度を含む宇宙航行は未完了または未確認として残る。
