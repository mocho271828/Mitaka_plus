# 作業規則

- 作業計画・進捗・報告は日本語で記述する。
- 本番投入前の新規プロジェクトである。このディレクトリは Plus の同梱コピーであり、判断入口は Plus ルートの `IMPLEMENTATION_POLICY.md` と `policy_gates/`。このディレクトリ内の方針・gate は移行前の記録として保持する。
- コアと GUI の変更は `native/` に行い、公式原本 `sources/official/` は編集しない。
- Plus の `resources/` に収録したデータ・画像を読み取り専用で利用し、元のアプリとデータも保全する。
- このディレクトリは Plus に追跡された通常ファイルであり、Mitaka 側の更新は自動では反映されない。
- GitHub の可視性は Private を維持する。
- リポジトリ全体の方針を変更する場合は `IMPLEMENTATION_POLICY.md` と対応 gate を更新する。
- gate 検証は `temp_gates/YYYY-MM-DD-HH-MM-SS/` にコピーし、条件のチェックボックスと YES / NO を記入する。
- 完了時に Git 状態・変更ファイル・差分量を確認する。300 行以上なら原則 commit する。
- commit 前に既存依存の利用と不要な独自実装を確認し、`/simplifier-lai` が利用可能なら実行する。利用不可は commit を妨げないが報告する。
- 完了報告には変更、Git 状態と commit、skill 実施可否、方針の更新、検証結果と未実施理由を含める。
