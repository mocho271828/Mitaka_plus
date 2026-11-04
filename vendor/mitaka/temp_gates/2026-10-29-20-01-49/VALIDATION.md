# 単位3の policy gate 検証

検証開始: 2026-10-29 20:01 JST。判定者: plus_spec_audit 担当。試験実施者: 主担当と各実装担当。ソースの独立レビュー担当は、他の GUI 試験との競合を避けて試験を重ねて実行していない。

## 対象と最終判定

基準 HEAD は `ae300e1e396c5ed0e6eb5129ad8a6f0069489597`。単位3の共通表示設定、恒星名・マーク、格子・距離目盛、月間カレンダー、日時情報、JSON v3、追加 Lua API、投影 window の private factory と試験の分離を対象とする。
最終判定対象は UNIT3 の index である。2026-10-29 20:05 JST の `git diff --cached --binary -- native/` の SHA-256 は `8d2bd45c5e0757e563d5d737240e0dd1e8ef2d0e103d47729558971c4a0e7b41`。開始時点の追跡対象 native 差分と一致する。主担当が並行して開始した UNIT4 の未 stage 差分と未追跡ファイルを含めない。

**2026-10-29 20:06 JST、14 gate すべて YES。判定条件138個をすべて確認した。** 開始時は最終 controller と記録待ちの5条件を未チェックとし、11 YES / 3 NO で保留した。3構成の最終結果と Git 記録を確認してから確定した。
不合格条件は非該当として未チェックのまま残す。`policy_gates/` のテンプレートにはチェックを入れていない。

| Gate | 判定 | 主な根拠 |
| --- | --- | --- |
| continuous_flight | YES | 既存契約維持、航行/地表モデル回帰、4回の全体smoke |
| core_architecture | YES | coreの既存製品差分なし、独立clean build、GUI境界 |
| data_contracts | YES | 既存ローダーの異常系、両実データ、全件保持 |
| local_plus_assets | YES | 小天体・背景・媒体の既存回帰と未確定仕様の保持 |
| moon_surface_navigation | YES | 既存公式比較、今回のモデル・AppKit回帰 |
| native_gui | YES | 表示・格子・CUA・最終3構成controller成功、実OS遮蔽は未通過と明記 |
| planet_rotation | YES | 既存公式比較、今回の軸描画・姿勢回帰 |
| planet_textures | YES | 既存上限・読み取り契約、今回の画像回帰 |
| plus_compatibility | YES | JSON/Lua/部分互換と最終3構成controllerを確認 |
| preservation | YES | 全manifest一致、出力拒否、原本・許諾保持 |
| repository_management | YES | Private確認、資産非登録、cleanと後続strict buildを区別 |
| solar_view | YES | core座標再利用、同一JD、3D/選択/状態復元smoke |
| time_playback | YES | clock/calendar回帰、月末CUA、追従/停止smoke |
| verification | YES | 最終3構成controller・sanitizer・Git状態・差分検査を確認 |

各コピーの「判定根拠」に判定条件の番号と証拠を対応させた。単位2から変更がない契約と、単位3で再実行した試験を区別する。
この判定は旧 Plus の全機能、画素一致、全ローカル Lua の無変更実行、時系補正、未確定の衛星/探査機/星座絵/景観/Renderer設定の完了を意味しない。
次単位の未追跡 core / RendererQuality / HTML helper / 新規監査文書は、この単位の接続済み機能として評価しない。

## 実行記録

- [単位3 README](../../investigation/native-plus/unit3/README.md) と [ログのSHA-256](../../investigation/native-plus/unit3/logs/SHA256SUMS) に各構成の証跡を残す。別担当が収集した最終 controller と実 OS モードのログも含む。
- 通常・ASan / UBSan・x86_64 の `test` は成功。代表値は calendar 333、session 865、grid renderer 87、distance scales 127、playback clock 10,134、file IO 51 checks。x86_64 実行は Rosetta であり、Intel実機と記載しない。
- Plus / 標準版の `data-test` が成功。通常 Plus、通常標準版、ASan / UBSan Plus、x86_64 Plus の4回の全体smokeは exit 0 を主担当が確認し、成功行をログへ残した。
- clean は `/tmp/mitaka-unit3-clean.5ljHod` の clone + staged単位3patchから core / GUI `all test` が成功。最終private factory seam前の結果である。後続のseamは既存object内の生成委譲だけで新依存を増やさず、通常 / sanitizer / x86_64 のtargeted strict buildと単体46 checksが成功した。最終全差分のclean再実行とは扱わない。
- core公式比較は単位2の [比較ログ](../../investigation/native-plus/unit2/logs/mitaka-plus-unit2-final-references.log) を継続根拠とする。rotation 33,129、lunar 12,108、CF96 5,427 成分成功。単位3で同じ比較を再実行したとは記載しない。既存coreの製品変更はなく、今回のcleanで既存coreテストが成功した。
- 主担当のCUAは月間42セル、2000-01-31→02-29→01-29、年・秒刻みに桁区切りなし、UTC+00:15適用後 JD2451603.989583 を確認した。全画面の網羅試験とは扱わない。
- [独立レビュー](../../investigation/native-plus/unit3/review.md) は入力境界・既存依存・500行目安・状態復元・非表示層・カレンダー・追加factoryを確認し、修正必須の新規指摘はなかった。

## 実 OS の遮蔽通知と controller の境界

実WindowServerによる完全遮蔽通知は未通過であり、通常controller成功や全体smokeで置き換えない。[環境制約](../../investigation/native-plus/unit3/occlusion-environment.md) にbaseline、単独実行、別processcover、描画完了、寸法・level・待機・eventloopの切り分けを記録する。

private factoryの製品実装は以前と同じNSWindowを返す。`updateTimer`の可視・非最小化・非sleep・非occluded条件と通知処理は基準commitから不変である。試験だけが `occlusionState` と公開通知を入力する。通常と `--system-occlusion` は同じlifecycleを通り、遮蔽直後の停止、遮蔽中sleep/wake停止維持、表示復帰、hidden wake、close/invalidateをassertする。

通常の状態注入単体は通常 / ASan・UBSan / x86_64 各46checks成功。実OSモードはexit1（完全遮蔽待ち）であり、skipや成功への変換はない。`make system-occlusion-test` を別ターゲットに残す。これは通知に対するcontrollerの回帰を安定して検証するための境界分離であり、未解消のOS通知を解消したという判定ではない。

## 保全・依存・Git

[原本検証](../../investigation/native-plus/preservation-final.json) は16,365 files、6,622,642,667 bytes、465 symlinksで追加/削除/変更0。公式ZIP310files一致、参照checkoutのHEAD/statusも基準一致。比較日時は2026-10-29T10:38:56.971022Z。
`gh repo view --json nameWithOwner,visibility` は mocho271828/Mitaka = PRIVATE。追跡済み画像・data・実行ファイル・object/archiveの拡張子検索は0件。公式ソースは `.gitattributes` で `-text` を維持する。

新しい外部ライブラリは追加せず、既存AppKit / CoreGraphics / Foundation / core / 公式Lua helperを利用する。指定名 `/simplifier-lai` は利用不可。別名の `simplify-lai` はLobbyAI専用で適用していない。手動の依存・責務レビューを実施した。日本語文書には `japanese-writing` を使用した。

300行超のため主担当が単位3をcommitする。本担当はstage / commitを行わない。commit前の最終Git状態・差分量・差分検査と、controller最終結果は下節に記録した。commit/push実施前に成功と記載しない。


## 最終確定記録

2026-10-29 20:06 JST、実装担当と主担当から最終 `controller-test` の通常 → ASan / UBSan → x86_64 の逐次実行がすべて exit 0 との報告を受領し、各生ログの成功行を確認した。
[通常](../../investigation/native-plus/unit3/logs/mitaka-unit3-controller-suite-normal.log)、[ASan / UBSan](../../investigation/native-plus/unit3/logs/mitaka-unit3-controller-suite-san.log)、[x86_64](../../investigation/native-plus/unit3/logs/mitaka-unit3-controller-suite-x86.log) は Script、small-body 23、solar small-body 19、media 43、catalog browser 23、Playback、DisplayOutput 46 checks の成功を記録する。x86_64 は Rosetta で実行した。

[実 OS モード](../../investigation/native-plus/unit3/logs/mitaka-unit3-occlusion-system.log) の exit 1 は残る。この結果を隠さず、製品 timer 条件を弱めず、状態注入による controller の停止・復帰試験とは区別した。14 gate の合格は UNIT3 の上記境界・部分互換・検証記録が条件を満たす判定であり、WindowServer の完全遮蔽通知や旧 Plus の全機能の完成を意味しない。

最終記録作成前の `git status --short` と index の変更ファイルを確認した。`git diff --cached --shortstat` は **76 files changed, 4,181 insertions, 322 deletions**。この値は stage 済み UNIT3 の差分で、未追跡の本 gate コピー・レビュー・ログと UNIT4 を含まない。`git diff --cached --check` は成功。並行作業中の作業ツリー全体を単位3の差分量や判定対象として扱わない。

本担当の変更は14個の gate コピーと本記録、独立レビュー文書に限る。原本の `policy_gates/` と `IMPLEMENTATION_POLICY.md` は主担当による単位3方針更新を参照し、本担当は編集していない。stage / commit / push は行っていない。300行超の単位3 commit と最終登録ファイルの選別は主担当が行う。
