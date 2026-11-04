# リポジトリ分離の独立レビュー

確認日: 2026-10-29。
対象は `repositories/Mitaka/` と `repositories/Mitaka_plus/` の登録予定ファイルと、新しい構成のビルド入口。
既存 native の実装や保全対象は変更していない。

## 結果

確認した範囲では、登録を止める不具合は見つからなかった。
GitHub の Private 状態、submodule の gitlink、push 後の clone とビルドは、親担当の最終検証で確認する。
本レビューはそれらを実行済みとして扱わない。

## 登録内容と保全

- レビュー時点の Mitaka は、Git 管理領域・ビルド生成物を除いて 527 ファイル。
- 最大ファイルは公式ソース ZIP の 905,545 bytes。
- 元の `sources/official/` の ZIP と展開後 310 ファイルを SHA-256 で比較し、差異は 0。
- `.gitattributes` の `text` 属性が、公式の Readme、C++ ソース、ZIP で `unset` であることを `git check-attr` で確認。
- 移行元の native 74 ファイルとの比較では、変更は README と PROVENANCE の 4 文書だけで、実装・ヘッダー・Makefile・テストは同一。
- `native/core/build/` と `native/gui/build/` は `git status --ignored` で除外を確認。
- 実データ・惑星画像・旧アプリ・Wine 環境のファイルは登録予定範囲に含まれない。
- 公式ソースに含まれる `.ico` と `.rc` は、元のソースアーカイブの構成要素であり、既存の惑星画像を追加したものではない。
- 登録予定ファイルに対する秘密鍵、代表的な GitHub / OpenAI / AWS キー形式の簡易スキャンで該当はなかった。

過去のログと結果 JSON はソースの調査・検証記録で、天文カタログ本体は含まない。
過去の絶対パスと Git 未初期化時の記述は `investigation/README.md` で履歴として説明されている。
非収録の baseline manifest・before スナップショット・画面画像への過去リンクについても、その説明と整合する。

## 共通実装の参照とビルド入口

Plus の Makefile は共通ソースを複製せず、`vendor/mitaka/native/core` と `vendor/mitaka/native/gui` の既存ターゲットを呼び出す。
GUI と Plus の入口では `DATA_ROOT` が `data` 自体を指し、コアの `data-test` を呼ぶ場合だけ親ディレクトリに変換する。
`CF96_DATA` は `DATA_ROOT/cf96.dat` として渡し、公式比較用ソースは共通側の既定 `UPSTREAM` を使用する。
パスはシェルで引用されており、既存アプリの `Program Files` を含むパスを扱える。

submodule 未取得時とデータ指定不足時には、Makefile が案内付きで停止する。
README は Private な 2 リポジトリへの読み取り権限、再帰 clone、コミット固定、採用コミットの更新手順を説明している。
旧 Mitaka_plus の公式 C/C++ ソースを含むとは主張せず、現在の共通 GUI を使用することを明記している。

## 依存と品質確認

新たな実行時依存や独自のビルド基盤は追加していない。
既存の Make、Git submodule、Apple Clang、AppKit と macOS 標準フレームワークを使用する。
共通コードの再実装や不要な互換層は追加されていない。

正確な名前の `/simplifier-lai` は利用できず、本レビューでは実行していない。
類似名 `simplify-lai` は非 LobbyAI プロジェクトを対象外としているため適用しない。
