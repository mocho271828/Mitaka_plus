# UI-07: 同梱マニュアルの所在監査

確認日: 2026-11-07（JST）。対象はこの PC の `/Users/kota/playground/Mitaka_plus`。
基点は LUA-03 完了 commit `54f75fe3fd9198923f1e86a7fbd2802a5588c3f0`、作業ブランチは `codex/mitaka-manual-audit`。
別 PC の担当調整に従い、固定された同梱資料を開く範囲だけを確認した。

## 確認できたこと

- `resources/scripts/gui.lua:237–238` と `gui_jp.lua:237–238` は `mitaka_manual_J.pdf` と `mitakaPlus_script_J.chm` を `System:openDocument` へ渡す。
- 追跡対象の `resources/` 575ファイルには PDF・CHM・HTML/HTM 文書がない。実行に必要な既存データ・画像・スクリプトの収録と、マニュアルの収録は区別する。
- 既存の[UI/状態監査](../../vendor/mitaka/investigation/native-plus/local-ui-state-input-audit.md)と[ウィンドウ監査](../../vendor/mitaka/investigation/native-plus/local-window-unit4-audit.md)は、既定ビューアで開く点を記録している。相対パスの基準、欠損時、戻り値、macOSのCHM表示方法は未確定。
- `HtmlBrowserController` は明示して信頼したローカルHTMLにLua実行を許す機能であり、一般のマニュアル表示とは責務が異なる。マニュアルを開く経路に転用しない。

## 今回の結果

この checkout に対象の実資料がないため、マニュアルを開くUIは実装していない。不在を示すメニューだけを追加したり、存在しない固定パスを成功扱いしたりはしない。資料の追加取得・コピー・変換・再配布は行わない。任意パス/URLの `System.openDocument` は SEC-03 の信頼境界に関わるため、この単位には含めない。実資料と使用条件が確認できてから、固定文書の存在確認・既定ビューア起動・失敗表示を独立実装する。

検証は `git ls-files resources`、拡張子の一覧、元メニューの固定参照、既存監査とHTML controllerのコード読み取り。実文書表示、CHMアプリの互換性、旧Plus実機比較は資料がなく未実施。

本変更はこの監査・対応表のUI-07行・優先表・検証入口・gateコピーだけ。実装、依存、原本、Rust移行Markdown、権限・公開設定は変更しない。ビルド/テストは再実行せず、同じ実装で成功した親commitの[LUA-03検証](lua-console-validation.md)を継承する。既存方針の具体的な未確認事項を記録するもので、方針原本の変更はない。`/simplifier-lai` は同名skill不在で未実行。Markdownのリンク、Git差分、登録範囲を手動確認した。

Gate: `temp_gates/2026-11-07-03-14-14`。pushや他作業ブランチへの統合は行わない。
