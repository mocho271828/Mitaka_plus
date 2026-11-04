# Gate: リポジトリ分離と登録範囲

## 目的

共通実装の重複と、ローカルデータ・旧環境の意図しない登録を防ぐ。

## 判定条件

- [x] 共通コアと GUI の変更先は Mitaka の `native/` であり、Mitaka_plus に複製していない。
- [x] GitHub リポジトリの可視性は Private である。
- [x] Git の追跡対象はソース・文書・設定・公式ソース原本であり、天文データ・表面画像・旧アプリ・Wine 環境・生成物を含まない。
- [x] 公式ソースは `.gitattributes` で改行変換を無効にし、ZIP と展開原本の一致を確認している。
- [x] 新規 clone からビルドと単体テストを実行でき、ローカルデータは明示的なパスで参照する。

## 不合格条件

- [ ] 許可なくリポジトリを Public にする、またはローカルデータ・認証情報を登録する。
- [ ] 共通実装を Mitaka_plus へコピーして並行保守する。

## 判定

YES

## 判定根拠（UNIT4 / 2026-10-29-21-28-30 JST）

判定条件 5 件を確認した。不合格条件は今回の対象に該当せず、未チェックのまま残した。対象・共通証拠・制約は [VALIDATION.md](VALIDATION.md) に記録する。

- **[repository_management](../../policy_gates/repository_management.md) C1、C3–C4（3 件）**: 共通実装は `Mitaka/native`。staged 対象はソース・文書・設定で、元のデータ・画像・旧アプリ・生成物を含まない。公式ソースは `.gitattributes` の `/sources/official/** -text` と ZIP 照合で保持。 UNIT5 の未追跡ファイルと wrapper の採用準備を、この UNIT4 index に含めない。
- **repository_management C2、C5（2 件）**: 主担当が `gh repo view --json visibility,nameWithOwner` により `PRIVATE` を最終確認し、[結果](../../investigation/native-plus/unit4/logs/mitaka-unit4-private-final.log) を保存。新規 local clone と明示パスによる実データ参照を clone / data / reference 試験で確認。 新規 clone に timer fixture 修正を含む staged patch を適用し core / GUI `all test` が成功。修正前の index export と別のログで記録している。
