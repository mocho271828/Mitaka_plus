# Mitaka_plus

Mitaka_plus の既存天文データを、macOS ネイティブの共通コア・GUIで利用するためのリポジトリ。
共通実装は [Mitaka](https://github.com/mocho271828/Mitaka) で管理し、`vendor/mitaka` の Git submodule で使用するコミットを固定する。
現在の GUI には恒星表示、太陽系 3D、惑星・月の表面と自転、時間再生、地表移動、天体間の連続飛行がある。

このリポジトリに旧 Mitaka_plus の公式ソースは含まれない。
入手できている公式 Mitaka 1.3.1 のソースから分離したコアと、新しく実装したネイティブ GUI を使用する。
旧 Mitaka_plus の全機能や固有データ形式への対応を保証するものではない。

## 取得とビルド

macOS、Xcode または Command Line Tools、Git、`make` が必要。
追加の外部ライブラリは不要。
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
既存データをこのリポジトリにコピーする必要はない。

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
```

`make test` はデータなしでコア・GUI・再生コントローラのテストを実行する。
`make data-test` は指定された既存データを読み取り専用で検証する。
`make reference-test` は公式 1.3.1 原本との惑星位置・自転・月計算の比較を実行する。
後者 2 つには `DATA_ROOT` の指定が必要。
Plus の Makefile は `DATA_ROOT` を常に `data` ディレクトリとして受け取り、コアのデータテストに渡すときだけ親ディレクトリへ変換する。

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

公式 Mitaka 1.3.1 の由来と許諾表示は共通リポジトリの [ソース入手先の記録](vendor/mitaka/SOURCE_AVAILABILITY.md) と [第三者コードの表記](vendor/mitaka/native/gui/THIRD_PARTY_NOTICES.txt) を参照。
コードの許諾から旧 Mitaka_plus 本体や天文データ・画像の改変・再配布条件を推定しない。
このリポジトリ全体に新たな一律のライセンスを付与しない。

実装時の判定入口は [IMPLEMENTATION_POLICY.md](IMPLEMENTATION_POLICY.md)。
