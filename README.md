# Mitaka_plus

Mitaka_plus の既存天文データを、macOS ネイティブの共通コア・GUIで利用するためのリポジトリ。
共通実装は [Mitaka](https://github.com/mocho271828/Mitaka) で管理し、`vendor/mitaka` の Git submodule で使用するコミットを固定する。
現在の GUI には恒星・地平表示、星座線・境界・名前、ローカルの NGC/IC・SDSS カタログ表示と検索、太陽系 3D、惑星・月の表面と自転、順逆の時間再生、地表移動、天体間の連続飛行がある。表示状態の保存・復元、PNG/JPEG/BMP 出力、投影ウィンドウ、信頼済みローカル Lua の実行にも対応する。
ローカルの小天体一覧と計算可能な軌道、可視光・赤外線の天の川、画像・動画一覧にも対応する。解釈できない行や参照先が見つからない画像も一覧に保持する。日時は年月日と時差で入力でき、月・年単位の送りと実時間追従を選べる。
恒星名・連星／系外惑星マーク、惑星の本体・名称・軌道・自転軸、座標格子・距離目盛をメニューと Lua で操作できる。月間カレンダーは日曜始まりの 42 セルを使い、日時情報の表示設定とともに JSON v4 の状態保存へ接続している。旧開発版 JSON v1 / v2 / v3 は読み込まない。

このリポジトリに旧 Mitaka_plus の公式ソースは含まれない。
入手できている公式 Mitaka 1.3.1 のソースから分離したコアと、新しく実装したネイティブ GUI を使用する。
旧 Mitaka_plus の全機能や固有データ形式への対応は未完了。原典と実装・不足の対応は [機能対応表](vendor/mitaka/PLUS_FEATURE_MATRIX.md) を参照。

### 単位4で採用した機能

単位4では、追加衛星の検索・位置表示・日時追従、描画品質 4 項目、主画面の全画面表示/About、信頼したローカル HTML のリンクからの Lua 実行を採用した。JSON v4 に描画品質と衛星の全体表示を保存する。旧開発版 v1 / v2 / v3 は変換せず拒否し、全画面・HTML 信頼・実行状態は保存しない。

衛星は出典・原行・同名定義を保持し、同じ出典・JD で計算した親位置に結び付ける。衛星の物理的な時系と精度期間は未確定。追加衛星の表面・自転、個体別可視性、探査機 GUI、旧 Lua の全 API は未対応のまま残る。探査機定義・PPI/PTH のコア読込だけを表示対応と扱わない。

HTML は明示選択したローカル文書のメインページでユーザーが押した `mtkp://` リンクだけを実行元とする。文書内容・ファイル同一性・表示世代を検査し、通常リンクの操作や閉じる操作などで信頼を解除する。ページ JavaScript、Flash、オンライン閲覧・実行は提供しない。Lua helper のファイル・OS 権限は通常のローカル Lua と同じで、サンドボックスではない。

## 取得とビルド

macOS、Xcode または Command Line Tools、Git、`make` が必要。
Lua helper 用に公式 Lua 5.4.9 をビルドする。初回は HTTPS でソースを取得し、固定 SHA-256 を検証して build 配下に展開するためネットワーク接続が必要。完成アプリには静的リンクされ、Homebrew や外部 Lua のインストールは不要。
macOS の deployment target は 13.0。
両リポジトリが Private のため、取得する GitHub アカウントには両方の読み取り権限が必要。

```sh
git clone --recurse-submodules https://github.com/mocho271828/Mitaka_plus.git
cd Mitaka_plus
make build
make test
```

submodule を取得せずに clone した場合は、次を実行する。

```sh
git submodule update --init --recursive
```

出力は `vendor/mitaka/native/gui/build/Mitaka Native.app`。
アプリ名と実装は共通の Mitaka Native を使い、別の GUI コピーは持たない。

## 既存データで起動

`DATA_ROOT` に `hip.dat` と `cf96.dat` が直下にある `data` ディレクトリの絶対パスを指定する。
表面画像は `data` と同じ親ディレクトリにある `textures` から読み込む。
独自追加を含むローカルデータを優先し、元ファイルを読み取り専用で使う。公開データへの置換・既知の件数への切り詰めは行わない。既存データをこのリポジトリにコピーする必要はない。

```sh
export DATA_ROOT='/absolute/path/to/mitaka_plus/data'
make run
```

旧アプリのパッケージ内部にデータがある場合も、その `data` のパスを直接指定できる。
そのパスに Wine 関連のディレクトリ名が含まれていても、アプリはデータを読むだけで Wine を実行しない。
データを起動後に選ぶ場合は、ビルド後のアプリを直接開く。

```sh
open -n 'vendor/mitaka/native/gui/build/Mitaka Native.app'
```

操作方法と表示上の制約は [共通 GUI の説明](vendor/mitaka/native/gui/README.md) を参照。

## 検証

```sh
make test
make data-test
make reference-test
make smoke
```

`make test` はデータなしでコア・GUI・再生・出力・Lua コントローラのテストを実行する。
`make data-test` は指定された既存データを読み取り専用で検証する。
`make reference-test` は公式 1.3.1 原本との惑星位置・自転・月計算の比較を実行する。
`make smoke` は実アプリで描画・表示状態復元・画像符号化・再生・飛行・Lua 接続を検証する。`data-test`・`reference-test`・`smoke` には `DATA_ROOT` の指定が必要。
Plus の Makefile は `DATA_ROOT` を常に `data` ディレクトリとして受け取り、コアのデータテストに渡すときだけ親ディレクトリへ変換する。

## 採用した共通実装の検証

2026-10-29 に共通実装を `002adcf663fd5005e14ac86c343a3ec7e56fa706` へ固定した。
ラッパーからの検証結果は [VALIDATION.md](VALIDATION.md)、共通側の検証範囲と残る制約は [単位4の記録](vendor/mitaka/investigation/native-plus/unit4/README.md) に記載する。
投影ウィンドウの制御された遮蔽状態によるテストと、実 OS の完全遮蔽通知は区別する。実 OS 通知の試験は共通側で未通過として残している。

## 共通実装の更新

通常の取得・更新では、Plus が記録したコミットを使用する。

```sh
git pull --ff-only
git submodule update --init --recursive
```

共通実装の採用バージョンを変更するときは、Mitaka に push 済みのコミットを明示して切り替え、テスト後に gitlink を記録する。
`<commit>` は採用するコミット ID に置き換える。

```sh
git -C vendor/mitaka fetch origin
git -C vendor/mitaka checkout --detach <commit>
make build
make test
make data-test
make reference-test
git add vendor/mitaka
git commit -m 'Update shared Mitaka implementation'
```

共通コア・GUI の修正は Mitaka 側で行い、Plus 側ではそのコミットを採用する。
submodule 内の変更を Plus のコミットだけで保存することはできない。

## 保存範囲と利用条件

GitHub にはソース・文書・設定と共通実装への参照を保存する。
既存の天文データ、独自追加データ、表面画像、旧アプリ、Wine 環境、ビルド生成物、認証情報は登録しない。
データと旧アプリは利用者のローカル環境で保持する。

公式 Mitaka 1.3.1 の由来と許諾表示は共通リポジトリの [ソース入手先の記録](vendor/mitaka/SOURCE_AVAILABILITY.md) と [第三者コードの表記](vendor/mitaka/native/gui/THIRD_PARTY_NOTICES.txt) を参照。Lua は [専用の許諾表示](vendor/mitaka/native/gui/LUA_LICENSE.txt) をアプリへ同梱する。

Lua はユーザーが信頼して明示選択したローカルファイルを実行する。ファイル・OS 操作はユーザー権限で行われ、サンドボックスではない。対応 API と旧 Lua との差は [スクリプト説明](vendor/mitaka/native/gui/SCRIPTING.md) を参照。
コードの許諾から旧 Mitaka_plus 本体や天文データ・画像の改変・再配布条件を推定しない。
このリポジトリ全体に新たな一律のライセンスを付与しない。

実装時の判定入口は [IMPLEMENTATION_POLICY.md](IMPLEMENTATION_POLICY.md)。
