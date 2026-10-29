# 作業規則

- 作業計画・進捗・報告は日本語で記述する。
- 本番投入前の新規プロジェクトである。`IMPLEMENTATION_POLICY.md` と `policy_gates/` に従う。
- 共通コア・GUI は Mitaka 側で修正する。`vendor/mitaka` の未 commit 変更を Plus の commit だけで保存したと扱わない。
- 採用する共通コードは Mitaka に push 済みのコミットへ固定し、参照更新後にビルド・テスト・実データ検証を行う。
- 天文データ・画像・旧アプリ・Wine・生成物・認証情報は Git に登録しない。両リポジトリは Private を維持する。
- 方針変更時は `IMPLEMENTATION_POLICY.md` と gate を更新する。検証コピーは `temp_gates/YYYY-MM-DD-HH-MM-SS/` に作り、チェックボックスと YES / NO を記入する。
- 完了時に Git 状態・変更ファイル・差分量を確認し、300 行以上なら原則 commit する。
- commit 前に依存の妥当性と `/simplifier-lai` の利用可否を確認する。利用可能なら実行し、利用不可なら報告する。
- 完了報告には変更、Git 状態と commit、skill 実施可否、方針の更新、検証結果と未実施理由を含める。
