# Gate: コアの境界と依存関係

## 目的

天文計算とデータ読み込みを macOS の UI・描画・Wine から独立して利用できるようにする。

## 判定条件

- [x] 天文計算とローダーは `native/core/` の C++17 ライブラリに閉じ、ヘッダーと実装を分離している。GUI と表示モデルは `native/gui/` に配置している。
  - 判定根拠: 確認。unit7/README.md の core/GUI 独立テストおよび Makefile と現差分の配置を確認。今回の小天体計算も core にある。
- [x] ライブラリは Windows、Wine、OpenGL、SceneKit、ウィンドウ生成に依存せずリンクできる。
  - 判定根拠: 確認。unit7/README.md の独立 core test 成功記録。今回の P1-4 core evaluator/sampler も単独で成功。
- [x] ファイルの場所は呼び出し側が指定し、CWD の変更・暗黙の Wine パス探索・既存データへの書き込みを行わない。
  - 判定根拠: 確認。unit7/README.md と TERRAIN_PROVENANCE.md の明示パス・原本保全の記録。P1-4 は新規ファイル入出力を追加しない。
- [x] 計算状態と読み込んだデータはオブジェクトまたは戻り値が所有し、可変のプロセス共通状態に依存しない。
  - 判定根拠: 旧 gate vendor/mitaka/temp_gates/2026-10-30-02-00-26/core_architecture.md の同一条件を再利用し、P1 の core 追加箇所の所有と static 宣言を確認。
- [x] コアの実行時依存は C++ 標準ライブラリのみであり、既存の数式・形式を使用する理由を由来文書に示している。macOS フレームワークの依存は GUI 層に閉じている。
  - 判定根拠: 確認。unit6/README.md と unit7/README.md は C++17 と既存標準 framework を明記。P1-4 の evaluator/sampler に新規依存なし。
- [x] 大気の単一・多重散乱は公式 scalar 式とローカル emmap の由来、m 単位の幾何・密度・強度を明示し、原 bytes と診断を保持する。公式参照との数値比較と、地表・退化入力・無効 map の試験を記録し、旧 Plus の GL 描画との画素一致と区別する。
  - 判定根拠: 確認。native/core/ATMOSPHERE_PROVENANCE.md と tests/test_atmosphere.cpp、test_atmosphere_upstream.cpp に出典・比較・異常系・画素一致の制限が記録されている。

## 不合格条件

- [ ] UI コードや既存アプリのビルドを実行しないとコアをビルド・テストできない。
  - 判定根拠: 該当を確認していない。非該当と断定するための全経路監査も未完了。
- [ ] 新規 API のために不要な Windows 互換層や外部ライブラリを導入している。
  - 判定根拠: 該当を確認していない。非該当と断定するための全経路監査も未完了。

## 判定

YES（既存検証記録と変更箇所の確認を根拠とする。未実施の確認は成功扱いしない。）
