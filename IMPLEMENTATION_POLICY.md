# 実装方針

## プロジェクト状態

- 確認日: 2026-10-29。
- ユーザー回答: **本番投入前の新規プロジェクト**。
- 対象は Mitaka の共通コア・GUI を使用する Mitaka_plus の開発入口。
- 共通実装は Private リポジトリ `mocho271828/Mitaka` に置き、`vendor/mitaka` の submodule でコミットを固定する。
- 不要な後方互換層や共通コードの複製は追加しない。
- ユーザーの指定により、ソース・文書・設定だけを GitHub に登録し、既存データ・画像・旧アプリはローカルで保持する。

## 方針の判定入口

1. [共通実装と依存関係](policy_gates/shared_implementation.md)
2. [データ保全と登録範囲](policy_gates/preservation.md)
3. [ビルド・検証・変更管理](policy_gates/verification.md)

変更はすべての gate を通過すること。
検証時は gate を `temp_gates/YYYY-MM-DD-HH-MM-SS/` にコピーし、コピーのチェックボックスと YES / NO 判定を記入する。
検証記録はリポジトリに保存し、既存データ本体は含めない。
共通実装を変更するときは、Mitaka リポジトリの `IMPLEMENTATION_POLICY.md` と各 gate も満たすこと。
