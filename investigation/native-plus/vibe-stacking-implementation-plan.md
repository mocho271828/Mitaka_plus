# Mitaka Plus 優先順位別スタック実装計画

## 対象と完了条件

- 対象は [`feature-priorities.md`](feature-priorities.md) の P1-1〜P4 の全行と、対応する [`PLUS_FEATURE_MATRIX.md`](../../vendor/mitaka/PLUS_FEATURE_MATRIX.md) の原典・検証条件である。表の「部分」「不足」「未検証」「仕様未確定」を分け、既存動作を消して作り直さない。既存行、Pro 専用行、前提行 SEC/SPEC を新たな機能数に加算しない。
- ユーザーは旧 Mitaka Plus の不明仕様について推測を許可している。旧資料・現実装・データの順に根拠を探し、なお不明な操作や表示は一貫した仮定を選ぶ。仮定、採用理由、実測結果、旧版一致の有無を区別する。安全・権限・認証・配布許諾・破壊的変更の不明点は推測で変更しない。
- 各単位は担当範囲の受入条件、変更に対する回帰試験、必要な実データ／GUI 検証、方針 gate、機能表と検証記録の更新を完了条件とする。複数単位に跨る機能 ID は全担当範囲と必要な検証が揃うまで部分実装または未検証とする。旧版比較が不可能な場合、仮定と未検証を記録し、一致を主張しない。計画書の短い受入文は機能表を省略・緩和しない。
- 実装先は本番投入前の macOS ネイティブ版で、`vendor/mitaka` は通常ファイル。原本・リソース・旧アプリ・Wine 環境を読み取り専用とし、Private を維持する。外部データの取得・再配布を前提としない。データ追加は承認済み Earth/Mars 地形の範囲に限る。
- 信頼した明示選択ローカル Lua の既存権限、HTML bridge のローカル文書と明示操作に限定する境界、自動実行禁止、JSON v9 の検証・原子的適用を守る。`IMPLEMENTATION_POLICY.md` と全 `policy_gates/` が優先する。機能実装で既存の全体方針を変える場合、当該単位で方針と gate を更新する。
- 全予定単位を順に実装し、各単位をレビュー可能な形にする。vibe-stacking によるブランチ／PR の作成は plan gate を通過してから行う。未承認の公開、破壊的 Git 操作、権限拡大は行わない。

## 単位の読み方と共通検証

各行は機能範囲を示す。実際のブランチ順・分割・依存関係は [スタック計画](vibe-stacking-stack.md) を正本とし、同一ファイルに触れる後続単位は親へ積む。優先度 P1→P2→P3→P4 を維持し、同じ優先度内で依存を満たす順に並べる。予定単位が大きくなったときは機能・契約の境界で分割し、機械的な薄い変更は親へまとめる。各行のファイル名は主な入口であり、関連モデル・テスト・UI／Lua 接続の追加変更を妨げない。以下 `gui/` と `core/` は `vendor/mitaka/native/` 以下である。仮定を必要とする場合は上記の範囲で記録して進め、データ取得・安全境界の変更が必要な場合だけ、その変更を実行せず理由を報告する。

- 実装前 baseline: `make build`、`make test`、`make data-test`、`make reference-test`、`make smoke` は今回成功済み。これらは旧版比較や目視確認の実施を意味しない。
- 各単位: 対応する単体・controller テストと失敗／境界系、必要に応じて実データを使う統合試験を追加または実行する。描画・操作は同梱データの実画面でも確かめる。検証不能な機器・旧版は未検証として残す。
- 各作業単位の結合: `make build`、`make test`、`make data-test`、`make reference-test`、`make smoke`。`make test` は GUI の `unit8-test` を含む。地形は別途 `make -C vendor/mitaka/native/gui terrain-real-data-test`、独立銀河 controller は `galaxy-controller-test` を実行する。
- 各単位: `policy_gates/` を `temp_gates/YYYY-MM-DD-HH-MM-SS/` に複製し、検証コピーの checkbox と YES/NO を実際に記入する。Git 状態・変更ファイル・差分量を確認する。300 行以上なら既存依存の利用と `/simplifier-lai` の利用可否を確認して原則 commit する。指定 skill がなければ実施不能を報告する。
- 仮定の主な基準: 距離は既存 Lua `zoom` の pc、地上 FOV は 45° 復帰を提供し不正値を拒否。現行の地平起動視野は 180° のため、起動値と投影移行の整合を確認し、無条件で起動値を 45° へ変更しない。旧資料の GUI 距離ラベルと実引数の 10 倍差はどちらかを無根拠に書き換えず、検証・説明を残す。時刻はデータごとの既知の時系だけを保証し、未知を数値 JD と記す。名称のないカタログ点を近傍天体と断定しない。視覚の補間や UI 詳細は既存操作と矛盾しないよう決める。

## 最初の単位: CAM-03 の距離補間契約

- 対象は `Camera:setZoomTo(distance, duration)` と `Camera:setZoomLogTo(distance, duration)`。`distance` は既存 `Camera.zoom` と同じ pc、内部カメラへの変換は既存 `auPerParsec` に従う。`duration` は秒で、省略時は `Camera.duration` を使い、未設定の場合は既存の他の Camera アニメーションと同様にエラーにする。通常起動時の既定値は 9 秒。明示 0 秒は即時適用。
- 非同期に開始し、通常の画面更新時に現在距離を反映する。`setZoomTo` は開始から終了の距離を線形、`setZoomLogTo` は対数距離を線形に補間する。終点を正確に設定し、進捗を 0〜1 に制限する。曲線の旧版詳細は未確認のため、この規則は仮定として記録する。
- 開始・終点とも正かつ有限、duration は非負かつ有限とし、不正値を拒否して直前の視点を維持する。新しい zoom 指定はその時点の距離から開始し、旧 zoom 補間は置き換える。即時 `Camera.zoom` 代入も旧補間を解除する。対象選択・対象の時刻追従によるカメラの中心移動と距離補間を両立させ、手動操作やモード変更の競合規則は既存 camera 動作を確認して統一する。
- 境界は Lua 引数解析（`ScriptWorker.mm`）、action・transport の表現（`ScriptController.mm` 等）、UI スレッドでの時刻更新（`AppScripting.mm`）と既存カメラのみ。FOV・状態形式・他の操作の仕様はこの単位に含めない。
- 受入: 1→100 pc、2 秒の補間で開始時・1 秒・終了時がそれぞれ線形 1/50.5/100 pc、対数 1/10/100 pc。逆方向・極端な有限値・非有限値・0・負値、duration 省略／0／負／非有限、補間中の再指定・即時代入・動く対象との同時実行を自動試験。必要なテスト時計を注入し、実時間待機に依存しない。Lua 入口から action を経てカメラの読み戻しを試験し、実画面は通常の GUI 検証で確認する。

## P1: 基盤と移動

| 単位 | 対象 ID / レビュー理由 | 主要境界・依存 | 受入と検証・仮定 |
| --- | --- | --- | --- |
| 1 | P1-1a CAM-03 距離の時間補間 | `gui/src/ScriptWorker.mm`, `ScriptController.mm`, `AppScripting.mm`, `solar_camera.cpp`。先行なし | 既存 pc `zoom` に線形 `setZoomTo` と対数 `setZoomLogTo` を接続し、正値・途中再指定・終了・対象追従・即時設定を `test_script_controller.mm` と実画面で検証。旧資料との差は仮定を記録。 |
| 2 | P1-1b CAM-03 地上 FOV | `HorizonView.mm`, 地平投影・逆投影、Lua、状態保存。1 の後 | `fov` と `setFovTo` を距離から独立させ、45° 復帰、範囲検証、補間／中断、既存起動視野 180° と投影移行の整合、描画とクリック位置の一致を検証。API の適用範囲は資料のプラネタリウム用を優先し、宇宙側まで同一と断定しない。 |
| 3 | P1-1c GAL-02 点群の個別選択と名称 | `OurGalaxyRenderer.mm`, `OurGalaxyRadiativeRenderer.mm`, `our_galaxy_navigation.cpp`, `GalaxyOverlay.mm`。2 の後 | 描画点の出典・group・ordinal を選択結果に結び、重なり・非表示点・画面外を検証。名前と対応する確かなキーがある場合だけ結合し、ない点は出典識別子を表示する。`test_our_galaxy_renderer.mm`, `test_our_galaxy_navigation.cpp` と実データ。 |
| 4 | P1-1d GAL-02/GAL-03 連続視点と実描画 | `shared_camera.cpp`, `galaxy_camera.cpp`, `galaxy_spatial_scene.cpp`, `GalaxyRenderer.mm`, `HipSpatialRenderer.mm`。3 の後 | 太陽系→恒星→天の川→SDSS/QSO を同一視点で往復し、位置・縮尺・選択の連続性と表示復帰を検証。`test_shared_camera.cpp`, `test_galaxy_spatial_scene.cpp`, `galaxy-controller-test` と実画面。色・座標・測光の旧版比較は観測できた範囲のみ記録。 |
| 5 | P1-2 OBJ-15 地平動天体 | `horizon_objects.cpp`, `HorizonView.mm`, 小天体・PTH の位置 evaluator。4 の後 | 彗星・小惑星・有効 PTH の描画、選択、同一 JD・観測地点、表示切替、時刻追従を `test_horizon_objects.cpp`, `test_horizon_view.mm`, `make data-test` で検証。視差・光行時間・時系などの補正は根拠と採用範囲を明記。PPI は P2-11 の別契約で扱う。 |
| 6 | P1-3 OBJ-06 地形世代と連続操作 | `TerrainSurfaceController.mm`, `terrain_generation_coordinator.hpp`, `terrain_surface.cpp`, `SolarTerrain.mm`。5 の後 | Earth/Mars 実データで連続移動・連続 JD・停止後復帰・欠落を確認。古い世代を公開せず、表示中の地形と scene の時刻を一致させる。`test_terrain_generation_coordinator.cpp`, `test_terrain_surface_controller.mm`, `terrain-real-data-test` と操作遅延の実測。高速時の基準球表示を無条件に欠陥扱いしない。月・水星の別配布取得は承認範囲外。 |
| 7 | P1-4a OBJ-09/OBJ-10 37 byte 形式 | `core/src/minor_planet_position.cpp`, 同 tests、`small_body_model.mm`。6 の後 | 36 と 37 の loader を区別し、不正長・切断・全原行／順序／重複・出典 ID を保持。37 byte の raw record を隔離して構造・由来を調査し、Mitaka++ の色分岐の根拠と旧 Plus 採用未確認を明示。旧 Plus が使用するとみなして位置や分類の意味を推定しない。内部表現から元行を削除しない。 |
| 8 | P1-4b OBJ-09/OBJ-10 軌道と表示 | `core/src/minor_planet_orbit_path.cpp`, `small_body_orbit_model.cpp`, `SmallBodyRenderer.mm`。7 の後 | 36 byte および根拠を確認できる個別形式の位置・選択・一周期軌道・標本上限・不正値を `test_minor_planet_position.cpp`, `test_minor_planet_orbit_path.cpp`, `test_small_body_orbit_model.mm` と実データで確認。37 byte は旧 Plus の採用・位置契約を確認するまで描画・位置評価へ混ぜず、未知の物理時系と旧標本規則を記録。 |
| 9 | P1-5a CAM-01 宇宙と地表の連続切替 | `surface_navigation.cpp`, `interplanetary_flight.cpp`, `SolarSystemNavigation.mm`, `SolarTerrain.mm`。8 の後 | 同一時刻と観測地を保ち即時／時間指定・往復・中断・`forceMode` を確認。投影・画角・風景・遮蔽の遷移を検証し、ジャンプを抑制。`test_surface_navigation.cpp`, `test_interplanetary_flight.cpp` と GUI。 |
| 10 | P1-5b CAM-01 非地球の地平表示 | `HorizonView.mm`, `horizon_objects.cpp`, `surface_navigation.cpp`。9 の後 | 観測天体の自転・地表座標・時刻で地平表示し、地球／火星・月で地上と宇宙を往復、可視対象と選択が一致。従来の非地球 3D 地表と操作範囲を区別する。 |
| 11 | P1-6 CAM-02 姿勢・ロール | `SolarScriptOrientation.mm`, `shared_camera.cpp`, `SolarSystemView.mm`, Lua。10 の後 | 姿勢の往復・相対回転・極付近・補間・中断・位置不変をテスト。Lua から主画面の銀河、地平、地表、飛行中に実行。独立銀河ブラウザ・全天図の対象範囲を仮定として明示。 |
| 12 | P1-7 CAM-04 地上方位・高度 | `horizon_segments.cpp`, `HorizonView.mm`, `surface_navigation.cpp`, Lua。11 の後 | 地球・非地球で時刻／観測地固定の方位・高度、極・天頂・0/360°・時間補間・中断を確認。`test_horizon_segments.cpp`, `test_horizon_view.mm`, `test_script_controller.mm` と実画面。 |
| 13 | P1-8a CAM-06 対象の名前／ID 契約 | `SolarScriptTarget.mm`, `AppScripting.mm`, 各 catalog／spacecraft／small-body model。12 の後 | 機能表の全種別と観測地接尾辞を解決し、重複名・複数出典・不明値・未評価行で誤選択しない。名前／ID の往復と source/ordinal をテスト。 |
| 14 | P1-8b CAM-06 移動・注視・追従 | `SolarSystemNavigation.mm`, `SolarScriptTarget.mm`, `HorizonView.mm`。13 の後 | Earth 地点間・非地球地表発・宇宙発の即時／時間指定移動、回転追従、中断、最終姿勢、地上の look／lookTo を実データと Lua で確認。星・星座の無限遠近似や zoomMode の未知半径規則を記録。 |

## P2: 基本天文表示・選択・時刻

| 単位 | 対象 ID / レビュー理由 | 主要境界・依存 | 受入と検証・仮定 |
| --- | --- | --- | --- |
| 15 | CAM-07 座標選択と選択モード | `SkyView.mm`, `SolarSystemView.mm`, 対象選択／Lua。14 の後 | NONE/MOUSEOVER/MOUSECLICK と座標選択、名前選択が同一対象を返す。背景・重なり・可視外・モード切替を検証。 |
| 16 | CAM-08 統一対象ブラウザ | `CatalogBrowserController.mm`、各 BrowserController。15 の後 | 全ロード対象を出典・階層付きで検索し、右クリックのジャンプと向き変更、地上追従を区別。重複名・未評価対象も保持。 |
| 17 | CAM-09/CAM-10 距離自動調整とホーム | `SolarSystemNavigation.mm`, `SolarScriptTarget.mm`, session state。16 の後 | NONE/AUTO/ALWAYS の距離差、対象全種のジャンプ・時間指定、保存ホーム復帰をテスト。未知半径と AUTO 判定の仮定を明記。 |
| 19 | CAM-12 地表クリック移動 | `SolarSystemView.mm`, surface projection/navigation。17 の後 | ダブルクリックから地球の緯度経度へ変換し、裏面・輪郭・極・ミスを含め補間移動を検証。 |
| 20 | TIME-03 時系・地方時 | `calendar_time.cpp`, `AppScriptingTime.mm`, `AppTimeCommands.mm`。19 の後 | UTC/地方時の取得設定・別名・夏時間／offset と往復、日付境界・不正値を確認。時系変換の根拠と保証範囲を記載。 |
| 21 | TIME-04/TIME-05/TIME-06/TIME-07 時刻移動・時計追従 | `plus_time_step.cpp`, `plus_time_playback.cpp`, `playback_clock.cpp`。20 の後 | 刻みの境界と month-end、正逆・全速度・変更中の全表示の同一 JD、リアルタイム時の時計変更を検証。GUI と Lua の単位契約を区別。 |
| 22 | ANIM-01 共通時間補間 | `plus_time_animation.cpp`, `PlaybackController.mm`, Lua transport。21 の後 | 属性・日時の時間補間と連続番組で開始／中間／終了・一時停止・再指定・取消を確認。カメラ等の既存実装を接続。 |
| 23 | OBJ-03 大気 | `atmosphere_renderer.cpp`, `sky_background.mm`, `HorizonView.mm`。22 の後 | 利用可能な同梱散乱データで地平空・昼夜・表示切替を検証し、欠落と近似を区別。旧版比較は可能な範囲で記録。 |
| 24 | OBJ-04 地上の日食暗化 | `eclipse_surface.cpp`, `eclipse_display.cpp`, `atmosphere_renderer.cpp`。23 の後 | 太陽・月・観測地・同一 JD と物理半径から暗化し、食なし／部分／皆既と表示切替を試験。 |
| 25 | OBJ-05 表示倍率補間・KEEP_RADIUS | `radius_display.cpp`, `RadiusDisplayController.mm`, shared camera／Lua。24 の後 | 4 倍率と mode の補間、KEEP_RADIUS 時のカメラ補正、月位置・軌道と物理計算の分離を試験。旧補正順序は仮定として記録し、該当 policy/gate の未対応記述を同じ単位で更新。 |
| 26 | OBJ-07 衛星位置と自転 | `core/` 衛星モデル、`satellite_scene.cpp`, `planet_surface.cpp`。25 の後 | 対応軌道・衛星表面・自転を同一 JD で評価、出典／原行を保ち、精度期間・時系不明を明示。基準データと親重心の二重補正防止を検証。 |
| 18 | CAM-11 衛星への離着陸 | `surface_navigation.cpp`, 衛星 scene、自転モデル。26 の後 | 対応する惑星・衛星で連続離着陸し、Horizontal / Surface View を区別。親天体・自転・時刻と欠損データを検証。 |
| 27 | OBJ-08 彗星の名前と表示 | 彗星 evaluator、`SmallBodyRenderer.mm`, Lua。18 の後 | 既知の古代暦と名前 API を検証し、不明な行は保存したまま評価不能を表示。尾は同梱資料・データで可能な描画を採用し、旧版提供の推測を明記。 |
| 28 | OBJ-11 オールトの雲 | `core/` の入力モデル、`SolarSceneRenderer.mm`。27 の後 | 同梱データがあれば出典を保持して描画、なければ原本の代替として扱わない明示的な模式モデルを採用。選択・表示切替・縮尺・性能を確認。 |
| 29 | OBJ-12 PPI と探査機姿勢 | spacecraft model、`SpacecraftRenderer.mm`。28 の後 | PPI を PTH と区別し、原点・面・時系の仮定と信頼範囲を記録。機体位置・姿勢・アニメーション・データ範囲外・無効標本を試験。現行 gate が禁じる PTH と同一扱いをしない。 |
| 30 | OBJ-13 はやぶさ・あかつき | `SpacecraftRenderer.mm`, spacecraft model。29 の後 | 同梱形状・姿勢で機体と動きを表示、日時追従・欠損・可視切替を確認。未同梱の画像やモデルを無断取得しない。 |
| 31 | STAR-02 3D 恒星名 | `star_labels.cpp`, `HipSpatialRenderer.mm`, `StarRenderer.mm`。30 の後 | 正の視差で位置評価できる近傍星名と距離依存 fadeLabels を表示し、重複／非表示／未評価を確認。 |
| 32 | CONST-01 3D 星座 | `ConstellationRenderer.mm`, `constellation_display.cpp`, `HipSpatialRenderer.mm`。31 の後 | 3D 空間から星座名・線・境界を表示し、全天／地平の状態と略号を共有、切替・星欠損・視点移動を確認。 |
| 33 | DATA-01/DATA-02 観測地の編集・適用・ラベル | `observer_places.cpp`, `place_display_model.cpp`, `AppObserverCommands.mm`。32 の後 | 他天体の地点適用・編集保存・3D 着陸・Lua と距離条件／グループ操作を確認。原本は変更せずユーザー保存先を使用。 |
| 34 | DRAW-02 実データ描画性能 | 各 renderer と可視化 scene。33 の後 | P1/P2 の対象レイヤーを実データで測定し、入力件数・視点・解像度・時間と欠落なしを記録。必要な可視範囲絞り込み・キャッシュを回帰検証。 |

## P3: 旧機能・スクリプト・状態・メディア

| 単位 | 対象 ID / レビュー理由 | 主要境界・依存 | 受入と検証・仮定 |
| --- | --- | --- | --- |
| 35 | CAM-13 視点情報とヘッドライト | camera／scene renderer、Lua。34 の後 | 表示と照明を独立切替し、移動・姿勢変更後も視点基準で保つ。 |
| 36 | TIME-02/TIME-08 日時ダイアログ・表示切替 | `AppTimeCommands.mm`, `calendar_time.cpp`。35 の後 | 入力／カレンダー・閏日・無効日と表示切替を確認し、表示だけの変更で時刻を変えない。 |
| 37 | OBJ-02 惑星レイヤー | `earth_layers.cpp`, `planet_textures.mm`。36 の後 | 4 レイヤーを個別切替し対象と状態保存を確認、取得できる範囲で原版の画面と比較。 |
| 38 | STAR-03/STAR-04/STAR-05 恒星 API と表示 | `StarRenderer.mm`, `StarBrightnessController.mm`。37 の後 | HIP 選択往復、連星・系外惑星、明るさ補間と全モードを検証。旧テクスチャの比較結果を記録。 |
| 38a | OBJ-14 小天体・探査機の名前別表示 API | `SmallBodyController.mm`, `SpacecraftController.mm`, `ScriptWorker.mm`。38 の後 | 名前別 show/hide/isVisible と探査機の個体別表示集合を検証。重複名・不明名と個体／種別の切替を区別し、原行識別を維持。 |
| 39 | CONST-02/CONST-03 3D 星座絵と Lua | `ConstellationArtRenderer.mm`, `constellation_display.cpp`。38 の後 | 3D での星座絵配置・可視切替、略号別 show/hide/isVisible を検証。全天・地平絵と区別。 |
| 40 | GAL-01 天の川描画 | `sky_background.mm`, 銀河 renderer。39 の後 | 4 種の切替と投影・屈折・フェードを検証し、可能な場合に旧版と比較。 |
| 41 | GRID-01/GRID-02/GRID-03 座標線・距離目盛・地表ポインター | `grid_geometry.cpp`, `distance_scales.cpp`, `GridRenderer.mm`。40 の後 | 4 座標系の軸と極、距離間隔と視点距離、地表ポインターの API と GUI 一致を検証。 |
| 42 | DATA-03 風景編集 | `earth_landscapes.mm`, `HorizonLandscapeRenderer.mm`。41 の後 | 風景の編集・他天体・フェード、欠損画像を検証し、ユーザー保存先を使う。 |
| 43 | DATA-04 外部データ形式 | 各 loader、catalog browser。42 の後 | 対応形式ごとの追加／再読込・GUI 編集・保存先・不正入力を検証。原本は変更しない。外部取得は行わない。 |
| 44 | DATA-05 翻訳データ | 翻訳／名称 loader、UI。43 の後 | 複数出典の共存、言語切替、欠落と重複を検証。 |
| 45 | UI-02/UI-08 複数画面 | `WindowPresentationController.mm`, `DisplayOutputController.mm`。44 の後 | 全画面の非同期遷移、複数投影ウィンドウの同期・配置を試験。物理画面が足りなければ自動試験の結果と手動未検証を記録。 |
| 46 | UI-03/UI-04 描画設定・スナップショット | `RendererQuality.mm`, `AppWindowCommands.mm`。45 の後 | 寸法・透明背景・全入力・保存エラー、描画品質／操作ダイアログの設定反映を検証。 |
| 47 | UI-06/UI-07 ウィンドウ配置・文書 | `WindowPresentationController.mm`, `AppWindowCommands.mm`。46 の後 | 全配置の保存／復帰／初期化、画面消失時の可視領域復帰、明示選択文書の openDocument と欠損を確認。 |
| 48 | UI-09/UI-10/UI-11 投影 UI | `DisplayOutputController.mm`, `GridRenderer.mm`, `AppDisplayCommands.mm`。47 の後 | フェード時間・ポインター XYZ の往復、文字倍率・ふりがな・FPS・版・デバッグ表示の独立切替を検証。 |
| 49 | RENDER-01/RENDER-02 描画品質・明示描画 | `RendererQuality.mm`, render loop／Lua。48 の後 | 文字品質の独立設定、明示描画・フレームカウンター・出力寸法／パターン、無効値を確認。旧 OpenGL 画素比較が可能なら記録。 |
| 50 | LUA-01/LUA-04 Lua 互換 | `ScriptWorker.mm`, `ScriptController.mm`。49 の後 | 各機能の host API・別名を公開し、同梱旧番組の 5.1／5.4 差と標準関数を試験。明示選択のローカル実行・取消を SEC-01 の境界で維持。 |
| 51 | LUA-02/LUA-03 エディタ・コンソール | script controller、AppKit UI。50 の後 | 内蔵編集・ユーザー保存・操作／カメラ記録、対話入力・履歴・失敗・取消を検証。自動実行しない。 |
| 52 | STATE-01/STATE-02 状態の保存とメモリ内復帰 | `session_state.mm`, `session_layers_json.mm`, Lua。51 の後 | 追加対象を含む全状態の保存・復元と store/restore/getStored/canRestore、失敗時の全体不適用を検証。実行可能形式は信頼済み明示操作のみ。 |
| 53 | STATE-03 初期状態 | session state／起動設定。52 の後 | 明示先・読込順の非実行データを保存／解除して再起動復元し、欠損と循環参照を検証。旧 init.lua 自動実行は現行方針上行わず、互換の未達として記録。 |
| 54 | INPUT-01/INPUT-02 入力割当と操作 | AppKit 入力、camera／Lua。53 の後 | キー・マウス・ジョイスティックの登録／解除／照会、移動速度・慣性・ロール・フォーカス喪失停止を試験。実機未所持の装置は未検証と記録。 |
| 55 | CUSTOM-01/CUSTOM-02 メニュー・ツールバー | AppKit menu/action、Lua。54 の後 | 共有 action の作成／更新／消去、実行と状態更新、アイコン／キーの同期・残存参照を検証。 |
| 56 | CUSTOM-03 スクリーンメニュー | screen menu model、入力、Lua。55 の後 | 階層移動・追加・戻る・取消・更新をキーと利用可能な装置で試験。 |
| 57 | MEDIA-01 動画 | `MediaController.mm`, `media_catalog.mm`, 合成 renderer／Lua。56 の後 | ローカル動画の選択・表示・再生・停止・フレーム移動と先頭末尾、破損・終了を検証。対応コーデックと合成位置の仮定を記録。 |
| 58 | MEDIA-02 音声 | `MediaController.mm`, AVFoundation／Lua。57 の後 | 再生・一時停止・位置・終了・デバイス喪失を検証。frame 単位の仮定を明記。 |
| 59 | MEDIA-03 画像 | `MediaImageView.mm`, `media_catalog.mm`, 合成 renderer／Lua。58 の後 | 複数画像の画面合成・ルビ・先頭末尾・不正 index／破損／空集合を検証。 |
| 60 | CUSTOM-04 メディアメニュー | screen menu と media catalog。59 の後 | 動画・画像・音声の階層と対象の実再生を検証。charts/titles は P4-64/65 の実装後に同じ契約へ接続し、先に全種完了と扱わない。 |

## P4: 装飾・限定機能

| 単位 | 対象 ID / レビュー理由 | 主要境界・依存 | 受入と検証・仮定 |
| --- | --- | --- | --- |
| 61 | DRAW-01 表示切替フェード | renderer／表示状態と共通 animation。60 の後 | 名称・軌道等で表示開始／停止の時間補間・途中反転・最終状態を検証。 |
| 62 | UI-05 GUI テーマ | AppKit UI／スタイル設定。61 の後 | 標準・黒テーマと切替、設定保存、可読性・各画面への反映を検証。旧 stylesheet の非対応構文は明示。 |
| 63 | RENDER-03 アナグリフ | render camera／出力。62 の後 | 通常 Plus の左右視差と色合成、無効時復帰・サイズ変更を検証。Pro 専用方式と混同しない。 |
| 64 | MEDIA-04 3D チャート | media catalog／3D scene／Lua。63 の後 | 原版形式の確認可能な入力を切替し、配置・表示状態・index/name と不正入力を検証。形式が不明なら根拠と仮定を明示する。 |
| 65 | MEDIA-05 タイトル | media catalog／画面合成／Lua。64 の後 | タイトルの選択・表示・非表示と文字／画像配置、空集合を検証。64/65 を CUSTOM-04 へ接続し全メディアを実際に選択する。 |
| 66 | MEDIA-06 サウンド controller | 音声 controller／AppKit window。65 の後 | 開閉・再表示と再生状態の同期、音声停止・機器喪失を試験。旧 API の綴り・ウィンドウ詳細の仮定を記録。 |
| 67 | CUSTOM-05 UI ブラウザ | `HtmlBrowserController.mm`, `html_bridge_policy.mm`。66 の後 | 現行のローカル信頼境界を守りつつホーム／ブックマークや安全な API を検証。オンライン文書・frame・遷移先の実行を拒否。JavaScript、Flash、オンライン経由実行の互換は安全方針との衝突として未達を記録。 |
| 68 | CUSTOM-06 天文トピック | ローカルシナリオ／HTML bridge。67 の後 | 同梱トピック・日食ショートカットを明示操作で開き、日時・観測地・視点を再現。外部ページへの権限継承を拒否。 |

## 分岐・保留とリスク

- この表は全 88 件の対象行を網羅する機能単位案であり、既存実装済みの部分は回帰・統合検証を優先する。各単位の正確な差分、テスト名と分割点は着手時に現 HEAD を再確認する。単位 60 は 64/65 の後に残る接続を別の子単位として切り出してよい。
- PPI を PTH と同一視しないこと、非承認の外部データを取得しないこと、原本・出典・重複を保持することは、仕様の推測許可を受けても維持する。利用データや機器がない場合は利用できる範囲を完成させ、欠落分を未検証と記録する。
- `STATE-03` の旧スクリプト自動実行と `CUSTOM-05` のオンライン JavaScript / Flash 実行は現行セキュリティ方針と衝突する。信頼境界の変更は推測せず、独立部分を実装してから必要性・影響を具体化し、変更時のみユーザー確認を求める。
- 旧 Plus の観測不可、複数物理画面・ジョイスティック・音声デバイス等の不足は、実行できる自動検証と分けて明記する。旧版との一致が未証明であっても、仮定の根拠を記録して実装を進める。
- ユーザー指定の会話内計画を採用し、旧仕様の推測については明示された許可に従う。branch 名、サイズ予算、backend、提出窓、実装状態はスタック計画に記録する。
