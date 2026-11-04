# UNIT6 最終 policy gate 検証

判定日時: 2026-10-30-00-13-19 JST。14 gate の判定条件 **161 / 161** を YES、不合格条件 50 件は該当なしと判定した。テンプレートをコピーして本ディレクトリのチェックボックスを記入した。対象は地平背景・観測地点の読込規則・雲/夜景・CAB 星座絵・恒星名集合・明るさ・大気と JSON v6 の接続であり、旧 Plus の全機能完了を意味しない。

基点 HEAD は `5dd3409f8c551ff94666d84f4504f6f92f7047c7`。主担当と各担当の独立読取レビュー、原典契約、局所・統合実行証跡を照合した。[条件別根拠](../../investigation/native-plus/unit6/gate-evidence.md) と [UNIT6 README](../../investigation/native-plus/unit6/README.md) に対象と制限を残した。

| Gate | 条件 | 判定 |
| --- | --- | --- |
| [continuous_flight](continuous_flight.md) | 12 / 12 | YES |
| [core_architecture](core_architecture.md) | 6 / 6 | YES |
| [data_contracts](data_contracts.md) | 6 / 6 | YES |
| [local_plus_assets](local_plus_assets.md) | 20 / 20 | YES |
| [moon_surface_navigation](moon_surface_navigation.md) | 9 / 9 | YES |
| [native_gui](native_gui.md) | 17 / 17 | YES |
| [planet_rotation](planet_rotation.md) | 10 / 10 | YES |
| [planet_textures](planet_textures.md) | 13 / 13 | YES |
| [plus_compatibility](plus_compatibility.md) | 23 / 23 | YES |
| [preservation](preservation.md) | 7 / 7 | YES |
| [repository_management](repository_management.md) | 5 / 5 | YES |
| [solar_view](solar_view.md) | 7 / 7 | YES |
| [time_playback](time_playback.md) | 20 / 20 | YES |
| [verification](verification.md) | 6 / 6 | YES |

## 実行と記録

- core / GUI 全 test、Lua を含む controller は通常・ASan/UBSan・Rosetta x86_64 の各構成で成功。Plus の full smoke は各3構成、通常版は通常構成で成功した。
- Plus / 通常版の実データ、CF96 5,427、自転 33,129、月 12,108 の公式比較を確認。最初の CF96_DATA 指定漏れと smoke fixture の旧項目数による失敗は、修正後と別ログで保持する。
- 新規 local clone の core / GUI all test が成功。92 native build/source ファイルは tested clone と byte 一致し、その後の atmosphere 2ファイルの変更は冒頭ライセンスコメントの CRLF→LF のみ。実行文の bytes は一致する。
- 保存ログの SHA-256 は189件一致。初回の照合スクリプトは2 manifest の repo-relative path を誤って manifest-relative と扱って失敗し、正しい基準で再照合した。ログ内容の変更・再生成では解決していない。
- 原本16,365 files / 6,622,642,667 bytes / 465 symlinks の追加・削除・変更0、公式ZIP310ファイル一致。source / wrapper 両方 Private。
- Intel実機、macOS13実機、複数画面、実OS完全遮蔽通知、旧Plus全画素一致は未確認。食・地形・銀河3D等の UNIT7 新規ファイルは stage 対象から除外した。

## 依存・方針・Git

新規外部依存なし。既存 C++17、AppKit/Core Graphics/ImageIO/Foundation と Lua helper を再利用し、天文計算を core、表示と状態を GUI に配置した。IMPLEMENTATION_POLICY と対応 gate を更新済み。正確な `/simplifier-lai` は利用できず未実行、類似 skill は LobbyAI 専用のため適用しない。独立レビューで境界・再利用・失敗時状態保持を点検した。

staged native は99 files、+5,875 / −293。native patch SHA-256 は `c3a1d4cef3f0e90aded5784418a459288d6dff0c66cf350c5c332e4b438ed079`。原文の改行・行末空白を保つ監査ログ2件だけ .gitattributes で whitespace 検査を除外し、派生ソースのコメントはLFへ整えた。`git diff --cached --check` とローカル文書リンク148件を確認済み。Git状態・変更ファイル・差分量を確認し、300行以上のためこの単位を commit / push する。最終 commit 完了と wrapper 採用は後続で記録する。
