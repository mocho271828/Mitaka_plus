# N06 地平図の天の川: 原典と接続契約の監査

調査日: 2026-10-29。UNIT4 の `002adcf663fd5005e14ac86c343a3ec7e56fa706` を基点とする UNIT5 作業ツリーを読み取った。これは **UNIT6 の実装前監査**であり、以下の接続案・試験案は未実装・未実施。原本のアプリやスクリプトは実行せず、媒体の変換・再保存・Git 登録も行っていない。UNIT5 の変更には触れていない。

## 参照位置と版の区別

| 略記 | 絶対パス |
| --- | --- |
| `PLUS` | `/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka` |
| `REGULAR` | `/Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka` |
| `OFFICIAL` | `/Users/kota/mitaka/repositories/Mitaka/sources/official/mitaka_source` |
| native / investigation の相対パス | `/Users/kota/mitaka/repositories/Mitaka` を基準とする |

ローカル Plus は 1.5.4 build101013、同梱 API 文書の表示版は 1.3.0、参照可能な公式ソースは通常 Mitaka 1.3.1。公式の球面画像対応は参照できるが、Plus の描画経路や画素一致の証拠にはならない。既存調査は [local-assets-audit.md](../local-assets-audit.md)、対象範囲は [next-feature-units.md](../unit4/next-feature-units.md) の N06 / GAL-01。

## 原典で確定した設定とローカル資産

`PLUS/doc/script_jp/milkyway.html:12–19` は `Milkyway.type` の文字列値 `None`、`Normal`、`Bright`、`Infrared` と `Milkyway:toggleType()` を記載する。`PLUS/scripts/gui_jp.lua:169–173`、英語 `gui.lua` の同位置、`screenmenu_jp.lua:83–87` の代入・比較が 4 値を裏付ける。API の例文にはプロパティとメソッドの区切りの誤記があるため、例文だけで構文を推定しない。`toggleType()` の巡回順は文書にない。

`PLUS/ui/scripts/eclipse_20090722.lua:68` と `eclipse_diagram.lua:68` も `Milkyway.type = "Normal";` を設定する。`state/init.lua` と `scripts/init.lua` では `Milkyway` の記述は見つからなかった。これらは読み取りのみで、実行結果は確認していない。

4 状態は「非表示 + 画像 3 枚」であり、4 枚の背景画像ではない。次の 3 枚を SHA-256 と `sips -g` の読み取りで再確認した。すべて JPEG、1024 × 512、アルファなし。

| 状態 | `PLUS` 相対パス | バイト数 | SHA-256 |
| --- | --- | ---: | --- |
| Normal | `textures/milkyway.jpg` | 15,666 | `98e5a8da31288e9898b32e77e045a0fd28cfc590e5e955b689b6ac2c43cf8050` |
| Bright | `textures/milkyway2.jpg` | 26,230 | `c1e1a25df435675d3bcbc9295cae6255c5ac3a60ebc7a83cc47003a130d5a758` |
| Infrared | `textures/MilkyWay_IR.jpg` | 425,617 | `08dad5580d182ab780260b3b1c58b32b229b4a95e27190ac555d2a9128da5e7a` |

既存資産監査では通常版は同じ IR のみを持つ。欠損している Normal / Bright を公開データや他のセットから補わない。`PLUS/media/MilkyWay.mvp` のメディア画像は別用途であり、天球背景への自動代用の根拠はない。

既存 `native/gui/src/sky_background.mm:76–95` は利用者が選んだ data の兄弟 `textures` だけを読む。IR の正式名 `MilkyWay_IR.jpg` が存在しない場合に限り `milkyway_IR.jpg` を試す。存在する破損画像・symlink を別名の成功で隠さず、各失敗を warnings に残す。N06 でもこの共有 loader を使い、独自追加・置換されたローカル画像の bytes を保持する。

## 既存の座標契約

| 根拠 | 利用できる契約 |
| --- | --- |
| `OFFICIAL/Mitaka/main.cpp:989–1007,1468–1520` | 3 画像のロード、銀河変換、Z 軸 180° 回転、天球描画、加算ブレンド。公式独自の CMB と 3D 距離減衰は N06 の対象外。 |
| `OFFICIAL/common/astro/astrometry.cpp:127–141`、`astrometry.h:139–144` | 銀河基底 `M_G2R` と赤道・黄道の区別。基準方向は厳密には直交していない。 |
| `OFFICIAL/common/graphics/gl_common.cpp:55–116`、`image.cpp:259–278` | 球面 UV と JPEG の上下反転。合成した対応は下式。 |
| `native/gui/src/sky_background.mm:14–56,98–131` | 既存の実際の逆銀河行列、左上原点 UV、水平 repeat・垂直 clamp・双線形補間。 |
| `native/core/include/mitaka/observation.hpp:7–29`、`src/observation.cpp:36–73` | 地点・JD ごとの `ObservationFrame`。J2000 赤道と地平の相互変換。北 0°、東 90°、高度上向き。 |
| `native/gui/src/HorizonView.mm:15–27,151–155` | 既存の円筒投影を再利用し、地平方位は右向き。viewport の正規化も既存 SkyViewport に従う。 |

公式由来の左上原点画像座標 `(u,v)` は `l = π − 2πu`、`b = π/2 − πv`、J2000 赤道方向は `normalize(M_G2R * (cos(b)cos(l), cos(b)sin(l), sin(b)))`。既存 `sky_background_uv` はこの逆対応を扱う。逆行列を転置に置換しない。上下反転・180° 回転・黄道傾斜を追加しない。

`ObservationFrame` は公式 Earth 回転を再利用し、屈折・視差・章動・極運動・時系変換を含まない。既存ビューと同じ数値 JD を使う。GMST の追加回転や UTC→TDB 変換は二重変換になるため加えない。地球の極では指定経度の子午線を保持し、天頂・天底の不定な方位は 0 とする。詳細は `native/core/OBSERVATION_PROVENANCE.md:5–24,46–53`。

## 実装可能な最小単位（未実装の提案）

背景画像の逆参照を既存 `sky_background.mm` に追加すれば、decoder、銀河変換、補間を再実装せずに済む。候補の境界は次のとおり。

```cpp
TextureImage render_horizon_background(
    const TextureImage& texture, HorizonViewport viewport,
    const ObservationFrame& frame, std::size_t width, std::size_t height);
```

出力画素中心 `(x+0.5,y+0.5)` から、正規化した viewport に対して次を求める。

```text
azimuth = center_azimuth + ((x+0.5)/width - 0.5) * 360 / zoom
altitude = center_altitude + (0.5 - (y+0.5)/height) * 180 / zoom
equatorial = frame.to_equatorial({azimuth, altitude})
uv = sky_background_uv(equatorial)
```

既存補間で画像を引く。`ObservationFrame` はビューの現在値を一つ渡し、画素ごとに歳差・地球回転を再構成しない。画像と出力の各辺 1..1024、RGBA 長、有限 viewport を事前検証する。viewport は `HorizonView` と同じ正規化を使う。新規の汎用画像ライブラリは不要で、現在の ImageIO / CoreGraphics / AppKit を使える。

`HorizonView` に既存 `SkyView` と対応する mode、共有 `SkyBackgrounds`、生成済み画像を保持する。描画案は「基礎色 → 地平背景 → 既存地面と grid → 星座・恒星・惑星」。現在の地面は高度 0 未満を不透明で塗る (`HorizonView.mm:289–296`)。この順なら地平線下の天の川は地面に隠れ、恒星・惑星の既存の暗い表示は維持される。これは **ネイティブの既存地面に合わせた設計案**であり、Plus の地平線下の描き方を確定したものではない。

bitmap は `mapRect` (`HorizonView.mm:78`) で明示クリップし、周囲のタイトル・説明へ漏らさない。既存 `SkyView.mm:364–387` の plus-lighter 合成と非 premultiplied sRGB 出力を再利用できるが、旧 Plus と明るさが一致するとは記載しない。

### キャッシュと共有設定の接続

SkyView の背景は J2000 赤道のため時刻で変わらない。一方、地平背景は観測地・日時で変わる。SkyView の cache key をそのまま流用してはいけない。

| 変更 | 必要な処理 |
| --- | --- |
| 地点 / JD | `setObservationSite:julianDate:` と `setBodies:julianDate:` の検証成功後に背景 cache を無効化する。失敗時は既存状態を保持する。 |
| viewport / map サイズ / mode | 現在の画面範囲と設定で再生成。None は背景を描かない。 |
| data 再読込 / 画像の共有モデル交換 | 同じファイル名でも cache を破棄。欠損・破損時に前の画像を残さない。 |
| 非表示ビューへの設定 | 値と無効化だけを反映し、描画要求まで計算しない。独自 timer は追加しない。 |
| 同じ状態の再描画 | 生成済み画像を再利用し、星の選択など背景と無関係な更新で再計算しない。 |

`AppController.mm:225,244–249` のロード済み `_skyBackgrounds` を両ビューへ渡す。既存 warnings とロード件数 (`302–304`) は維持する。

`AppPlusCommands.mm:146–150` は現状、天の川を SkyView に設定して **mode 0 へ強制切替**している。N06 では地平図のまま変更できるよう、この動作も修正する必要がある。App の共通 setter を経由し、メニュー、Lua (`AppScripting.mm:306–311`)、Session 復元 (`AppSessionCommands.mm:191`) から隠れた側も含む両ビューを同期する。現在の単一 `milky_way_mode` が全体設定という意味を保つなら、ビューごとの保存項目や schema version の追加は不要。

現在の Lua worker は 4 文字列を厳密検証する (`ScriptWorker.mm:234–238`)。読み戻しは SkyView の値 (`AppScripting.mm:45–49`) なので、共通 setter 後は同じ値になる。N06 に `toggleType()` の不明な巡回順を混ぜない。

## 実装後に必要な試験（この監査では未実施）

| 層 | 試験条件と判定 |
| --- | --- |
| 投影 / 向き | 方向が識別できる合成画像を使い、固定地点・JD の独立した既知方向と画素位置を比較する。既存 UV と ObservationFrame を単に同じ式で呼ぶ試験だけにせず、左右反転・上下反転・二重回転を検出する。 |
| 継ぎ目 | 地平方位 0/360° をまたぐ viewport と銀河画像 U=0/1 の両方を検証する。連続する方向で左右端の補間がつながり、逆側の不要な帯・欠落を生じない。 |
| 極 | 銀河北極・南極、観測緯度 ±90°、天頂・天底を含める。不定な方位の数値一致を要求せず、単位方向・有限画素・最端行の clamp を検証する。 |
| 地平 / 領域 | 高度 ±微小値、地平線が画面外となる全上空・全地面を検証する。採用した地面の合成順と map 外への非描画を bitmap で検証する。 |
| 境界入力 | 不正な画像寸法・RGBA 長・出力サイズ・非有限 viewport を拒否する。地点・JD の失敗時に既存 frame と cache の状態を壊さない。 |
| ローカル資産 | 4 mode / 3 slot、欠損、破損、IR 大小文字規則を維持。欠損しても選択 mode は保持して背景なしとなり、他 mode や公開データを代用しない。原 bytes・mtime を変えない。 |
| 更新 | JD、地点、viewport、resize、mode、reload の各変更で画像が更新される。同じ状態は再利用する。非表示中の更新後に表示しても旧日時の画像が出ない。 |
| App / Lua / Session | 4 値が両ビューに反映される。地平図で menu 操作しても全天図へ飛ばない。Lua の getter と保存・復元が一致し、不正値は原子的に拒否される。 |
| 再生 / 性能 | 再生時の別 JD で背景が変わり、キャッシュが時刻依存であることを確認する。出力長辺 1024 以下を保持し、原本解像度の変更や無制限の生成をしない。 |

再利用できる既存試験は `test_sky_background.mm:79–194`（銀河基底、UV、補間、loader と原本保持）、`test_sky_view.mm:30–79`（4 mode と bitmap/cache）、`test_horizon_view.mm:63–71`（地面と状態）、`native/core/tests/test_observation.cpp:64–134`（往復・範囲・異常値）。新しい描画・統合回帰は通常 / ASan+UBSan / x86_64 Rosetta で実施し、AppKit 試験は他の GUI 試験と直列にする。CUA は固定地点・JD の 4 状態、時刻・地点変更、再表示を確認する。いずれも本監査時点では未実施。

## 未確定事項と判断境界

旧 Plus の厳密な明るさ、夜空・薄明・地平線下との合成、3D 距離減衰、`toggleType()` の巡回順は未確定。公式 1.3.1 の処理を Plus 固有仕様として記述しない。CMB、風景 offset、CAB 星座絵、大気・屈折・霧の新設は N06 へ含めない。

既存のネイティブ地平図へ上記の限定的な背景表示を加えるための追加依存・オンライン実行・原本変更は不要。旧 Plus の見た目まで厳密に再現する要件が生じた場合は、ローカル原典による追加証拠を先に集める。証拠が得られなければ、既存ネイティブ合成を採用するか、厳密互換部分を保留するかを具体的に提示する。本監査では未確定の部分を推測で確定していない。
