# 検証記録

## 2026-11-05: P1-5〜P1-8 の途中実装

地球の地上・宇宙間の移動と Lua mode API、投影の補間、太陽系・銀河のロール、太陽系通常視点の姿勢 API、地平図の方位・高度設定と補間を追加した。Lua 対象と地平図の注視には、恒星の HIP 番号・英語名、一意に解決でき位置を評価できる小天体・探査機・衛星・球状星団、天の川銀河などを追加した。星座の正式英語名・略号による注視にも対応する。各項目の残りは[優先順位表](investigation/native-plus/feature-priorities.md)と[機能対応表](vendor/mitaka/PLUS_FEATURE_MATRIX.md)を参照する。P1-5〜P1-8 の全機能の完成や旧版との一致は主張しない。

統合 `make -j4 build` は成功した。途中段階では既存の関連する地表移動・方位高度・姿勢・Lua・状態保存の確認も成功し、地平図の投影・風景などの関連試験も通過した。実アプリでは、Lua から姿勢を設定し、恒星名で対象を選び、地平図で方位・高度を指定して太陽へ注視する通常操作を確認した。修正後の地球での離陸と降下も画面で確認した。姿勢補間と手動操作の競合修正、追加した全対象の操作、旧版との描画一致や速度は未確認。

失敗注入を含む `make test` および全体の `make data-test`・`make reference-test` は今回実行していない。[今回の policy gate 判定](temp_gates/2026-11-05-21-27-47/)では検証 gate が NO で、全 gate 通過ではない。新規ライブラリ依存はない。`/simplifier-lai` は利用可能な skill に存在せず、LobbyAI 専用の `simplify-lai` は適用対象外。

## 2026-11-05: P1-1〜P1-4 の実装と確認状況

- **P1-1:** 太陽系、3D 恒星、天の川銀河、大規模構造を共有カメラで接続した。旧 Plus との座標・色・形状・操作の一致には未確認の項目が残る。
- **P1-2:** 地平図に彗星・小惑星・有効な PTH 探査機の描画、選択、日時追従、表示切替を接続した。地心近似を用い、視差・光行時間・大気差・時系変換は未補正。PPI と旧 Plus との比較は未対応・未確認。
- **P1-3:** 承認を得た国立天文台の別配布地形データを使い、地球・火星の地形表示を接続した。両データを旧 Plus が読み込み表示できることを確認したが、旧版との描画一致は未確認。月・水星の地形データは同梱しておらず、旧 Plus での提供自体も未確認。日時を高速に連続変更すると、時刻整合を保つため地形の代わりに基準球が表示される場合がある。
- **P1-4:** 36 byte 小惑星・TNO の数値 JD による一周期の軌道を描画する。既定は非表示で、`selectedOnly` による表示集合への限定も可能。実データ全 8,451 軌道を使った局所試験と描画負荷測定を実施した。小天体の物理時系、旧版の軌道標本法と表示一致は未確認。37 byte 形式の旧 Plus での利用も未確認で、Mitaka++ の仕様と同一視しない。

小天体の位置・軌道の局所回帰試験は通常構成と ASan/UBSan 構成で通過した。描画負荷の測定条件と結果は[機能優先順位](investigation/native-plus/feature-priorities.md)を参照する。Intel Mac・macOS 13 の実機、複数物理ディスプレイ、旧 Plus との全画素一致は未確認。Mitaka++ の有用な機能の調査・採用は [Issue #1](https://github.com/mocho271828/Mitaka_plus/issues/1) で管理する。新規依存は追加していない。

P1-1〜P1-4 を含む `make build`、`make test`、`make data-test`、`make reference-test`、`make smoke` はすべて成功した。公式比較は CF96・自転・月・大気・食・銀河を含む。新規 clone でのビルド・単体テストと `git lfs fsck` も成功した。地球・火星の実データによる地形表示と、地球の連続 20 回の視点操作を確認した。全機能の旧版一致や Intel Mac・macOS 13 実機での動作を保証するものではない。

上記の P1 検証は Codex（主担当と作業担当サブエージェント）が実施し、対象コードは commit `c582d01` とする。追加テストは行わず、[今回の gate 判定](temp_gates/2026-11-05-20-10-00/)を既存の記録に基づいて確認した。

## 2026-11-05: UNIT8 表示半径の採用

Mitaka `73d3457969f8bcce88937492b66889a90b22d4bd` の表示半径と依存する UNIT8 の native 実装を `vendor/mitaka/` に取り込んだ。Plus 用のデータパスと同梱 Lua のオフラインビルドを維持した。表示半径の UI・Lua・描画・JSON v9 への接続に加え、依存する地形・銀河・時刻コードを含む。宇宙倍率変更の `KEEP_RADIUS`、`setScaleTo`、旧版との画素一致は未対応または未確認。

独立したビルドディレクトリでのクリーンビルドと、Plus データを使う `make build`、`make test`、`make data-test`、`make reference-test`、`make smoke` が成功。表示半径 controller 150 checks、session state 1,770 checks、Plus state 988 checks、実データ表示 192 checks が通過し、smoke は Lua の radius と session v9 を含む。元リポジトリの過去の sanitizer・x86 検証は今回の Plus 環境での再実行と区別する。

`resources/` と `vendor/mitaka/sources/` の開始時ファイル 885 件は作業後の SHA-256 が一致した。新規依存なし。`/simplifier-lai` は利用できず、LobbyAI 専用の類似 skill は対象外。方針と gate を更新し、[今回の gate 検証](temp_gates/2026-11-05-00-56-52/VALIDATION.md)を記録した。

## 2026-10-30: 風景・食と影・時間操作とローカルデータ基盤の採用

共通実装を `b901489c9b08a85742ff2d5a0ce1d9db522fe246` に固定した。fetch済みorigin/mainに存在し、submodule内はclean。風景、食の4設定と物理半径による影、旧Plusの時間step・連続再生、原地点ID、JSON v7、地形・銀河の読込と数値モデルを採用した。地形・銀河3D描画はこの単位に含めない。

独自追加を含むローカルPlusのdataを指定した `make build test data-test reference-test` は終了コード0。[統合ログ](verification/unit7-final-pin-tests.log)と[4ログのSHA-256](verification/unit7-SHA256SUMS)を保存した。公式比較はCF96 5,427、自転33,129、月12,108、大気12,606+792、食7,993成分が成功。submodule未取得、空・相対DATA_ROOTは[負例ログ](verification/unit7-negative.log)のとおり案内付き終了コード2で拒否する。

共通側の通常・ASan/UBSan・Rosetta x86_64のcore/GUI/controller、Plus full smoke 3構成、通常版full smoke、実データ、公式比較、新規cloneは[単位7記録](vendor/mitaka/investigation/native-plus/unit7/README.md)と[統合記録](vendor/mitaka/investigation/native-plus/unit7/logs/integration/README.md)を参照する。JSON v7はID・座標・出典・設定を全体検証し、通常再生・時計追従・旧Plus連続再生を停止して復元する。食は衛星マーク表示と独立、風景の画像失敗は他定義への差替えで隠さない。原本保全は16,365 files、6,622,642,667 bytes、465 symlinks、変更0。公式原本310ファイル一致。ラッパーではsanitizer・x86_64・full smokeを重複実行せず、採用SHAの結果を参照した。Intel/macOS13実機、複数画面、実OSの完全遮蔽通知、旧Plusとの全画素一致は未確認として残す。

[Mitaka](verification/unit7-source-private.log)と[Mitaka_plus](verification/unit7-private.log)は双方Private。データ/原本の複製登録、新規依存なし。既存Makefileに大気・食の公式比較を追加し、README、IMPLEMENTATION_POLICY、3 gateを更新した。exact `/simplifier-lai` は利用不可・未実行、類似skillはLobbyAI専用のため不適用。既存依存・差分・登録範囲を手動レビューし、[3 gate / 39条件](temp_gates/2026-10-30-02-12-29/VALIDATION.md)をYESとした。Git状態・差分量・diff --checkを確認しcommit/pushする。

## 2026-10-30: 星座絵・恒星名と明るさ・地球層・大気の採用

共通実装を `d1c361a750b2a1d71d71c423194954c4eade7a81` に固定した。fetch済みorigin/mainに存在し、submodule内はclean。地平図の天の川、全天図・地平図のCAB星座絵、恒星名のHIP選択と明るさ補間、地球の雲・夜景、大気のモードと強度、観測地点の読込規則、JSON v6を採用した。

独自追加を含むローカルPlusのdataを指定し、`make build test data-test reference-test` は終了コード0。[統合ログ](verification/unit6-final-pin-tests.log)と[4ログのSHA-256](verification/unit6-SHA256SUMS)を保存した。公式比較はCF96 5,427、自転33,129、月12,108成分が成功。submodule未取得、空・相対DATA_ROOTも[負例ログ](verification/unit6-negative.log)のとおり案内付き終了コード2で拒否する。

共通側の通常・ASan/UBSan・Rosetta x86_64のcore/GUI/controller、Plus full smoke 3構成、通常版full smoke、実データ、公式比較、新規cloneは[単位6記録](vendor/mitaka/investigation/native-plus/unit6/README.md)を参照する。JSON v6は恒星名HIP、明るさ、地球層、大気を全体検証し、不正入力で正常状態や明るさ補間を失わない。原本保全は16,365 files、6,622,642,667 bytes、465 symlinks、変更0。公式原本310ファイル一致。ラッパーではsanitizer・x86_64・full smokeを重複実行せず、採用SHAの結果を参照した。Intel/macOS13実機、複数画面、実OSの完全遮蔽通知、旧Plusとの全画素一致は未確認として残す。

[Mitaka](verification/unit6-source-private.log)と[Mitaka_plus](verification/unit6-private.log)は双方Private。データ/原本の複製登録、新規依存、Makefile変更なし。README、IMPLEMENTATION_POLICY、3 gateを更新した。exact `/simplifier-lai` は利用不可・未実行、類似skillはLobbyAI専用のため不適用。既存依存・差分・登録範囲を手動レビューし、[3 gate / 37条件](temp_gates/2026-10-30-00-31-57/VALIDATION.md)をYESとした。Git状態・差分量・diff --checkを確認しcommit/pushする。

## 2026-10-29: 小天体・衛星集合、探査機、星座集合の採用

共通実装を `5dd3409f8c551ff94666d84f4504f6f92f7047c7` に固定した。fetch後のorigin/mainに存在し、submodule内はclean。小天体・衛星の表示集合と軌道、PTH探査機の一覧・位置・軌跡、星座略号ごとの表示、JSON v5を採用した。

独自追加を含むローカルPlusのdataを指定し、`make build test data-test reference-test` は終了コード0。[統合ログ](verification/unit5-final-pin-tests.log)と[ログのSHA-256](verification/unit5-SHA256SUMS)を保存した。公式比較はCF96 5,427、自転33,129、月12,108成分が成功。submodule未取得、空・相対DATA_ROOTも[負例ログ](verification/unit5-negative.log)のとおり案内付き終了コード2で拒否する。

共通側の通常・ASan/UBSan・Rosetta x86_64のtest/script-test/controller-test、Plus/通常版のfull smoke、新規clone、JSON v5の正常復元と不正ID/出典不一致/上限超過の全体拒否は[単位5記録](vendor/mitaka/investigation/native-plus/unit5/README.md)を参照する。原本保全は16,365 files、6,622,642,667 bytes、465 symlinks、変更0。ラッパーではsanitizer・x86_64・full smokeを重複実行せず、採用SHAの結果を参照した。Intel/macOS13実機、複数画面、実OSの完全遮蔽通知、旧Plusとの全画素一致は確認済みと扱わない。

[Mitaka](verification/unit5-source-private.log)と[Mitaka_plus](verification/unit5-private.log)は双方Private。データ/原本の複製登録、新規依存、Makefile変更なし。README、IMPLEMENTATION_POLICY、3 gateを更新した。exact `/simplifier-lai` は利用不可・未実行、類似skillはLobbyAI専用のため不適用。既存依存・差分・登録範囲を手動レビューし、[3 gate / 35条件](temp_gates/2026-10-29-23-05-13/VALIDATION.md)をYESとした。Git状態・差分量・diff --checkを確認しcommit/pushする。

## 2026-10-29: 衛星表示・描画品質・全画面・信頼したローカル HTML の採用

共通実装を `002adcf663fd5005e14ac86c343a3ec7e56fa706` に固定した。fetch 後の `origin/main` に存在し、submodule 内の未保存差分がないことを確認した。追加衛星の表示・検索・日時追従、描画品質 4 項目、非同期全画面/About、信頼したローカル HTML の実クリックからの Lua、JSON v4 を採用した。

`DATA_ROOT` に独自追加を含むローカル Plus の `data` を指定し、`make build test data-test reference-test` が終了コード 0 で完了した。[統合ログ](verification/unit4-final-pin-tests.log) と [5 ログの SHA-256](verification/unit4-SHA256SUMS) を保存した。衛星 340 行を保持し 330 行の位置を評価した。renderer 64、HTML policy 80、session 964、satellite controller 38、solar satellite 99、controlled fullscreen 31、controlled occlusion 46 checks が成功した。公式比較は CF96 5,427、自転 33,129、月 12,108 成分が成功した。

submodule 未取得、空の DATA_ROOT、相対 DATA_ROOT はすべて案内付き終了コード 2 で停止した。[負例ログ](verification/unit4-negative.log) に記録する。通常データ経路は `data` を GUI、その親を core へ渡しており、Makefile の既存契約を変更していない。

共通側の通常・ASan/UBSan・Rosetta x86_64 の全 test / script-test / controller-test / Plus full smoke、通常版データと smoke、新規 clone、原本保全の結果は [共通単位4記録](vendor/mitaka/investigation/native-plus/unit4/README.md) を参照する。原本保全は 16,365 files、6,622,642,667 bytes、465 symlinks、変更 0。ラッパーでは sanitizer・x86_64・full smoke・HTML 実ブラウザ結合を重複実行せず、採用 SHA の記録を参照した。個別 HTML host 試験で使った通常 arm64 helper と、共通 script-test の各構成 helper は区別されている。

controlled occlusion は試験値による停止・復帰条件の検証であり、実 OS の完全遮蔽通知は未通過のまま残る。共通側の全画面実 OS 試験の成功を、複数画面や全操作の網羅と扱わない。Intel Mac と macOS 13 の実機確認も未実施。SAN timer、月 FMA、JSON 丸め、HTML 通常リンクの途中失敗と修正は共通側の記録を保持し、最終成功で隠さない。

[Mitaka](verification/unit4-source-private.log) と [Mitaka_plus](verification/unit4-private.log) の双方が Private であることを再確認した。共通コード・原本・天文データの複製登録や新規依存はない。README、IMPLEMENTATION_POLICY.md、3 gate を JSON v4 と衛星・HTML・全画面の契約に更新した。物理時系・精度期間、衛星表面/自転・個体別可視性、探査機 GUI、旧 Lua の全 API は未対応のまま明記する。

正確な `/simplifier-lai` は利用できず未実行。類似の `simplify-lai` は LobbyAI 専用のため対象外。既存依存、Makefile、gitlink、差分、登録範囲を手動レビューした。[今回の gate](temp_gates/2026-10-29-21-36-01/VALIDATION.md) は 3 gate / 26 条件を YES とした。Git 状態・変更ファイル・差分量と `git diff --check` を確認し、この採用を commit / push する。

## 2026-10-29: 表示設定・座標格子・カレンダーの更新

共通実装を `cf4fcbfe5447adf554e5bca0b0caf5ae5f529505` に固定した。Mitaka の `origin/main` に存在し、submodule 自体に未保存の差分がないことを確認した。

`DATA_ROOT` に独自追加を含むローカル Plus の `data` を指定し、`make build test data-test reference-test` の終了コード 0 を確認した。記録は [verification/unit3-final-pin-tests.log](verification/unit3-final-pin-tests.log)、ログの SHA-256 は [verification/unit3-SHA256SUMS](verification/unit3-SHA256SUMS)。小天体 19,475 行を保持し、そのうち 2,388 行の位置を評価した。カタログ一覧は 1,059,477 行を保持し、500 行ずつ表示する契約を確認した。公式計算との比較は CF96 5,427 成分、自転 33,129 成分、月 12,108 成分が成功した。

最初の呼び出しでは `DATA_ROOT` の指定がなく、ビルドとテストの成功後、`check-data` が案内を出して終了コード 2 で停止した。[初回ログ](verification/unit3-initial-invocation.log) を保持し、指定を加えて全ターゲットを再実行した。submodule 未取得と相対 `DATA_ROOT` も、[異常系ログ](verification/unit3-negative.log) のとおり案内付きエラーで停止する。

投影ウィンドウのテストは、試験ウィンドウに遮蔽状態を注入してタイマー条件を検証するもので、46 checks が成功した。実 OS の完全遮蔽通知は共通側で未通過のまま保持しており、この結果を実 OS 通知の成功とは扱わない。共通側の通常・ASan/UBSan・Rosetta x86_64 のコントローラ試験、4 回の GUI smoke、原本保全の結果と制約は [共通側の単位3記録](vendor/mitaka/investigation/native-plus/unit3/README.md) を参照。ラッパーでは sanitizer・x86_64・smoke を重複実行せず、Intel Mac と macOS 13 の実機確認も未実施である。

両 GitHub リポジトリが Private であることを再確認した。共通コードの複製、新規依存、原本・天文データの登録はない。`IMPLEMENTATION_POLICY.md` と対応 gate に、明示的に信頼したローカル HTML のみ Lua 呼び出しを許可する方針を追記した。HTML ブラウザの実装完了は主張しない。

正確な名前の `/simplifier-lai` は利用できず未実行。類似名の `simplify-lai` は LobbyAI 専用のため対象外である。既存 Makefile と Git submodule の利用、差分、依存と登録範囲を手動レビューした。[今回の gate 記録](temp_gates/2026-10-29-20-13-42/VALIDATION.md) は 3 gate と 22 条件を YES とし、不合格条件の未チェックは該当なしを示す。Git 状態・変更ファイル・差分量を確認し、この更新を commit / push する。

## 2026-10-29: ローカル Plus データ対応の更新

共通実装を `ae300e1e396c5ed0e6eb5129ad8a6f0069489597` に固定した。Mitaka の `origin/main` に存在し、submodule 自体に未保存の差分がないことを確認した。

この固定コミットで `make build test data-test reference-test` が終了コード 0。記録は [verification/unit2-final-pin-tests.log](verification/unit2-final-pin-tests.log)。Plus 原本を指定し、独自追加を含む小天体・画像一覧・天の川背景、既存カタログ、GUI と Lua コントローラを検証した。公式比較は CF96 5,427 成分、自転 33,129 成分、月 12,108 成分が成功した。

共通側の sanitizer、Rosetta x86_64、GUI smoke、画面操作、原本保全は [共通側の検証記録](vendor/mitaka/investigation/native-plus/unit2/README.md) を参照。Intel Mac と macOS 13 の実機確認は未実施。

両 GitHub リポジトリが Private であることを再確認した。新規依存やコードの複製はなく、画像・動画は共通実装の ImageIO / AVKit を使う。`/simplifier-lai` は利用できず未実行。類似名の `simplify-lai` は LobbyAI 専用のため対象外。依存・差分・登録範囲を手動レビューした。

今回の変更は共通参照、README、検証記録のみであり、既存の方針を変更していない。3 gate の検証コピーへ判定を記録し、Git 状態・変更ファイル・差分量を確認して commit する。

確認日: 2026-10-29。macOS 26.6.2 / arm64。

## 固定参照

`vendor/mitaka` は Private リポジトリ `https://github.com/mocho271828/Mitaka.git` の Git submodule。
採用コミットは `94c9af3d968fcdb9591e4d3efcf2992954293f01`。
このコミットは GitHub の `main` に push 済みであることを fetch で確認した。
初回取得した `67c4779c879454763c30e5e5858011c4eacc96d9` との差分は作業規則・案内・検証記録だけで、`native/` と `sources/` に差分はない。
共通コードの複製、新規の実行時依存、既存データの登録は行っていない。

## 実行した検証

GitHub から取得した共通コードで初回ビルドとコア・GUI・コントローラのテストが成功した。
最終コミットへ参照を更新した後にも、以下をすべて実行して終了コード 0 を確認した。

```sh
make build test data-test reference-test
```

`DATA_ROOT` はローカルに保持した Mitaka_plus の `data` を明示した。
空白を含む絶対パスの受け渡し、既存データの読み込み、11 枚の画像、全着陸対象、CF96・自転・月の公式計算との比較が成功した。
記録は [verification/final-pin-tests.log](verification/final-pin-tests.log)。
submodule 未取得とデータ指定不足で案内付きエラーになることも確認した。

共通実装の AppKit smoke test、元ファイルの保全照合、依存と登録範囲の独立レビューは [共通リポジトリの検証記録](vendor/mitaka/investigation/repository-organization/VALIDATION.md) を参照。
実装コードは変更していないため、sanitizer は今回再実行せず既存の結果を保持した。
Intel Mac、macOS 13 実機、全操作の人手による再確認は今回行っていない。

## 方針と変更管理

両 GitHub リポジトリの `isPrivate: true` と `visibility: PRIVATE` を確認した。
`IMPLEMENTATION_POLICY.md` と 3 つの policy gate に共通参照、登録範囲、データ保全、検証手順を記録した。
gate は `temp_gates/` にコピーし、判定条件をチェックして YES とした。
不合格条件の未チェックは該当なしを表す。

正確な名前の `/simplifier-lai` は提供されておらず未実行。
類似の `simplify-lai` は非 LobbyAI プロジェクトを適用対象外としているため使用していない。
既存 Makefile と Git submodule の利用、不要な独自実装がないことを独立レビューで確認した。
登録前に Git 状態・追加ファイル・差分量と `git diff --check` を確認し、初回ファイルと固定参照を commit / push する。
