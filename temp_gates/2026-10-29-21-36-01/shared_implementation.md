# Gate: 共通実装と依存関係

## 目的

Mitaka と Mitaka_plus の共通実装の分岐と、取得時の意図しないバージョン変更を防ぐ。

## 判定条件

- [x] `vendor/mitaka` は Git submodule であり、`.gitmodules` の URL が `https://github.com/mocho271828/Mitaka.git` である。
- [x] submodule の gitlink は Mitaka のリモートに存在するコミットを指す。
- [x] Plus に共通コア・GUI のソースを複製せず、Makefile は submodule の既存ターゲットへ委譲する。
- [x] 新たな依存を追加した場合、必要性と既存依存では不十分な理由を記録している。
- [x] README に現在の実装の由来と、旧 Mitaka_plus の公式ソースを含まないことを明記している。
- [x] Lua は共通実装の固定 SHA-256 と同じ公式ソースを使用し、helper へ静的リンクする。独自の Lua 処理系や外部 dylib の実行依存を追加しない。
- [x] 旧 Plus の互換状況は共通の機能対応表を参照し、未対応のある状態で全機能完了と記載していない。
- [x] HTML の Lua 呼出しを追加する場合、明示的に信頼したローカル HTML だけに許可し、オンライン文書・フレーム・遷移先から実行させない。
- [x] HTML の実行は同一読み取りの内容・ファイル識別・メインページ・表示世代を検証し、通常リンク操作やファイル変更で信頼を失効させる。ページ JavaScript・Flash を有効にしない。
- [x] 描画品質と衛星表示は共通状態モデル、全画面/About は共通ウィンドウ処理を使う。JSON v4 の保存範囲と旧開発版 v1/v2/v3 の拒否を記載し、全画面・HTML 信頼・実行状態を復元しない。

## 不合格条件

- [ ] 浮動するブランチの自動更新によって、記録した gitlink と異なる共通コードをビルドする。
- [ ] 共通実装を Plus にだけ複製・変更し、Mitaka 側との対応を失っている。

## 判定

YES

## 検証根拠

- `.gitmodules` の URL と `vendor/mitaka` の gitlink を確認。採用 SHA は `002adcf663fd5005e14ac86c343a3ec7e56fa706`。fetch 後の `origin/main` がこの commit を含み、submodule の `git status --porcelain` は空。
- Makefile は変更しておらず、既存の submodule ターゲットへ委譲する。今回の差分は gitlink・文書・検証記録のみ。共通実装の複製、新規依存はない。
- Lua 5.4.9 の固定 SHA-256、静的 helper は共通 Makefile をそのまま使う。共通側の WebKit / CommonCrypto も macOS 標準機能であり、ラッパー独自の処理系を追加しない。
- README は公式 Mitaka 1.3.1 由来、新規 native GUI、旧 Plus 公式ソース未収録、未対応機能を明記。共通 `PLUS_FEATURE_MATRIX.md` へ接続する。
- 信頼したローカル HTML の同一内容・識別・main frame・世代、通常リンクでの失効、ページ JavaScript / Flash 無効の契約は共通の `HtmlBrowserController` / `html_bridge_policy` を採用。共通単位4の HTML 試験・レビューを参照する。
- 描画品質、衛星表示、非同期全画面/About、JSON v4 と旧版拒否、信頼・実行状態の非永続化を README / 方針へ記載した。共通試験の範囲と制約は共通単位4 README を参照する。

詳細は [今回の検証記録](VALIDATION.md) と [リポジトリの記録](../../VALIDATION.md) を参照。
