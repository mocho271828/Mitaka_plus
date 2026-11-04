# UNIT5: JSON v5 の表示状態保存

2026-10-29。基点は UNIT4 `002adcf663fd5005e14ac86c343a3ec7e56fa706`。本書は Session の実装と局所試験を記録し、全アプリの最終合否は [単位5の統合記録](README.md) で判定する。

## 保存する状態

既存の日時・カメラ・基本天体の選択・観測地・表示設定に次の型を追加した。

| 型 | 保存内容 | ID と原本の照合 |
| --- | --- | --- |
| `SmallBodySessionDisplay` | master、3 種類の visible / labels / orbits / selected_only、表示集合、有限 TDB 区間と標本数 | source + 元 record ordinal。選択に使う各 source の読込済み bytes の SHA-256 とサイズを照合 |
| `SatelliteSessionDisplay` | 4 表示設定、表示集合 | source + 元 block ordinal。definition source の bytes を照合。別の orbit source の変更は body ID の変更として扱わない |
| `SpacecraftSessionDisplay` | master、points、labels、orbits | 個体別の集合はこの単位では持たない |
| `ConstellationDisplayOptions` | lines、boundaries、labels、default_visible、例外集合 | raw 略号 ID の存在を照合。同じ ID の全図形に適用し、元ファイル全体の hash は要求しない |

表示集合は一時的なクリック選択と別である。恒星・小天体・衛星・探査機・深宇宙天体のクリック対象や HTML 信頼状態、全画面状態は保存しない。
本番投入前のため v1〜v4 の移行層は残さず、非対応 version として拒否する。旧 Plus の実行可能な Lua 状態形式との互換は主張しない。

## 入力境界

既存の 1 MiB 制限と Foundation JSON parser を使用する。bool は CFBoolean、数値は有限で bool ではない値に限定し、ordinal と byte count は 2^53−1 以下の整数とする。
raw source key と星座略号は canonical base64 で保存し、復号後は非空・最大 65,536 bytes・NUL なしを要求する。CP932 などの bytes を Unicode の正規化で変えない。
SHA-256 は 64 桁の小文字 hex、source 証明は選択 ID が参照する集合と完全一致し、重複・余剰・不足を拒否する。

hash はファイルを再読込せず、現在モデルが所有する原 bytes から macOS 標準 CommonCrypto で計算する。状態ファイルへ原本そのものを複製しない。
復帰は現在の表示モデルをコピーして ID と原本を照合する。星座 ID と全要求の軌道予算も検査し、失敗時に部分的な表示変更を行わない。native のカタログ再bindで消失 ID を報告して除去する契約と、外部 Session の未知 ID を全体拒否する契約を分ける。

`AppSessionCommands` は形状・日時・全表示集合・原本証明・星座 ID・軌道予算を検査してから、スクリプト停止と日時変更へ進む。成功後も再生・時計追従・連続飛行・Lua 実行を自動再開しない。
起動時の設定は全カタログ、snapshot、display model の接続後に同じ検証で復帰する。不一致なら保留状態と診断を残し、終了時の自動保存で無言に上書きしない。

## 実装と依存

`session_layers.hpp/.mm` が保存用の型と capture / prepare、`session_layers_json.h/.mm` が JSON 境界、既存 `session_state.mm` が全体の schema を担当する。App はこれらを通して表示 model の setter を利用する。
新しい外部依存は追加せず、C++17、既存表示 model、Foundation、CommonCrypto を再利用した。独自 JSON parser や SHA-256 実装は追加していない。
独立レビューでは source 証明、base64、未知・重複 ID、prepare copy、App の適用前検証と起動時順序を確認し、修正必須の指摘はなかった。

## 局所検証

| 試験 | 通常 | ASan+UBSan | Rosetta x86_64 |
| --- | ---: | ---: | ---: |
| `test_session_state` | 1,233 checks | 1,233 checks | 1,233 checks |
| `test_session_layers` | 31 checks | 31 checks | 31 checks |

専用 build は `build-unit5-session`、`build-unit5-session-san`、`build-unit5-session-x86`。ログは [logs/session](logs/session/) に保存する。正常往復、旧 version と不正型・範囲、raw bytes、ID 重複・未知、証明の余剰・欠落・変更、再bind後の照合を確認した。
通常ログの保存時に旧 `build/` の state test を一度指定し、旧 964 checks は成功したが同ディレクトリに layers test はなく exit 127 となった。この実行は v5 の成功根拠に含めず、専用 build で上表の 2 試験を再実行した。

新規 `AppSessionSmokeTests` は非既定の全表示群を JSON 往復し、未知 ID・原本 hash/size 不一致の拒否前後で状態が変わらないことを確認する。JSON 数値往復だけは既存衛星 smoke と共通の限定許容差を使い、bool・文字列・配列・キーは厳密比較する。不正状態の拒否前後は同一状態のため厳密比較する。
strict compile は完了した。全 App smoke の成功は統合担当が最終 tree で確認後に記録し、この局所テストだけでは判定しない。

正確な `/simplifier-lai` は利用不可であり、LobbyAI 限定の `simplify-lai` は代用しなかった。Git 状態・差分・300 行以上の commit と最終 policy gate は親担当が統合単位で確認する。
