# Mitaka Native

Mitaka 1.3.1 の公式ソースを基にした、開発中の macOS ネイティブ版です。
C++17 の天文計算・データローダーと、AppKit の GUI を管理します。
公式の Mitaka 配布版ではありません。

現在の実装には恒星の全天図と地平図、太陽系 3D、惑星と月の表面・自転、日時の順行・逆行、地表からの離着陸と天体間の連続飛行があります。星座・追加カタログと小天体の検索、既知形式の彗星・小惑星・TNO の位置と表示集合、天の川画像、ローカルメディアのプレビュー、暦ステップと時計追従、状態・画像の保存、投影ウィンドウ、ローカル Lua の一部 API も追加しています。
追加衛星の検索・位置と瞬間軌道の表示・日時に合わせた視点追従、PTH 探査機の点・名称・軌跡、点・線・文字の描画品質設定、全画面表示とアプリ情報、信頼したローカル HTML のリンクからの Lua 実行にも対応します。追加衛星の表面・自転表示、探査機の機体モデルと PPI の表示、原版 Lua API の全互換は未対応です。
**旧 Mitaka Plus 1.5.4 の部分互換です。全機能の移植は完了していません。** 原典・現在対応・不足・検証状況は [機能対応表](PLUS_FEATURE_MATRIX.md)、操作と計算上の制限は [GUI の説明](native/gui/README.md) を参照してください。
このディレクトリは Mitaka_plus に通常ファイルとして収録した実装です。起動方法は [Plus ルートの README](../../README.md) を参照してください。

## ビルドとテスト

macOS と Xcode Command Line Tools（`xcrun clang++`、Make）が必要です。
GUI の設定上の最低バージョンは macOS 13 です。
今回の実行確認は macOS 26.6.2 / arm64 と、同機の Rosetta 上の x86_64 です。macOS 13 実機や Intel Mac 実機での確認は含みません。機能別の統合検証結果は機能対応表に記録しています。
追加のパッケージマネージャや Wine は不要です。Lua helper は同梱の公式 Lua 5.4.9 ソースを使うため、ビルド時のネットワーク接続は不要です。
アーカイブの SHA-256 を固定して検証し、macOS 13.0 以上の `arm64` / `x86_64` 向けにソースからビルドして静的リンクします。完成アプリは Homebrew や外部 Lua dylib を必要としません。ハッシュとビルド契約は [SCRIPTING.md](native/gui/SCRIPTING.md) に記載しています。

```sh
cd vendor/mitaka
make -C native/core all test rotation-reference-test lunar-reference-test
make -C native/gui all test controller-test
make -C native/gui script-test
```

アプリは `native/gui/build/Mitaka Native.app` に生成されます。
`controller-test` とアプリの起動には macOS の GUI セッションが必要です。
署名・公証は未対応です。

## ローカルデータを使う

Plus の天文データ・表面画像は Plus ルートの `resources/` に収録しています。旧 Windows アプリと Wine 環境は登録していません。
ユーザーのローカル原本・独自追加データを最優先し、読み取り専用で参照します。公開データへの置換、件数合わせ、変換・間引きを行いません。
`data/` の隣に `textures/` を置く既存の構成を維持してください。
独自に追加した全形式を描画できるという意味ではありません。
HIP / CF96 に加え、旧星座バイナリ、NGC/IC、SDSS 銀河・QSO、恒星名、系外惑星を持つ恒星の HIP 一覧、旧 Plus の日本語観測地定義を扱います。任意カタログの欠損・形式エラーは警告し、元データを更新しません。
小天体と衛星は出典・原行・重複を保持し、計算に必要な項目を確認できた行だけを表示します。追加衛星は出典ごとに独立して登録し、同じ出典・日時の親天体位置と結び付けます。旧衛星データの物理的な時系と精度保証期間は未確定です。探査機の定義・PPI/PTH の全行を保持し、確定した PTH だけを GUI 表示へ接続します。PPI の表示原点・面・時系と機体モデルは未対応です。

```sh
export DATA_ROOT="$(cd ../.. && pwd)/resources/data"
make -C native/gui run
make -C native/gui data-test
CF96_DATA="$DATA_ROOT/cf96.dat" make -C native/core reference-test
DATA_ROOT="$(dirname "$DATA_ROOT")" make -C native/core data-test
```

GUI は `data` ディレクトリ、コアの `data-test` はその親ディレクトリを受け取ります。
GUI 起動後の「データを開く…」からも読み込み先を変更できます。
データと画像の利用条件は各配布元の条件に従い、コードの許諾と分けて扱います。

「スクリプト」メニューから、明示選択した信頼済みのローカル Lua を実行できます。ユーザーの選択により `io` / `os` 等の標準ライブラリを有効にしており、本人の権限でファイル・外部コマンドを操作できます。別 helper での実行と取消機能は OS サンドボックスではありません。URL やデータ配置からの自動実行は行いません。原版 API・Lua 5.1 との差は [SCRIPTING.md](native/gui/SCRIPTING.md) を参照してください。
「信頼したローカルHTML…」では、明示して開いた HTML のメインページでユーザーが `mtkp://` リンクを押したときだけ、同じ Lua helper に処理を渡します。オンラインページからの実行、ページ JavaScript、Flash、自由なページ遷移は提供しません。ファイル変更や通常リンクの操作で実行元の信頼を解除します。

## 構成

| ディレクトリ | 役割 |
| --- | --- |
| `native/core/` | 描画に依存しない天文計算とデータローダー |
| `native/gui/` | AppKit GUI、視点・再生・飛行制御、テスト |
| `sources/official/` | 改変していない公式 1.3.1 ZIP と展開ソース。比較テストに使用 |
| `investigation/` | 設計、出典調査、移行前からの検証記録 |
| `policy_gates/` | 実装時に満たす判定条件 |
| `temp_gates/` | 判定済みの gate コピー |

今後の変更は [Plus ルートの IMPLEMENTATION_POLICY.md](../../IMPLEMENTATION_POLICY.md) に従います。このディレクトリの方針と gate は移行前の記録として保持します。
`investigation/` の過去のログに含まれる絶対パスは、その検証時点のものです。

## 原本と許諾

公式 1.3.1 は、取得した ZIP と展開後の全 310 ファイルをバイト列を変えずに収録しています。
取得元とハッシュは [sources/README.md](sources/README.md)、改変箇所と対応元は `native/core/*_PROVENANCE.md` に記録しています。
原著作権・MIT 許諾を各ソースと [THIRD_PARTY_NOTICES.txt](native/gui/THIRD_PARTY_NOTICES.txt) に保持します。
Lua の原著作権・MIT 許諾は [LUA_LICENSE.txt](native/gui/LUA_LICENSE.txt) に保持し、両文書をアプリ内へ同梱します。
天文データ・画像・旧アプリに、リポジトリ内のコードの許諾を一括で適用しません。
