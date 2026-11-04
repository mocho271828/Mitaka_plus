# 旧Plus Lua API と既存ネイティブ機能の接続調査

調査日: 2026-10-29。対象は第1実装単位の作業ツリー（調査開始時 HEAD `94c9af3`）。この記録は次単位の接続候補を示すもので、記載された未接続 API の実装完了を意味しない。

## 根拠と表記

原典は、手元の `mitaka_plus` に同梱された日本語スクリプトマニュアルと Lua ファイル。原本を変更せず、HTML は Windows-31J から UTF-8 へメモリ上で変換して読んだ。本文の参照は次の基準ディレクトリからのファイル名と行番号を示す。

- `D`: [doc/script_jp](</Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/doc/script_jp>)。
- `L`: [scripts](</Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/scripts>)。
- ネイティブ側: [ScriptWorker.mm](../../native/gui/src/ScriptWorker.mm)、[AppScripting.mm](../../native/gui/src/AppScripting.mm)、[ScriptController.h](../../native/gui/include/ScriptController.h)、[SCRIPTING.md](../../native/gui/SCRIPTING.md)。

マニュアルは古い版の記述を含み、同梱 GUI スクリプトにはマニュアル未掲載の API がある。「マニュアルで契約を確認」「同梱スクリプトで使用を確認」「意味・引数が未確定」を区別する。通常版 Mitaka の C++ ソースを、Plus の Lua バインディングの証拠として代用しない。

下表の `boolean` / `number` / `integer` / `string` は旧資料の型に対応する。`integer` は整数値という契約であり、Lua 5.4 固有の整数型を旧 Lua に遡って要求する意味ではない。メソッドは原則コロン呼出しで記す。戻り値の記載がないメソッドは **未記載** とし、成功 `true` を返すなどの仕様を推測しない。プロパティは値の型を示す。定数の数値は原典に記載がないため、名前だけを確定事項とする。

## 接続の優先順位

| 区分 | 対象 | 判断 |
| --- | --- | --- |
| 優先1: 既存表示への接続 | `Stars.labels`、`Galaxies.NGCs`、`Galaxies.distantGalaxies` / `SDSS`、`Galaxies.quasars` / `QSOs`、各 toggle | 既存の表示フラグと対象カタログが一致する。現在の描画範囲は全天図のみ。 |
| 優先1: 既存ウィンドウ | `GUI.targetBrowser` / `timeSetting` / `placeSetting` / `scriptOutput`、各 toggle、`GUI:saveImageDialog()` | 既存のウィンドウ・画像保存処理を再利用できる。保存パネルを開くことと、ファイル保存の完了を区別する。 |
| 優先2: 地平方向 | `Camera.azimuth` / `altitude`、`Camera:look(targetName)` | 地平ビューの方向に対応可能。旧モードとの対応、対応する天体名、中心化時の zoom 維持を明記する必要がある。 |
| 優先2: 同梱スクリプトの投影 API | `GUI.dualScreen`、`GUI:toggleDualScreen()` | 英語・日本語 GUI スクリプト双方に用例がある。マニュアル掲載 API とは根拠を分ける。 |
| 別実装が必要 | 日時アニメーション、`Time.realtime`、月・年ステップ、カメラ姿勢/着陸制御、`State` の Lua 文字列形式、画像列出力 | 既存機能への名前の付け替えでは旧契約を満たさない。 |
| 今回は確定しない | `Scene.Fader` と `Desktop.Fader` の同一性、未掲載の `GUI.projection` / `dualWindow`、未記載の戻り値 | 同梱用例だけでは詳細契約を確定できない。成功する仮 API や独自 alias を登録しない。 |

## 1. 現在登録済みの範囲

`ScriptWorker.mm` の `install` / `readProperty` / `writeProperty` / `invoke` と、`AppScripting.mm` の `configureScripts` / `applyScriptAction` を照合した。

| オブジェクト | 登録済み | 既知の制限 |
| --- | --- | --- |
| `Time` | `JD`、`setTime` / `getTime`、年月日時分秒（`min` / `sec` alias）、`step` / `stepValue` / `speed`、`forward` / `backward` / `stop` / `setCurrent` / `prevStep` / `nextStep` | 固定秒の6ステップと `STEP_VALUE` のみ。ステップ設定は各 helper 実行で初期化される。日時は既存 core の JD に接続し、UTC / UT1 / TT の変換や ΔT 補正は行わない。 |
| `Camera` | `target`、`zoom` | `Sun`、`Planet.Mercury`〜`Planet.Pluto`、`Satellite.Moon` の11天体のみ。target 設定は太陽系ビューへ切替え focus する。旧 `zoomMode` の選択には未対応。 |
| `Constels` | `lines` / `bounds` / `labels`、`toggleLines` / `toggleBounds` / `toggleLabels` | 全天図の各フラグ。星座絵・星座別表示には未対応。 |
| その他 | `print`、`waitTime(seconds)`、`mtk.STEP_*` の対応部分、`mtk.UNIT_AU` / `UNIT_KM` / `UNIT_LY` | `print` は出力レコードを GUI ログへ渡す。アニメーション API 自体は未接続。旧定数の数値互換は保証していない。 |

実行モデルは信頼したローカルファイルの明示実行、Lua 5.4 helper、メインスレッドのホスト操作コールバック。未対応オブジェクト/プロパティを無処理の成功扱いにしない。既存の実行時間・命令数・メモリ・出力上限、キャンセルを拡張後も維持する。

## 2. 日時と逆再生

| 旧 API / 型・引数 | 戻り値 | 根拠 | 現状・不足 |
| --- | --- | --- | --- |
| `Time.JD: number` | プロパティ | `D/time.html:12` | 接続済み。旧資料の日時表現と native の時系簡略化は別に明示する。 |
| `Time:setTime(year, month, day, hour, min, sec)`、全6引数 integer | 未記載 | `D/time.html:19` | 接続済み。旧資料は UTC と明記。 |
| `Time:getTime()` | 6 integer、年/月/日/時/分/秒の順 | `D/time.html:22` | 接続済み。 |
| `Time.year` / `month` / `day` / `hour` / `minute` / `second`: integer、`min` / `sec` alias | プロパティ | `D/time.html:28–44` | 接続済み。 |
| `Time:setLocalTime(year, month, day, hour, min, sec)`、全6引数 integer / `Time:getLocalTime()` | setter は未記載、getter は6 integer | `D/time.html:46–50` | 未接続。ローカル時刻との変換が必要。既存日時 UI はローカル時刻 UI ではない。 |
| `Time.localYear` / `localMonth` / `localDay` / `localHour` / `localMinute` / `localSecond`: integer、`localMin` / `localSec` alias | プロパティ | `D/time.html:55–71` | 未接続。同じ JD の暦表現を変換する契約。 |
| `Time.step`、`Time.stepValue: integer` | プロパティ | `D/time.html:73–79` | `STEP_10SEC, MIN, 10MIN, HOUR, DAY, WEEK, MONTH, YEAR, 10YEAR, 100YEAR, VALUE`。`stepValue` は VALUE 時の秒数。月・年を固定秒数として代用しない。 |
| `Time:prevStep()` / `nextStep()` | 未記載 | `D/time.html:81–87` | 現行は固定6ステップ内のみ。月・年を含む列への対応は日時担当と調整。 |
| `Time:forward()` / `backward()` | 未記載 | `D/time.html:89–95` | **1ステップの移動**。連続再生の開始ではない。現行の意味は一致。 |
| `Time.speed: number`、`Time:stop()` | stop は未記載 | `D/time.html:97–101`、`L/gui.lua:214–216` | `speed` は実時間1秒あたりのステップ数。負数が逆再生、0が停止。既存 native の signed rate に接続済み。 |
| `Time:setCurrent()` | 未記載 | `D/time.html:103–104` | 現在時刻への一回の移動。接続済み。 |
| `Time.realtime: boolean`、`Time:toggleRealtime()` | toggle は未記載 | `D/time.html:106–112` | 常に現在時刻へ追従するモード。native `playRealtime` は「現在表示中の JD から順方向1倍速」であり、同じ契約ではない。 |
| `Time:setJDTo(jd, duration)` / `setTimeTo(6 integers, duration)` / `setLocalTimeTo(6 integers, duration)`、duration は number 秒 | 未記載 | `D/time.html:15–17,25–26,52–53` | 日時補間の開始が必要。単発 setDate や `waitTime` で代用しない。 |
| `Time.timeInfo: boolean`、`Time:toggleTimeInfo()` | toggle は未記載 | `D/time.html:114–120` | 時刻表示の有効/無効。native の日時欄には対応する表示フラグがない。 |

アニメーションの `*To` は開始後すぐ次の Lua 行へ進む。待つ場合は `waitTime(number 秒)` を別に呼ぶ（`D/aboutanimation.html:12–16`）。同期的に duration 秒ブロックする実装は互換にならない。

## 3. カメラ・地平・地点

| 旧 API / 型・引数 | 戻り値 | 根拠 | native への対応・残差 |
| --- | --- | --- | --- |
| `Camera.azimuth: number` | プロパティ | `D/camera.html:84–86` | 度、北0・東正・西負・南±180。`HorizonViewport.center_azimuth_deg` に対応。native は0〜360表現なので周期を揃える。 |
| `Camera.altitude: number` | プロパティ | `D/camera.html:91–93` | 度、地平0・天頂90。`center_altitude_deg` に対応。上下範囲や有限値を検査する。 |
| `Camera.fov: number` | プロパティ | `D/camera.html:98–100` | planetarium の視野角、度、資料の有効範囲は0〜90。native 地平図は等距離円筒図、SolarCamera は固定垂直45度。zoom 倍率をそのまま fov として公開しない。 |
| `Camera:look(targetName: string)` | 未記載 | `D/camera.html:114–116` | planetarium で指定天体を中央へ向ける。native の地平方向計算と選択処理を利用できるが、`HorizonView.focusSelection` は zoom も最低4へ変更するため、そのまま呼ぶと余分な副作用がある。 |
| `Camera.target: string` | プロパティ | `D/camera.html:105–108`、`D/abouttargets.html:12–55` | 現行11天体以外に、旧仕様は恒星、星座、銀河、球状星団、小天体、探査機、地点接尾辞を含む。native が持たない3D対象を、全天図の検索結果へ置き換えない。 |
| `Camera.zoom: number` | プロパティ | `D/camera.html:72–74` | target からの距離、単位 parsec。既存 AU カメラへの換算は接続済み。地平図の拡大率とは異なる。 |
| `Camera.zoomMode` | プロパティ、`ZOOM_NONE` / `ZOOM_AUTO` / `ZOOM_ALWAYS` | `D/camera.html:151–154` | target 変更時に距離を維持/大きい対象のみ調整/常に調整。現在は常に focus しており、旧 API の全契約には未対応。 |
| `Camera.mode`、`Camera:forceMode(mode)` | mode は定数、method 戻り値未記載 | `D/camera.html:12–15,29–31` | `PLANETARIUM` / `HIPPARCOS` は着陸/宇宙。通常 mode 変更には距離条件、forceMode は条件省略。native の全天図/太陽系/地平図という3ビューを単純な enum alias にしない。 |
| `Camera:toggleMode()` / `setModeTo(mode, duration?)` / `toggleModeTo(duration?)`、`modeDuration: number` | method は未記載 | `D/camera.html:17–35` | native の着陸・離陸処理は関連するが、対象・距離条件・遷移時間・終了状態を揃える必要がある。 |
| `Camera:setOrient(x,y,z,w)` / `getOrient()` | getter は4 number | `D/camera.html:45–51` | quaternion。native は yaw/pitch または基底ベクトル。成分順は判明しても座標規約と回転解釈を別途確認する必要がある。 |
| `Camera:setEuler(h,p,r)` / `addEuler(h,p,r)` | 未記載 | `D/camera.html:56–63` | 度、heading/pitch/roll。旧0,0,0は黄道南極を見る。native yaw/pitch のゼロ姿勢や roll 不在と相違する。 |
| `Camera.duration: number`、`setOrientTo` / `setEulerTo` / `addEulerTo` / `setZoomTo` / `setZoomLogTo` / `setAzimuthTo` / `setAltitudeTo` / `setFovTo` / `setTargetTo` / `lookTo` | method は未記載 | `D/camera.html:52–54,64–82,87–119,147–149` | 各即時 API の引数末尾へ duration 秒を追加。省略時は Camera.duration。非同期補間と停止処理が必要。 |
| `Camera:jumpToTarget(duration?)` / `jumpToHome()` | 未記載 | `D/camera.html:140–145` | 前者は対象を見るのに適した距離へ移動。後者は初期着陸地点と関連する視点状態を復元。native の一般的な飛行/カメラ reset と同一とは限らない。 |

地点 ID は `Camera.target = "Planet.Earth.Japan"` のように天体名へ接尾辞を加える（`D/abouttargets.html:53–55`）。native は [observer_places.hpp](../../native/gui/include/observer_places.hpp) と [AppObserverCommands.mm](../../native/gui/src/AppObserverCommands.mm) で手元の地球地点を読込・選択できる。次の動的追加 API と、読込済み地点の選択は分けて扱う。

| 旧 Places API | 引数 / 戻り値 | 根拠 | 現状 |
| --- | --- | --- | --- |
| `addLabelGroup(name,distance,size,r,g,b,alpha)` | name:string、他:number。戻り値未記載 | `D/places.html:39–41` | 同名定義を上書き。native 地点ローダーは定義を静的に解析するが、実行時ラベル群の描画・追加はない。 |
| `addLandscape(targetName,name,fileName,scale,horOffset,verOffset)` | 最初の3引数:string、他:number。戻り値未記載 | `D/places.html:42–44` | 画像を使う風景登録。horOffset は度、scale は縦倍率。native 風景描画はない。 |
| `addPlace(targetName,name,lon,lat,labelGroup,landscape)` | string,string,number,number,string,string。戻り値未記載 | `D/places.html:45–47` | lon は東経正、lat は北緯正。既存 target/name の上書き、既定 group/landscape の扱いを含む。動的レジストリの追加なしに成功扱いしない。 |
| `pointer` / `labels` / `landscape`: boolean、各 toggle、`labelSize: number` | toggle 戻り値未記載 | `D/places.html:12–37`、`L/gui.lua:185–187` | 地表の地点表示・ポインタ・風景のフラグ。投影ポインタや観測地設定ウィンドウの表示とは異なる。 |

`D/places.html:20` の見出しは `Places.pointer` と重複するが、説明・例・toggle と `L/gui.lua:185` により当該項目は `Places.labels` と確認できる。

## 4. 星座・恒星・カタログ

| 旧 API | 型 / 戻り値 | 根拠 | native 対応 |
| --- | --- | --- | --- |
| `Constels.lines` / `bounds` / `labels` と各 toggle | boolean、toggle 戻り値未記載 | `D/constels.html:12–50` | `SkyView.showsConstellationLines` / `Boundaries` / `Names`。接続済み。 |
| `Constels.illusts` / `toggleIllusts()` | boolean、toggle 戻り値未記載 | `D/constels.html:32–40` | 星座絵レイヤー未実装。線や名前のフラグに代用不可。 |
| `Constels:show(names)` / `hide(names)` / `isVisible(name)` | names:string（略号を空白区切り）、name:string（略号1つ）。isVisible は boolean | `D/constels.html:52–62` | 星座ごとの表示集合が必要。native は全体表示フラグのみ。 |
| `Stars.labels` / `toggleLabels()` | boolean、toggle 戻り値未記載 | `D/stars.html:20–26` | `SkyView.showsStarNames` と恒星名描画へ接続可能。 |
| `Stars.markingType` | string: `None` / `Binary` / `ExoPlanets` | `D/stars.html:60–66`、`L/gui.lua:149–151` | `showsExoplanetHosts` に None/ExoPlanets の部分対応は可能。Binary は未実装。toggle の巡回順は資料に明記なし。 |
| `Stars:select(hips)` / `deselect(hips)` / `isSelected(hip)` | hips:string（HIP番号を空白区切り）、hip:string（1つ）。isSelected は boolean | `D/stars.html:88–98` | `selectedLabels` 用の表示対象集合。native のクリック選択/HIP検索とは別機能。 |
| `Stars.visible` / `selectedLabels` / `bayerLabels` / `flamsteedLabels` / `hipLabels` と各 toggle | boolean、toggle 戻り値未記載 | `D/stars.html:12–58` | 対応する恒星表示レイヤーや部分ラベル状態がない。 |
| `Stars.brightness` / `setBrightnessTo(brightness,duration)` / `brighten()` / `darken()` / `defaultBrightness()` | brightness:number、1が既定。duration:number 秒。method 戻り値未記載 | `D/stars.html:68–86` | native の等級上限は表示対象の切り捨てであり、明るさ倍率ではない。 |
| `Galaxies.NGCs` / `toggleNGCs()` | boolean、toggle 戻り値未記載 | `D/galaxies.html:36–42`、`L/gui.lua:159` | `showsNebulae` → `ngc.dat` 描画。見出しの toggleGCs 誤記は同梱スクリプトで toggleNGCs と確認できる。 |
| `Galaxies.distantGalaxies` / `toggleDistantGalaxies()`、alias `SDSS` / `toggleSDSS()` | boolean、toggle 戻り値未記載 | `D/galaxies.html:52–66` | `showsGalaxies` → `SDSS_GAL.dat` の密度表示へ接続可能。 |
| `Galaxies.quasars` / `toggleQuasars()`、alias `QSOs` / `toggleQSOs()` | boolean、toggle 戻り値未記載 | `D/galaxies.html:68–82` | `showsQuasars` → `SDSS_QSO.dat` の密度表示へ接続可能。 |
| `Galaxies.ourGalaxy` / `globularClusters` (`GCs`) / `nearbyGalaxies`、各 toggle | boolean、toggle 戻り値未記載 | `D/galaxies.html:12–34,44–50` | 対応レイヤー未実装。`showsGalaxies` は近傍銀河ではなく SDSS のため代用不可。 |

カタログと実際の描画対応は [extended_catalogs.cpp](../../native/gui/src/extended_catalogs.cpp) と [SkyCatalogRenderer.mm](../../native/gui/src/SkyCatalogRenderer.mm) で確認した。原典が3D表現を含んでいても、今回のフラグ接続だけで旧3D描画互換を主張しない。

`Targets:select(targetName: string)` と `Targets:select(x: integer,y: integer)` は別のオーバーロード（`D/targets.html:15–20`、戻り値未記載）。native の body/HIP/deep-sky 選択を利用できる部分はあるが、`Camera.target` の変更や `Stars:select` のラベル集合操作とは分離する。`Constel.Ori` という用例と、`abouttargets.html:41` の英語正式名契約には不一致があるため、星座 ID の追加対応は別途確認する。

## 5. 既存 GUI、画像、投影

| 旧 API | 型 / 戻り値 | 根拠 | native 接続候補・注意 |
| --- | --- | --- | --- |
| `GUI.targetBrowser` / `toggleTargetBrowser()` | boolean、toggle 戻り値未記載 | `D/gui.html:23–30` | `CatalogBrowserController` のウィンドウ表示。選択検索の全旧機能への対応を意味しない。 |
| `GUI.timeSetting` / `toggleTimeSetting()` | boolean、toggle 戻り値未記載 | `D/gui.html:31–38` | `AppPlusCommands.showCalendar` と `_calendarWindow` の表示。 |
| `GUI.placeSetting` / `togglePlaceSetting()` | boolean、toggle 戻り値未記載 | `D/gui.html:39–46` | `AppObserverCommands.showObserver` と `_observerWindow` の表示。 |
| `GUI.scriptOutput` / `toggleScriptOutput()` | boolean、toggle 戻り値未記載 | `D/gui.html:74–80` | `showScriptConsole` と `_scriptWindow` の表示。スクリプト編集機能を兼ねるわけではない。 |
| `GUI:saveImageDialog()` | 引数なし、戻り値未記載 | `D/gui.html:20–21`、`L/gui.lua:5` | 既存の画像 capture + save panel。出力先 guard を通す。旧資料には呼出し中の待機・取消結果の返却仕様がない。 |
| `GUI.fullScreen` / `toggleFullScreen()` | boolean、toggle 戻り値未記載 | `D/gui.html:12–18` | 主画面の全画面化。投影ウィンドウを開く API に読み替えない。 |
| `GUI.dualScreen` / `toggleDualScreen()` | 用例は値読み出しと引数なし toggle。boolean の表示状態として使用。戻り値未確認 | `L/gui.lua:195`、`L/gui_jp.lua:195` | マニュアル未掲載。native `projectionVisible` / `showProjection` / `closeProjection` が対応候補。書込み例・ウィンドウ配置等の旧詳細仕様は未確認。 |
| `GUI.projection` / `GUI.dualWindow` | `false` の代入例のみ | `L/tutorial.lua:11–12` | `dualScreen` との同一性や対象ウィンドウが未確定。追加 alias にしない。 |
| `Desktop.Fader:toggle()` / `Desktop.Fader.visible` | toggle 引数なし、visible の値読み出し。戻り値未確認 | `L/gui.lua:193` | 日本語版は呼出し `Scene.Fader:toggle()`、表示判定は `Desktop.Fader.visible`（`L/gui_jp.lua:193`）。両者の同一性を推測しない。 |
| `Scene.Fader.type = Fader.TYPE_SOLIDCOLOR` | 同梱用例のみ | `L/quadraopt.lua:3` | native は投影専用の黒 opacity。旧 Fader の対象範囲、色、時間、type を満たす証拠はない。 |
| `Pointer.visible` / `toggle()` / `setPos(x,y,z)` / `addPos(x,y,z)` / `getPos()` | visible:boolean、座標3 number、getPos は3 number、他method 戻り値未記載 | `D/pointer.html:12–30` | 旧ポインタには3次元位置がある。native 投影ポインタは2次元マウス位置なので、表示フラグだけ接続して全 Pointer 互換としない。 |

[DisplayOutputController.h](../../native/gui/include/DisplayOutputController.h) の画像は現在ビューの PNG/JPEG/BMP。投影専用のポインタ・黒フェードは保存画像に含まれない。この範囲を旧レンダラ出力 API と混同しない。

| 旧レンダラ/画像 API | 契約 | 現状・根拠 |
| --- | --- | --- |
| `Renderer.renderFileNamePattern: string`、`frame: integer`、`resetFrame()` | パターンはフレーム番号を含む printf 形式。frame は次回描画番号。resetFrame は0へ戻す。 | `D/renderer.html:52–60`。native にフレーム番号やパターン処理はない。任意 printf 式をそのまま C varargs に渡す設計を持ち込まない。 |
| `Renderer.renderWidth` / `renderHeight`: integer | 保存画像の寸法。 | `D/renderer.html:61–65`。native capture は現在ビュー寸法。 |
| `Renderer:render()` / `renderToFile()` / `captureToFile()` | 引数なし、戻り値未記載。描画で frame を1増加。renderToFile は指定寸法、captureToFile は現在画面寸法。 | `D/renderer.html:67–74`。後二者は資料で **Pro only**。native の現在画像保存は基盤だが、連番・出力名・フレーム更新契約が不足。 |
| `Renderer.interactive` / `toggleInteractive()` | boolean。false では明示 render まで描画しない。 | `D/renderer.html:44–50`。現行 AppKit の常時描画とは違い、単にフラグを返す実装は不可。 |
| `Renderer.stereoType` | string: `None` / `Anaglyph` / `ColorAnaglyph`。 | `D/renderer.html:77–79`。native 未実装。 |
| `Images.visible` / `name` / `index`、`toggle` / `prev` / `next` / `first` / `last` | boolean / string / integer、名前と番号が連動する画像表示リスト。method 戻り値未記載。 | `D/images.html:12–37`。画像保存 API ではない。画像ギャラリー未実装。 |

## 6. 状態保存

| 旧 API | 確定した型 / 戻り値 | 根拠 |
| --- | --- | --- |
| `State:set(state)` | state:string、**Lua スクリプト文字列を実行**。戻り値未記載 | `D/state.html:12–13` |
| `State:get()` | 現在状態を表す **Lua スクリプト文字列** | `D/state.html:15–16` |
| `State:store()` / `restore()` | 引数なし、内部バッファへ保存/そこから復元。戻り値未記載 | `D/state.html:18–22` |
| `State:getStored()` | 保存済み状態を表す **Lua スクリプト文字列** | `D/state.html:24–25` |
| `State:canRestore()` | boolean | `D/state.html:27–28` |
| `State:storeAsInit()` / `resetInit()` | 引数なし、`state/init.lua` へ保存/内容を空にする。戻り値未記載 | `D/state.html:30–34` |
| `GUI:openStateDialog()` / `saveStateDialog()` | 引数なし、Lua 状態ファイルの読込実行/保存。戻り値未記載 | `D/gui.html:82–86` |

native [session_state.hpp](../../native/gui/include/session_state.hpp) / [AppSessionCommands.mm](../../native/gui/src/AppSessionCommands.mm) は型付き JSON 状態。`State:get()` が JSON を返す実装では旧スクリプトに渡せない。部分対応する場合でも、実際に登録済みの旧 API で再適用可能な Lua を生成する範囲を定め、対象外項目を明記する必要がある。

さらに現在の `applySessionState` は実行中 helper を cancel する。Lua の `State:restore()` からそのまま呼ぶと自分自身を中断するため、GUI 復元と Lua 内復元の呼出し契約を分ける必要がある。保存形式だけの問題ではない。

初期化 Lua の自動実行、原本配下の `state/init.lua` の変更は、今回の「明示選択した信頼済みローカルスクリプト」および原本保全の方針とは別の動作。既存の JSON 設定保存に名前だけ合わせて自動有効化しない。

## 7. その他の既存描画との境界

- `Planets.visible` / `labels` / `orbits` / `axes` と各 toggle はマニュアルにある（`D/planets.html:12–42`）。native には惑星・軌道の描画自体があるが、これらを独立して制御する公開フラグがない。Lua 接続だけで完了する項目ではない。
- `Planets:setScale(sun,planet,plnSun,plnPlanet)` は4 number、`getScale()` は同順の4 number（`D/planets.html:84–90`）。`setScaleTo(...,duration)` はマニュアル見出しの誤記を `L/screenmenu.lua:23–26` で確認できる。native の画面上の最小惑星サイズとは別の、宇宙/planetarium ごとの倍率である。
- `Grids.equatorial` / `ecliptic` / `galactic` / `horizontal` / `circleScales` / `squareScales` / `surfacePointer` と各 toggle は boolean（`D/grids.html`）。native の固定グリッド描画を切り替えるには状態と描画分岐を追加する必要がある。
- `Input:zoomUp()` / `zoomDown()` / `left()` / `right()` / `up()` / `down()` などはメニュー状態にも作用する操作（`D/input.html:26–48`）。active view の zoom だけへ結び付ける場合、メニュー動作まで旧互換としない。
- `GUI.scriptEditor` / `uiBrowser` や動的 menu/toolbar、`System:openDocument(fileName: string)` は公開資料に存在するが、本調査の既存 native 機能への最小接続対象外。未実装の編集・HTML 実行・外部文書表示を成功 no-op で補わない。

## 8. 次実装で確認する回帰

1. 追加プロパティを読み出すと実際の native 状態が返り、GUI で変えた値も反映される。alias は同一状態を共有する。
2. boolean に string/number、数値に NaN/Inf、未知の天体名を渡した場合は、対応するエラーを返し、その操作で状態を部分更新しない。
3. `Time.speed < 0` と `Time:backward()` の違いを維持する。ステップ定数は原典の名前を使い、未確定の旧数値を固定しない。
4. 地平の方位を北/東/南/西で検証し、視野倍率・中心高度を保持する。高度・look を将来接続する場合は地平/天頂も検証し、未知の対象は無変更とする。
5. GUI の true/false/toggle は実ウィンドウ表示と一致する。画像保存の取消は画像保存成功と報告しない。原本への出力 guard を迂回しない。
6. API 追加後も helper のキャンセル、実行予算、ログ、構文/実行エラー、未対応 API の失敗を維持する。native UI を `waitTime` やアニメーション待機で止めない。

調査段階では原典・実装の読取りと本記録の追加だけを行った。以後の接続結果は以下に追記する。

## 9. 第2単位の接続結果

- `Stars.labels`、`Galaxies.NGCs/distantGalaxies/SDSS/quasars/QSOs` と文書化された各 toggle を既存の全天図表示フラグへ接続した。
- `GUI.targetBrowser/timeSetting/placeSetting/scriptOutput` は実ウィンドウの表示取得・設定・toggle、`GUI.dualScreen` は資料で確認できる表示取得・toggle のみを公開した。閉じる操作後も実際の表示を取得する。
- `GUI:saveImageDialog()` は既存の PNG 保存パネルを開始する。引数・Lua 戻り値なし。画像取得やパネル開始の拒否はエラー、正常終了はパネル開始までで保存完了を意味しない。選択した出力先には通常 GUI の原本保護を適用する。
- `Camera.azimuth` は地平図の中心方位へ接続し、設定時に地平ビューを選ぶ。`Camera.altitude/look/fov` は未接続を維持する。`HorizonView.setViewport` が拡大率1で中心高度を0に制限するため、指定高度や天頂を向く契約をそのまま満たせないと確認した。
- `Time` の暦ステップ・固定時差・継続時計同期、`State`、資料間で不明な alias は今回変更していない。新規依存はない。

実装範囲と利用時の制約は [SCRIPTING.md](../../native/gui/SCRIPTING.md) を参照する。対応したフラグ群は旧レンダラや配布 GUI スクリプト全体の互換を示さない。
