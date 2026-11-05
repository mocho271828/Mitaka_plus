# ローカル Lua スクリプト

ユーザーが明示的に選んだ、信頼済みローカル Lua ファイルを実行する。ユーザーの選択に基づき Lua 標準ライブラリの `io`、`os`、`package`、`debug` を有効にしている。ファイル操作や外部コマンドはユーザー本人の権限で動く。これはサンドボックスではない。実行済みの書き込みや表示変更は、中断・エラー時にも巻き戻さない。

オンライン HTML からの自動実行、データフォルダの `init.lua` の自動実行、リモート URL の直接実行は提供しない。ホスト API は以下の実装済み範囲だけを公開し、未対応プロパティ・メソッドを呼ぶとエラーにする。

## 実装済みホスト API

| API | 動作 |
| --- | --- |
| `Time.JD` | GUI と同じユリウス日を取得・設定。UTC 入力扱い、ΔT・TT/TDB 補正なし |
| `Time:setTime(y,m,d,h,min,sec)` / `Time:getTime()` | UTC 相当の先発グレゴリオ暦、6 個の整数。月・日・時分秒の超過を繰り越す。対応年は core の -4712..9999、閏秒なし |
| `Time.year/month/day/hour/minute/second` | 個別の日時要素を取得・設定。`min` / `sec` も利用可 |
| `Time:setLocalTime(y,m,d,h,min,sec)` / `Time:getLocalTime()` | 明示した旧 Plus 地方時差を用い、地方時の 6 成分を設定・取得。未設定時はエラー |
| `Time.localYear/localMonth/localDay/localHour/localMinute/localSecond` | 地方時の成分を取得・設定。`localMin` / `localSec` と対応する get/set メソッドも利用可 |
| `Time:setTimeString(text)` / `Time:getTimeString()` | UTC 相当の日時文字列を設定・取得。設定は元の引数文字列を返す |
| `Time:setJDTo(jd,seconds[,curve])` / `Time:setTimeTo(y,m,d,h,min,sec,seconds[,curve])` / `Time:setLocalTimeTo(y,m,d,h,min,sec,seconds[,curve])` | 指定秒数の日時補間を要求。`curve` は boolean、省略または true は半余弦、false は線形 |
| `Time.step` | `mtk.STEP_SEC`、`STEP_10SEC`、`STEP_MIN`、`STEP_10MIN`、`STEP_HOUR`、`STEP_DAY`、`STEP_WEEK`、`STEP_MONTH`、`STEP_YEAR`、`STEP_10YEAR`、`STEP_100YEAR`、`STEP_VALUE`。列挙値は順に 0..11 |
| `Time.stepValue` | **日単位**の有限数。負・0・小数も保持し、代入すると `STEP_VALUE` へ切り替わる |
| `Time.speed` | 実時間 1 秒あたりのステップ数。代入値を 0 方向に切り捨てた int32。0 は停止、連続再生の日数は `stepValue × speed` |
| `Time:forward()` / `rewind()` | 1 ステップ進む／戻る。月・年では UTC の暦成分を動かし、月末の超過を翌月へ繰り越す |
| `Time:stop()` / `setCurrent()` | 再生停止／現在の UTC へ移動 |
| `Time.realtime` / `Time:toggleRealtime()` | OS 時計への継続追従を取得・設定・切替。開始に失敗すると Lua エラーを返す |
| `Time.timeInfo` / `Time:toggleTimeInfo()` | 主画面の日付欄と地平・太陽系の日時情報表示。日時・再生・時計追従は変更しない |
| `Time:prevStep()` / `nextStep()` | 列挙値だけを変更し、`stepValue` を保持。prev は `max(step−1,0)`、next は原版の `min(step+1,9)` |
| `Camera.target` | `Sun`、`Planet.Mercury`〜`Planet.Pluto`、`Satellite.<名前>`、`Star.<HIP番号または英語固有名>`、`Asteroids.<番号または名前>`、`TNO.<番号または名前>`、`Comet.<名前>`、`Spacecraft.<名前>`、`GC.<名前>`、`Other.OurGalaxyCenter`、`Other.OurGalaxy` を選択。一意に解決でき、位置を計算できる対象に対応。探査機は原本の DisplayName または Name に一致させる |
| `Camera:setTargetTo(target[,duration])` | 同じ対象へ非同期に移動する。省略時は `Camera.duration` 秒。移動中も惑星・月・小天体・探査機の位置を更新し、完了後は追従する |
| `Camera:look(target)` | 地平図で太陽、地球以外の惑星、衛星、恒星、小天体、探査機、球状星団、銀河系中心、星座を視野中央へ向ける。星座は `Constel.<正式英語名>` または `Constel.<略号>`、その他は `Camera.target` と同じ指定方法を使う。地点・ズーム・選択対象を維持する |
| `Camera:lookTo(target[,duration])` | 同じ対象へ方位と高度を非同期補間する。秒数の省略時は `Camera.duration`。補間中は現在日時の対象方向を終点に使い、完了後の継続追従はしない |
| `Camera.mode` / `toggleMode()` / `setModeTo(mode[, duration])` / `toggleModeTo([duration])` | `mtk.PLANETARIUM` (0) と `mtk.HIPPARCOS` (1) を切り替える。地球近傍と地平図の間に限定 |
| `Camera.modeDuration` | モード移行の秒数。通常起動時の初期値は 7.1 秒 |
| `Camera:getOrient()` / `setOrient(x,y,z,w)` / `setOrientTo(x,y,z,w[,duration[,smooth]])` | 太陽系の通常視点で quaternion の姿勢を取得・設定・補間する |
| `Camera:getEuler()` / `setEuler(h,p,r)` / `addEuler(h,p,r)` と各 `To` | 太陽系の通常視点で heading・pitch・roll の取得・設定・加算・補間を行う。角度は度単位 |
| `Camera.zoom` | ターゲットまでの距離を **パーセク** で取得・設定。GUI の AU と変換する |
| `Camera.azimuth` | 地平ビューの中心方位を度で取得・設定。北0・東90・西−90。設定時は地平ビューへ切り替え、拡大率を維持する |
| `Camera.duration` | カメラ補間の秒数。通常起動時の初期値は 9 秒 |
| `Camera:setAzimuthTo(value, duration, smooth)` / `setAltitudeTo` | 方位・高度を非同期補間。`duration` 省略時は `Camera.duration`、`smooth` 省略時は true。方位は最短経路への補正をしない |
| `Camera.altitude` | 地平ビューの中心高度を度で取得・設定。水平0・天頂90。指定範囲は −90〜90 度で、範囲外はエラーとする。設定時は地平ビューへ切り替え、拡大率を維持する |
| `Constels.lines/bounds/labels/illusts` | 全天図・地平図の星座線・境界線・名称・2D 星座絵の真偽値 |
| `Constels:toggleLines()` / `toggleBounds()` / `toggleLabels()` / `toggleIllusts()` | 対応する表示を切り替える |
| `Stars.visible/labels/bayerLabels/flamsteedLabels/hipLabels` | 全天図・地平図の恒星、固有名、バイエル符号、フラムスティード番号、HIP 番号の表示。`toggle()` / `toggleLabels()` / `toggleBayerLabels()` / `toggleFlamsteedLabels()` / `toggleHipLabels()` も利用可 |
| `Stars.selectedLabels` / `Stars:toggleSelectedLabels()` | 固有名を選択した HIP 集合だけに限定する。Bayer・Flamsteed・HIP 番号や星の表示は変えない |
| `Stars:select(list)` / `deselect(list)` / `isSelected(hip)` | 空白区切り HIP 一覧または単独 `All` の選択・解除。照会は単一 HIP の文字列を取り、集合への所属を boolean で返す |
| `Stars.markingType` | `None` / `Binary` / `ExoPlanets`。ローカル HIP の多重星フラグ／系外惑星ホスト HIP 集合を使うマーク |
| `Stars.brightness` / `brighten()` / `darken()` / `defaultBrightness()` | 正の有限 float の `L_ref`。標準 1、小さいほど明るい。増減はそれぞれ `10^-0.2` / `10^+0.2` 倍 |
| `Stars:setBrightnessTo(target, seconds)` | 半余弦で現在値から target へ非同期に変更する。2 数値、秒数は有限かつ 0 以上、戻り値なし |
| `Planets.visible/labels/orbits/axes` | 太陽・惑星・月の表示／名称、惑星・月の軌道／自転軸。太陽の自転軸はモデル未提供。`toggle()` / `toggleLabels()` / `toggleOrbits()` / `toggleAxes()` も利用可 |
| `Planets:setScale(a,b,c,d)` / `Planets:getScale()` | 宇宙惑星・宇宙太陽・天球惑星・天球太陽/月の順に正の有限 float の4値を設定・取得する |
| `Planets.scaleMode` / `Planets:setScaleMode(value)` / `Planets:getScaleMode()` | `mtk.KEEP_RADIUS`（0）または `mtk.KEEP_ORBIT`（1）。ホストが拒否した設定は Lua エラーになる |
| `Planets.topoAmplification` | 地形高さ倍率の取得・設定。Lua 値 1〜5 が実倍率 1・2・5・10・20 に対応 |
| `Planets.clouds/cityLights` | 地球の雲・夜景設定の真偽値。`toggleClouds()` / `toggleCityLights()` も利用可 |
| `Planets.shadows/shadowBorders/shadowUmbra/shadowPenumbra` | 表面の食、境界、本影円錐、半影円錐の独立した真偽値。各 `toggleShadows()` / `toggleShadowBorders()` / `toggleShadowUmbra()` / `toggleShadowPenumbra()` も利用可 |
| `Places.landscape` / `Places:toggleLandscape()` | 地平図の風景画像の表示。採用したローカル地点定義・画像を使い、定義がないときは黒い下半球を表示する |
| `Planets.atmosphere` / `Planets:toggleAtmosphere()` | `mtk.ATMOS_NONE` / `mtk.ATMOS_SINGLE` / `mtk.ATMOS_MULTIPLE`（0 / 1 / 2）。なし→単一散乱→多重散乱→なしの順で切り替える |
| `Asteroids` / `TNObjects` / `Comets` / `Satellites` の `visible/labels/orbits/selectedOnly` | 各群の表示・名称・軌道線・表示集合だけの表示。strict boolean の取得・設定と各 `toggle()` / `toggleLabels()` / `toggleOrbits()` / `toggleSelectedOnly()` に対応 |
| `Grids.equatorial/ecliptic/galactic/horizontal/circleScales/squareScales` | 各座標線・黄道・距離目盛の表示。各 `toggleEquatorial()` / `toggleEcliptic()` / `toggleGalactic()` / `toggleHorizontal()` / `toggleCircleScales()` / `toggleSquareScales()` も利用可 |
| `Milkyway.type` | `None` / `Normal` / `Bright` / `Infrared`。全天図・地平図の背景モード |
| `Galaxies.NGCs` / `toggleNGCs()` | 全天図の `ngc.dat` 表示 |
| `Galaxies.distantGalaxies` / `toggleDistantGalaxies()` | 全天図の `SDSS_GAL.dat` 密度表示。`SDSS` / `toggleSDSS()` は同じ状態の alias |
| `Galaxies.quasars` / `toggleQuasars()` | 全天図の `SDSS_QSO.dat` 密度表示。`QSOs` / `toggleQSOs()` は同じ状態の alias |
| `GUI.targetBrowser/timeSetting/placeSetting/scriptOutput` | カタログ検索・日時設定・観測地設定・実行ログの実ウィンドウ表示を取得・設定。各 `toggleTargetBrowser()` / `toggleTimeSetting()` / `togglePlaceSetting()` / `toggleScriptOutput()` も利用可 |
| `GUI.dualScreen` / `GUI:toggleDualScreen()` | 投影ウィンドウの表示を取得・切り替え。同梱 GUI スクリプトで確認できる読出し・toggle のみ公開し、プロパティ代入は未対応 |
| `Renderer.antialias/pointSmooth/lineSmooth/textSmooth` | 描画品質の boolean 取得・設定、各 `toggleAntialias()` / `togglePointSmooth()` / `toggleLineSmooth()` / `toggleTextSmooth()` |
| `GUI.fullScreen` / `GUI:toggleFullScreen()` | 実全画面状態の取得、boolean 設定／切替要求。受付と非同期完了を区別する |
| `GUI:aboutDialog()` | 標準のアプリ情報ウィンドウを開く |
| `GUI:saveImageDialog()` | 現在のビューを PNG に符号化し、保存先パネルを開く。引数・戻り値なし。符号化失敗や既存のシート表示中はエラー |
| `mtk.UNIT_AU` / `UNIT_KM` / `UNIT_LY` | パーセクへ換算する距離定数 |
| `print(...)` | 実行ログへ出力。1 回 8 KiB まで、非 UTF-8 出力は代替表示 |
| `waitTime(seconds)` | 指定した実時間だけ処理を待つ。GUI は動作を続け、中断可能。実行期限を超える待機は拒否 |

ステップ定数と距離定数は、`mtk.` なしのグローバル名でも利用できる。`step`・`stepValue`・`speed` はホスト側に保持し、スクリプトを再実行しても初期化しない。native の初期値は 1 時間・1/24 日・速度 0。通常 GUI の秒/秒レートとは別状態で、停止・手動日時変更・通常 GUI 再生・スリープ・非表示では互換速度を 0 にする。状態復元でも速度を 0 にして自動再開しない。

`step` の直接代入は `stepValue` も原版の日数表へ設定する。月・年・10 年・100 年はそれぞれ 31・365・3650・36500 日、`STEP_VALUE` は 0 日になる。連続再生にはこの固定日数を使い、単発の `forward/rewind` は暦を使う。例えば 2001 年 1 月 31 日から月を 1 ステップ進めると 3 月 3 日になる。native 日時設定画面の秒単位 custom・月末 clamp とは異なる契約である。`prevStep/nextStep` は日数を再計算しないため、列挙値と日数表が一致するとは限らない。

同梱説明書の `stepValue` の「秒」と `backward()` は、対象の Plus 1.5.4 build101013 の実装・登録と異なる。native は確認できた日単位・`rewind()` を公開する。日時入力の月・日・時・分は signed byte の -128..127、秒は int32 の整数に限定し、暗黙の wrap は再現しない。非有限値、積の overflow、core の暦範囲外、読み込み済み暦表の範囲外は適用前に拒否する。根拠と未確定範囲は [N23 時刻契約監査](../../investigation/native-plus/unit7/n23-time-contract-audit.md) を参照する。

地方時差は GUI の「旧 Plus 地方時の時差…」で UTC より西を正とする整数秒を明示設定する。未設定と UTC の 0 秒を区別し、OS 設定や GUI の表示時差から推定しない。日本標準時は −32400 秒。地方時 API と日時補間の全体統合・原版との一致は未検証。

日時は既存 core の簡略モデルへそのまま渡す。UTC と天体暦の時系を厳密に変換する機能はなく、高精度の日食時刻などを保証するものではない。

時計追従は OS 時計を繰り返し読み、非表示・スリープからの復帰時も現在時刻へ同期する。手動日時変更、通常再生、速度指定、停止は時計追従を解除する。これは native の採用契約であり、旧 Plus の操作優先順位と同じだとは確認できていない。

表示設定の取得は GUI の実状態を参照する。恒星名・番号・マークは現在の等級制限と可視域に従う。座標線はビューに応じた投影で、黄道は全天図・地平図では大円、太陽系では平面と軸を表す。円形・方形の距離目盛は太陽系で表示する。`Milkyway.type` は画像が欠損していても選択した値を保持し、別モードの画像で代用せず欠損の診断を表示する。

恒星の明るさは点の径と透明度へ反映し、名称・マーク・等級制限・クリック選択を変えない。直接代入は補間を取り消し、brighten / darken / defaultBrightness は継続中の補間を残す。現在値と同じ target の要求も既存補間を残す。0 秒は同期完了、Lua 終了後も開始済み補間は継続する。これらの確認済み旧動作と native 独自の時計・寿命・画素制限の区別は [恒星の明るさ](STAR_BRIGHTNESS.md) を参照する。`fadeLabels` は必要な 3D 恒星位置・カメラ位置・縮尺を現在の描画が持たないため未対応。

恒星名の選択集合は画面のクリック選択と独立している。`select` / `deselect` は正の int32 範囲の ASCII 十進 HIP を半角空白で区切った文字列、または大文字小文字を区別する単独 `All` を取る。外側・連続空白は許し、符号・小数・指数・接尾辞・空文字・`All` との混在は拒否する。全トークンを検証してから適用する。原版の `atoi` より厳密な native 境界であり、旧版の曖昧な数値変換は再現しない。未知 HIP はこの Lua 境界だけで無視し、`isSelected` は false を返す。`All` は読み込み済みの全名前集合を対象とする。`isSelected` は表示フラグに依存しない。通常 GUI と状態復元では未知 HIP を拒否する。

雲・夜景は太陽系の地球へ、大気は物理半径で描く地球・火星へ反映する。夜景の false は画像を完全に無効化する意味ではなく、採用した標準 Mitaka の高度依存係数へ切り替わる。大気は地球の多重散乱 map がなければ診断付きで単一散乱へ移り、火星は単一散乱を使う。3 定数は `mtk.` 名前空間だけに公開する。大気強度の旧 Lua API は確認できず追加していない。[地球レイヤー](EARTH_LAYERS_PROVENANCE.md) と [大気描画](ATMOSPHERE_RENDERING.md) に描画の範囲と原版との差を記す。

小天体三群と追加衛星の表示フラグは、それぞれの一覧・太陽系ビューと共通の設定を使う。`selectedOnly` はクリック選択一件ではなく、一覧で編集する複数行の表示集合を参照する。表示集合は出典と元の行順で識別し、同名・言語別の原行を統合しない。各群の初期値は `visible=true`、その他三つは `false`、表示集合は空である。この初期値と集合の管理は native 版の契約であり、原版の初期表示集合との一致は未確認である。

実描画には全体の表示、現在のビュー、位置の評価結果も反映される。追加衛星の軌道線は、検証済み Kepler 行について現在日時の親位置・軌道面を固定した瞬時楕円を描く。月の専用解析や未評価行は軌道線を作らず、一覧に診断を表示する。日時を進めた日心軌跡や旧版と同じ線形状を保証するものではない。小天体の軌道線は native の有限期間・標本予算に従う。詳細は [衛星表示の契約](SATELLITE_DISPLAY.md) と [小天体軌道の監査](../../investigation/native-plus/unit5/comet-orbit-contracts.md) を参照する。

これら四群の旧 `show()` / `hide()` / `isVisible()` は未接続。小天体は原番号・名前・別名の完全一致が全出典中で一行だけの場合に選択でき、同名行は曖昧として拒否する。`Satellite.<名前>` は、衛星ブラウザーであらかじめ選択した衛星と同じ出典内で名前を解決する。衛星が選択されていない場合は全出典で一意の名前だけを受け付ける。同じ出典内にも同名行がある場合や、その時刻の位置が未評価の場合はエラーを返す。衛星を選ぶときに出典を明示するこの native 版の方法と、旧版の起動時の言語別出典選択が一致するかは未確認。`Satellite.Moon` は太陽・惑星・月の経路を維持する。

恒星の `Camera.target` は `star_names_HIP.dat` の英語名を大文字小文字を区別して完全一致で解決し、複数の HIP に一致する名前は拒否する。スクリプトで指定した恒星を選択中は指定した文字列を返し、それ以外の恒星は `Star.<HIP番号>` を返す。距離は現在の 3D 恒星表示と同じく正の視差から推定し、固有運動は含まない。位置が得られない恒星は移動できない。

球状星団の `GC.<名前>` は同梱カタログの英語名を大文字小文字を区別して完全一致させる（例: `GC.Terzan 1`）。複数行に一致する名前や位置がない対象は拒否する。`Other.OurGalaxyCenter` は銀河系中心、`Other.OurGalaxy` は銀河系全体を表示し、注視時はいずれも中心を向く。中心位置と全体表示には現在の native 版の近似を使い、旧 Plus の配置や倍率との一致は未確認。`Galaxy.<名前>` と `Other.M31` などは名前とカタログの対応が未確認のため未対応。

星座の `Camera:look` / `lookTo` は、一覧と同じ星座中心の赤経・赤緯を観測地点と現在日時の地平座標へ変換する。正式英語名または略号は大文字小文字を区別して完全一致させ、複数行に一致する場合は拒否する。星座への `Camera.target` は未対応。

`Camera.mode` の取得・切替は地平図と太陽系表示に対応し、全天図ではエラーとなる。地表移行は地球近傍のみで、ほかの天体と `forceMode` は未対応。移行途中の表示モードは実際の画面に従うため、降下中の `toggleMode(To)` は遷移先ではなく表示中のモードを反転する。姿勢 API は太陽系の通常視点に限定し、地平図・全天図・地表・飛行中は未対応。`Camera:lookTo` の対象追従や補間方法の旧版との一致は未確認。`Camera:setTargetTo` は画面切替・手動視点操作・対象変更で停止する。天の川銀河の対象指定では即時指定時の姿勢へ補間し、それ以外の移動中は開始時の姿勢を保つ。移動距離は即時の `Camera.target` と同じ規則を用いる。旧版の `Camera.zoomMode` と移動経路の互換性は未対応・未確認である。

GUI の表示プロパティはウィンドウを閉じた操作も反映する。画像保存パネルは非同期で、Lua は次の行へ進む。関数の正常終了はパネル開始までを意味し、保存・取消の結果を返さない。出力先は通常 GUI と同じ原本保護を通す。投影専用のポインタ・黒フェードは画像へ含まれない。

```lua
Time:setTime(2009, 7, 22, 0, 30, 0)
Time.step = mtk.STEP_MIN
Time.speed = 1
Camera.target = "Planet.Earth"
Camera.zoom = 0.05 * mtk.UNIT_AU
Constels.lines = true
print("year", Time.year)
```

## 互換範囲

`KEEP_RADIUS` で宇宙惑星・太陽倍率を変更する要求はカメラ補正が未対応のため拒否する。倍率の時間補間 `setScaleTo` は未対応。惑星 response は暫定 1 であり、天球図の円は模式表示で物理角直径ではない。

旧 Plus の `doc/script_jp/` と同梱 GUI スクリプトの単位・操作を基に接続した。API ごとの資料と差異は [接続調査](../../investigation/native-plus/local-lua-audit.md) と [単位6の表示 API](../../investigation/native-plus/unit6/lua-display-contracts.md) に記録している。旧 Lua 5.1 用のすべてのスクリプトを実行できるものではない。実行系は Lua **5.4.9** であり、5.1 専用の `setfenv`、`getfenv`、`module`、グローバル `unpack` 等を補完しない。言語・ライブラリの差は [Lua 5.4 公式マニュアルの非互換一覧](https://www.lua.org/manual/5.4/manual.html#8) を参照する。

原版の local 処理は CRT の固定 `__timezone` を参照するが、その初期化契約は未確定であり native は明示設定を用いる。旧カメラの姿勢・遷移アニメーションとの完全な互換、星座ごとの show/hide、3D 空間の星座絵、`Grids.surfacePointer`、旧独自 GUI も未対応。`Milkyway:toggleType()` / `Stars:toggleMarkingType()` は巡回順が未確認のため公開しない。対応表にない API はエラーとなる。表示フラグの接続は旧3D描画の再現を意味しない。

地平ビューは視線を中心に球面を回転した円筒投影を使用し、天頂・天底の周囲も表示する。旧版との投影の一致は未確認。`fov` は未対応。`Camera.duration` の初期値には、旧 `scripts/init.lua` が読み込む `option.lua` の設定を採用している。`State` は旧 Lua 文字列形式と native の JSON 形式が異なり未接続。`GUI.projection` / `dualWindow`、`Scene.Fader` / `Desktop.Fader` は詳細契約未確認のため alias として補完しない。

手元の配布スクリプトを読み取り確認した結果、`ui/scripts/12constels.lua` / `orion3d.lua` は個別星座・3D 配置・カメラアニメーション等に依存し、日食スクリプトも旧カメラの視点・姿勢等の未対応 API を使うため、そのままの全実行には未対応である。`scripts/init.lua` も旧 GUI と `mtk.LANGUAGE` に依存する。これらの原本は変更せず、自動実行しない。

`dofile` / `require` / `io` の相対パスは `ScriptController.workingDirectoryURL` を基準にする。設定されていない場合は、選んだファイルの親ディレクトリを使う。旧 Plus の `scripts/...` 形式に合わせる場合は、呼び出し側が使用中のローカルデータルートを設定する。Lua の通常の `require` 検索規則を使い、独自にネットワークからモジュールを取得しない。

## 描画品質とウィンドウ操作

`Renderer.antialias` / `pointSmooth` / `lineSmooth` / `textSmooth` は boolean の読み書きと、引数なしの `toggleAntialias()` / `togglePointSmooth()` / `toggleLineSmooth()` / `toggleTextSmooth()` に対応する。毎回ネイティブ側の最新設定を読み、三つのビューへ共通設定を反映する。読み出す値は各設定値そのもので、実効描画は `antialias AND 個別設定`。全項目の初期値 true とこの優先関係は native 版の契約であり、旧版の既定値・画素との一致を意味しない。対象はキャンバス内の描画であり、CPU 画像の sampling や標準 UI 部品の描画は変更しない。`MitakaRenderer` alias、stereo 等の未確認・未対応 API は追加しない。

`GUI.fullScreen` は実ウィンドウの状態を読み、boolean の代入で切替を要求する。`GUI:toggleFullScreen()` はウィンドウへ直接 toggle 要求を渡す。成功は非同期切替の受付を意味し、直後の getter は切替前の状態を返す場合がある。遷移中の反対方向要求などの拒否は Lua エラーになる。`GUI:aboutDialog()` は標準のアプリ情報ウィンドウを開く。これらのウィンドウ操作は天文データのロードに依存しない。引数違い・boolean 以外の代入・ホスト側の拒否を成功扱いしない。

## 信頼したローカル HTML

「スクリプト → 信頼したローカルHTML…」から専用ウィンドウを開き、「信頼した HTML を開く…」でファイルを選ぶ。選択時の説明に同意して開いた HTML だけを実行元とする。読み込み完了後、そのメインページの `mtkp://Lua source` リンクをユーザーが押すと、上記と同じ Lua helper・予算・停止操作を使う。リンク先の Lua が未対応 API を呼んだ場合は通常の Lua エラーとなり、旧配布 HTML 全体が動作するという意味ではない。

- HTML は `.html` / `.htm` の通常ローカルファイル、最大 1 MiB、UTF-8 または Shift_JIS。読込時の実体パス・device・inode・SHA256 と同じ読取から得た immutable bytes を表示する。
- クリック時に表示元ファイルの identity と内容を再検査する。変更・置換・別ページへの移動・window close で信頼を解除し、明示選択をやり直す。取り消したオンライン遷移にも信頼は残らない。
- ページ自身の JavaScript、iframe、オンラインページ・外部ネットワーク資産は無効。ローカル CSS・画像は利用できる。`window.external` と JavaScript 経由の旧 API は公開しない。
- アプリ管理の隔離された WebKit script が raw `href` を取得し、main frame の実クリックだけを受け付ける。リンクの `target` は省略または `_self` のみ。`mtkp://` 後の payload を UTF-8 として一度 percent decode し、`+` はそのまま残す。空・不正 UTF-8・NUL・64 KiB 超過は拒否する。この復号は native 版の限定契約であり、旧 Internet Explorer の正規化を完全再現しない。
- Lua の相対ファイル基準は、通常スクリプトと同じく選択中のデータフォルダの親。ユーザーが信頼を与えた Lua 標準ライブラリには同じ権限を与える。元 HTML は書き換えず、0600 の一時 Lua ファイルを専用の一時ディレクトリに保存し、終了・停止後に削除する。

ホーム・ブックマーク、ブラウザ内の自由な遷移、オンライン閲覧、ページ JavaScript の動作互換は今回提供しない。資料は [ローカル HTML 調査](../../investigation/native-plus/local-html-bridge-audit.md) と [境界と検証](../../investigation/native-plus/html-bridge-policy-design.md) を参照する。

## 実行と中断

`ScriptController` は専用実行ファイル `MitakaScript` を起動し、ローカル socket の長さ付き JSON メッセージで通信する。Lua を GUI スレッドで実行しない。`snapshot` / `applyAction` / `output` / `completion` はメインスレッド上で呼び出される。ホストは範囲・選択対象を検証し、拒否理由を Lua エラーとして返す。構文エラーにはファイル名・行、実行エラーには Lua のトレースを付ける。

- 入力ファイルは 1 MiB 以下のローカル通常ファイル。トップレベルはテキスト Lua のみ。
- Lua のアロケータは 64 MiB、Lua 命令は 1,000 万命令、通常の実行は 110 秒に制限する。
- GUI 側も 120 秒で停止するため、標準 C ライブラリ内での待機や Lua フック無効化にも終了期限がある。
- 中断時は helper と同じプロセス群を停止する。明示的に別プロセス群へ離脱した外部処理や、既に書き込んだファイルまでは取り消せない。
- `print` は GUI のログへ送る。`io.stdout` / `io.stderr` の直接出力は `/dev/null` に向かう。必要な出力は `print` または明示したファイルを使う。

## 依存とビルド

標準 C++ / macOS framework には Lua 実行系がないため、公式 Lua を使用する。独自のスクリプト言語や Lua 互換インタプリタは実装しない。GUI helper のみに静的リンクし、core には依存を追加しない。

`tools/build_lua.sh OUTPUT_DIR [ARCH] [SANITIZE]` は [公式 Lua 配布](https://www.lua.org/ftp/) の原本を収録した `vendor/lua-5.4.9.tar.gz` の SHA256 `2335b6c582a52654f94612bf10d2f4672805d05329aa6568b1d8cd9e5c6fb8e6` を検証する。展開ソース・オブジェクトは build 配下に生成する。AppleClang でアプリと同じ macOS 13.0 以上・`arm64` または `x86_64` 向けにビルドし、2 回目以降はキャッシュを使う。初回を含めネットワーク接続は不要。

Homebrew 版 Lua 5.4.8 の静的ライブラリは手元では macOS 15.0 向けだったため採用しない。Homebrew、Lua の別途インストール、外部 Lua dylib は完成したアプリの実行要件に含まれない。配布物には [Lua の MIT ライセンス](LUA_LICENSE.txt) を同梱する。

Lua C API の仕様は [公式 5.4 マニュアル](https://www.lua.org/manual/5.4/manual.html) に従う。呼び出しが `longjmp` する箇所へ C++ / Objective-C の所有オブジェクトをまたがせず、POD の結果へ変換してから Lua スタックへ渡す。
