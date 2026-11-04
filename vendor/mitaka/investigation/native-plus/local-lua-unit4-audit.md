# 描画品質と次の Lua 接続候補

調査日: 2026-10-29。調査時の HEAD は `ae300e1`。第 3 単位の統合試験中に、次の接続候補を読み取り専用で確認した。この文書の追加以外に、第 4 単位の製品コードは変更していない。

原典は `/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka`（以下 `PLUS`）。対象は Plus 1.5.4 build101013、同梱 API 文書の表示は 1.3.0。HTML の行番号は CP932 から読み取った原本の行番号を指す。旧アプリの実行結果は今回確認していない。

## 先に接続できる描画品質の 4 項目

`PLUS/doc/script_jp/renderer.html:12–42` は次のプロパティとメソッドを定義する。プロパティは boolean の取得・設定、toggle は引数なしで対応する値を反転する。toggle の戻り値は原典に記載がない。

| 公開名 | メソッド | 原典行 | ネイティブ値 |
| --- | --- | --- | --- |
| `Renderer.antialias` | `Renderer:toggleAntialias()` | 12–18 | `RendererDisplayOptions.antialias` |
| `Renderer.pointSmooth` | `Renderer:togglePointSmooth()` | 20–26 | `point_smoothing` |
| `Renderer.lineSmooth` | `Renderer:toggleLineSmooth()` | 28–34 | `line_smoothing` |
| `Renderer.textSmooth` | `Renderer:toggleTextSmooth()` | 36–42 | `text_smoothing` |

原典は品質と描画速度の関係を説明するが、既定値、全体設定と個別設定の優先順位、サンプル数、点の形状、画素の一致条件を定義していない。新しい [renderer_options.hpp](../../native/gui/include/renderer_options.hpp) は既定値をすべて true とし、点・線・文字の実効設定を全体 AA と個別設定の AND にする。この規則はネイティブ版の契約として説明する。

[RendererQuality.h](../../native/gui/include/RendererQuality.h) の helper は CoreGraphics の graphics state を保存・復元し、`ShouldAntialias`、文字では `ShouldSmoothFonts` も設定する。graphics state の外にある `Allows*` は変更しない。文字 smoothing は出力 context に依存し、CPU 画像内部の輪郭や画像補間まで変更しない。根拠と helper の検証結果は [local-renderer-stereo-audit.md](local-renderer-stereo-audit.md) に記録済み。

Lua 接続は第 3 単位の表示フラグと同じ構造を使える。以下は接続案であり、調査時点では未実装。

1. `ScriptSnapshot` に `RendererDisplayOptions` を持たせ、host が現在の共通設定を返す。
2. `ScriptActionKind` に 4 個の設定操作を追加し、`ScriptWorker` の `BooleanBinding` で上表だけを登録する。
3. AppController の共通 getter / setter を通し、ビュー、メニュー、保存状態と同じ値へ反映する。メソッド名は `rendererDisplayOptions` / `setRendererDisplayOptions:` を統合担当へ提案済み。
4. Getter と toggle は毎回 snapshot を読み、GUI 操作後の値を反映する。Lua の数値や文字列を boolean に暗黙変換しない。失敗した host 操作を成功扱いにしない。

品質 helper だけが存在する段階では、Lua から設定値だけを変更して実装完了としない。全ビューの描画群への接続と、その値を引き継ぐ静止画・投影出力を統合担当と確認する。

### 名前を追加しない範囲

`PLUS/scripts/option.lua:16–18` は `MitakaRenderer.pointSmooth=false`、`lineSmooth=true`、`textSmooth=false` を記録する。`MitakaRenderer` と文書の `Renderer` の同一性は未確定であり、保存済みの値から製品既定値も判断できない。alias は今回の候補に含めない。

`Renderer.interactive`、`frame`、`render()` は `renderer.html:44–68` に別の再描画契約を持つ。特に `interactive=false` は `render()` まで自動再描画を抑止し、`frame` は次回描画番号を表す。現在の AppKit 再描画や画像保存をそのまま代用できない。`renderToFile()` / `captureToFile()` は 70–75 行で Pro only。`stereoType` は名前が確定していても左右カメラの幾何が未確定なので、今回の品質設定へ含めない。

### 接続時の回帰条件

- 4 プロパティの true / false、各 toggle、GUI 側変更後の get / toggle を controller 試験で確認する。
- 数値・文字列・nil の代入、toggle への余分な引数、未知 API は失敗し、host の値を保持する。
- host 拒否時のエラーを Lua へ返す。既存の unsupported API が登録の副作用で成功しないことを確認する。
- GUI smoke では全ビューの値と保存・復元後の値を照合する。点・線・文字の画素差と graphics state 復元は helper の既存試験を再利用する。

## 恒星ラベル用の複数選択

`PLUS/doc/script_jp/stars.html:28–35,88–99` は以下を定義する。

| 公開名 | 引数・値 | 確定している意味 |
| --- | --- | --- |
| `Stars.selectedLabels` | boolean | `Stars.labels=true` のとき、一部のラベルだけを表示する |
| `Stars:toggleSelectedLabels()` | 引数なし | 上のフラグを反転する |
| `Stars:select(...)` | HIP 番号の空白区切りリスト文字列 | ラベル表示の対象となる恒星をリストで指定する |
| `Stars:deselect(...)` | HIP 番号の空白区切りリスト文字列 | ラベル対象から指定した恒星を外す |
| `Stars:isSelected(...)` | HIP 番号文字列 1 個 | 両フラグが有効な場合にラベル表示される対象なら true を返す |

`PLUS/scripts/gui.lua:143` は `Selected Proper Names Only` と表示し、`screenmenu.lua:67` にも同じ操作がある。固有名のラベル対象を制御する候補として根拠があり、Bayer / Flamsteed / HIP 番号へ一括適用する根拠にはしない。

現在の `SkyView` / `HorizonView` の `selectStarHIP:` は一つの観測対象を選び、その星を見せるため等級上限も変える。ラベル集合を持たず、Lua の `Stars:select` には使えない。`SkyModel::star_index` による HIP 照合と、`StarRenderer` の固有名描画は再利用できる。

次の実装には、表示設定と独立した HIP 集合、原本の全恒星を保持する参照方法、複数ビューへの反映が必要になる。未知 HIP、空文字列、重複番号、不正トークン、複数回の `select` が追加か置換か、`isSelected` がフラグ無効時に返す値は、原典の説明だけでは確定しない。これらを旧仕様として推測せず、追加根拠または明示したネイティブ契約が必要である。入力全体を検証してから反映し、後半の不正番号で前半だけ更新される状態は避ける。

96 行の見出しは `isSelected`、98 行の例は `isSelect` と異なる。例の綴りを alias として追加しない。

## 恒星の明るさ

`PLUS/doc/script_jp/stars.html:68–87` で次の範囲が確定する。

| 公開名 | 引数・値 | 確定している意味 |
| --- | --- | --- |
| `Stars.brightness` | 実数 | 恒星の輝度。1.0 が標準 |
| `Stars:defaultBrightness()` | 引数なし | 標準の輝度へ戻す |
| `Stars:brighten()` / `darken()` | 引数なし | 輝度を上げる / 下げる |
| `Stars:setBrightnessTo(brightness, dur)` | 実数 2 個 | `dur` 秒で輝度をアニメーションさせる |

`PLUS/scripts/gui.lua:153–155` と `screenmenu.lua:71–73` に増減・標準へ戻す操作がある。原典は増減幅、許容範囲、負値、ゼロ、補間式、実行中の再設定を定義していない。72 行のメソッド見出しは `setBrightnessTo`、74 行の例は `setBrightness` なので、後者を追加の API と認定しない。

現在の `StarRenderer` は等級から点の半径と alpha を求め、`magnitudeLimit` で描画対象を選ぶ。独立した輝度倍率はない。`brightness` を等級上限へ写すと、星の数や選択結果まで変えてしまう。プロパティと `defaultBrightness()` は、ネイティブ描画に輝度設定を導入すれば次の候補になる。ただし線形輝度・alpha・点径のどこへ作用させるかを原版と同一と断定しない。`brighten/darken` とアニメーションは追加の仕様確認を要する。

## 時刻と個別ターゲットの注意点

`NextTime`、`nextTime`、`next_time` の名前は、今回 `PLUS/doc` と `PLUS/scripts` の Lua / HTML / TXT を検索しても見つからなかった。確認できる関連名は `Time:nextStep()`（`time.html:85–88`）であり、これは時刻を進める操作ではなく、次の規定ステップを選ぶ操作である。時刻を 1 単位進める操作は `Time:forward()`（89–91 行）。

既存 worker の `prevStep/nextStep` は 10 秒から 1 週間までの固定単位を扱う。ネイティブ GUI は [calendar_time.hpp](../../native/gui/include/calendar_time.hpp) に月・年・10 年・100 年の単発移動を持つが、Lua の `speed=1` は 1 実秒につき 1 ステップを意味するため、月・年の連続進行方法を決めずに定数だけを追加しない。固定 UTC offset を旧 `localTime` と同じと説明することも避ける。残る時刻契約は [local-time-audit.md](local-time-audit.md) に記録済み。

`abouttargets.html:12–14,38–40` は `Camera.target` を宇宙空間の中心天体または着陸先とし、`Star.<HIP番号>` と固有英語名を許容する。ネイティブ全天図の単一選択だけを変更しても、このカメラ契約を満たさない。星の 3D 位置・距離とカメラ移動の対応が必要であり、ラベル用 `Stars:select` とも別に扱う。固有名の大小文字や重複名を推測で統合しない。

## 次の作業単位の優先順位

1. Renderer の 4 個の boolean と各 toggle。公開名・型・意味が確定し、ネイティブ helper もある。実描画と共通設定の接続を完了してから公開する。
2. 恒星の固有名ラベル集合。GUI の操作目的まで確定しているが、集合操作の境界条件を先に決める必要がある。
3. 恒星輝度のプロパティと標準値への復帰。描画側の独立設定が前提で、増減幅・アニメーションは同じ単位に混ぜない。
4. 月・年の Lua 時刻操作、恒星等の `Camera.target`。既存 native 機能の一部を利用できるが、連続速度・3D 視点との対応が未確定。

今回の成果物は本監査文書のみで、依存・公開 API・方針 gate を変更していない。原典の読取と既存コード照合を行い、新しい実行試験は行っていない。第 3 単位の controller 試験と独立レビューは [local-lua-next-audit.md](local-lua-next-audit.md) を参照する。
