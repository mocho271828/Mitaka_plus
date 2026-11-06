# 作業規則

- 作業計画・進捗・報告は日本語で記述する。
- 本番投入前の新規プロジェクトである。`IMPLEMENTATION_POLICY.md` と `policy_gates/` に従う。
- `vendor/mitaka` の実装はこのリポジトリの通常ファイルとして管理する。Mitaka 側の変更を取り込む際は由来を記録し、Plus のデータでビルド・テスト・実データ検証を行う。
- 同梱する天文データ・画像は原本の内容を保持し、読み取り専用で利用する。旧アプリ・Wine 環境の原本は保持し、生成物・認証情報は Git に登録しない。リポジトリの Private を維持する。
- 方針変更時は `IMPLEMENTATION_POLICY.md` と gate を更新する。検証コピーは `temp_gates/YYYY-MM-DD-HH-MM-SS/` に作り、チェックボックスと YES / NO を記入する。
- 完了時に Git 状態・変更ファイル・差分量を確認し、300 行以上なら原則 commit する。
- 完了報告には変更、Git 状態と commit、skill 実施可否、方針の更新、検証結果と未実施理由を含める。
