# 単位 5 の検証記録

基点は単位 4 の `002adcf663fd5005e14ac86c343a3ec7e56fa706`。対象はローカルの Mitaka Plus 1.5.4 build101013 と通常版の原データである。原本・独自追加データを優先し、公開データへの置換、原件数に合わせた切捨て、原本への書込みを行わない。

この索引は担当別の実装根拠と統合検証をまとめる。下表と後述の試験成功は確認した範囲の判定であり、旧 Plus の全機能互換の完了とは扱わない。

| 対象 | 記録 | 現時点の判定範囲 |
| --- | --- | --- |
| N01 彗星・小天体の表示と軌道 | [契約](comet-orbit-contracts.md)、[表示 helper](comet-display-helper-validation.md)、[軌道経路](orbit-pipeline-validation.md)、[統合計画](n01-integration-plan.md)、[統合の局所検証](n01-integration-validation.md) | controller 60 / rendering 148 / Solar 42 checks が各 3 構成で成功。visible は種別 master、labels / orbits はその下の個別設定。原版の表示優先順位との一致は未認定。 |
| N02 衛星の表示と軌道 | [表示仕様](../../../native/gui/SATELLITE_DISPLAY.md)、[Lua 契約](lua-comet-satellite-contracts.md) | 検証済み出典の Kepler 軌道、選択集合、名称・軌道、canonical visible を接続。月の軌道線、追加衛星の形状・自転・表面は未完。 |
| N01/N02 の Lua API | [Lua 契約](lua-comet-satellite-contracts.md) | 対応 API と未対応境界を原版根拠ごとに記載。衛星の形状・姿勢・表面対応を含むものではない。 |
| N03 PTH 探査機 | [実装・検証と未完範囲](spacecraft-minor-validation.md) | 位置、点・名称・原標本軌跡、一覧、選択・日時追尾を確認。PPI の表示や機体の形状・姿勢は未完。 |
| N04 packed 36 byte 小惑星/TNO | [契約](minor-planet-position-contracts.md)、[実装・検証と未完範囲](spacecraft-minor-validation.md) | 確定した形式の位置と GUI モデルへの接続を確認。37 byte 形式と原版の細部一致は未完。 |
| N05 星座集合 | [表示設計と検証](constellation-display-design.md) | 共通の略号集合と例外集合を全天図・地平図へ接続。88 略号 / 89 図形、Ser2 を同じ星座として扱う。CAB 星座絵は次単位。 |
| 状態保存 | `session_layers`、`session_layers_json`、`AppSessionSmokeTests` | JSON v5 に各表示設定・集合・軌道標本設定を保存し、原出典 SHA-256・バイト数・安定 ID を復元前に照合する。旧開発版 v1〜v4 の暗黙変換はしない。 |

N06 地平図の天の川は [次単位の原典調査](../unit6/horizon-milkyway-contracts.md) の段階であり、この単位の製品実装に含めない。

新しい外部依存はこの単位の表示・状態保存には追加していない。C++17 標準ライブラリ、既存の軌道計算・loader、AppKit/CoreGraphics/ImageIO、既存の太陽系カメラ・描画品質管理を使用する。状態保存は既存の Foundation JSON と macOS 標準 CommonCrypto の SHA-256 を使用する。元 Windows 実装との bit 一致・画素一致、macOS 13 実機・Intel 実機の確認は、この局所試験の対象外である。

正確な名称の `/simplifier-lai` は利用可能な一覧にない。`simplify-lai` は LobbyAI 用であり代用せず、担当間の独立した読取レビューで契約、既存依存の再利用、出典・時刻・選択の境界を確認した。方針は IMPLEMENTATION_POLICY.md と対応する gate テンプレートへ反映した。300 行以上の差分を commit する前に、Git 状態・登録ファイル・差分量・依存を確認する。

## 統合検証

macOS 26.6.2 / Apple Silicon で実施した。通常、ASan/UBSan、x86_64（Rosetta）の 3 構成でコア・GUI の試験と controller 試験が成功した。別 clone・新しいビルド出力でも `all test` が成功し、その後の Lua/星座修正を同 clone へ反映した再試験も成功した。通常の warning は `-Werror` で扱う。

- Plus 原データの全体 smoke は 3 構成で成功。小天体 19,475 行（位置評価可能 10,839）、衛星 340 行（位置あり 330）を保持する。Session v5 の全表示設定、3 小天体 ID、2 衛星 ID の往復と、5 種の不正入力による状態維持を確認した。
- 通常版の原データでも全体 smoke が成功。追加小天体・衛星がない状態を正常な空集合として扱い、Lua、状態保存、描画、再生、地表移動、連続飛行が完走した。
- Lua からの星座設定が全天図・地平図で同期し、表示モードと星座集合を保持することを確認した。軌道標本の予算を超える実データ要求は、設定を変更せず拒否した。
- 通常版・Plus のデータ試験が成功。公式の独立参照と CF96 5,427 成分、自転 33,129、月 12,108 checks を比較した。CF96 の最大位置差は 7.10543e-14 AU、最大速度差は 6.93889e-18 AU/day だった。
- 原本保全検査では 16,365 ファイル・6,622,642,667 bytes・465 symlink に追加・削除・変更がなく、公式 ZIP の 310 ファイルも一致した。両リポジトリの Private 設定を確認した。

記録は [統合ログ](logs/integration/) と [SHA-256 一覧](logs/integration/SHA256SUMS) に保存する。`final3-app-*` が修正後の全体 smoke、`final3-clean-gui` が最新 3 ファイル反映後の clone 試験、`final2-*-controller` が controller 試験である。担当ごとの局所試験は上表の検証文書から辿れる。

途中で失敗したログも残した。通常版の衛星テストが Charon の存在を前提とした箇所、探査機テストの不完全な衛星定義、Lua テストが全小惑星の軌道を意図せず要求した箇所、星座 toggle が常に全天図へ切り替わるという旧期待を修正した。最後の確認で見つかった Lua の星座設定の同期漏れは共通 setter への接続で修正し、実アプリで無効・有効の両状態を検証した。失敗を成功ログで置き換えていない。

旧 Windows Plus の画素一致、macOS 13 実機、Intel 実機、実 OS の完全遮蔽通知、複数画面は今回の成功範囲に含めない。これらの機器・旧実行環境での試験は未実施である。未実装の尾、PPI 表示、機体形状、追加衛星表面、CAB 星座絵等は機能対応表に残している。
