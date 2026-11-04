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

## 検証根拠

単位7。private-repositories.jsonl、fresh clone core/GUI全試験、preservationの公式310ファイル照合、登録ファイルを確認。単位8と生成物はstage対象外。 不合格条件はいずれも該当なし。詳細は `investigation/native-plus/unit7/logs/integration/README.md` と同ディレクトリのログを参照。
