# UNIT4: About・主画面全画面の検証

検証日: 2026-10-29。原典の範囲と未確定事項は [ウィンドウ原典監査](../local-window-unit4-audit.md) を参照する。

## 実装の範囲

- `AppWindow.mm` のアプリメニューに About、ウィンドウメニューに主画面全画面の項目を追加した。全画面のキーは AppKit の Control + Command + F を使用する。
- `AppWindowCommands.mm` がデータモデルを必要としない操作を受け、主ウィンドウだけの delegate 通知を転送する。再生・時計追従・飛行へ停止操作を送らない。
- `WindowPresentationController` は実際の `NSWindowStyleMaskFullScreen` を getter に使い、要求の受付と非同期完了を区別する。同方向の処理中要求は再発行せず受け付け、反対方向の要求と toggle は拒否する。失敗で遷移中を解除し、close 後の遅延通知を無効化する。
- About は標準パネルを使い、名称・版は bundle の情報に任せる。Credits に非公式版の説明と、bundle に存在する `THIRD_PARTY_NOTICES.txt` / `LUA_LICENSE.txt` へのリンクを渡す。
- 新規外部依存・ファイル書込み・独自全画面アニメーション・製品側の完了待ち run loop は追加していない。原本データを変更していない。

## 試験結果

専用 `build-unit4-window`、`build-unit4-window-san`、`build-unit4-window-x86` を使用した。GUI 試験は他担当と調整し、構成ごとに逐次実行した。

| 構成 | 状態管理・About options | 実 OS 全画面移行・復帰 |
| --- | --- | --- |
| arm64 通常 | 31 checks、exit 0 | 5 checks、exit 0 |
| arm64 AddressSanitizer + UndefinedBehaviorSanitizer | 31 checks、exit 0 | 5 checks、exit 0 |
| x86_64（Apple Silicon 上） | 31 checks、exit 0 | 5 checks、exit 0 |

全構成を `-Wall -Wextra -Wpedantic -Werror` でビルドした。`AppWindow.mm` / `AppWindowCommands.mm` の通常構成 object ビルドと `git diff --check` も通過した。

状態管理試験では実状態 getter、受付後の未完了状態、同状態の冪等性、処理中の反対要求・toggle 拒否、成功・失敗・再試行、別ウィンドウ通知の除外、hidden / miniaturized / close 後の拒否を確認した。About options の試験は bundle の名称・版を上書きせず、同梱ライセンスの URL を利用することを確認した。

実 OS 試験は `make BUILD_DIR=<構成のディレクトリ> system-fullscreen-test` で明示的に実行した。実際の NSWindow に対して移行と復帰を要求し、各 12 秒の上限内で delegate 完了・実 style mask・失敗通知なしを検査した。通常の `controller-test` は決定的な状態管理試験のみを実行する。

ログ:

- `/tmp/mitaka-unit4-window-normal.log`
- `/tmp/mitaka-unit4-window-san.log`
- `/tmp/mitaka-unit4-window-x86.log`
- `/tmp/mitaka-unit4-window-system-normal.log`
- `/tmp/mitaka-unit4-window-system-san.log`
- `/tmp/mitaka-unit4-window-system-x86.log`
- `/tmp/mitaka-unit4-window-integration-compile.log`

## 統合で残る確認

本記録の実 OS 試験は独立したウィンドウを用いた。主アプリのメニュー・delegate 転送・Lua 連携、About パネルの実表示、全画面前後の天文状態・再生保持は統合試験側で別途記録する。ウィンドウ寸法・最小寸法・拡大の新 API は実装していない。旧 Plus の同期性や Windows の画面動作との完全一致を保証しない。

担当範囲の新規コード 4 ファイルは計 373 行、既存 `AppWindow.mm` は 13 行追加。Git 状態と差分量を確認した。統合担当が他機能・policy gate の検証とまとめて commit するため、この担当では stage / commit を行っていない。`/simplifier-lai` の実施可否と commit 前レビューも統合担当へ引き継ぐ。
