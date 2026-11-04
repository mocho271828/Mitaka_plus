# 太陽系 3D と視点操作の検証

確認日: 2026-10-29。
環境: macOS 26.6.2 / arm64、Xcode 27.1、Apple Clang 21、macOS SDK 27.0。
deployment target は macOS 13.0。Intel Mac と macOS 13 実機は未検証。

## 変更範囲

`native/gui/` に太陽系モデル、透視投影カメラ、AppKit の 3D ビューを追加した。
起動時は太陽系 3D を表示し、既存の全天図へ切り替えられる。
回転・平行移動・拡縮、全体／内惑星の視点、天体選択、選択天体を中心とする日時追従を実装した。

既存コアの CF96 から太陽中心位置を取得し、コアの座標変換で J2000 黄道座標へ変換する。
太陽を含む 10 天体を表示し、9 本の軌道線は有効期間内の CF96 位置を各 181 点で標本化する。
地球は地球月重心、冥王星は衛星系重心を表示する。天体サイズは模式表示である。
`native/core/` の実装、既存天文データ、公式 1.3.1 原本は変更していない。

## ビルドと自動検証

以下はすべて終了コード 0。通常と sanitizer の出力先を分離した。

| 対象 | 実行内容 | 結果 |
| --- | --- | --- |
| 通常 GUI | `make -j4 all test` | `-Wall -Wextra -Wpedantic -Werror` でビルド。全天図・太陽系モデルのテスト成功 |
| Sanitizer GUI | `make -j4 BUILD_DIR=build/sanitize SANITIZE=address,undefined all test` | ASan / UBSan で同じテスト成功 |
| 実データ | 通常・sanitizer × mitaka・mitaka_plus の各モデルテスト | HIP 117,956 件、全天図 9 天体、太陽系 10 天体・9 軌跡を確認 |
| AppKit | 通常・sanitizer × mitaka・mitaka_plus の `--smoke-test` | 最終ソースで 4 組とも起動・計算・実描画・カメラ・選択検証に成功 |
| 独立コア | `native/core/` の `make test` | astronomy 1,275 checks、catalog、ephemeris テスト成功 |

データの指定先は次の 2 ディレクトリ。

```text
/Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data
```

GUI ディレクトリでの再実行手順は [README](../../native/gui/README.md) に記載した。
AppKit の最終実行結果は 4 組とも次の値だった。

最終ログ: [通常・mitaka](build-mitaka-smoke.log)、[通常・mitaka_plus](build-mitaka_plus-smoke.log)、[sanitizer・mitaka](build-sanitize-mitaka-smoke.log)、[sanitizer・mitaka_plus](build-sanitize-mitaka_plus-smoke.log)。

```text
AppKit smoke passed: HIP=117956 visible=7983 bodies=9 lit_samples=12039 render=2000x1036
Solar AppKit smoke passed: bodies=10 camera=orbit,pan,zoom,focus,date-tracking lit_samples=1194
```

`lit_samples` は画面内の明るい画素を 3 pixel おきに数え、描画が空でないことを確認する値。
画像の完全一致試験や、全点の可視性の保証には使わない。

### 数値・入力境界

- CF96 からの位置対応、地球月重心の識別、太陽の原点、有効範囲の始点・中間・終点を検証した。
- 軌道線の有限性、標本数、有効期間、期間の端での切り詰めを検証した。
- カメラの回転、平行移動、拡縮、距離 0.05–1,000 AU と仰角 ±89° の制限を検証した。
- 非有限値・不正な投影サイズの拒否、背面点の除外、近接面に交差する線分のクリップを検証した。
- 実データ試験では読み込んだ入力の内容と更新時刻を照合した。保護対象全体は別途 SHA-256 で照合した。

### AppKit スモーク

読み込み、全天図／3D 切替、日時の変更と復元、天体選択、全天図の等級制限、各ビューの実描画を確認した。
3D は回転・平行移動・拡縮・内惑星視点・全体への復帰・天体中心への移動をメソッド経由で検証し、選択天体への日時追従を確認した。
日時追従は、翌日へ変更した直後と元の日付へ復元した直後のそれぞれで、カメラの中心と地球月重心の位置が一致することを検証した。
マウス選択と共通の判定処理には合成配置を渡し、重なった天体の手前を選ぶこと、近接面内・背面・画面外の天体を選ばないこと、空白クリックで選択と追従を解除することを確認した。
合成配置の検証後は元の天体・カメラ・選択・追従状態を復元する。

## 画面での確認と限界

更新した通常版を起動し、太陽系・軌道線・格子・ラベルの描画を確認した。
「内惑星」「地球月重心」「選択を中心」「＋1日」の操作と、5 行の座標表示・日時変更後の追従を画面で確認した。
回転・拡縮したカメラ値と、それに対応して変わった描画も観察できた。

一方、検証ツールからの座標指定ドラッグは `noWindowsAvailable`、再起動後の再試行はユーザー操作との競合で停止した。
そのため、検証ツールによるドラッグ／Shift・右ドラッグ／スクロール／ピンチの一連の実入力確認は完了扱いにしない。
自動テストは操作先の処理と投影・選択を検証しており、物理マウスやトラックパッドのイベント配送とは区別する。

今回の読み込み失敗後・不正 JD 適用後の画面保持についても、追加の実画面確認は未実施。
コードレビューでは、2D 位置・3D 位置・軌道線の全計算が成功した後に表示状態を更新し、失敗時は既存モデル・時刻・ビューを保持することを確認した。
ローダーと表示モデルの異常入力は自動テストで検証した。

3D は AppKit / Core Graphics による透視投影と模式球の描画であり、テクスチャ・実寸の惑星表面・光源計算は含まない。
恒星は既存の全天図に表示する。
今回の GUI が読む既存データは HIP と CF96 のみで、独自追加データの他形式への対応を示すものではない。
配布署名・notarization と UTC／観測地補正は対象外。

## 保全・品質・変更管理

最終照合は [PRESERVATION.md](PRESERVATION.md) と [preservation-result.json](preservation-result.json) に記録した。
通常ファイル 16,365 件、シンボリックリンク 465 件に追加・削除・変更なし。
公式 ZIP の 310 ファイルと展開原本が一致し、参照用 Git の HEAD と clean 状態も維持した。

依存を確認し、既存 C++17 コア、C++ 標準ライブラリ、AppKit / Core Graphics、UniformTypeIdentifiers を使用した。
追加の外部ライブラリはない。既存コアの暦表計算やローダーを重複実装していない。
小規模な投影・カメラ処理を C++ に置くことで AppKit を伴わずテストでき、現在の模式描画には別の描画エンジンを追加しない判断とした。
独立レビューで数値・座標・クリップ・非同期更新・UI 状態の不整合を確認し、修正必須の指摘は残っていない。

ルートの `git status` は Git リポジトリではないため実行不可。
参照リポジトリの `git status --short` は空だった。
[source-diff.json](source-diff.json) にソースの変更 9・追加 6 ファイル、+1,073 / −50 行を記録した。
300 行以上の差分だが、ルートは Git 管理外のため commit していない。Git の初期化も行っていない。
この行数には `build/`、調査記録、gate の検証コピーを含めない。

指定の `/simplifier-lai` は利用可能なスキル一覧とローカル配置を確認したが存在せず、実行していない。
類似名の `simplify-lai` は LobbyAI を対象とするため適用せず、独立コードレビューで品質を確認した。
文書には `japanese-writing` を適用した。
`IMPLEMENTATION_POLICY.md`、`policy_gates/native_gui.md` を更新し、`policy_gates/solar_view.md` を追加した。
各 gate を [temp_gates/2026-10-29-13-01-02/](../../temp_gates/2026-10-29-13-01-02/) へコピーし、チェックボックス・根拠・判定を記入した。全 6 gate の判定は YES。
