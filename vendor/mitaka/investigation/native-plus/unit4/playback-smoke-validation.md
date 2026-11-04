# UNIT4: 実タイマー再生 smoke の開始境界

検証日: 2026-10-29。対象は `native/gui/src/AppSmokeTests.mm` の試験開始方法であり、製品の再生時計を変更するものではない。

## 発生した失敗と切り分け

統合担当の arm64 AddressSanitizer + UndefinedBehaviorSanitizer 構成で、`smoke: real timer did not advance before pause` が発生した。これは再生開始から 250 ms 後に main queue へ投入する検査が、pause の前に実タイマーによる JD の進行を要求する箇所である。

当初の実装は、大量の同期描画・画像検査を行う `runSceneSmokeTest` の末尾から、そのまま `runPlaybackSmokeTest` を呼んでいた。再生時計を開始した時点では、前段の callback が戻る際の一時オブジェクト解放や AppKit の後処理がまだ終わっていなかった。

変更前の同じ SAN 実行ファイルを単独で起動した試験でも一度失敗した。その後の変更前の実行ファイルによる 2 回の full smoke は成功したため、常に発生する失敗ではない。統合担当の最初の失敗時には並行ビルドがあったが、それだけを原因とは判定していない。

`/tmp` の診断用コピーだけに単調時計の記録を加えた。通常のフル試験と、250 ms の進行判定で終了する診断試験を区別して実行した。記録を加えた 5 回では失敗を再現せず、失敗した実行の最終 tick の理由は取得できていない。

| 診断条件 | 再生開始から初回 NSTimer まで | 250 ms 検査の実際の経過時間 |
| --- | --- | --- |
| 同一 callback 内で開始、診断 3 | 約 0.700 秒 | 約 0.759 秒 |
| 同一 callback 内で開始、診断 4 | 約 0.774 秒 | 約 0.840 秒 |
| 同一 callback 内で開始、診断 5 | 約 0.690 秒 | 約 0.719 秒 |
| 同期試験を明示的な autorelease pool で囲み、同一 callback 内で開始 | 約 0.591 秒 | 約 0.626 秒 |
| 上記 pool を維持し、次の run loop callback で開始 | 約 0.034 秒 | 約 0.263 秒 |

pool の明示的な解放には約 0.275 秒を要した。再生中の `SolarSystemView` 一回の描画はこの測定ではおおむね 0.008〜0.011 秒だったため、表面描画一回だけで初回の約 0.7 秒を説明することはできなかった。callback 境界を分けた診断には pool の変更も含むので、数値を今回採用する最小差分だけの効果と断定しない。

観測結果は「前段の試験後処理を再生の経過時間に含めてしまう」という試験構造の問題を示す。元の失敗が製品の 1 秒超の中断処理に入ったのか、NSTimer と検査 callback の実行順によるものだったのかは未確定である。診断で成功した実行から、失敗時の状態を推定して確定原因とは扱わない。

## 採用した変更と維持した条件

`runSceneSmokeTest` の最後に一回限りの `NSTimer` を main run loop の common modes に登録し、その callback から再生試験を開始する。時間を固定で余分に待つ処理や、製品時計の手動 tick は追加していない。診断用の pool・時刻ログ・途中終了は製品ソースへ採用していない。

- 製品の `PlaybackClock`、`PlaybackController`、1 秒超の中断規則を変更しない。
- 実タイマーの進行を pause 前に要求する条件を維持する。
- 250 ms の進行検査と pause 後 120 ms の JD 不変検査を維持する。
- 同一 JD の位置・姿勢・衛星の親補正・追尾、手動変更での停止を検査する。
- 後続の離着陸・連続飛行の実タイマー試験まで実行する。

## 最小差分での確認

`make all` で変更をビルドした後、同梱 Plus のローカル data を読み取り専用で使い、`--smoke-test` を構成ごとに逐次実行する。ビルドは既存の `-Wall -Wextra -Wpedantic -Werror` を維持する。

| 構成 | build directory | full Plus smoke |
| --- | --- | --- |
| arm64 通常 | `build-unit3-root` | exit 0 |
| arm64 AddressSanitizer + UndefinedBehaviorSanitizer | `build-unit3-root-san` | exit 0 |
| x86_64（Apple Silicon 上） | `build-unit3-root-x86` | exit 0 |

3 構成とも Script / small body / satellite / Plus / sky / solar / texture / rotation / playback / Moon-travel / continuous flight の全段階を通過した。`git diff --check` も通過した。この確認は一般的な OS スケジューリング遅延の上限や、あらゆる負荷での成功を保証するものではない。

ログ:

- 当初の統合失敗: `/tmp/mitaka-unit4-app-plus-san-final.log`
- 変更前の単独再現: `/tmp/mitaka-unit4-app-plus-san-timer-repro.log`
- 変更前の full smoke 成功: `/tmp/mitaka-unit4-app-plus-san-timer-original-1.log`、`/tmp/mitaka-unit4-app-plus-san-timer-original-2.log`
- 時刻診断: `/tmp/mitaka-unit4-app-plus-san-timer-probe-3.log`、`/tmp/mitaka-unit4-app-plus-san-timer-probe-4.log`、`/tmp/mitaka-unit4-app-plus-san-timer-probe-5.log`
- pool の診断: `/tmp/mitaka-unit4-app-plus-san-timer-pool-probe.log`
- callback 分離の診断: `/tmp/mitaka-unit4-app-plus-san-timer-boundary-probe.log`
- 最小差分の build: `/tmp/mitaka-unit4-timer-boundary-{normal,san,x86}-build.log`
- 最小差分の full smoke: `/tmp/mitaka-unit4-timer-boundary-{normal,san,x86}-smoke.log`

既存コードの今回の差分は `AppSmokeTests.mm` の 6 行追加・1 行削除だけである。新規依存を導入せず、AppKit / Foundation の既存 run loop を使う。原本データを変更していない。stage / commit と全体の policy gate 判定は統合担当が行う。
