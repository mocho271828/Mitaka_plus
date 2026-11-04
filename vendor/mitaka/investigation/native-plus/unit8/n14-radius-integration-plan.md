# N14: 即時表示半径設定の統合範囲

## 実装済みの境界

`radius_display.hpp/.cpp` は4倍率と2つの表示文脈を扱う純モデルである。`RadiusDisplayController.h/.mm` はこの検証を使う設定画面を提供する。App が状態を所有し、UI、Lua、session、renderer に接続する。旧版の公開 API と演算式の根拠は 同梱元 Mitaka の `investigation/native-plus/unit8/n14-radius-display-contracts.md` に分けた。

今回の設定画面は既存の AppKit controller と同じ `NSWindowController`、`NSStackView`、`NSTextField`、`NSPopUpButton`、Dark Aqua を使用する。4値を個別に適用する操作は設けず、まとめて検証して1回の callback へ渡す。データ原本を書き換えない。画面を開くまで `NSWindow` を生成しない。

## App が所有する状態と callback

App は `RadiusDisplayOptions` と `RadiusScaleMode` の現在値を所有する。controller は次の2つの block で接続する。

```objc
BOOL (^readSettings)(RadiusDisplayOptions *options,
    RadiusScaleMode *mode, NSString **error);
BOOL (^applySettings)(RadiusDisplayOptions options,
    RadiusScaleMode mode, NSString **error);
```

どちらも main thread で呼び、`NO` は理由を `error` へ返す。`applySettings` が `NO` を返すときは、倍率・mode・カメラ・追従・飛行を変更しない。controller はホストの拒否を成功へ置き換えず、カメラ補正を独自に代行しない。適用中に再入した apply/reload は callback を呼ばず拒否する。

`reloadSettingsWithError:` は毎回 callback を読み、4値と mode を検証する。`applyFieldValues:mode:error:` は4個の数値文字列と mode を全体検証してから一度だけ apply callback を呼ぶ。主スレッド制約と入力検証は窓なしでも利用できる。画面の「適用」が成功した後は live 値を再読込する。適用後の再読込だけ失敗した場合は、既に適用済みであることと読込失敗を区別して表示する。

UI は入力を128文字以内に制限し、既存 `SmallBodyController` と同じ Foundation `NSScanner` / `en_US_POSIX` / 全体消費を使う。正の有限 float に変換できない値、0へ丸まる値、桁区切り、余分な文字、未知 mode は拒否する。最大 float は表示の丸めで範囲外にならないよう、double に拡張した値を17桁で往復させる。原版の無検証入力受入れとは異なる native 境界である。

## 接続範囲

| 層 | 接点と制限 |
| --- | --- |
| App / UI | main thread で共通の設定を取得・全体検証・適用。未読込や終了中は理由付きで拒否 |
| Lua | `Planets:setScale(a,b,c,d)` / `getScale()`、`Planets.scaleMode`、`setScaleMode(value)` / `getScaleMode()`。厳密な数値と mode を検証し、ホストの拒否を Lua エラーにする |
| Session | JSON v9 の必須 `radius_display` に4倍率と `mode` を保存。全体検証後に保存済み camera を変更せず復元。旧開発版 v1〜v8 は変換せず拒否 |
| Renderer | 太陽系通常表示と全天図・地平図の模式表示に倍率を反映。天球図の選択リングも円に合わせ、クリック判定は既存の近傍選択を優先し、該当なしの場合に拡大円を使う |

アプリ設定も同じ検証を使い、v9 は独立した UserDefaults キーに保存する。旧キーを上書きせず、v9 の読込失敗時も終了時の自動上書きを抑止する。`setScaleTo` は倍率補間とカメラ補間の順序が未確定のため未対応。

## 物理値と表示値の受け渡し

4値順は実行版どおり `space_planet, space_sun, planetarium_planet, planetarium_sun_moon` とする。同梱 HTML の引数名に自動で並び替えない。

惑星の response は現在 1 を暫定使用し、原出典から取得した値として扱わない。旧 parser の省略時も 1 と確認したが、英語と日本語の木星 response は異なる。将来の出典接続では source を明示し、未知・重複・不正な定義を成功扱いせず、原データを書き換えない。

`surface_body_info` の半径、暦表の位置、着陸高度、食や大気の計算へ表示倍率を上書きしない。Solar renderer では描画用の中心・半径を別に用意する。Moon の表示軌道倍率は float の exact-1 分岐を含み、月の表示半径だけ変更して旧版と同じ位置・角度になるとは扱わない。`Body` enum と Solar 配列の順も一致しないため、配列添字を型へ直接 cast しない。

Sky/Horizon の模式円は物理角直径を再現しない。太陽系の地表・飛行・地球月の物理球、地形・大気・食の物理幾何には適用しない。月の模式位置が物理位置と異なる場合は中心不一致を避けるため物理位置で計算した月面の食の影を表示しない。食円錐と遮蔽物は物理位置のままである。旧 Plus の画素一致は未対応である。

## KEEP_RADIUS の未解決境界

旧即時 setter は倍率変更前に guard を検査し、宇宙空間の太陽/惑星だけ mode 0 で距離補正を行う。mode 1 はその補正を省く。この違いを mode の保存だけで実装したことにしない。

カメラ guard と native の追従・地表・飛行との対応が未確定のため、ホストは `KEEP_RADIUS` で宇宙惑星または太陽倍率の変更を要求された場合、現在の視点にかかわらず理由付きで拒否する。mode の切替と天球側だけの倍率変更は許す。拒否時は倍率・mode・カメラ・追従・飛行を変更しない。将来補正を接続する際は候補 camera と全表示値を先に検証し、一括適用する。

## 検証と残件

controller は通常・ASan/UBSan・x86_64 の厳格 compile と窓なし試験が **各150 checks、exit 0**。4値順、全項目の異常値、float の両端、mode、callback 不在、host 拒否、live 読込、再入、別 thread からの拒否を検証した。ログとコマンドは 同梱元 Mitaka の `investigation/native-plus/unit8/logs/n14-controller/COMMANDS.md` に保存した。純モデルの各221 checks は別の既存証跡を参照する。

上記 controller の局所試験では窓を開いていない。実ウィンドウ・App・Lua・session・描画の統合検証は別途結果を記録する。新規依存なし。AppKit/Foundation と既存の純モデルを使用する。
