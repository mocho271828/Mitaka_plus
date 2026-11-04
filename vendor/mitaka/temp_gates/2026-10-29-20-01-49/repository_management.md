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

## 判定根拠

検証日: 2026-10-29 20:01 JST。条件番号はこのコピーの判定条件を上から数えたもの。

- 条件1・3: 変更先は Mitaka の native/ と文書であり、Mitaka_plus への実装複製はない。追跡済み *.jpg/*.png/*.dat/*.exe/*.app/*.o/*.a の検索は0件。未追跡の次単位コードは今回の判定対象外で、データ・Wine・生成物は登録しない。
- 条件2: 2026-10-29 に `gh repo view --json nameWithOwner,visibility` を読み取り実行し、mocho271828/Mitaka = PRIVATE を確認した。
- 条件4: `.gitattributes` の `/sources/official/** -text` と preservation の公式ZIP310件一致を確認。
- 条件5: `/tmp/mitaka-unit3-clean.5ljHod` の clone + staged 単位3 patch から core / GUI `all test` が成功。この clean は最終 window factory seam より前であり、後続の同じ object 内の seam と controller 試験は専用通常 / sanitizer / x86_64 strict build で確認した。最終全差分の clean 再実行と同一とは記載しない。
- 不合格条件は非該当。

共通の対象範囲・ログ・限界は [VALIDATION.md](VALIDATION.md) を参照する。不合格条件の未チェックは非該当を表す。
