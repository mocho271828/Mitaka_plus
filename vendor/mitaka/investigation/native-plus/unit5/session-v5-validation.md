# 小天体・衛星・星座の保存状態

JSON v5 に導入された表示集合と軌道設定のデータ構造を示す。現行形式は JSON v9 で、v5 ファイルの読み込みはサポートしない。

| 型 | 保存内容 | ID と原本の照合 |
| --- | --- | --- |
| `SmallBodySessionDisplay` | master、3 種類の visible / labels / orbits / selected_only、表示集合、有限 TDB 区間と標本数 | source + 元 record ordinal。選択に使う各 source の読込済み bytes の SHA-256 とサイズを照合 |
| `SatelliteSessionDisplay` | 4 表示設定、表示集合 | source + 元 block ordinal。definition source の bytes を照合。別の orbit source の変更は body ID の変更として扱わない |
| `SpacecraftSessionDisplay` | master、points、labels、orbits | 探査機の個体別の集合は保存しない |
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
