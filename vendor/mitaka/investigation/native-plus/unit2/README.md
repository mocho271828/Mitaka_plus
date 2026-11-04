# Plus 機能追加・単位2の検証記録

確認日: 2026-10-29。基準コミットは `3f47a39972340c6673f5b8aa4ad8b57bd7564840`。
この単位はローカル小天体、天の川背景、メディアの単独プレビュー、暦ステップ・固定 UTC 時差・時計追従、一部 Lua ホスト API と状態復元の接続を対象とする。
原版の全機能完了を示す記録ではない。原典との対応、未確定事項、残る受入条件は [機能対応表](../../../PLUS_FEATURE_MATRIX.md) に記載する。

**単位2の実装検証は合格。** 2026-10-29 の最終ビルド・sanitizer・controller・Plus / 通常版 smoke と媒体 clip の実操作を確認した。以下では途中失敗と修正前後の検証範囲を区別する。source commit は `ae300e1`、wrapper の参照更新は `8497dfe` として確認した。push の成否と単位3の作業ツリー変更はこの判定に含めない。
試験は主担当および各実装担当が実行した。この文書の担当者はコード・原典記録・出力を照合し、ここに記した試験を再実行していない。

## 保存したログと判定時点

`logs/` は `/tmp/mitaka-plus-unit2-*.log` と媒体画像の回帰試験ログの時点コピーである。
[SNAPSHOT.tsv](logs/SNAPSHOT.tsv) に各コピーの元パス、元ファイルの更新日時、保存サイズ、SHA-256 を記録した。
ファイル名に `final` があっても、この単位の最終合格を意味しない。後続修正の前後と、単体・controller・全体 smoke の範囲を区別する。
再試験ログを追加する場合は既存の失敗記録を残し、保存日時と対応する変更を追記する。

| 対象 | 確認できた結果と保存ログ | この時点での制約 |
| --- | --- | --- |
| core 通常 | 成功。[core](logs/mitaka-plus-unit2-core.log)。小天体 orbit 272 checks、catalog 64 checks を含む。 | 小天体の全形式を評価可能にしたことは意味しない。 |
| core ASan / UBSan | 成功。[core-sanitize](logs/mitaka-plus-unit2-core-sanitize.log)。既存天文計算と新しい小天体テストを含む。 | 実行したテストの範囲に限る。 |
| GUI 通常・controller | 成功。[final-normal](logs/mitaka-plus-unit2-final-normal.log)。calendar 67、session 548、小天体 controller 23、solar small-body 19、media controller 40、投影 43 checks を含む。 | `Camera.zoom` の後続修正より前の結果。 |
| GUI ASan / UBSan | `all test` 成功。[final-sanitize](logs/mitaka-plus-unit2-final-sanitize.log)。core と GUI の対象コードを instrument している。 | このログに `controller-test` の実行は含まれない。修正後の追加実行は final2 表を参照。 |
| Plus 実データ | `data-test` 成功。[final-plus](logs/mitaka-plus-unit2-final-plus.log)。小天体モデル 28、メディア登録 56 checks、天の川 3/3 画像・警告 0。 | 同ログ末尾の初回全体 smoke は失敗。下記の経緯を参照。 |
| Plus 修正後の全体 smoke | 成功。[smoke-fix-build](logs/mitaka-plus-unit2-smoke-fix-build.log)、[final-plus-smoke](logs/mitaka-plus-unit2-final-plus-smoke.log)。小天体 18 checks、全表示、既存再生・地表・飛行まで確認。 | `Camera.zoom` の後続修正より前の結果。 |
| 通常版実データ・全体 smoke | 修正後に成功。[final-regular](logs/mitaka-plus-unit2-final-regular.log)。メディア登録 46 checks、小天体 0 件の全体 smoke 11 checks、既存再生・地表・飛行を含む。 | 初回は任意登録の非空を要求するテストが誤って失敗した。後続 Lua 修正の影響は別途確認する。 |
| x86_64 | `all test` 成功。[final-x86-build](logs/mitaka-plus-unit2-final-x86-build.log)。アプリと Lua helper を含む x86_64 ビルドと、同環境のテスト実行を確認。 | このログに x86_64 全体アプリ smoke は含まれない。Intel Mac 実機検証ではない。 |
| 新規 clone | staged patch を適用した新規 clone で core `all test`、GUI `all test` 成功。[final-clean](logs/mitaka-plus-unit2-final-clean.log)。既存 build 出力は持ち込んでいない。 | 後続のテスト修正と `Camera.zoom` 修正より前の staged 内容。 |
| 公式計算との比較 | 成功。[final-references](logs/mitaka-plus-unit2-final-references.log)。自転 33,129 成分、月 12,108 成分、CF96 5,427 成分を比較。 | 公式コードとの一致を、現代の高精度暦や Plus GUI との完全一致と扱わない。 |
| 原本保全 | 成功。[preservation](logs/mitaka-plus-unit2-preservation.log)、[判定 JSON](../preservation-final.json)。18:41:36 JST 時点で追加・削除・変更 0。 | 後続作業後の確認が必要な場合は別の時点として記録する。 |

途中の成功記録も [normal](logs/mitaka-plus-unit2-normal.log) と [data-smoke](logs/mitaka-plus-unit2-data-smoke.log) に保存した。
後者は小天体全体 smoke 追加前、前者の solar small-body は選択復元回帰追加前の 18 checks であり、後続の 19 checks と区別する。

`Camera.zoom`・媒体 clip・任意媒体テストの修正後に、次の再試験が成功した。

| 対象 | 保存ログと結果 |
| --- | --- |
| arm64 通常 | [final2-normal](logs/mitaka-plus-unit2-final2-normal.log) の `all test` と [final2-controller](logs/mitaka-plus-unit2-final2-controller.log) の `controller-test` が成功。media controller は clip 回帰を含む 43 checks。 |
| arm64 ASan / UBSan | [final2-sanitize](logs/mitaka-plus-unit2-final2-sanitize.log) の `all test` と [final2-sanitize-controller](logs/mitaka-plus-unit2-final2-sanitize-controller.log) の `controller-test` が成功。旧 `final-sanitize` ログに含まれなかった controller の実行も確認できた。 |
| x86_64 / Rosetta | [final2-x86](logs/mitaka-plus-unit2-final2-x86.log) の `all test` と [final2-x86-smoke](logs/mitaka-plus-unit2-final2-x86-smoke.log) の Plus 全体アプリ smoke が成功。小天体 18 checks と `invalid-zoom` を含む。 |
| arm64 通常版 smoke | [final2-regular-smoke](logs/mitaka-plus-unit2-final2-regular-smoke.log) が成功。任意小天体がない構成の 11 checks と `invalid-zoom`、既存の再生・地表・飛行を含む。 |

後続修正は Camera の 5 ファイル、媒体 clip の 2 ファイル、任意媒体の実データ assertion に限られるため、主担当は厳格ビルド・sanitizer・実アプリ smoke で影響を確認する方針とした。
新規 clone の全試験は再実行していない。上表の `final-clean` は修正前の staged 内容だけを検証した結果であり、最終差分全体の clean build 成功とは扱わない。

## 失敗、修正、再試験の経緯

最初の Plus 全体 smoke は `small-body browser did not search every original row with a bounded page` で失敗した。
検索はバックグラウンド処理後にメインキューへ結果を渡す。試験がメインキュー内で同期的に完了を待ったため、結果反映の機会を妨げていた。
試験を非同期の継続処理へ分け、run loop に制御を返しながら期限付きで待つよう修正した。
製品の全件検索や 500 件ページの条件を緩めた修正ではない。修正後は Plus の原記録 19,475 件に対して 18 checks が成功した。
失敗全文は `final-plus.log`、修正後の成功は `final-plus-smoke.log` に保存している。

通常版の最初の `data-test` は `real registry missing` で失敗した。
媒体登録は任意ファイルであり、登録のないデータ一式から空のカタログを返す製品動作は有効である。
実データ試験の非空必須 assertion を除去し、任意登録がない場合を既存の fixture 試験と同じ契約で確認するよう修正した。
製品の読み取り処理や原本は変更していない。修正後は通常版の `data-test` と全体 smoke が成功した。
初回の `/tmp/mitaka-plus-unit2-final-regular.log` は再試験で上書きされたため、全文ログは残っていない。
予備監査時に読み取った [出力抜粋](logs/regular-initial-failure-excerpt.txt) を別保存した。これは当時の終端部分であり、原ログ全文の復元ではない。

この文書の作成中に、`Camera.zoom` の既存実装でホスト操作の失敗が Lua 側へ伝播しない経路が見つかった。
`applyCameraState:error:` で候補をコピーし、既存の `solar_camera_basis` による検証を済ませてから航行状態とカメラを変更するよう修正した。Lua 側にも失敗を返す。
独立レビューでは、無効な距離 4 種に対して通常追従中・航行中のカメラ、frame、選択、追従、タイマー、進捗を保持する回帰試験と、検証前に状態を変更しない実装を確認した。
担当者の実行出力を保存した [zoom-validation](logs/zoom-validation.log) で arm64 Plus 全体 smoke の成功を確認した。この記録はシェル出力の時点コピーではなく、実行コマンド・終了コード・取得出力を保存したものである。修正後の final2 ビルド・controller と x86 Plus / arm64 通常版 smoke も成功した。

主担当の CUA 実操作では媒体 9 件・未解決 5 件を確認し、`localimages/MilkyWay_Mellinger.jpg` を表示できた。
倍率・回転・不透明度を 3 行に分けた操作欄の幅は確認できたが、回転 30 度・不透明度 0.6 で画像がプレビュー境界から操作欄にはみ出した。
`MediaImageView` の描画開始時に view 境界を明示的に clip するよう修正した。
[修正前後の回帰ログ](logs/media-clip-regression-before-after.log) は、240 × 240 px の canvas 中央に 120 × 120 px の view を配置し、倍率 2・回転 30 度・不透明度 0.6・pan (25, 0) で外周画素が変化しないことを確認する。
元ツリーを変えず `/tmp` のコピーから clip だけを除いた比較ビルドでは `transformed image drew outside preview bounds` で失敗し、修正後は media controller 43 checks が成功した。主担当の最終 CUA 操作では、単位2の build と Plus データで同じ天の川画像の倍率 2・回転 30 度・不透明度 0.6 を AX 操作し、スクリーンショットで画像が表示領域に収まり、3 行の操作欄と説明文に侵入しないことを確認した。スクリーンショット自体はこの記録に同梱していない。

## 原本と実データの扱い

データは既存の通常版・Plus 版の `Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data` を明示指定した。
画像はその隣の `textures`、媒体登録は `media` から読み取り専用で参照した。
公開データへの置換、件数合わせ、原本の変換・再保存は行っていない。
保全確認は 16,365 ファイル / 6,622,642,667 bytes / 465 symlinks、追加・削除・変更はすべて 0、公式 ZIP との 310 ファイル照合も不一致 0 だった。
参照 checkout は HEAD `ab63d81723a9261b663c8ab1283de2e7607f1094` と clean 状態を維持していた。
これらの数値はこの環境の観測値であり、別のローカルデータを拒否する固定条件ではない。

Plus の小天体は 67 出典・19,475 記録を保持した。重複番号、番号 `-1`、同一時刻、旧新ファイルを暗黙に統合していない。
確認できた契約による計算可能行は 2,388 件で、楕円 859、放物線 1,298、双曲線 231。未確定行も一覧・検索・診断に残る。
モデルの実データ試験は表示オンと非表示時の処理時間を記録しているが、その測定値を端末一般のフレームレート保証には使わない。
媒体登録は解決できない参照も保持し、名前の近い画像へ自動置換しない。利用者が選んだ対応づけはメモリ内だけに保存する。

## 依存と品質レビュー

core は C++17 標準ライブラリと既存の軌道計算・読み込み制限・エラー型を再利用した。
GUI の静止画読み込みは既存の ImageIO / Core Graphics 経路を `local_image` へ分離し、惑星画像と背景・媒体プレビューで共用した。
従来の AppKit / Foundation / ImageIO だけでは動画・音声のデコード、再生状態、シーク UI を提供できないため、macOS 標準の AVKit / AVFoundation を GUI 層に追加した。
AVPlayer と AVPlayerView に再生を任せ、独自 codec、再生エンジン、追加の外部媒体ライブラリは導入していない。core の依存は増えていない。
Lua は前単位で導入した公式 5.4.9 の固定ハッシュ・静的 helper を引き続き使用する。

指定名 `/simplifier-lai` は利用可能なスキルに存在しなかった。
別名の `simplify-lai` は LobbyAI 用であり、代わりに実行したとは扱わない。
独立した手動レビューで App* の責務分離、依存の再利用、時刻・セッションの境界、非同期検索、再読込時の参照を確認した。
小天体ブラウザで旧ページの index を新データへ流用しない修正、選択中の小天体を合成シーン試験の前後で復元する回帰確認も含む。
この検証文書には `japanese-writing` を適用し、実行結果と未確認項目の表現を確認した。

## 再実行手順

Apple Clang / Make、macOS SDK を使用し、追加コードには `-Wall -Wextra -Wpedantic -Werror` を適用する。
実行環境は macOS 26.6.2 / arm64、および同機上の x86_64 / Rosetta。deployment target は macOS 13.0 だが、macOS 13 実機や Intel Mac 実機は未確認である。
次の手順はリポジトリのルートから実行する。`DATA_ROOT` は `hip.dat` と `cf96.dat` を含む既存の `data` ディレクトリを明示する。

```sh
make -C native/core all test
make -C native/gui all test controller-test
DATA_ROOT='/absolute/path/to/local/data' make -C native/gui data-test smoke
make -C native/core BUILD_DIR=build-unit2-sanitize SANITIZE=address,undefined test
make -C native/gui BUILD_DIR=build-unit2-sanitize SANITIZE=address,undefined all test controller-test
make -C native/gui BUILD_DIR=build-unit2-x86 ARCH=x86_64 all test
DATA_ROOT='/absolute/path/to/local/data' make -C native/gui BUILD_DIR=build-unit2-x86 ARCH=x86_64 smoke
make -C native/core rotation-reference-test lunar-reference-test
CF96_DATA='/absolute/path/to/local/data/cf96.dat' make -C native/core reference-test
ruby investigation/native-plus/verify_preservation.rb final /Users/kota/mitaka
```

GUI controller と全体 smoke はログイン済みの画面環境を必要とする。
上記は再現用手順であり、未保存の実行を成功と認定するものではない。
新規 clone の確認では実行時点の staged patch を適用し、元 checkout の build 出力をコピーせず core と GUI の `all test` を実行した。

## 未対応・未確認の範囲

- 小天体の未確定な参照面・時系・個別 `Tp`・古代暦は推測しない。評価できる行も二体近似であり、摂動・彗星の尾・精度保証期間・原版の優先順位は含まない。小天体選択の永続化は未対応で、今回の合成シーン試験では一時選択を明示的に復元する。
- 天の川は全天図に接続した。地平図・太陽系 3D への接続、距離減衰、旧 Plus の投影・明るさとの画素一致、星座絵・風景は未対応または未検証である。
- 媒体は独立ウィンドウのプレビューであり、旧 Plus の画面合成・座標・フレーム API・全 codec の互換性は含まない。試験は人工画像、無音 PCM、破損動画を使用し、有効な動画の実再生中の終了・再読込・古い callback 競合を実操作で確認した記録ではない。解放と旧結果の除外はコードレビューと実施済み試験の範囲で区別する。
- 暦は先発グレゴリオ暦と固定 UTC 時差を使う。夏時間、閏秒、UTC / UT1 / TT / TDB の補正、原版 Lua の全日時 API・月末規則の再現は含まない。
- 外部物理ディスプレイ、保存・対応づけダイアログの全操作、全ローカル Lua の互換性、オンライン HTML / URL からの実行は確認していない。

## Git と policy gate の判定

18:48 JST の確認では HEAD は基準コミットのまま、staged 差分は 86 files、6,005 行追加・384 行削除だった。
その時点で通常版媒体試験の修正 1 行は未 stage だった。この文書・ログの追加と後続修正により最終差分は増えるため、commit 前に再計測する。
300 行を超えており主担当の commit 対象である。検証文書担当者は今回の証跡文書・ログと gate コピーだけを stage し、単位3のソースは stage しない。commit / push は主担当の実施後判定待ちである。
実装方針には小天体・背景・媒体と時間操作を追加し、対応する gate を更新済みである。
14 gate を時刻付きコピーへ記入し、単位2の index に固定された実装と実行ログに対して判定した。判定パスと最終 Git 確認は [2026-10-29-19-09-31/VALIDATION.md](../../../temp_gates/2026-10-29-19-09-31/VALIDATION.md) を参照する。commit 前の差分確認と、commit / push 後に追記すべき事項を分けている。
新規 clone の再実行は上記の局所修正確認方針により省略した。初回通常版失敗の原ログ全文、外部物理ディスプレイ、Intel / macOS 13 実機、有効動画の全ライフサイクル操作は未確認として残る。

### commit 後の追記

ローカル Git の commit と tree を確認した。source は `ae300e1e396c5ed0e6eb5129ad8a6f0069489597`（`Implement local Plus catalogs media and calendar controls`）。wrapper の `8497dfe`（`Adopt local Plus catalog media and calendar implementation`）では `vendor/mitaka` がこの source commit を指している。
上記の 18:48 / 19:10 JST 時点の未 commit 記録は作業経緯として残す。この追記はローカル commit と参照更新の確認であり、remote の push 状態や単位3の検証結果を示さない。
