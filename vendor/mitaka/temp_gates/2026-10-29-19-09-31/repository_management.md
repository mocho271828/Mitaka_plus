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

YES（単位2の commit 前検証。commit / push 自体は実施後判定待ち）。

## 根拠と確認範囲

共通実装は Mitaka/native に置き、Mitaka_plus に複製していない。主担当が gh repo view で両リポジトリの Private を確認済み。追跡ファイルにローカル天文データ・画像・旧アプリ・生成物を追加していない。公式原本の改行属性と ZIP 310 files の一致を確認した。final-clean は局所修正前の staged patch による新規 clone の core / GUI all test 成功である。後続の Camera / media clip / 任意媒体 assertion 修正は final2 strict build・sanitizer・controller・実アプリ smoke で確認した。最終全差分の clean clone 再実行はしていないため、その成功とは主張しない。

共通証跡は [単位2の検証記録](../../investigation/native-plus/unit2/README.md) と [判定対象](VALIDATION.md)。不合格条件は非該当のため未チェック。単位3の未 stage 変更は対象外。
