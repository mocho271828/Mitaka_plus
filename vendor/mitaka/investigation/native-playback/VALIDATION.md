# 連続再生の検証記録

確認日: 2026-10-29。macOS 26.6.2（25G83）、Apple Silicon、Apple Clang 21.0.0。
対象は `native/gui/` の連続再生・一時停止・速度変更。天文計算コア、既存の天文データ・画像、公式原本には変更を加えていない。
保全の照合結果と変更一覧は [PRESERVATION.md](PRESERVATION.md) を参照。

## 実装と依存関係

- `PlaybackClock` は GUI 層の C++17 の時計。単調時計の絶対経過時間から JD を求め、更新回数による速度差と微小加算の蓄積を避ける。
- `PlaybackController` は AppKit の再生ボタン、6 段階の速度選択、実タイマー、停止通知を担当する。初期速度は実 1 秒あたり暦表 1 時間。
- `AppController` は全天図の天体位置と太陽系の位置・姿勢を同一 JD で計算し、成功した状態だけを表示へ渡す。手動日時・データ選択・最小化・スリープ・終了を再生停止へ接続した。
- 再生中は軌道線の標本を保持し、一時停止時に更新する。天体位置と表面の向きは継続して更新する。
- 既存の C++ 標準ライブラリと macOS 標準 AppKit を利用した。時計やイベント処理のための新規外部ライブラリは追加していない。
- アプリのバージョンを 0.5.0（build 5）へ更新した。

## 自動検証

以下は実行済みで、すべて終了コード 0。GUI を伴う試験はログイン中の macOS GUI セッションで実施した。

| 検証 | 結果・記録 |
| --- | --- |
| `make -C native/core test` | 天文計算 1,275 検査、カタログ・暦表、自転 11,033 検査が成功。[core-test.log](core-test.log) |
| `make -C native/gui all test` | `-Wall -Wextra -Wpedantic -Werror` でビルド。全天図・太陽系・表面・画像・再生時計が成功。[gui-build-test.log](gui-build-test.log) |
| 再生時計 | 10,098 検査。6 速度、更新間隔の分割、速度変更、停止・再開、終端、遅延・逆行・異常値を確認。[playback-clock-test.log](playback-clock-test.log) |
| `make -C native/gui controller-test` | 実タイマー、ボタンと速度選択の action、停止・再開、終端、失敗時の JD 保持、中断・破棄後の更新停止が成功。[controller-test.log](controller-test.log) |
| Mitaka の `data-test smoke` | HIP 117,956 件、全天図 9 天体、太陽系 10 天体・9 軌道・9 自転、表面画像 10/10（警告 0）。GUI と連続再生の試験が成功。[gui-mitaka-final.log](gui-mitaka-final.log) |
| Mitaka Plus の `data-test smoke` | 同じ件数・表示対象・画像数で成功。[gui-plus-final.log](gui-plus-final.log) |
| AddressSanitizer / UndefinedBehaviorSanitizer | 別ビルドで `all test controller-test`、Mitaka の `data-test smoke` が成功。診断なし。[ビルド・単体テスト](sanitized-build-test.log)、[GUI・実データ試験](sanitized-integration.log) |
| Intel 向けビルド | `ARCH=x86_64` でアプリを生成。実機・Rosetta での実行は未確認。[x86_64-build.log](x86_64-build.log) |

再現する場合の主なコマンドは以下のとおり。

```sh
cd /Users/kota/mitaka
make -C native/core test
make -C native/gui all test controller-test
DATA_ROOT='/Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data' make -C native/gui data-test smoke
DATA_ROOT='/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data' make -C native/gui data-test smoke
make -C native/gui BUILD_DIR=build-playback-sanitized SANITIZE=address,undefined all test
DATA_ROOT='/Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data' make -C native/gui BUILD_DIR=build-playback-sanitized SANITIZE=address,undefined controller-test data-test smoke
make -C native/gui ARCH=x86_64 BUILD_DIR=build-playback-x86_64 all
```

smoke は一時停止を呼ぶ**前**に実タイマーで JD が進んだことを確認する。
停止操作自体による時刻更新だけで試験を通さないようにした。
更新後の全 10 天体の位置と姿勢を同じ JD のモデル出力と照合し、全天図の距離、選択した地球へのカメラ追従、停止中の JD 保持、手動の 1 時間操作による停止も検証している。

## 実画面での確認

既存の起動中アプリとの識別を保つため、ビルドしたアプリの検証用コピーを別 bundle ID `local.mitaka.playback-check` で起動した。
このコピーだけを操作し、終了後にプロセスが残っていないことを確認した。既存のデータ・画像をコピーしたわけではない。

| 操作 | 確認した結果 |
| --- | --- |
| J2000、太陽系 3D、地球選択、「表面を見る」、1 時間／秒で再生 | 地球を追従しながら表面が回転。一時停止後の JD は 2451545.789982。[開始画像](ui-earth-before.png)、[停止画像](ui-earth-after.png)、[停止時の UI](ui-earth-after.txt) |
| 速度メニューを開く | 1 秒・1 分・1 時間・1 日・10 日・30 日の 6 選択肢と単位表示を確認 |
| 内惑星表示、30 日／秒で再生 | 時刻と惑星位置が進み、再生中でも表示モードを切り替えられる。[再生中の画像](ui-orbit-playing.png)、[UI 記録](ui-orbit-playing.txt) |
| 再生中に「＋1時間」 | 再生が止まり、JD 入力欄が編集可能になる |
| 再生中に「データを開く…」、選択を取消 | 選択開始時に停止し、取消後も停止したまま直前のデータを保持 |
| JD 2487980.49 から 30 日／秒で再生 | 共通終端 JD 2487980.500000 に正確に止まり、再生ボタンが無効になり、終端到達の理由を表示。[UI 記録](ui-endpoint.txt) |
| 再生中にウィンドウを最小化 | JD 2451550.181230 で停止。再確認でも同じ時刻を保持し、「最小化により一時停止」を表示。[UI 記録](ui-minimized.txt) |

再生中のスクリーンショットとアクセシビリティツリーは別の時点で取得しているため、その間にも JD は進む。
マウスの連続ドラッグ・トラックパッドの全操作を今回あらためて網羅したわけではない。既存のカメラ操作処理は smoke で回帰確認し、従前の手動操作の記録は [太陽系 3D の検証](../native-solar/VALIDATION.md) を参照した。

## レビューと変更管理

時計、AppKit の再生制御、AppController との接続を独立担当がレビューした。
速度変更時の連続性、失敗時の最終成功 JD、停止要求の再入、タイマーの解放、手動操作・読み込み・終了通知との接続を確認した。
smoke が一時停止前のタイマー更新を確認していないという指摘を修正し、その後の通常・サニタイザ・両データの smoke はすべて成功した。最終レビューで追加の修正指摘はなかった。

`AppController.mm` は 500～700 行の設計レビュー対象として確認した。再生時計と AppKit のタイマー・速度 UI を別ファイルへ分離し、接続を日時更新と停止通知に絞った。既存のウィンドウ構築・読み込み・smoke の責務を今回さらに移す変更は加えていない。

ルートは Git リポジトリではなく、`git status --short` は `fatal: not a git repository`。300 行以上の差分があるが commit は作成できないため、新しい Git リポジトリは作成していない。
作業前スナップショットとの比較は追加 7・変更 8・削除 0 ファイル、+1,099 / -17 行（計 1,116 行）。ビルド生成物と検証証跡はこの集計に含めない。変更一覧は [SOURCE_DIFF.md](SOURCE_DIFF.md) にまとめた。
保護対象 16,365 通常ファイル・465 シンボリックリンクに変更はなく、公式 ZIP の全 310 ファイルと展開原本も一致した。参照 Git は HEAD 不変・clean、既存コア全 25 ファイルも変更なし。
指定名 `/simplifier-lai` は利用できず未実行。ローカルに存在する別名 `simplify-lai` は LobbyAI 対象のため、このプロジェクトには適用していない。上記の独立レビューで品質を確認した。

`IMPLEMENTATION_POLICY.md` に時刻制御の境界を追記し、`policy_gates/time_playback.md` を追加した。9 個の gate を [検証コピー](../../temp_gates/2026-10-29-14-16-18/)で確認し、判定条件のチェックボックスと根拠を記入して全て YES と判定した。不合格条件は全て非該当。

## 制限・未確認事項

- 30 Hz はタイマー更新の目標。描画性能や全フレームの表示は保証しない。1 秒を超える更新の空白では、追いつこうとせず停止する。
- 高い再生速度では表面の自転が飛び飛びに見える。細かい自転の確認には 1 分／秒や 1 時間／秒を使う。
- 再生中の軌道線は開始時点の標本を保持する。停止時に現在の JD に対応する標本へ更新する。
- システムを実際にスリープさせる試験は行っていない。スリープ通知への接続をコードレビューし、中断による停止・時刻保持はコントローラー試験で確認した。
- macOS 13 と Intel 実機での実行は未確認。今回の GUI 実行環境は上記 Apple Silicon のみ。
- 既存と同じ単一 JD の近似であり、UTC / UT1 / TT / TDB の変換や新たな観測補正は追加していない。太陽の表面は固定姿勢、惑星の画像・半径・照明は模式表示。
- 逆再生・終端からの繰り返し、配布用署名・notarization は今回の対象外。
