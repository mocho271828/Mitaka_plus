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

YES（単位2の commit 前検証。commit / push 自体は実施後判定待ち）。

## 根拠と確認範囲

追加は small_body_catalog / small_body_orbit と関連 parser に閉じ、C++17 標準ライブラリと既存 astronomy・読み込み制限・エラー型を使用する。core all test と ASan / UBSan は GUI を起動せず成功した。AVKit / AVFoundation、ImageIO と Lua は GUI / helper のみに置く。SMALL_BODY_PROVENANCE.md に採用した契約と未確定形式を記録した。

共通証跡は [単位2の検証記録](../../investigation/native-plus/unit2/README.md) と [判定対象](VALIDATION.md)。不合格条件は非該当のため未チェック。単位3の未 stage 変更は対象外。
