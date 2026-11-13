# 恒星名称・表示設定の根拠

`star_labels.cpp` の hip.dat 内星座IDの固定順は、手元の公式 Mitaka 1.3.1
`common/astro/constellation.cpp` の `ConstellationAbbr` に由来する。
任意ローカル `constellation_HIP.dat` の行順はIDとして使わない。
Greek ID 0–23 は `common/text/unicode.cpp`、名称の組合せと欠損値 -1 は
`Mitaka/mtk_stars.cpp::make_Bayer_name` を確認した。
公式の独自上付指定 `\\S` は Unicode 上付き数字へ変換する。

固有名は読み込み済みローカル `star_names` の CP932 バイト列を使い、
日本語名が欠損なら原語名を使う。同HIP重複は後勝ち。
Binary は `hip.dat` の `is_double`、ExoPlanets はローカル
`exoplanets_HIP` のHIP集合に従う。恒星データを間引かず全可視等級を対象にする。
可視域と等級上限、Stars.visible は星・名称・マーク・クリックで共有する。

惑星の軸は既存コアの時刻ごとの `BodyOrientation::north_axis`（J2000黄道座標）を使い、
公式 `mtk_planets.cpp` の ±1.3 半径の軸長を表示半径へ適用する。
対象は9惑星と月。太陽の科学的北軸モデルはこのGUIでは提供していないため表示しない。
Planets.visible は太陽・9惑星・月の円盤、表面合成、軸、名称、hitを制御する。
Planets.orbits は独立して既存9惑星・月軌道を制御し、距離グリッドと混同しない。
既存選択は非表示中もナビゲーション用に保持するが、選択リングは描画しない。
軸は太陽系3Dで表示し、全天・地平の位置記号に模式軸を追加しない。

原PlusのAPIはローカル1.3.0ドキュメントと1.5.4配布Luaを照合した。
この移植版の文字配置・描画色・線幅はAppKitで実装しており、原Plus実行画面との
ピクセル一致は未検証。selectedLabels、brightness、惑星倍率はこの単位の対象外。

## 元コードの許諾

Copyright (c) 2007   Tsunehiko Kato

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
