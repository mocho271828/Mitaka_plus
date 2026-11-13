# UI-07: 同梱マニュアルの所在監査

2026-11-07 時点の同梱資料を確認した。

## 確認できたこと

- `resources/scripts/gui.lua:237–238` と `gui_jp.lua:237–238` は `mitaka_manual_J.pdf` と `mitakaPlus_script_J.chm` を `System:openDocument` へ渡す。
- 追跡対象の `resources/` 575ファイルには PDF・CHM・HTML/HTM 文書がない。実行に必要な既存データ・画像・スクリプトの収録と、マニュアルの収録は区別する。
- 既存の[UI/状態監査](../../vendor/mitaka/investigation/native-plus/local-ui-state-input-audit.md)と[ウィンドウ監査](../../vendor/mitaka/investigation/native-plus/local-window-unit4-audit.md)は、既定ビューアで開く点を記録している。相対パスの基準、欠損時、戻り値、macOSのCHM表示方法は未確定。
- `HtmlBrowserController` は明示して信頼したローカルHTMLにLua実行を許す機能であり、一般のマニュアル表示とは責務が異なる。マニュアルを開く経路に転用しない。

## 今回の結果

この checkout に対象の実資料がないため、マニュアルを開くUIは実装していない。不在を示すメニューだけを追加したり、存在しない固定パスを成功扱いしたりはしない。資料の追加取得・コピー・変換・再配布は行わない。任意パス/URLの `System.openDocument` は SEC-03 の信頼境界に関わるため、この単位には含めない。実資料と使用条件が確認できてから、固定文書の存在確認・既定ビューア起動・失敗表示を独立実装する。

検証は `git ls-files resources`、拡張子の一覧、元メニューの固定参照、既存監査とHTML controllerのコード読み取り。実文書表示、CHMアプリの互換性、旧Plus実機比較は資料がなく未実施。
