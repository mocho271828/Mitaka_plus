# Gate: コアの境界と依存関係

## 目的

天文計算とデータ読み込みを macOS の UI・描画・Wine から独立して利用できるようにする。

## 判定条件

- [x] 天文計算とローダーは `native/core/` の C++17 ライブラリに閉じ、ヘッダーと実装を分離している。GUI と表示モデルは `native/gui/` に配置している。
- [x] ライブラリは Windows、Wine、OpenGL、SceneKit、ウィンドウ生成に依存せずリンクできる。
- [x] ファイルの場所は呼び出し側が指定し、CWD の変更・暗黙の Wine パス探索・既存データへの書き込みを行わない。
- [x] 計算状態と読み込んだデータはオブジェクトまたは戻り値が所有し、可変のプロセス共通状態に依存しない。
- [x] コアの実行時依存は C++ 標準ライブラリのみであり、既存の数式・形式を使用する理由を由来文書に示している。macOS フレームワークの依存は GUI 層に閉じている。

## 不合格条件

- [ ] UI コードや既存アプリのビルドを実行しないとコアをビルド・テストできない。
- [ ] 新規 API のために不要な Windows 互換層や外部ライブラリを導入している。

## 判定

YES

## 判定根拠（UNIT4 / 2026-10-29-21-28-30 JST）

判定条件 5 件を確認した。不合格条件は今回の対象に該当せず、未チェックのまま残した。対象・共通証拠・制約は [VALIDATION.md](VALIDATION.md) に記録する。

- **[core_architecture](../../policy_gates/core_architecture.md) C1–C5（5 件）**: `native/core` の C++17 header / source と `native/gui` の Objective-C++ を分離。core の静的ライブラリ・単体試験は標準ライブラリのみでリンク。既存 CF96 / Kepler / Trajectory / 座標変換を再利用し、各 satellite / spacecraft provenance に記録。パスは呼出側から渡し、データと評価状態はインスタンス内に所有。 新規 WebKit / CommonCrypto 利用は GUI 層に限る。Lua は既存 helper だけへ静的リンク。独立 core build / test の成功を上表で確認。
