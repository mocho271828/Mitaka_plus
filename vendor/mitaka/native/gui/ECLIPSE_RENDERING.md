# 食の表面・境界・円錐表示

UNIT7 は [公式由来の純計算](../core/ECLIPSE_PROVENANCE.md) を、同一 JD の日心 J2000 黄道 AU と物理半径で既存 surface renderer に接続する。Plus の四つのフラグ、対象名、有限円錐の算術は [ローカル PE の監査](../../investigation/native-plus/unit7/n13-plus-display-contracts.md) に基づく。原版の OpenGL 画素や模式半径を再現したものではない。

## 表示設定と時刻・出典

`EclipseDisplayOptions` は `shadows=true`、`shadow_borders=false`、`shadow_umbra=false`、`shadow_penumbra=false`。四項目は独立しており、`shadows` は他の三項目の master ではない。これは Plus PE の画像内初期値であり、任意の起動スクリプト実行後の状態を保証しない。

`make_eclipse_display_frame` は値を所有する表面 binding と診断を一度生成する。呼出し側は `SolarBodies` を渡す数値 JD にそろえる。衛星は snapshot の JD を完全一致で検査し、登録根拠、定義 ID、各評価と全体 snapshot の位置、表示中の親位置を追加検証する。`verified_satellite_scene_context` は既存の検証を共有する内部 seam であり、返す pointer の寿命は snapshot に従う。

同じ出典の検証済み context だけを採用し、欠損を別出典や後続同名行から補完しない。衛星マーカーの非表示中も食は raw snapshot を参照する。描画が返す診断を Solar view の状態表示と tooltip へ渡し、未解決の衛星を静かに推測表示しない。

| 受影体 | 遮蔽体 | 影の RGB |
| --- | --- | --- |
| Earth | Moon | `(0,0,0)` |
| Moon | Earth | `(0.3,0,0)` |
| Jupiter | 同一出典の先頭 `Io`、`Europa`、`Ganymede`、`Calliso` | `(0,0,0)` |

`Calliso` は Plus の実文字列を保持し、`Callisto` を alias として扱わない。衛星の `Radius` は重複のない field の先頭数値を km として使い、欠損・0・負・非有限値は診断する。太陽は 696,000 km、Earth/Moon/Jupiter は既存 `surface_body_info` の物理半径、AU は既存 149,597,870.7 km を使う。公式通常版にある Saturn←Titan を Plus の登録として追加していない。

## 表面と雲

`EclipseSurfaceBinding` は有限で離れた球を受け、core の候補判定を共有する。単位法線から受影点を求め、太陽方向と法線の内積が正の昼側だけに適用する。各遮蔽体の `eclipse_surface_sample` と `eclipse_shadow_multiplier` を使い、複数の影は RGB 乗数を掛け合わせる。

境界は円錐面からの距離を物理 AU の画素 footprint と比較する native の線幅である。半影境界は赤、本影境界は橙で、重なる標本は本影色を優先する。原版の 1.004 倍 mesh と GL 線幅の画素一致は主張しない。

preview、物理 surface view、共通深度を持つ Earth/Moon scene に同じ binding を渡す。表面の昼夜・夜景を合成した画素へ影の乗数と境界を適用する。雲の加算層には同じ物理受影面の法線から得た乗数だけを掛け、境界線を重ねない。binding と surface の中心・半径の不一致、発光球への binding は拒否する。大気の散乱輝度と地上から見た空の暗化はこの段階では食に連動しない。

## 空間円錐

Earth/Moon の空間円錐は原版の有限面の算術を使う。本影は頂点から太陽側接線円へ、半影は太陽側と下流の **二面** を生成する。本影と太陽側半影は頂点 alpha 0.5 から rim の 0、下流半影は頂点・終端とも 0.5。受影体による切断は原版の太陽距離を使う平面であり、最初の球交点への切断ではない。

下流半影では母線が受影球の内部を通る場合だけ終端を置き換える。厳密な接線一致、頂点の後方にある受影体は置換しない。置換距離が負でも原式の符号を保持し、二重円錐の反対側で同じ母線を照会する。球の接触・交差、`Rsun<=Roccluder`、不正な根号・非有限値は拒否する。

native は連続円錐への ray 交点を評価する。原版の円周 64 分割 fan/strip と画像は一致しない。最近の不透明球より手前の交点だけを描き、同じ赤の層を source-over 合成する。入力画像は最大 1024²、Solar scene では最大 800²。球内視点は透明にする。模式記号の拡大半径を食の物理球へ流用しない。

## 検証と修正履歴

最終の通常 arm64、ASan/UBSan arm64、x86_64 の各構成で、surface **1,021**、display **92**、cone **28,293**、scene **21 checks PASS**。

display fixture は二出典の実 loader を使い、JD・登録根拠・親位置・原行 ID・評価と snapshot の位置一致、Radius の欠損・重複・不正値、先頭一致を検証する。surface は昼夜、表面と雲、境界、深度を、cone は独立幾何・全 16 フラグ・透明度・切断境界・負の終端・遮蔽を検証する。scene は既存描画経路で四フラグの可視差を確認する。

初回の円錐実装は半影を下流一面の 0.5→0 としていた。追加の静的追跡により二面と下流 alpha 一定、母線ごとの再切断が確定し、UNIT7 内で修正した。修正直後の `final2-normal` は scene の半影独立性試験が失敗した。旧 fixture の距離 0.01 AU、121² 画素では、正しく切断された面が subpixel になったためである。物理半径と天体位置を変えず、カメラ target を 0.9995 AU、距離を 0.0015 AU へ寄せた。これは観測条件の修正であり、製品の影や公差を緩めていない。失敗ログも保存する。

## 残る範囲

地上視点での空・大気の食による暗化、旧モードごとの半径倍率と 3D chart、扁平受影体、原版の 64 分割や GL blend の画素一致は対象外。これらを表面・円錐表示の成功から完了扱いにしない。
