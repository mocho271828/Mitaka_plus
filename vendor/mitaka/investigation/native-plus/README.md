# Plus 機能追加の検証記録

確認日: 2026-10-29。基準コミットは `94c9af3d968fcdb9591e4d3efcf2992954293f01`。
この記録は地平図、ローカル追加カタログ・地点、時間操作、状態/画像保存、投影、信頼済み Lua の追加作業を対象とする。原版の全機能完了を示すものではない。残る仕様と受入条件は [機能対応表](../../PLUS_FEATURE_MATRIX.md) に記載する。

後続の小天体・背景・媒体・時間操作の追加は [単位2の検証記録](unit2/README.md) に分離している。
探査機、小惑星/TNO、表示・軌道設定などの後続作業は [単位5の検証記録](unit5/README.md) に分離し、局所試験と全体の完了判定を区別している。

## ローカル原本の保全

データは既存の通常版・Plus 版の `Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data` を明示指定した。画像はその隣の `textures` から参照した。公開データへの置換、件数の調整、元ファイルへの書込みは行っていない。

`ruby investigation/native-plus/verify_preservation.rb final /Users/kota/mitaka` により、保存済み manifest と全原本を照合した。[結果](preservation-final.json) は 16,365 ファイル / 6,622,642,667 bytes / 465 symlinks、追加・削除・変更すべて 0。公式 ZIP との 310 ファイル照合も不一致 0、参照 checkout の HEAD と clean 状態は不変だった。これらはこのローカル環境の観測値であり、ローダーの固定件数や一般の合否基準ではない。

## ビルド・検証

Apple Silicon の macOS 環境で Apple Clang / Make を使用した。`-Wall -Wextra -Wpedantic -Werror` を全ネイティブ追加コードに適用した。macOS 13.0 をビルド下限とするが、macOS 13 実機・Intel 実機の検証ではない。

| 対象 | 結果・ログ |
| --- | --- |
| GUI 通常ビルド・単体・controller | 成功。[ログ](logs/mitaka-plus-final-build.log) |
| Plus ローカルデータ・全体 smoke | 成功。[ログ](logs/mitaka-plus-final-data-smoke.log) |
| 通常版ローカルデータ・全体 smoke | 成功。[ログ](logs/mitaka-regular-final-data-smoke.log)。選択表示の復元修正を含む。 |
| x86_64 ビルド・Rosetta 全体 smoke | 成功。[ログ](logs/mitaka-x86-final-smoke.log)。Lua helper も x86_64。 |
| クリーン clone + staged patch | core `all test` と GUI `all test` 成功。[ログ](logs/mitaka-plus-clean-build.log)。既存 build 生成物の持込みなし。 |
| core ASan / UBSan | 成功。[ログ](logs/mitaka-plus-core-final.log) |
| GUI ASan / UBSan | 単体、Lua、ブラウザ、再生 controller は成功。投影試験の前面表示前提が欠けて失敗した記録を[保存](logs/mitaka-gui-final-san.log)。製品コードは変更せず試験を修正した。 |
| 投影の可視性・sleep/wake 回帰 | 修正後、通常 1 回と ASan / UBSan 連続 5 回が各 43 checks 成功。[ログ](logs/mitaka-display-output-wake-validation.log)。被覆・非表示中の停止と再表示時の再開を確認。 |
| 修正後の GUI controller 全体 ASan / UBSan | Lua、ブラウザ、再生、投影を一連の `controller-test` で再実行し成功。[ログ](logs/mitaka-plus-controller-final.log)。 |
| 自転・月の公式計算との比較 | 成功。[ログ](logs/mitaka-core-final-references.log)。自転 33,129 成分の最大差 `4.32943121631e-09`、月 12,108 成分の最大位置差 `1.73472347598e-18 AU`、姿勢差 `9.48019440727e-13`。 |
| CF96 公式計算との比較 | 成功。[ログ](logs/mitaka-cf96-final-reference.log)。5,427 成分、最大位置差 `7.10543e-14 AU`、速度差 `6.93889e-18 AU/day`。 |

通常の再実行手順:

```sh
make -C native/core all test
make -C native/core rotation-reference-test lunar-reference-test
CF96_DATA="$DATA_ROOT/cf96.dat" make -C native/core reference-test
make -C native/gui all test controller-test
DATA_ROOT="/absolute/path/to/local/data" make -C native/gui data-test smoke
make -C native/core BUILD_DIR=build-plus-validation SANITIZE=address,undefined test
make -C native/gui BUILD_DIR=build-plus-validation SANITIZE=address,undefined test controller-test
make -C native/gui BUILD_DIR=build-x86-final ARCH=x86_64 all
```

GUI 試験はログイン済みの画面環境を必要とする。投影試験ではウィンドウが可視であることを確認する。ユーザーが他の画面・Space に切り替えた場合など、OS の可視性条件を満たさなければ診断付きで失敗する。待ち時間の延長で成功に見せない。

追加の境界試験では session 466 checks、GUI file I/O 51 checks を確認した。状態入力の通常ファイル限定、容量制限、FIFO 拒否、出力パスの正規化・symlink・保全対象拒否、空の選択状態を含む往復を扱う。GUI 全体 smoke は 3 表示モード、11 天体、地球の地点、9 通りの画像形式/表示の組合せ、Lua の正常・失敗経路を検証した。実機のカタログブラウザでは Dark Aqua の文字、選択によるボタン有効化、501–1,000 件ページへの移動を確認した。

保存/読込ダイアログの全操作、外部物理ディスプレイ、旧 Lua 全 API、全既存スクリプトの実行成功、原版との画素一致は未確認である。信頼済み Lua のファイル/OS 操作試験は一時領域で実施し、原本は使用しなかった。

## 依存・変更レビュー

C++17 標準ライブラリ、既存の天文コア、AppKit / Foundation / Core Graphics / ImageIO を優先した。JSON・画像・ウィンドウを独自の低水準実装へ置き換えていない。Lua は独自インタープリタを作らず、公式 5.4.9 を固定ハッシュで検証し helper に静的リンクする。既存の依存に Lua 実行系がなかったために追加し、コアへの依存を避けた。出典・許諾・言語版差は `native/gui/SCRIPTING.md` と `THIRD_PARTY_NOTICES.txt` に記録した。

`/simplifier-lai` は利用可能なスキルに存在しなかった。別名の `simplify-lai` は LobbyAI 専用であり、このリポジトリへ適用していない。代わりに独立した手動レビューで App* の分割境界、入力検証、状態復元、時刻共有、全件保持、カタログ参照境界、依存の再利用を確認し、明確な追加修正事項はなかった。Git 状態・ファイル・差分量を確認し、300 行を超えるため commit 対象とした。policy gate の実際のチェックは `temp_gates/` の時刻付きコピーに残す。
