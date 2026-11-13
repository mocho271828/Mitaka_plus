# 天の川の背景画像と地平座標

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

既存 `native/gui/src/sky_background.mm:76–95` は利用者が選んだ data の兄弟 `textures` だけを読む。IR の正式名 `MilkyWay_IR.jpg` が存在しない場合に限り `milkyway_IR.jpg` を試す。存在する破損画像・symlink を別名の成功で隠さず、各失敗を warnings に残す。地平図でもこの共有 loader を使い、独自追加・置換されたローカル画像の bytes を保持する。

## 既存の座標契約

| 根拠 | 利用できる契約 |
| --- | --- |
| `OFFICIAL/Mitaka/main.cpp:989–1007,1468–1520` | 3 画像のロード、銀河変換、Z 軸 180° 回転、天球描画、加算ブレンド。公式独自の CMB と 3D 距離減衰は 地平図の背景への適用対象外。 |
| `OFFICIAL/common/astro/astrometry.cpp:127–141`、`astrometry.h:139–144` | 銀河基底 `M_G2R` と赤道・黄道の区別。基準方向は厳密には直交していない。 |
| `OFFICIAL/common/graphics/gl_common.cpp:55–116`、`image.cpp:259–278` | 球面 UV と JPEG の上下反転。合成した対応は下式。 |
| `native/gui/src/sky_background.mm:14–56,98–131` | 既存の実際の逆銀河行列、左上原点 UV、水平 repeat・垂直 clamp・双線形補間。 |
| `native/core/include/mitaka/observation.hpp:7–29`、`src/observation.cpp:36–73` | 地点・JD ごとの `ObservationFrame`。J2000 赤道と地平の相互変換。北 0°、東 90°、高度上向き。 |
| `native/gui/src/HorizonView.mm:15–27,151–155` | 既存の円筒投影を再利用し、地平方位は右向き。viewport の正規化も既存 SkyViewport に従う。 |

公式由来の左上原点画像座標 `(u,v)` は `l = π − 2πu`、`b = π/2 − πv`、J2000 赤道方向は `normalize(M_G2R * (cos(b)cos(l), cos(b)sin(l), sin(b)))`。既存 `sky_background_uv` はこの逆対応を扱う。逆行列を転置に置換しない。上下反転・180° 回転・黄道傾斜を追加しない。

`ObservationFrame` は公式 Earth 回転を再利用し、屈折・視差・章動・極運動・時系変換を含まない。既存ビューと同じ数値 JD を使う。GMST の追加回転や UTC→TDB 変換は二重変換になるため加えない。地球の極では指定経度の子午線を保持し、天頂・天底の不定な方位は 0 とする。詳細は `native/core/OBSERVATION_PROVENANCE.md:5–24,46–53`。
