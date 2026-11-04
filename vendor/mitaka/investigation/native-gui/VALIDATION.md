# macOS ネイティブ GUI の検証記録

検証日: 2026-10-29。
対象は `native/gui/` の AppKit アプリと表示モデル。
以下は実行済みの検証記録である。

## 環境とビルド

- 実行環境: macOS 26.6.2 / arm64。
- ツール: Apple Clang、Make、macOS SDK。
- 実装: C++17、Objective-C++、AppKit。追加の外部パッケージなし。
- deployment target: macOS 13.0。macOS 13 実機、Intel Mac 実機での実行は未確認。
- 警告設定: `-Wall -Wextra -Wpedantic -Werror`。

`native/gui/` で通常の `make all` と `make test` が成功した。
出力は `build/Mitaka Native.app` と `build/test_sky_model`。

## 表示モデルの自動テスト

`tests/test_sky_model.cpp` を Apple Clang でビルドし、通常構成と AddressSanitizer / UndefinedBehaviorSanitizer 構成で成功した。
表示モデルとコアに加え、AppKit アプリ全体も同じサニタイザ構成でビルド・実行した。

合成データで次を確認した。

- HIP レコード全件、負視差、未知のスペクトル型を保持する。
- 太陽＋8惑星の順序、地球・月重心からの方向と距離、日付変更による再計算が期待値と一致する。
- 9 惑星の共通時刻範囲を計算し、その両端を評価できる。
- 赤経の左右方向、360° の折り返し、極の位置、拡大時の表示範囲が期待値と一致する。
- 星の選択、等級フィルタ、同距離での天体優先、描画領域外の選択を処理できる。
- 空パス、欠落ファイル、不正赤緯、NaN、切断データ、9 惑星が揃わない CF96、共通時刻範囲なし、非有限 JD、範囲外 JD、天体のゼロ距離を拒否する。

## 既存データの読み取り専用テスト

表示モデルのテスト実行ファイルに、以下のディレクトリを明示して検証した。

```text
/Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data
```

両方で通常構成と ASan/UBSan 構成のテストが成功した。
各データセットの HIP 117,956 件を保持し、全件を投影できた。
共通時刻範囲の開始・中央・終了時点で、9 天体の有限な方向と正の距離を確認した。
テスト前後で `hip.dat` と `cf96.dat` のバイト内容および更新時刻が一致した。
これは読み込んだ 2 ファイルの確認であり、保全対象全体の最終比較は [保全照合](PRESERVATION.md) に記録した。

## AppKit の実行確認

mitaka と mitaka_plus の既存データを指定した AppKit smoke test が、通常構成と ASan/UBSan 構成で成功した。
HIP 117,956 件の読み込み、9 天体の計算、日付を進めて戻す操作、天体選択、等級変更、メモリ上の非空描画を確認した。
描画サイズとサンプル画素数はレイアウトに依存するため、固定の合格値として記録しない。

実際のウィンドウ操作で次を確認した。

- 初期時刻から 1 日進めると惑星位置が更新され、木星の選択欄に赤経 23.911°、赤緯 +8.617°、距離 4.63671 AU が表示された。
- V 等級上限 4.5 で恒星の表示件数が 838 件になった。
- 数値として不正な JD と範囲外の JD では理由が表示され、適用前の天体表示が保持された。
- 引数なしで起動すると、データ選択前の時刻・等級・天体ボタンが無効になった。
- フォルダ選択で mitaka のデータを読み込み、星をクリックして HIP 32349、赤経 101.289°、赤緯 −16.713°、ファイル由来の V 等級 −1.09 を表示した。
- `hip.dat` が存在しない `native/gui/` を選択するとファイル名と失敗理由を表示し、直前のデータ・時刻・天体表示を保持した。
- 続けて mitaka_plus の `data` フォルダに切り替え、表示中のパス、HIP 117,956 件、初期表示 7,983 件、9 天体を確認した。

新 SDK ではフォルダ選択フラグが content type から再計算されるため、`allowedContentTypes = @[UTTypeDirectory]` を指定した。
この修正後にフォルダ選択の繰り返し、読み込み失敗からの復帰を実操作で確認し、通常版とサニタイザ版の AppKit smoke を再実行した。

数値は今回のデータと操作で得た表示結果であり、独立した観測暦との精度比較を意味しない。

## 最終統合確認

最終レイアウトとフォルダ選択の修正後も、通常版とサニタイザ版のビルドが成功した。
代表的な smoke の出力は次のとおり。終了コードは 0、サニタイザの診断なし。

```text
sky model tests passed
AppKit smoke passed: HIP=117956 visible=7983 bodies=9 lit_samples=12157 render=2000x1112
```

既存コア単独の `make test` も成功した（astronomy 1,275 checks、catalog、ephemeris）。
`plutil -lint` は元とアプリ内の Info.plist の両方で成功。
実行ファイルは arm64 Mach-O であり、`otool -L` では macOS 標準フレームワーク・ランタイムだけを確認した。
コアの著作権・許諾表示がアプリ内の `Contents/Resources/THIRD_PARTY_NOTICES.txt` に含まれる。

[保全照合](PRESERVATION.md)では、通常ファイル 16,365 個とリンク 465 個の追加・削除・変更が 0 件、公式 ZIP の 310 ファイルが展開原本と一致した。

## 変更管理

追加は `native/gui/` のアプリ・表示モデル・テスト・Makefile・文書と、`investigation/native-gui/` の検証記録。
更新は `native/core/README.md`、`IMPLEMENTATION_POLICY.md`、`policy_gates/core_architecture.md`、新規追加は `policy_gates/native_gui.md`。
既存コアのコード、既存データ、公式原本、参照用移植ソースは変更していない。

`native/gui/` の追加はビルド生成物を除いて 12 ファイル・1,336 行。300 行を超えるが、ルートの `git status` は Git リポジトリではないため実行できず、commit は作成していない。
参照用 Git の `git status --short` は空で、HEAD も基準と一致した。Git 差分量は算出できないため、追加ファイルの行数と変更ファイル一覧を記録した。

指定された `/simplifier-lai` skill は利用できない。利用可能な `simplify-lai` は LobbyAI 専用で対象外のため適用していない。
代わりに独立したコードレビューで依存、エラー処理、データ保全、Makefile を確認し、起動時の `open -n` とアプリ内の許諾表示を改善した。
新規の外部ライブラリは追加せず、既存 C++ コアと C++ 標準ライブラリ、macOS 標準フレームワークを使用した。
5 つの policy gate はすべて YES。判定と根拠は [今回の検証コピー](../../temp_gates/2026-10-29-05-39-44/) に記入済み。独立した最終レビューにも残る指摘はなかった。

## 未確認・未対応の範囲

macOS 13 実機および Intel Mac 実機での動作、配布用署名・notarization、長時間連続運転は未確認。
月・地平座標・3D 描画・追加カタログ形式の表示は今回の実装範囲に含まれない。
既存の独自追加データを保存することと、全形式を GUI から利用できることは区別する。
