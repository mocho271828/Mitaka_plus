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

## 不合格条件

- [ ] 浮動するブランチの自動更新によって、記録した gitlink と異なる共通コードをビルドする。
- [ ] 共通実装を Plus にだけ複製・変更し、Mitaka 側との対応を失っている。

## 判定

YES

## 検証根拠

gitlink は origin/main に push 済みの cf4fcbfe5447adf554e5bca0b0caf5ae5f529505。共通ソースを複製せず、Makefile と依存は変更していない。README は未対応事項を共通機能表に結び、HTML 方針の追記を実装完了と区別している。

不合格条件の未チェックは該当なしを示す。詳細は [VALIDATION.md](VALIDATION.md) を参照。
