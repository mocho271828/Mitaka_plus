# 連続惑星間飛行の検証記録

検証日: 2026-10-29。macOS 26.6.2（25G83）、arm64、Apple Clang 21.0.0。
成果物は `native/gui/build/Mitaka Native.app`、バージョン 0.7.0。

## 変更と依存

GUI 層へ `InterplanetaryFlight` を追加し、地表から離陸 4 秒・航行 16 秒・着陸 4 秒で移動する。
既存コアの同一 JD の天体位置・姿勢を毎回使い、到着後は指定緯度・東経・高度 2 m の地表視点へ引き継ぐ。
停止時は慣性系の視点を保持し、再航行はその位置・姿勢から同じ目的地への新しい約 24 秒の移動とする。
飛行と地表表示は全 11 天体の物理半径と視線交点による深度合成を使用する。
航行操作・描画・smoke test を分離し、既存の C++17、AppKit、ImageIO、Core Graphics を使用した。新規依存はない。
`native/core/` 全 31 ファイルは変更なし。設計は [DESIGN.md](DESIGN.md)、独立レビューは [REVIEW.md](REVIEW.md)。

## 実行結果

| 確認 | 結果 | 証跡 |
| --- | --- | --- |
| 既存コアの単独テスト | PASS。天文計算 1,275、姿勢 11,033、月 14,172 checks、catalog、ephemeris | [core-tests.log](core-tests.log) |
| GUI ビルド・C++ テスト・AppKit controller テスト | PASS。警告をエラーとしてコンパイル | [gui-tests.log](gui-tests.log) |
| mitaka 実データ | PASS。HIP 117,956、11 天体、9 惑星軌道と月相対軌道、10 姿勢、画像 11/11、全 10 目的地への飛行 | [data-mitaka.log](data-mitaka.log) |
| mitaka_plus 実データ | PASS。同じ項目、画像警告 0 | [data-mitaka-plus.log](data-mitaka-plus.log) |
| AddressSanitizer + UndefinedBehaviorSanitizer | PASS。GUI ビルド、全 GUI 単体テストと controller テスト | [gui-sanitize.log](gui-sanitize.log) |
| sanitizer 付き実データ試験 | 両データセットで PASS | [mitaka](data-sanitize-mitaka.log)、[mitaka_plus](data-sanitize-mitaka-plus.log) |
| 実 AppKit ウィンドウの smoke test | 両データセットで PASS | [mitaka](smoke-mitaka.log)、[mitaka_plus](smoke-mitaka-plus.log) |
| sanitizer 付き AppKit smoke test | mitaka で PASS | [smoke-sanitize.log](smoke-sanitize.log) |
| 保全照合 | 全 16,365 ファイル・465 リンク、公式 ZIP 310 件一致。参照 Git clean | [PRESERVATION.md](PRESERVATION.md) |

smoke test は星、太陽系、テクスチャ、自転、日時再生、月と単独離着陸に加えて、実タイマーでの連続飛行を検査する。
再生速度を実 1 秒あたり 1 時間として月への飛行を開始し、移動停止、停止中の固定、同じ視点からの再航行、選択変更による目的地の不変、月面への到着、JD の進行を確認した。
試験用時刻を注入する view テストでは公転・自転更新、操作ロック、時計異常、月到着後から火星への連続出発も検査した。

モデルの回帰試験には 4・20・24 秒の境界、全目的地、動く端点、太陽の迂回、天体内部へ入る経路の停止、不正入力での状態保持、時計逆行・NaN・長い空白を含む。
同一天体の対蹠地点・両極、24 秒間に 2.4 回自転する目的地も検査した。
描画テストには球の入力順に依存しない深度、重なり、中心が画面外・背面の球、縦長と横長の表示領域を含む。
最終の巡航折点の交差検査を追加した後に、通常・sanitizer のテストと実データ試験、上表の smoke test を実行した。

初回の GUI smoke test では `performClick:` の押下アニメーション中にタイマーが進み、再航行開始瞬間の完全一致検査が失敗した。
開始瞬間の比較は同じボタン action の同期送信へ変更し、時間進行と到着は実タイマーで別に検査した。
失敗時の出力は [smoke-debug.log](smoke-debug.log) に残した。最終試験はすべて終了コード 0。

## 実画面の確認

独立した bundle ID の検証用アプリで以下を操作し、画面を確認した。

1. 地球の緯度 0°・東経 0°から月の同座標へ飛行。離陸、航行中の月面画像、月面の高度 2 m への到着を確認。
2. 月面から火星の緯度 20°・東経 40°へ続けて出発。火星の指定座標・高度 2 m への到着を確認。
3. いずれも日時を実 1 秒あたり 1 時間で再生し、表示日時の進行と着陸後の追従を確認。終了時に再生を停止し、検証用アプリを終了。

実画面操作は最後の巡航折点の安全検査の追加前のバイナリで行った。その後の最終バイナリは、上記の通常・sanitizer の自動試験で確認した。
手動確認した経路は地球→月→火星。全目的地はモデルの実データ試験で検査し、すべてを手動操作したとは扱わない。

## 再実行

プロジェクトルートで以下を実行する。実データのパスは GUI 用の `data` 自体を指定する。

```sh
make -C native/core test
make -C native/gui -j4 all test controller-test
export DATA_ROOT='/Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data'
make -C native/gui data-test
make -C native/gui smoke
make -C native/gui BUILD_DIR=build/continuous-sanitize SANITIZE=address,undefined -j4 all test controller-test
make -C native/gui BUILD_DIR=build/continuous-sanitize SANITIZE=address,undefined data-test
make -C native/gui BUILD_DIR=build/continuous-sanitize SANITIZE=address,undefined smoke
```

mitaka_plus の再検証では `DATA_ROOT` を `/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data` へ変更する。
今回 sanitizer 付きの GUI smoke は mitaka のみ。実データ試験と通常 GUI smoke は両方で実行した。

## 制約・未確認範囲

- 約 24 秒の幾何的な視点移動であり、重力・推進力・速度制約に従う宇宙航法ではない。ガス惑星は基準球面への接近。
- 高速の日時更新などで安全に経路を継続できない場合は停止する。任意の日時・速度での到着や、天体の移動全体を含む連続衝突検査は保証しない。
- 停止中は慣性系で固定するため、日時だけを進めると天体が視点へ重なる場合がある。この場合の描画・再航行は拒否し、「全体」等から出発し直す。
- 地形、大気、雲、環は未実装。既存の球面画像と模式照明を用いる。球面描画を長辺 800 px 以下に制限するが、一定 FPS は保証しない。
- 最小化・スリープ・終了等の中断経路はコードレビュー、時計・controller・view の試験で確認。実機スリープと復帰を伴う今回の手動試験は未実施。
- 実行機は arm64 / macOS 26.6.2。Intel Mac、macOS 13 実機、署名・公証は未検証。独立した lint target はなく、Clang の型検査と `-Wall -Wextra -Wpedantic -Werror` を使用。

## 方針と変更管理

`IMPLEMENTATION_POLICY.md` を更新し、連続飛行の gate を追加、関連する既存 4 gate を更新した。
全 11 gate のコピーを [temp_gates/2026-10-29-15-29-05](../../temp_gates/2026-10-29-15-29-05/) に作成し、判定条件をチェック、非該当の不合格条件を未チェックとして YES と記録した。

ルートの `git status --short` は終了コード 128（Git リポジトリではない）。参照 Git は HEAD 不変・clean。
変更前スナップショットとの比較は追加 8・変更 18・削除 0 ファイル、+1,638 / −473、計 2,111 行。
集計はソース・README・方針文書で、ビルド生成物、調査記録、gate 検証コピーを除く。内訳は [SOURCE_DIFF.md](SOURCE_DIFF.md)。
差分は 300 行以上だが、作業ルートが非 Git のため commit なし。新しい Git リポジトリは作成していない。
正確な名前の `/simplifier-lai` は利用できず未実行。類似名 `simplify-lai` は LobbyAI 専用で本件には適用しなかった。代わりに独立コードレビューで構造・既存依存の利用・状態遷移を確認した。
