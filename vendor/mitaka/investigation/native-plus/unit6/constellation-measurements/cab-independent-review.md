# CAB星座絵の行列と数値検算

89件の CAB でヘッダーと先頭の点を照合した。[ファイルのハッシュ](original-file-hashes.tsv)・[検算の集計](summary.json)

対象: `mitakaPlus.exe` SHA256 `48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457`。
原本と既存の objdump 抜粋を静的に読んだ。旧実行ファイルは実行していない。以下は当該バイナリの確認結果であり、公式 source と同一と認定したものではない。

## 結論

列優先の行列配置、符号、合成順を個別に確認した。h を header 先頭3 float の正規化、s を第4 float、a を第5 float、p=(-raw_x, raw_y, 0) とし、q を後述の +Z→h quaternion とすると、observer=0、距離 d>0 で、当該 draw 関数が追加する変換後の方向は理想実数演算では

`normalize(Rx(-23.4 degrees) * (h + 2*s*R(q)*Rz(a degrees)*p))`

となる。旧実装は float と rsqrt + Newton 補正を使用するため、実機と bit 単位で一致する式ではない。-23.4 の immediate は float -23.399999618530273 である。

これは当該描画関数の入口にある modelview に対する局所変換である。入口の modelview、camera、通常天球と native equatorial の対応は、この読取だけでは確定しない。

## 追跡した命令

- loader `4ba9a1`..`4ba9ec`: 5 float と点数を順に読む。`4baa76`..`4baaf4`: header xyz を正規化し、第1引数 +Z、第2引数 h、出力 quaternion を `4bed00` に渡す。
- `4bab23`..`4babaa`: helper quaternion の norm² で w を割り、xyz を符号反転して同じ norm² で割る。record には逆 quaternion を格納する。
- `4bab8a/4bab8d`: 第4 float s を record +0x28 相当へ格納。`4bab9d/4baba0`: 第5 float a を record +0x24 相当へ格納。
- `4babd8`..`4babed`: 頂点を (-x,y,0) として格納する。
- draw `4c0f56`..`4c0f7a`: `glRotatef(-23.4,1,0,0)`。
- `4c0f80`..`4c1039`: record の h を再正規化。`4c103d`..`4c107e`: `glTranslatef(d*h.x,d*h.y,d*h.z)`。
- `4c1091`..`4c10f5`: record の逆 quaternion を正規化。
- `4c10f9`..`4c127c`: 下記の連続 float 行列を組み立て、`glMultMatrixf`。
- `4c1282`..`4c12ad`: `glScalef(2*d*s,2*d*s,2*d*s)`。
- `4c12b3`..`4c12d6`: `glRotatef(a,0,0,1)`。
- `4c1442`: raw point 由来の格納済み p を `glVertex3fv` に渡す。

## 行列の独立確認

正規化後の格納 quaternion r=(w,x,y,z)=q^-1 について、glMultMatrixf へ渡す 16 float は順に:

```
1-2(y²+z²), 2(xy-wz), 2(xz+wy), 0,
2(xy+wz), 1-2(x²+z²), 2(yz-wx), 0,
2(xz-wy), 2(yz+wx), 1-2(x²+y²), 0,
0, 0, 0, 1
```

これは通常の active R(r) を行ごとに並べた値である。OpenGL は列優先で読むため、実効行列は R(r)^T = R(q)。単に逆 quaternion をそのまま active 回転する解釈は逆向きになる。

OpenGL の後乗算により、追加する変換列は:

`[optional T(-observer)] * Rx(-23.4) * T(d*h) * R(q) * S(2*d*s) * Rz(a)`

uniform scale は回転と可換だが、T(d*h) は R(q) の左にある。observer=0、d>0 なら d を方向の正規化で除ける。

## q の端点分岐

`4bed00` はこの呼出しでは第1引数が必ず (0,0,1)。その条件で次が成立する。

- h.z > float 0.9999899864196777 (`4bed36/4bed3d`, `4beec0`): identity。
- h.z < float -0.9999899864196777 (`4bed43`..`4bed4e`): (w,x,y,z)=(0,-1,0,0)。
- それ以外 (`4bedfa`..`4beebd`): cross(+Z,h)=(-h.y,h.x,0) を軸、w=sqrt((1+h.z)/2)、xyz=unit(axis)*sqrt((1-h.z)/2)。

したがって一般式 q=rotation(+Z→h) は極付近の閾値による丸めを明記する必要がある。helper を一般の第1ベクトルにも正しい quaternion 関数だとは、この局所確認から主張しない。

同梱 89 CAB の h.z は正規化後 [-0.9931706558140089, 0.9727758721125371]。89件すべて一般分岐で、極端点の丸め分岐は使用しない。

## 距離と observer の条件

`4c0e7a` で global `fe9360` が 0 なら d=1.0015000104904175。非ゼロなら `4c0eab`..`4c0ec7` で関連レコードの double +0x98 と +0xa0 の平均にする。`4c0ed2`..`4c0eec` に別 float 値と 75 の比較による距離代入分岐がある。`4c0ef7`..`4c0f47` の分岐では observer の負座標を glTranslatef する。

この原点条件では observer の項が消える。一般の observer!=0 では d は方向から消えず、d=0 なら正規化不能、d<0 なら方向符号が変わる。d の呼出側における物理的意味や保証範囲はこの検算対象外。

- matrix の最大差: 0
- R(q)*(0,0,1) と h の最大差: 5.551115123125783e-16
- d={0.03125,1.0015000104904175,100000} の完全変換と距離消去式の方向最大差: 2.220446049250313e-16
