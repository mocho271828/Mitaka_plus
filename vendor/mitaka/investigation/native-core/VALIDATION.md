# macOS コア実装の検証結果

実施日: 2026-10-29 JST。
環境: macOS 26.6.2 (25G83)、Apple Silicon arm64、Apple clang 21.0.0 (clang-2100.3.34.2)。

## 実装した範囲

`native/core/` に公式 Mitaka 1.3.1 の天文計算とデータローダーを分離した。
本番投入前の新規プロジェクトとして、Windows API・描画層・可変グローバル状態を含まない C++17 API とした。
日付変換、楕円・引力双曲線の位置と速度、9 天体の平均軌道、座標変換、HIP、旧星座バイナリ、CF96、`.ppi` に対応する。
ヘッドレス CLI と独立したテストを追加し、実行時依存は C++ 標準ライブラリのみとした。

MIT 表示を派生実装に保持し、原本との対応・変更点は各 `*_PROVENANCE.md` に記録した。
データ自体はライブラリへ同梱していない。
非公式 macOS 移植のコードは今回コピーしていない。

## ビルドと検証

作業ディレクトリは `/Users/kota/mitaka/native/core`。
`DATA_ROOT` は README に記載した既存アプリ内のデータルート、`CF96_DATA` はその `data/cf96.dat`。

| 実行 | 結果 |
| --- | --- |
| `make -j4 all test` | PASS。静的ライブラリ・CLI・3 テスト実行ファイルを生成。天文計算 1,275 チェック、カタログ・暦表テスト成功 |
| `make -j4 BUILD_DIR=build/sanitize SANITIZE=address,undefined all test` | PASS。AddressSanitizer / UndefinedBehaviorSanitizer の報告なし |
| `make data-test`（両データルート） | PASS。全 HIP、CF96、存在する旧星座・`.ppi` を読み込み |
| `make BUILD_DIR=build/sanitize SANITIZE=address,undefined data-test`（両データルート） | PASS。サニタイザ報告なし |
| `make reference-test` | PASS。公式 CF96 と 5,427 成分の位置・速度比較 |
| `make BUILD_DIR=build/sanitize SANITIZE=address,undefined reference-test` | PASS。原本比較もサニタイザ報告なし |
| `make -j4 universal` | PASS。arm64 と x86_64 の静的ライブラリ・CLI を生成・結合 |
| `xcrun lipo -info build/universal/libmitaka_core.a` と CLI の検査 | 両方に `x86_64 arm64` を確認 |
| Universal CLI の平均惑星計算・HIP 読込 | PASS。arm64 ホスト上で実行 |
| `xcrun otool -L build/universal/core_probe` | 両 architecture とも `libc++.1.dylib` と `libSystem.B.dylib` のみ |

新規コードは `-Wall -Wextra -Wpedantic -Werror` でコンパイルした。
原本比較用のコンパイルに限り、CP932 コメント・古い無名構造体・未使用変数に対する警告を抑制した。
原本の内容は変更していない。

CF96 比較の最大差は位置 `7.10543e-14 AU`、速度 `6.93889e-18 AU/day`。
許容差はそれぞれ `1e-12 AU`、`1e-13 AU/day` とし、9 惑星 × 201 時刻 × 3 軸を比較した。
時刻は各範囲の始端から終端まで等間隔で、複数ブロックを横断する。
これらはコードの回帰精度であり、天体の観測精度を保証する値ではない。

## 実データ

| 対象 | mitaka | mitaka_plus |
| --- | ---: | ---: |
| `hip.dat` | 117,956 レコード | 117,956 レコード |
| `cf96.dat` | 9 惑星 | 9 惑星 |
| `constellation_HIP.dat` | なし（現行 JSON は対象外） | 89 星座、165 線、13,422 境界点 |
| `.ppi` | 17 ファイル、31,921 セグメント | 0（旧 `.pth` は対象外） |

HIP はファイルサイズから求めた全レコード数と一致した。
CF96 の各惑星と全 `.ppi` について、時刻範囲の始端・中間・終端で有限の計算結果を得た。
今回の `.ppi` 中間時刻が空隙に入る例は 0 件。
ローダーには既存データの件数・識別子を固定する制約を置いていない。
負視差や未知の ID を落とさず、読み取り専用で扱う。

## レビューと修正

独立レビューで、単位・回転順序・固定幅整数・カタログの全件保持・入力次元・時刻境界を確認した。
原本の CF96 ローダーには固定配列への無検査読込があるため、比較テストを既知のサイズと SHA-256 の入力に限定した。
同じサイズの 1 byte 改変入力と切断入力が、原本に渡される前に拒否されることも確認した。
この制約は比較テストのみ。新コアは独自データの形式を検査して読み込む。
ハッシュ計算に使う macOS SDK の CommonCrypto も、比較テストだけの依存である。

## 保全・方針・変更管理

保全対象は `mitaka/`、`mitaka_plus/`、`sources/official/`。
通常ファイル 16,365 件・6,622,642,667 bytes、symlink 465 件を基準 manifest と照合し、追加・削除・変更 0 件。
公式 ZIP と展開原本 310 ファイルも一致した。
照合時刻と機械可読の結果は [PRESERVATION.md](PRESERVATION.md) と [preservation-result.json](preservation-result.json) に記録した。

新規追加は `native/core/`（19 ファイル、生成物を除き 2,225 行）、ルートの `IMPLEMENTATION_POLICY.md` と 4 個の policy gate（計 109 行）、本検証・保全記録である。
保全対象ファイルの変更は 0 件。
ワークスペース直下で `git status` は `not a git repository`。Git 差分は取得できないため、追加ファイル数と行数で変更量を確認した。
300 行以上の追加だが、ルートが Git リポジトリではないため commit は行っていない。
参照用 `sources/reference/Mitaka-macOS` は HEAD `ab63d81723a9261b663c8ab1283de2e7607f1094`、`git status --porcelain=v1 --untracked-files=all` は空で変更なし。

指定名 `/simplifier-lai` は利用可能な skill に存在しなかった。
類似名 [simplify-lai](../../../.codex/skills/simplify-lai/SKILL.md) の指示も確認したが、`Do not use for non-LobbyAI projects` と明示され、このプロジェクトは対象外である。
同 skill は実行せず、独立レビューと数値・異常入力テストを実施した。
標準ライブラリで足りる処理に新規パッケージは追加していない。

`IMPLEMENTATION_POLICY.md` にユーザー確認済みのプロジェクト状態を記録し、4 カテゴリを `policy_gates/` に分離した。
検証コピーは [temp_gates/2026-10-29-04-54-21](../../temp_gates/2026-10-29-04-54-21/) に保存し、4 gate すべての判定条件をチェック済み・判定 YES とした。不合格条件はいずれも非該当。

## 未実施・未対応

Intel 実機での実行は未実施。今回は x86_64 のクロスコンパイルと Universal バイナリ生成までである。
最小 macOS バージョン、署名・配布、GUI・描画・Swift 接続は今回の範囲に含めていない。
現行 JSON 星座、旧 `.pth`、銀河・系外惑星など他のローダーと、月・衛星の重心補正、UTC/TT/TDB・閏秒の扱いは後続作業とする。
既存の独自天文データは保全したが、すべての形式への対応を確認したという意味ではない。
