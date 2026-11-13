# Aboutパネルと全画面切り替え

主ウィンドウの全画面状態は OS から通知される。Lua による要求の受付と非同期遷移の完了を区別する。

- `AppWindow.mm` のアプリメニューに About、ウィンドウメニューに主画面全画面の項目を追加した。全画面のキーは AppKit の Control + Command + F を使用する。
- `AppWindowCommands.mm` がデータモデルを必要としない操作を受け、主ウィンドウだけの delegate 通知を転送する。再生・時計追従・飛行へ停止操作を送らない。
- `WindowPresentationController` は実際の `NSWindowStyleMaskFullScreen` を getter に使い、要求の受付と非同期完了を区別する。同方向の処理中要求は再発行せず受け付け、反対方向の要求と toggle は拒否する。失敗で遷移中を解除し、close 後の遅延通知を無効化する。
- About は標準パネルを使い、名称・版は bundle の情報に任せる。Credits に非公式版の説明と、bundle に存在する `THIRD_PARTY_NOTICES.txt` / `LUA_LICENSE.txt` へのリンクを渡す。

| 構成 | 状態管理・About options | 実 OS 全画面移行・復帰 |
| --- | --- | --- |
| arm64 通常 | 31 checks、exit 0 | 5 checks、exit 0 |
| arm64 AddressSanitizer + UndefinedBehaviorSanitizer | 31 checks、exit 0 | 5 checks、exit 0 |
| x86_64（Apple Silicon 上） | 31 checks、exit 0 | 5 checks、exit 0 |
