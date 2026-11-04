# 月表示・地表移動の検証

2026-10-29、macOS 26.6.2（25G83）、arm64、Apple Clang 21.0.0 で検証した。
アプリは `native/gui/build/Mitaka Native.app`、バージョン 0.6.0。
既存の C++17 コア、AppKit、ImageIO、Core Graphics を利用し、新規の実行時依存を追加していない。

## 実装と対象範囲

- 公式 Mitaka 1.3.1 由来の月の位置・姿勢をコアへ分離し、CF96 の地球・月重心を地球中心へ補正した。3D は太陽・9 惑星・月の 11 天体、全天図は地球を除く 10 天体を表示する。
- 地球と月の近傍表示、月の相対軌道、既存 `moon.jpg` による月面、同一 JD の公転・表面姿勢更新を追加した。
- 地球からの離陸と、9 惑星・月の指定緯度／東経への着陸を追加した。天体固定の地表視点は日時変更と再生に追従する。
- 離着陸は実時間 3 秒で補間する。着陸は高度 2 m、離陸は半径の 8 倍の高度へ移り、停止や異常な時計差分で現在位置を保持する。
- 地球・月の物理球描画とクリック判定は視線と球の交点を共有する。中心が画面外・背後にある場合の縁も扱う。

式・単位・出典・許諾は [LUNAR_PROVENANCE.md](../../native/core/LUNAR_PROVENANCE.md)、責務と制限は [DESIGN.md](DESIGN.md)、操作は [GUI README](../../native/gui/README.md) に記録した。

## 自動検証

以下はすべて終了コード 0。通常の派生コードは `-Wall -Wextra -Wpedantic -Werror` でビルドした。公式コードを比較用に直接コンパイルする対象だけ、既存の文字コード・構文に対する限定した警告抑制を Makefile に明記している。

| 検証 | 結果と証跡 |
| --- | --- |
| コア `test rotation-reference-test lunar-reference-test` | 天文計算 1,275、自転 11,033、月 14,172 チェック、カタログ・暦表試験に合格。[core-tests.log](core-tests.log) |
| 公式の月計算との比較 | 1,009 日時、12,108 成分。位置の最大差 1.73472347598e-18 AU、姿勢の最大差 9.48019440727e-13。[core-tests.log](core-tests.log) |
| 公式の惑星姿勢との比較 | 33,129 成分に合格。[core-tests.log](core-tests.log) |
| コア実データと CF96 公式比較 | 両データセットの HIP 117,956 件、9 惑星、対応する既存軌道を読み取り、各 5,427 成分の比較に合格。[mitaka](core-data-mitaka.log) / [mitaka_plus](core-data-plus.log) |
| GUI `all test controller-test` | 位置・重心再構成・軌道・投影・球面描画・画像入力・再生・地表移動に合格。再生時計 10,098 チェック。AppKit の実タイマー・停止・速度変更に合格。[gui-tests.log](gui-tests.log) |
| GUI 実データ・実 AppKit smoke | 両セットとも HIP 117,956 件、全天図 10 天体、3D 11 天体、惑星軌道 9 本＋月軌道 1 本、画像 11/11・警告 0。全 smoke 段階に合格。[mitaka](gui-data-smoke-mitaka.log) / [mitaka_plus](gui-data-smoke-plus.log) |
| コア ASan / UBSan | 全コア単体テストと公式月比較に合格。[ログ](../../native/core/build/lunar-sanitize/validation.log) |
| GUI ASan / UBSan | `test controller-test` に合格。[gui-sanitize.log](gui-sanitize.log) |

月の比較値は公式式との数値一致を示す。実際の観測に対する精度保証ではない。
地球・月の共通有効期間、非有限 JD、範囲外、基底の直交性・右手系、地心距離を試験した。
地表移動では極・経度の周期・逆行自転・10 天体の追従、時計の逆行・1 秒超の遅延・中断・再開始・完了を検証した。
描画では高度 2 m の球面交差、UV、日照、画面外と視点背後の球、描画と選択の交点一致を検証した。

AppKit smoke は実際のウィンドウと描画結果を使い、月の位置・姿勢の日時変化、全着陸対象、地表描画、実タイマーの上昇・中断後の停止・再開始を確認した。
離陸完了では、停止状態だけでなく、中心から地球半径の 9 倍の距離に達することを許容差 1e-12 AU で確認した。
ASan / UBSan による GUI 全アプリの smoke は今回の実行対象に含めていない。

再実行する代表コマンド（ルートから）:

```sh
make -C native/core test rotation-reference-test lunar-reference-test
make -C native/gui all test controller-test
DATA_ROOT='/Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data' make -C native/gui data-test smoke
DATA_ROOT='/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data' make -C native/gui data-test smoke
make -C native/core BUILD_DIR=build/lunar-sanitize SANITIZE=address,undefined all test lunar-reference-test
make -C native/gui BUILD_DIR=build/moon-travel-sanitize SANITIZE=address,undefined test controller-test
```

## 実画面の操作確認

検証用のアプリコピーを別 bundle ID で起動し、macOS の UI 操作で次を確認した。既存データは mitaka 側を指定した。

- 「地球・月」で地球と月、月軌道を表示。J2000 で地球–月距離 402,364 km、視点距離 1,046,147 km の状態を確認。[最終画面](screenshots/earth-moon-final.png)
- 速度を実 1 秒あたり 1 日に変更して再生・一時停止し、表示時刻の連続更新と停止を確認した。
- 月を選択して「表面を見る」を操作し、月面を表示。1 日進めた前後の記録を保存した。[変更前](screenshots/moon-before.png) / [変更後](screenshots/moon-after.png)
- 月の緯度 35.68°、東経 139.76°へ着陸し、高度 0.002 km、仰角 0°、飛行完了と球面の地平線を確認。[月面](screenshots/moon-landed.png)
- 「地球から離陸」で上昇し、高度 51,025.093 km、仰角 −80°、飛行完了を確認。[地球上空](screenshots/earth-ascent.png)
- 緯度 91° の着陸を拒否し、視点を保持した。35.68° に直して木星へ着陸すると入力エラー表示が消え、高度 0.002 km、飛行完了、名称「木星 基準球面」になることを最終版でも確認した。
- 太陽を選択したとき、着陸ボタンが無効になることを確認した。

全対象への着陸、地表の見回し・高度変更・日時追従はモデル／AppKit smoke で検証している。実マウスで全惑星の全操作を網羅したものではない。
実際の OS スリープ／復帰と全画面・全ディスプレイ条件は今回未実施。通知への接続は独立レビュー、遅延時の状態保持は決定的な時計テストで確認した。

## 保全・レビュー・変更管理

[PRESERVATION.md](PRESERVATION.md) と [preservation-final.json](preservation-final.json) に最終照合を記録した。
既存 mitaka、mitaka_plus、公式原本の通常 16,365 ファイル（6,622,642,667 bytes）と 465 シンボリックリンクは追加・削除・変更 0 件。
公式 ZIP の全 310 ファイルは展開原本と一致し、参照 Git は HEAD 不変・clean。
既存データや画像の変換、書き込み、再配布物への同梱は行っていない。

実装担当と別の読み取りレビューを行い、未解決の修正必須事項なし。[REVIEW.md](REVIEW.md)
既存コアと macOS 標準フレームワークを使用している。独自の月計算移植は公式との再現性、球面・地表視点は既存描画との整合を目的とする。新たなライブラリの追加は不要と判断した。
描画は `SolarSceneRenderer.mm`、GUI 統合試験は `AppSmokeTests.mm` へ分離し、視点・タイマー・描画の責務を確認した。

`IMPLEMENTATION_POLICY.md` と既存 gate 5 件を更新し、月・地表移動の gate を追加した。
全 10 gate の検証コピーを [temp_gates/2026-10-29-14-52-04](../../temp_gates/2026-10-29-14-52-04/) に保存した。
各コピーで判定条件を確認してチェックし、不合格条件への該当がないことを確認した。全 10 件の判定は YES。

ソースと方針の差分は追加 14・変更 28・削除 0 ファイル、+3,000 / −531 行（計 3,531 行）。[SOURCE_DIFF.md](SOURCE_DIFF.md)
作業ルートの `git status` は非 Git のため終了コード 128。300 行以上の差分だが commit は行っていない。参照 Git を変更せず、ルートの Git 初期化も行っていない。
`/simplifier-lai` は利用できず未実行。近い名前の `simplify-lai` は LobbyAI 専用の指定があり適用していない。代わりに上記の独立レビューで差分全体を確認した。

## 未対応・未検証の範囲

月以外の衛星、地形・建物・大気・雲・環、惑星間を連続して飛行する経路、衝突・推進力は未実装。
着陸は対象上空への移動後に降下し、ガス惑星では基準球面へ接近する。
ユーザー追加データは全件保持したが、GUI が表示する形式は HIP、CF96、11 枚の表面画像に限る。
単一 JD の近似を用い、UTC / UT1 / TT / TDB の変換や厳密な観測補正は行わない。
実行環境は上記 arm64 の macOS のみ。Intel、macOS 13 実機、署名・公証・配布インストーラーは検証していない。
