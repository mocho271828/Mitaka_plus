# 次単位の Lua・選択・視点 API 接続監査

調査日: 2026-10-29。開始時 HEAD は `3f47a39`。第2単位の未コミット変更を含む作業ツリーを読み取り、次の接続候補を整理した。以下は監査時点の状態で、実装後の差分は末尾の追補へ記録する。原本は変更していない。前回の [接続調査](local-lua-audit.md) §9 と [SCRIPTING.md](../../native/gui/SCRIPTING.md) にある接続済み項目は、今回の不足 API と区別する。

## 根拠と確定範囲

- `D`: ローカル原本の [doc/script_jp](</Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/doc/script_jp>)。`D/file.html:行` は原本の行番号を示す。
- `L`: 同じ原本の [scripts](</Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/scripts>)。主に `gui.lua` を照合した。
- 原典 HTML は CP932 から読み取り時だけ変換した。Plus 1.5.4 build101013 に同梱された API 文書は 1.3.0 表記であり、版差や誤記がある。
- プロパティの型とメソッドの引数は資料で確認できたものだけを記す。戻り値が記載されていないメソッドに、成功 `true` などの仕様を付け足さない。定数は名前と意味が確定したものを用い、旧数値を推測しない。
- ユーザーが許可した信頼済みローカル Lua の権限は維持する。機能追加のために起動 Lua、オンライン HTML、URL からの自動実行を追加する必要はない。

## 優先順位

| 優先 | API / 課題 | 確定した旧契約 | 接続先と判断 |
| --- | --- | --- | --- |
| 先行修正済み | 接続済み `Camera.zoom` の失敗伝播 | target からの距離、number、parsec | 監査で見つかった成功扱いの経路を第2単位内で修正した。詳細は次節の追補。 |
| 1 | `Milkyway.type` | string、`None` / `Normal` / `Bright` / `Infrared` | 新しい `SkyView.milkyWayMode` と4値が対応する。全天図の背景として接続可能。画像欠損時の設定状態と診断を区別する。 |
| 1 | `Time.realtime` / `Time:toggleRealtime()` | boolean、常に現在時刻へ同期。toggle 引数なし、戻り値未記載 | 新しい `PlaybackController.clockTracking` / `setClockTracking:` が対応する。既存の `playRealtime` へは接続しない。 |
| 2 | `Stars.markingType` の一部 | string、`None` / `Binary` / `ExoPlanets` | `showsExoplanetHosts` で `None` / `ExoPlanets` は対応可能。`Binary` は未実装エラーを維持する。 |
| 2 | `Targets:select(targetName)` の一部 | string による天体選択。戻り値未記載 | 太陽・惑星・月と `Star.HIP番号` を優先できる。ただし選択と視点追従を分離する変更が必要。旧対象名と native 検索 ID を同一視しない。 |
| 3 | `GUI.fullScreen` / `toggleFullScreen()` | boolean、主画面の全画面化。toggle 引数なし、戻り値未記載 | 主ウィンドウは存在するが、全画面への移行状態を管理する Lua 接続はない。AppKit の実状態と非同期完了に接続する追加が必要。投影の表示フラグは代用しない。 |
| 契約整理後 | 月・年ステップと地方時 | 月・年等のステップ名、地方標準時という意味は確定 | 新 GUI の固定時差・月末規則と旧仕様の一致は未確定。worker 内のステップ状態を GUI と統合するだけでは全契約を満たさない。 |
| 描画変更後 | `Stars.visible`、`Planets.labels/orbits`、`Grids.equatorial/horizontal` など | 各 boolean と切替メソッドは確定 | 描画は存在するが、対応フラグがない。既存フラグへの別名追加だけでは実装できない。 |
| 継続調査 | 姿勢、FOV、高度、look、モード、各 `*To` | 引数・単位の一部は確定 | 投影・座標規約・遷移が不足。値の丸めや即時操作で旧契約を満たしたことにしない。 |

`Stars.labels`、`Galaxies.NGCs/distantGalaxies/SDSS/quasars/QSOs`、星座の全体表示フラグ、既存4ウィンドウ、画像保存パネル、`GUI.dualScreen` の取得と toggle、`Camera.azimuth` は第2単位で接続済みである。

## 接続済み経路で見つかった問題

### カメラ距離の失敗を呼出元へ返せない

[ScriptWorker.mm](../../native/gui/src/ScriptWorker.mm) は `Camera.zoom` を parsec から AU へ変換し、有限・正の値ならホストへ渡す。[AppScripting.mm](../../native/gui/src/AppScripting.mm) の `set_camera_distance` は `SolarSystemView.setCameraState:` を呼ぶ。

一方、[solar_camera.cpp](../../native/gui/src/solar_camera.cpp) は距離に上限 1000 AU を設け、通常カメラの下限は 0.000005 AU とする。`SolarSystemView.changeCamera:` は投影検証の例外を表示用コールバックだけに渡し、呼出元には返さない。`setCameraState:` は検証より前に `leaveNavigation` を実行し、結果にかかわらず追従を解除する。

したがって、監査時点では `Camera.zoom = 1`（1 parsec）のような上限を超える値が Lua 上で成功し、距離は変わらず、ナビゲーションだけ解除される経路がある。次単位の候補とは別に担当へ共有した。修正候補は「変更前に候補カメラを検証する」「適用できたかをホストへ返す」という境界であり、不正値を上限へ丸めて成功させることではない。

回帰では上限超過・下限未満・非有限値を、通常表示と飛行中の両方で確認する。不正値の Lua エラーに加え、カメラ、追従、飛行状態が部分更新されていないことを検証する。

追補: 親担当の依頼により、この問題だけは第2単位内で修正した。`SolarSystemView.applyCameraState:error:` は候補をコピーし、既存の `solar_camera_basis` で検証した後だけ状態を変更する。Lua へ BOOL とエラーを返す。通常追従・航行中の4種の不正距離に対する状態保持、Lua の失敗伝播を既存試験へ追加した。警告をエラーとするビルド、Lua 通信試験、Solar small-body 試験19件、ローカル Plus データの全 AppKit smoke が成功した。[実行記録](unit2/logs/zoom-validation.log) を参照。

## 直接接続できる表示と時計

### 天の川

`D/milkyway.html:12–17` と `L/gui.lua:170–173` が `Milkyway.type` の文字列4値を一致して示す。文書の例には `Milkyway:type = ...` という誤記があるが、GUI スクリプトはドット代入を使う。

[sky_background.hpp](../../native/gui/include/sky_background.hpp) の `MilkyWayMode`、[SkyView.mm](../../native/gui/src/SkyView.mm) の `milkyWayMode` が接続先になる。通常・強調・赤外線画像はそれぞれ独立して読み込み、別モードの画像で置換しない。getter は GUI で選択した実際のモードを返す必要がある。

現在の setter は enum の範囲を検証するが、画像の有無は検証しない。画像欠損なら選択モードを保持し背景を描かず、読み込み側の警告を使う。Lua でもこの「設定値」と「描画できたか」を混同せず、欠損を利用者に伝える。標準 Mitaka 1.3.1 に由来する画像配置と、Plus 原版の表示一致は別の検証である。

`Milkyway:toggleType()` は引数なしで type を変えることだけが明記され、巡回順は不明。4値の記載順を巡回仕様と推測して追加しない。

### 時計への継続追従

`D/time.html:103–112` は `setCurrent()` と `realtime` を分けている。前者は現在時刻の一度の適用、後者は常に現在時刻へ同期する boolean。`L/gui.lua:218` は引数なし `Time:toggleRealtime()` と boolean の表示判定を使う。

[PlaybackController.h](../../native/gui/include/PlaybackController.h) の `clockTracking` と、成功を BOOL で返す `setClockTracking:` を使用できる。通常再生とは独立したモードであり、OS 時計を毎回読み、範囲外や表示失敗なら追従を停止する。`playRealtime` は表示中の日時からの1倍速再生なので意味が異なる。

getter は timer の有無ではなく `clockTracking` を返す。native ではスリープ・非表示中も追従要求を保持し、復帰時に現在時刻へ追いつく。手動日時変更・通常再生・速度変更は追従を解除する。この優先順位は新 GUI の採用契約であり、旧 Plus が同じ優先順位だったという根拠はない。

接続時には `setClockTracking:` が NO を返す場合をエラーとして伝える。true / false / toggle、通常再生からの切替、手動操作後、非表示からの復帰、暦表範囲外を検証する。既存の `Time.speed=0` と `Time:stop()` からも、実際の停止状態が取得できることを確認する。

### 系外惑星の恒星マーク

`D/stars.html:60–66` と `L/gui.lua:149–151` は `None`、`Binary`、`ExoPlanets` を定義する。[SkyCatalogRenderer.mm](../../native/gui/src/SkyCatalogRenderer.mm) はローカル `exoplanets_HIP_list.dat` の HIP に対し円を描き、`SkyView.showsExoplanetHosts` で切り替える。`None` / `ExoPlanets` の取得・設定は既存機能へ対応できる。

`Binary` のデータと描画はない。未対応を `None` に読み替えたり、`ExoPlanets` のフラグだけを返して全3値対応としたりしない。`toggleMarkingType()` は巡回順が資料にないため、2値の独自 toggle を同名で追加する根拠もない。

## 選択・検索・追従を分ける

`D/targets.html:18–20` は `Targets:select(targetName: string)` を「指定された天体を選択」と記す。カメラを移動する `Camera.target` / `Camera:look` とは別 API である。戻り値は未記載。

| 対象名 | 原典 | native の状況 / 必要な判断 |
| --- | --- | --- |
| `Sun`、`Planet.Mercury`〜`Planet.Pluto`、`Satellite.Moon` | `D/abouttargets.html:17–25`、`L/gui.lua:27–39` | 既存11天体の解決表を再利用できる。選択だけの適用経路が必要。 |
| `Star.<HIP番号>` | `D/abouttargets.html:38–40` | `SkyView` / `HorizonView` の `selectStarHIP:` がある。未知 HIP は NO。選択した星を見せるため等級上限を変える現在の挙動も明記する。3D の `Camera.target` へは流用しない。 |
| `Star.<固有英語名>` | 同上。`star_names_HIP.dat` の名前と明記 | ローカル名称データの完全一致と重複を確認してから解決する。ブラウザーの部分一致検索で先頭の候補を採用しない。 |
| `Constel.Orion` / `Constel.Ori` | `D/abouttargets.html:41–43` と `D/targets.html:20` が不一致 | ブラウザーには星座表示と中心化があるが、星座の選択 ID を保持する API はない。略号と英語正式名の alias を推測しない。 |
| `Galaxy.*`、`GC.*`、`Other.*` | `D/abouttargets.html:44–52` | 旧名は近傍銀河等の名前。native の NGC / SDSS 検索結果 ID と一致する証拠はない。`NGC.*` などの旧 API 未確認 prefix を新設しない。 |
| `Comet.*`、`Asteroids.*`、`TNO.*` | `D/abouttargets.html:29–37` | 新しい小天体検索は原本レコード index を保持する。旧新・言語別の重複を保持しているので、名前や番号だけで一意とは限らない。参照元の優先順位を推測しない。 |
| `Planet.Earth.<地点名>` | `D/abouttargets.html:53–56` | 観測地の読み込みと地表移動はあるが、旧 API は宇宙なら地点の真上、地表なら地点へ移動する。地平図の観測地を選ぶだけでは満たさない。 |

[SkyView.h](../../native/gui/include/SkyView.h) と [HorizonView.h](../../native/gui/include/HorizonView.h) は天体選択と `focusSelection` を別に持つ。しかし [SolarSystemView.mm](../../native/gui/src/SolarSystemView.mm) の `selectBody:` は追従中にカメラ target も変更する。既存の `chooseBrowserEntry:center:NO` もビュー切替、表示フラグ、等級上限を変える経路があるため、そのまま純粋な選択操作にしない。

また、現在の `Camera.target` getter は太陽系の `selectedBodyIndex` から名前を生成する。独立した `Targets:select` を追加すると、カメラが別の対象を向いたまま getter の名前だけ変わり得る。カメラが追従する対象と、選択マークの対象を別状態にすることが先に必要である。既にパンした視点・地平ビュー・小天体選択のときの値も整理する。

`Targets:select(x,y)` は2整数、画面上の天体または名前を選択する（`D/targets.html:15–17`）。画面座標の原点、描画領域との関係、Retina の point/pixel は旧資料にない。native の点の hit-test だけでラベルの選択まで対応したことにしない。`Targets.selectMode` の `SELECT_NONE/MOUSEOVER/MOUSECLICK` も、現在の固定クリック処理へフラグを付けるだけでは不足する。

`Stars:select(hips)` / `deselect(hips)` は、空白区切り HIP 文字列による**ラベル表示集合**の操作である（`D/stars.html:88–98`）。`Stars:isSelected(hip)` はラベル表示対象の boolean を返す。現在の選択マークやカメラ対象を操作する API として実装しない。

## 日時新機能との統合で残る契約

詳細は [日時調査](local-time-audit.md)。次の点を Lua 接続時の前提とする。

| 項目 | 確定事項 | 未確定 / native との差 |
| --- | --- | --- |
| ステップ | `STEP_10SEC/MIN/10MIN/HOUR/DAY/WEEK/MONTH/YEAR/10YEAR/100YEAR/VALUE`。`L/gui.lua:203–212` は既定の順序を示す | 定数の旧数値は不明。`calendar_time.hpp` の enum 数値は native JSON 用であり、旧値の根拠にしない。 |
| 1ステップ | `forward()` / `backward()` は前後に1ステップ（`D/time.html:89–95`） | native は固定時差の先発グレゴリオ暦で移動先月末へ収める。月末・閏日・年0の旧規則は未確認。 |
| 再生速度 | `speed=1` は1実秒に1ステップ、負数は逆向き（`D/time.html:97–99`） | 月・年を何秒として連続補間するかは不明。現在の `PlaybackClock` は秒率。30日/365日への固定換算で旧互換としない。 |
| 任意ステップ | `stepValue` は整数秒、`STEP_VALUE` 時に有効（`D/time.html:77–79`） | native の1秒〜30日という範囲、custom から prev/next の扱いは新契約。 |
| 地方時 | `set/getLocalTime` は6整数、localYear 等も整数（`D/time.html:46–72`） | OS timezone、固定時差、観測地の経度、DST のどれに基づくか不明。native の UTC±14時間・整数分設定を旧地方標準時と断定しない。 |
| 表示と状態 | 年月日時分秒の取得・設定は現在接続済み | worker の `Time.step/stepValue` は実行ごとに初期化され、GUI の `TimeSettings` と別状態。統合時は GUI 操作・次の実行・保存復帰が同じ設定を読む必要がある。 |
| 日時アニメーション | `setJDTo`、`setTimeTo`、`setLocalTimeTo` の末尾は duration 秒 | `D/aboutanimation.html:12–16` は開始後すぐ次行へ進む。即時変更や Lua の待機だけでは満たさない。補間・中断・境界処理が必要。 |

全 native 操作は単一 JD を使い、UTC / UT1 / TT / TDB・ΔT の変換は行わない。今回追加された小天体も含め、表示の便利さと時系の厳密な一致は区別する。

## 姿勢・FOV・地平で近似を成功扱いにしない

| 旧 API | 確定した契約 | 現在不足している点 |
| --- | --- | --- |
| `Camera:setOrient(x,y,z,w)` / `getOrient()` | quaternion の4実数、getter も4値（`D/camera.html:45–51`） | 成分名だけでは世界座標の軸、回転方向、内因/外因、姿勢か逆変換かを確定できない。native の基底は右手系だが同一の証拠はない。 |
| `setEuler(h,p,r)` / `addEuler(h,p,r)` | 実数・度。0,0,0 は黄道南極を見る（同:56–63） | native yaw は黄道XYの+X基準、pitch は±89度、通常 roll はない。yaw/pitch への直接代入は不一致。Euler の回転順序も未確定。 |
| `Camera.fov` | planetarium の視野角、度、0〜90（同:98–100） | 全角/半角、縦/横の規定がない。native 太陽系は固定垂直45度、地平は円筒図。地平の zoom を視野角と同一視しない。 |
| `Camera.altitude` | 度、水平0・天頂90（同:91–93） | `normalize_sky_viewport` は中心高度を `±(90−90/zoom)` に制限する。zoom=1 では0のみで、有限の最大zoomでも90に届かない。指定を clamp して成功を返してはいけない。 |
| `Camera:look(targetName)` | planetarium で指定天体を視野中央へ向ける（同:114–116） | `HorizonView.focusSelection` は zoom を最低4へ変え、中心高度も制限する。方位高度計算だけで天頂への中心化は実現しない。未知名は無変更エラーにする。 |
| `Camera.mode` / `forceMode(mode)` | `PLANETARIUM/HIPPARCOS`。通常切替は天体への距離条件、force は条件なし（同:12–31） | native の全天図/太陽系/地平図は描画ビュー。旧着陸/宇宙状態とは別。3ビューの番号を旧2モードへ alias にしない。 |
| `Camera.landingMode` | `HORIZONTAL/SURFACEVIEW`。接近時に水平を見る/常に地面を見る（同:37–43） | 既存地表の ENU 視点を使用できるが、飛行中の姿勢遷移・切替条件の接続が必要。 |
| `Camera.zoomMode` | `ZOOM_NONE/AUTO/ALWAYS`。target 変更時に距離を維持/対象が大きい場合に調整/常に調整（同:151–154） | 現在 `Camera.target` は `focusSelection` を呼ぶ。対象半径に応じた距離選択と、この設定の状態はない。 |
| `jumpToTarget(duration?)` / `jumpToHome()` | 対象に適した距離へ移動/初期着陸地点と視点へ戻す（同:140–146） | 固定の24秒航行やカメラ reset の別名にはできない。home の対象・地点・mode・altitude・fov を保持する契約が必要。 |
| 各 `*To` と `Camera.duration` | duration 秒で非同期遷移。省略時は既定 duration（同:52–54,64–82,87–119,147–149） | カメラ・日時・地表飛行の競合、中断、最終状態を扱うアニメーション処理が必要。 |

小天体は日心 J2000 黄道 AU、通常の太陽・惑星・月のモデル位置は日心 J2000 赤道 AU から描画時に変換する。`SolarCamera.target` は黄道 AU、`distance_au` は視点距離で地表高度ではない。Sky の RA/Dec、Horizon の方位/高度、Solar の世界座標を同じ setter へ渡さない。

小天体の focus は評価可能な行だけが対象で、物理半径を持たない。地表・着陸・惑星間航行へ拡張したことにはならない。時刻系・座標系が不明な行を選択した場合は原本情報と診断を保持し、推測位置へ移動しない。

## 表示レイヤーと既存ウィンドウの次の範囲

- `Stars.visible` と `toggle()`（`D/stars.html:12–18`）には、恒星点描画の独立フラグが必要。等級上限を下げる処理は可視性の代用にならない。`brightness` も描画倍率であり、等級によるカタログ除外とは違う。
- `Planets.visible/labels/orbits/axes` と各 toggle（`D/planets.html:12–42`）は確定しているが、現在 `SolarSceneRenderer` の本体・ラベル・軌道は常時描画。Sun・Planet・Satellite の旧グループ分けを維持して状態と描画分岐を追加する必要がある。小天体の単一表示フラグを Asteroids/TNO/Comets の全設定へ流用しない。
- `Grids.equatorial/horizontal`（`D/grids.html:12–18,36–42`）は現在の全天図・地平図の格子に対応する候補。`ecliptic/galactic/circleScales/squareScales/surfacePointer` は別の描画対象であり、同じ格子フラグへまとめない。
- `Constels:show(names)` / `hide(names)` は略号の空白区切り文字列、`isVisible(name)` は略号1つに対する boolean（`D/constels.html:52–62`）。現在は全体フラグだけなので星座ごとの可視集合が必要。`illusts` は星座絵であり線の別名にしない。
- `Time.timeInfo`、`Camera.viewInfo`（`D/time.html:114–120`、`D/camera.html:131–138`）は表示 boolean。native の日時欄・描画内情報・視点説明のどの範囲に作用させるかを決め、実際の表示分岐を追加する必要がある。
- `GUI.fullScreen`（`D/gui.html:12–18`、`L/gui.lua:197`）は主画面の状態。全画面へ移行中の連続 setter/toggle、失敗、GUI 操作からの解除を扱い、getter が要求した値だけを返す構成にしない。`GUI.dualScreen` は別の投影ウィンドウである。

現在の媒体プレビューは `MediaController` の独立ウィンドウで、旧 `Images/Movies/Audio` の画面合成ではない。`name/index` の起点・重複名、前後端、frame の単位が未確定なので、そのまま旧 API へ対応づけない。詳細は [媒体調査](local-media-audit.md) を参照する。

旧 `State:get/set` と状態ダイアログは Lua 文字列の保存・実行であり、native の検証済み JSON v2 と異なる。`applySessionState` は実行中の Lua を取消すので、`State:restore()` から単純に呼ぶと自分自身を中断する。形式と呼出し契約の両方を整理する必要がある。`storeAsInit/resetInit` を原本 `state/init.lua` の書換えや起動自動実行へ接続しない。

## この監査の検証範囲

原典、監査時点のプロパティ登録、GUI コールバック、選択・描画・時計の実装を照合した。第2単位で行った追加修正・試験は、上記のカメラ距離の失敗伝播修正である。第3単位の実装と検証結果は次節へ記録する。

この監査と Lua 接続では実装方針や policy gate は変更していない。コミットと共有作業ツリー全体の確認は親担当がまとめて行う。

## 第3単位の実装追補

次の旧 API を新しい native の表示設定・時計へ接続した。すべて明示的に選んだ信頼済みローカル Lua の範囲で、HTML・オンライン経路へ実行機能は加えていない。

| 原典 | 接続した API | native の契約 |
| --- | --- | --- |
| `D/time.html:105–120` | `realtime`、`timeInfo` と各 toggle | OS 時計の継続追従／日時情報だけの表示。追従開始失敗は Lua エラー。手動操作の優先順位は native の仕様であり、旧版との一致は未確認 |
| `D/milkyway.html:12–17`、`L/gui.lua:170–173` | `Milkyway.type` の文字列4値 | 全天図の背景モード。画像欠損時は設定を保持し、欠損診断を表示 |
| `D/stars.html:12–26,36–66` | `visible/labels/bayerLabels/flamsteedLabels/hipLabels` と各 toggle、`markingType` の文字列3値 | 共通 `StarDisplayOptions`。Binary は今回追加したローカル HIP の多重星フラグ、ExoPlanets は全ホスト HIP 集合を使用 |
| `D/planets.html:12–42` | `visible/labels/orbits/axes` と各 toggle | 共通 `PlanetDisplayOptions`。太陽・惑星・月をまとめた native 表示設定。太陽の自転軸モデルはなく、軌道・軸は対応した惑星と月の範囲 |
| `D/grids.html:12–58` | `equatorial/ecliptic/galactic/horizontal/circleScales/squareScales` と各 toggle | 共通 `GridDisplayOptions`。各ビューの投影に応じた線・面・距離目盛。`surfacePointer` は未接続 |

各 boolean は Lua の boolean 型だけを受け付ける。toggle は引数なし・戻り値なし。取得は毎回ホストの snapshot を読み、GUI の操作後も最新の状態を返す。文字列は列挙した完全一致だけを受理する。型違い、未知モード、未対応 API はホストの変更前に拒否する。`toggleType()` / `toggleMarkingType()` は循環順が資料にないため未実装のままとした。

検証には専用 `native/gui/build-unit3-script` を使用した。`script-test` は17個の boolean の get/set/toggle、全モード、型違いと不明 API の無変更エラー、GUI 相当の外部状態変更後の取得、時計追従のホスト拒否を確認して成功した（`controller.log`）。AppKit の追加接続ファイルも警告をエラーとするコンパイルを通過した（`script-objects.log`）。全体 GUI build/smoke は親担当の統合試験で確認する。

独立した読み取りレビューでも、厳密な型検証、ホスト拒否の Lua エラー伝播、取得・切替時の最新 snapshot、GUI 共通 setter への接続に修正必須の問題は見つからなかった。
