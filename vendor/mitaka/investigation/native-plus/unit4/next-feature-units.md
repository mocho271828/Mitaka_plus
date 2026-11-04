# 残機能を進める次の実装単位

2026-10-29。UNIT3 の source `cf4fcbfe5447adf554e5bca0b0caf5ae5f529505` と、UNIT4 作業中のコード・監査を基点とする。対象は通常の Windows Mitaka Plus 1.5.4 build101013。これは実装順の提案であり、未完機能を対応済みに変更する文書ではない。

本書は [PLUS_FEATURE_MATRIX.md](../../../PLUS_FEATURE_MATRIX.md) の全 ID を、後続の実装・確認・対象外のいずれかへ割り当てる。API 文書は同梱 1.3.0、公式ソースは通常版 1.3.1 なので、Plus 1.5.4 の実行契約と区別する。原本は読み取り専用とし、独自データを公開データへ置換しない。

## 現在の単位に含まれるもの

UNIT4 の衛星、Renderer 4 設定、fullscreen/About、ローカル HTML は統合・検証中である。後続の新規作業と重複して担当を割り当てない。

| UNIT4 の対象 | 確認できた範囲 | 残す境界 |
| --- | --- | --- |
| 衛星 loader・回転・相対位置・登録モデル | Plus の 340 衛星を保持。独立再ビルドで実データ 2,158 checks 成功。328 通常相対位置、2 Moon 専用、10 未評価、4 shadowed を別々に記録 | source 別登録は native の独立コンテナであり旧 startup の再現ではない。L の RA/Decl 欠損を推測で補わない。絶対位置・GUI・選択・状態保存は UNIT4 の統合結果で判定する |
| 宇宙機 loader | Plus の PTH 原時刻・位置・同時刻行、通常版の PPI と定義・ORIGIN 原文を保持 | PTH の補間・単位・座標面・原点、PPI の表示側の時系・座標面は別確認。読み込めたことだけで表示可能としない |
| Renderer 4 bool、fullscreen/About | native の操作・取得と Lua の接続を追加中 | Renderer の明示描画、frame、立体視、一般オプションは別単位 |
| 信頼したローカル HTML | policy helper、WebKit controller と試験を追加中 | 繰返し open、古い view、外部接続、遷移による失効を含めた最終検証前。オンライン実行と Flash は対応したとしない |

衛星レビューで確認した境界は、原 bytes と全行の保持、source ごとの登録、構造上の親、Q の成功登録 index、補正前 CF96 入力、同じ source 内で一度だけ行う Earth/Moon・Pluto/Charon 補正である。GUI 詳細から回転診断が欠落する指摘は root が修正中。

## 優先順

手元データを実際に使える範囲を先に増やす。確定済み計算から描画へ進む作業と、未知契約の静的追跡を並行させる。後者の調査が終わるまで前者を止める必要はない。

| 優先 | 次単位 | 成立させる最小の成果 | 着手条件・受入 |
| --- | --- | --- | --- |
| 1 | N01: 彗星の軌道線と表示設定 | 現在評価可能な JPL 行を対象に、本体・名称・軌道・選択対象のみを別設定にし GUI/Lua/状態へ接続 | 楕円・放物線・双曲線を区別。有限の標本区間を明示し、非周期軌道を閉じない。未評価行・重複・選択 ID は保持 |
| 2 | N02: 衛星表示の UNIT4 後続 | 統合済みの絶対位置を使用する表示設定、Lua の対象指定、軌道線 | UNIT4 の位置/親/補正契約を再実装しない。未評価 10 行を消さず理由を表示。型付き ID は source と定義 ordinal を含む |
| 3 | N03: 宇宙機の評価契約追跡と表示 | PPI/PTH ごとに確定した subset の位置・名前・経路・選択を一覧と 3D へ接続 | 原本の loader→補間→親加算→描画変換を追跡。PPI の km だけから J2000/TDB を推測しない。PTH の同時刻行を整理・削除しない |
| 4 | N04: mp/mp2/TNO/TNO2 の評価契約 | 既存全件保持 loader から、座標・時刻が確定した record だけ位置計算を有効化 | 同一番号・同日時を出典ごとに保持。既存 Kepler を利用。未知時系を UTC/TT/TDB と命名せず、不明項目を個別診断 |
| 5 | N05: 星座個別表示と地平図 | 既存線・境界・名称を地平投影へ接続し、略号による表示集合を追加 | `Ser` が二つの図形に対応することを保持。`All`・大小文字・未知略号・集合と global flag の優先を追跡してから旧 API を公開 |
| 6 | N06: 地平図の天の川 | 既存の 4 種背景と確定した銀河変換を観測地/JD の投影へ接続 | 既存 ObservationFrame を使用。極・経度 seam・地平線で偽線や重複変換がないことを確認 |
| 7 | N07: 地点ラベルと風景 | 原文保持済み地点グループを表示し、解釈を確定した風景 PNG を地平図へ接続 | まずラベル群を独立単位にする。風景末尾 2 offset の順・符号・単位は SPEC-11 の追跡後。ユーザー追加地点・別天体行も保持 |
| 8 | N08: 地球の雲・夜景 | 手元 `earth_cloud.jpg` / `earth_lights.jpg` を独立レイヤーにする | 公式式の採用範囲を明記。昼夜と視点、経度 offset、地表/宇宙の差を試験。JPEG alpha を雲量とみなさない |

N03 と N04 は「調査→確定 subset の evaluator→GUI」の順に分けて commit できる。N01/N05/N06 の表示作業とは独立しやすい。N02 は UNIT4 の実際の完了範囲を差し引いて着手する。

## データと描画の後続単位

次表の番号は担当分割のための識別子であり、公開 API 名ではない。1 行の候補も、計算・描画・UI の変更が大きければ表記した段階ごとに分ける。

| 単位 / 対応 ID | ローカル根拠・再利用 | 実装の境界と完了条件 |
| --- | --- | --- |
| N01 彗星 / OBJ-08、OBJ-14、OBJ-15 | [軌道監査](../local-orbits-audit.md)、既存 small_body_catalog/orbit/model | 種類別設定と軌道線を先に実装し、地平図の投影は別段階。尾は SPEC-08 を調査。古代暦の不明行を現代暦へ仮変換しない |
| N02 衛星 / OBJ-07、CAM-06、OBJ-14 | [衛星位置契約](satellite-position-contracts.md)、SATELLITE_*_PROVENANCE | source 別の全 340 行と専用 Moon 経路を使用。親に従う軌道線と自転/表面/着陸は別機能。形状や姿勢を公転基底で代用しない |
| N03 宇宙機 / OBJ-12、OBJ-13、OBJ-15 | [軌道契約監査](../orbit-contracts-audit.md)、SPACECRAFT_TRAJECTORY_PROVENANCE、手元 spacecraft 定義 | 本体の点・名称・経路が先。Hayabusa/Akatsuki 固有の姿勢・3D モデル・可動部・表示期間は別単位。通常版 Gaia/TESS の EARTH 原点と SS_BC/SUN を混同しない |
| N04 小惑星/TNO / OBJ-09、OBJ-10、DATA-04 | 同軌道監査、既存全件保持 SmallBodyDataset | 時系・座標面・優先 source を確認。mp と mp2、TNO と TNO2 を勝手に統合しない。calc 不能と非表示を区別し、追加 file の失敗は source 診断で残す |
| N05 星座線と集合 / CONST-01、CONST-03 | [星座契約監査](../local-constels-contract-audit.md)、constellation_HIP.dat、89 CDF | 88 略号と 89 形状を保持。全天/地平の同じ集合で表示・検索・選択を検証。3D 星空への投影はカメラ単位の後 |
| N06 天の川 / GAL-01 | [資産監査](../local-assets-audit.md)、既存 sky_background と local_image | SkyView の 4 種設定を再利用。地平図の観測変換・背景合成を追加し、追加画像の欠損診断を保持 |
| N07 地点/風景 / DATA-01、DATA-02、DATA-03、GRID-03 | 地点 provenance、資産監査、defaultplaces/places と 21 風景 PNG | ラベル群→風景 offset→地点編集/利用者領域保存→他天体地点の順。Grids.surfacePointer と Places の別名関係、地表基底、ポインタ座標は確認後 |
| N08 雲/夜景 / OBJ-03 の一部 | [描画監査](../local-rendering-audit.md)、既存 planet_textures/planet_surface/local_image | 2 JPEG の読込と照明合成。欠損時は警告と対象レイヤーなし。異なる specular 名を自動代用しない。API の真偽値を複数描画経路で共有 |
| N09 星座絵 / CONST-02 | 星座契約監査、89 CAB、75,517 点・92,938 index を検算済み | 5 float header、点、区切り index の原順を保持する loader が先。軸/元期/尺度/角度は静的追跡後。CDF Pos を CAB 原点とする仮定は Serh/Sert の関係からも不可 |
| N10 恒星名の選択集合 / STAR-02、STAR-03 | [恒星監査](../local-star-controls-audit.md)、stars.html、selection.dat | clicked target と複数 HIP 名称集合を分離。`HIP_n: 1` の値・重複・初期集合を確定。固有名制限は Bayer/Flamsteed/HIP のスイッチと混ぜない |
| N11 恒星の明るさ・名称フェード / STAR-05、DRAW-01 | 恒星監査、stars.html、gui.lua の fadeLabels | brightness と等級 cutoff を分離。固定値の setter/getter→増減幅の追跡→時間補間。近接名/距離減衰の式をカメラ距離に推測適用しない |
| N12 大気 / OBJ-03 の残り | 描画監査、emmap.dat と公式 mtk_atmosphere.cpp | 散乱表 loader→単一散乱→多重散乱を別単位。表の寸法/有限値と単位を検査。地球/火星・地上/宇宙を明示し、通常版式の採用を Plus 画素一致と称さない |
| N13 食 / OBJ-04 | gui.lua 97–100、planets.html、公式食計算、ui/scripts/eclipse_* | 相対位置から食幾何→影/境界→本影/半影錐→地上暗化。時系の精度限界を保持し、既知事例の時刻/場所で検算。シナリオ実行とは別に試験 |
| N14 表示半径 / OBJ-05 | 描画監査、gui.lua の 4 倍率と秒数 | 4 文脈の実半径倍率を型で分離。航行半径・模式半径と関係を決めて固定値から接続。`setScaleTo` 誤記を確認し補間を後置 |
| N15 地形 / OBJ-06 | gui.lua 108–112、planets.html 96、公式地形 reader とローカル資産の追加照合 | 実データの存在・形式・座標・欠測を先に棚卸し。文書 1–5 と GUI 0–4 の値を確定してから 1/2/5/10/20 倍を接続。球面陰影を地形対応としない |
| N16 銀河/星団/3D カタログ / GAL-02、GAL-03 | 既存 NGC/IC、826,360 SDSS 銀河、104,848 QSO の全件保持、extended_catalog provenance | 距離を持つ種類だけ 3D snapshot→空間索引/描画。NGC の角位置から距離を作らない。天の川銀河・近傍銀河・球状星団の固有データは追加照合。ロード件数と表示密度制限を別表示 |
| N17 オールト雲 / OBJ-11 | tnobjects.html と gui.lua、原版バイナリの表示分岐 | 寸法・分布・名称・乱数/固定データの根拠が必要。仮の球殻を原版相当としない。小惑星/TNO の計算とは独立 |

## カメラ・日時・操作の後続単位

| 単位 / 対応 ID | 根拠と実装順 | 完了条件・先に解消する点 |
| --- | --- | --- |
| N18 対象レジストリ / CAM-06、CAM-08 | abouttargets.html、既存 catalog/small-body/satellite の安定 ID をつなぐ contract | 全保持対象の種類・名前・出典を検索可能にする。名前衝突は同一対象へ暗黙統合しない。Lua target/look、階層一覧、右クリック、地平追従を順に接続 |
| N19 選択と距離 / CAM-07、CAM-09 | targets.html、camera.html の NONE/AUTO/ALWAYS | 無効/hover/click と座標入力を追加。自動距離の半径/範囲・selected-only 表示の hit test を確認。表示を消しても既存選択の識別子は保持 |
| N20 姿勢/FOV / CAM-02、CAM-03、CAM-04 | camera.html、state の quaternion、[UI 状態監査](../local-ui-state-input-audit.md) | quaternion/Euler の成分順・積順・角度単位を確認。既存 yaw/pitch の上へ roll/FOV を接続。zoom の parsec と表示ラベル 10 倍差は SPEC-03 の追跡後 |
| N21 時間補間 / ANIM-01、CAM-01、CAM-10 | aboutanimation.html、camera.html、既存 playback/flight | 共通の cancel/置換/完了契約を持つ補間器を作り、まずカメラ 1 属性で検証。home・duration・即時/時間付き mode を接続。待機と UI 更新を main thread で塞がない |
| N22 着陸/地表選択 / CAM-11、CAM-12、CAM-13 | Readme 70–77、camera.html、既存 surface_navigation | 地球 ray/sphere 交点→緯度経度を独立試験。全衛星着陸は半径と自転の根拠がある subset のみ。Horizontal/Surface、headlight、視点情報は別々に実装 |
| N23 時刻 API の残り / TIME-02、TIME-03、TIME-04、TIME-06、TIME-07、TIME-08 | [時刻監査](../local-time-audit.md)、既存 calendar_time/playback | GUI の確認済み暦処理を Lua に接続。原版の月末・増減幅・local/timezone/DST を確認。UTC/UT1/TT/TDB は精度要求と変換根拠を別単位にし、単一 JD に別ラベルを付けない |
| N24 投影/ポインタ / UI-08、UI-09、UI-10 | UI 状態監査、pointer.html、DisplayOutputController | 実ディスプレイで配置を検証。フェードの時間補間を追加。Scene.Fader/Desktop.Fader の同一性と 3 座標 pointer の原点/軸/単位は追跡後 |

## UI・状態・媒体の後続単位

| 単位 / 対応 ID | ローカル根拠・既存機能 | 実装の境界と完了条件 |
| --- | --- | --- |
| N25 画像の選択と合成 / MEDIA-03 | [媒体監査](../local-media-audit.md)、9 登録、MVP、MediaController/MediaImageView | 前後選択と表示を接続する native 改善が先。旧 index 起点、wrap、重複名、type P、scene 内配置は原版追跡後。似た file 名や case 違いを無断で置換しない |
| N26 タイトル / MEDIA-05 | 同媒体監査、13 資産、PNG と混在文字コードの credits/caution/theater | 原文保持 loader→Size/Vspace/Color/Table/ruby 等の確定構文→描画。4 種類の登録/順/選択を検証し、未解釈行を黙殺しない |
| N27 3D チャート / MEDIA-04 | charts.html、太陽系/太陽系外縁/恒星色温度の同梱用例、公式比較コード | 内容と 3D 配置を種類別に確認。普通の画像 window を chart 実装としない。name/index と表示の状態を分離 |
| N28 動画/音声 / MEDIA-01、MEDIA-02、MEDIA-06 | movies/audio 文書、shortcuts、既存 AVKit/AVFoundation | 選択/終了/一時停止/音声喪失→専用 controller。旧 frame の単位・seek・可視性との関係は確認後 Lua 接続。手元に音声/動画登録実物がない範囲は明記 |
| N29 編集/コンソール / LUA-02、LUA-03 | scripting/gui 文書、既存 ScriptController | editor と save/run/cancel→対話入力と履歴→操作/カメラ記録の順。保存先 guard を再利用。対話環境を毎回新規 file 実行と同一視せず、global 変数の寿命を確定 |
| N30 状態 API / STATE-01、STATE-02 | state.html、state/20151008 と独自日本語名 file、既存 SessionState | 現行 native snapshot からメモリ store/restore を分離。旧 get/getStored は Lua 文字列、set は実行。対応 API だけを確実に往復し、未知項目を部分適用しない |
| N31 初期化/言語 / STATE-03、DATA-05 | init.lua の読込順、LANGUAGE 分岐、lang/gui/option/shortcuts | 言語資産 loader→明示 import→利用者領域の初期状態を順に扱う。原本 state/init.lua を空にしない。自動実行の権限は既存明示実行と区別して確認 |
| N32 動的メニュー/toolbar / CUSTOM-01、CUSTOM-02 | UI 状態監査、同梱日英 gui、NSMenu/NSMenuItem | callback 環境と action の寿命を先に定義。単一 action→menu 階層→同じ action を toolbar で共有。updateScript の例外・再入・clear 後参照を試験 |
| N33 screen menu / CUSTOM-03、CUSTOM-04 | screenmenu 文書と scripts、N32 action model | enter/cancel/親子選択→角度/表示先→媒体 menu 生成。空集合、削除、端の移動を検証。平面 menu だけで投影・立体表示済みとはしない |
| N34 入力 / INPUT-01、INPUT-02 | 同梱 shortcuts、input 文書。getShortcut は 0 始まり、慣性は ms | keyboard/mouse 登録と一覧→方向/速度/慣性→joystick adapter。key up/down・反復・優先対象を確認し focus 喪失で停止。壊れた独自割当も原文と診断を保持 |
| N35 HTML の残り/シナリオ / CUSTOM-05、CUSTOM-06 | [HTML 監査](../local-html-bridge-audit.md)、ui/index.html と 4 Lua | UNIT4 の信頼境界完了後に home/bookmark を追加。12constels/orion3d/eclipse を API 依存ごとに実行。Flash/IE と page JavaScript を旧互換のために無条件有効化しない |
| N36 アプリ表示/設定 / UI-02、UI-04、UI-05、UI-06、UI-07、UI-11 | gui/system 文書、[window 監査](../local-window-unit4-audit.md)、UNIT4 window/Renderer | fullscreen/About 完了分を除く。文字倍率/ルビ/情報→option dialog→window 配置→style の順。CSS/外部 style の構文・読込範囲と openDocument は別契約 |
| N37 描画制御/保存 / UI-03、RENDER-01、RENDER-02 | renderer.html、既存 PNG/JPEG/BMP export、UNIT4 quality | 既存 quality 完了分を除く。interactive→明示 render/frame→寸法/安全な出力名を順に実装。frame は描画番号で毎回 +1。任意 printf を無検証で実行しない |
| N38 通常 Plus 立体視 / RENDER-03 | [renderer/立体視監査](../local-renderer-stereo-audit.md)、None/Anaglyph/ColorAnaglyph | 左右眼の投影契約→2 画像→色合成を独立試験。表示/選択/保存で中心を維持。Pro の split/QuadBuffer を混在させない |

## 横断項目・確認済み範囲の扱い

| matrix ID | 次の扱い |
| --- | --- |
| CAM-05、TIME-01、TIME-05、OBJ-01、STAR-01、DATA-06、UI-01 | 基本機能は既存実装。新規対象や設定を足す単位で関連する回帰を実行し、機能を再作成しない |
| OBJ-02、STAR-04、GRID-01、GRID-02 | UNIT3 の native 表示/設定は実装済み。原版の画素一致を保証していない点は残す。新しい view へ接続する際に同じ設定を再利用 |
| DRAW-02 | 各表示単位の受入に含める。ロード全件数と描画件数/密度を分離し、大量データは index/snapshot を再利用。毎 frame の全行文字列生成を避ける |
| LUA-01 | 各機能単位の host API seam として実装する。全名前を一度に仮登録しない。getter/setter/toggle、型拒否、実状態 snapshot、host 拒否の伝播を試験 |
| LUA-04 | 採用済み Lua 5.4.9 と旧 5.1 の差を保持。実データの script 依存を個別確認し、runtime を入れただけで全互換としない |
| PRO-01、PRO-02、PRO-03 | 通常 Plus の対象外。通常の anaglyph、画像保存、明示 render は除外しない |
| SPEC-01、SPEC-10、SRC-01 | 版・出典・許諾の区別を全単位で維持。原版の限定静的解析は既存 skill の手順を使用。公開ソースを Plus 固有 code/data の許諾根拠に拡張しない |
| SPEC-02 | 用例だけの API は担当単位で追跡。fadeLabels=N11、shadow=N13、Fader=N24、soundControler=N28、style/restoreLastGUI=N36、dualScreen=N24 |
| SPEC-03、SPEC-04 | N20 の zoom、N14 の scale、N15 の地形値で解消。未確認値を選んで公開しない |
| SPEC-05、SPEC-06、SPEC-07 | N23 の単発 step、各該当媒体/GUI API の誤記照合、N31 の startup path へ割当 |
| SPEC-08、SPEC-09、SPEC-11 | N01 の尾、N37 の Background/editOnCapturedBG、N07 の landscape offset を個別追跡 |
| SEC-01、SEC-02 | 信頼済みローカル Lua と明示的に信頼したローカル HTML の許可はユーザー決定済み。再承認待ちにしない。オンライン/遷移先に権限を継承しない |
| SEC-03 | 外部文書起動・自動探索・新しい形式の外部参照は、既存の明示選択/容量/パス guard で満たせる範囲を先に作る。未解決の公開/security 契約だけを具体化して確認 |

## 共通の実装・検証条件

- source の識別、原 bytes、原順、同じ番号/名称/時刻の重複、解釈不能項目を保持する。評価可能な subset と全行保持は別の成功条件にする。
- 計算は既存 core の Kepler・座標変換・CF96・lunar・Trajectory を、読込/描画は C++ 標準機能、AppKit/CoreGraphics/ImageIO、AVFoundation、WebKit、採用済み Lua を優先する。新しい依存は必要性が判明した時点で検討する。
- 公開 API の型・単位・範囲・別名・時刻・親・寿命が不明な場合は根拠を追加調査する。native の新契約を採用する場合は、原版一致の認定と区別する。
- GUI、Lua、保存状態は同じ型付き設定を使う。未対応を成功応答しない。source を変更した際の選択 ID と古い snapshot の混線を試験する。
- 数値機能は確定した原式・独立した検算・端点/欠損/非有限/重複の試験を持つ。UI は表示・非表示、選択、復帰、取消の意味が変わる経路を確認する。原版を実行していない項目を画素一致と記載しない。
- 各単位の終了時に matrix の部分範囲を更新し、実データ保持検査、適切な通常/ASan/UBSan/x86 試験、必要な GUI 試験、policy gate、Git 差分確認を行う。未実行の機器/OS 依存確認は理由付きで残す。

本書の作成は新規 Markdown 1 ファイルのみで、製品コード・原本・matrix・policy は変更しない。実装単位の commit は root の統合範囲で行う。
