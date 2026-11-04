# N13 Plus の四フラグと有限円錐の実効契約

ローカル Plus 1.5.4 build101013 の PE を読み取り、UNIT7 の接続に必要な分岐を確認した。原本を実行・変更していない。手段は LLVM objdump と PE section の静的読み取りであり、実画素の比較ではない。以前の [接続前の監査](n13-eclipse-contracts.md) は当時の未確定事項を残す履歴とする。現在の実装範囲は [GUI provenance](../../../native/gui/ECLIPSE_RENDERING.md) を参照する。

対象 `mitakaPlus.exe` の SHA-256 は `48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457`。アドレスは PE の仮想アドレス。抜粋と再現手順は [監査・検証 archive](logs/n13-rendering/COMMANDS.md) に保存する。

## 四フラグ

| 項目 | mask | getter | setter | toggle |
| --- | --- | --- | --- | --- |
| `shadows` | 1 | `5cb3d0` | `5cb410` | `5cb420` |
| `shadowBorders` | 2 | `5cb460` | `5cb4a0` | `5cb4b0` |
| `shadowUmbra` | 4 | `5cb500` | `5cb540` | `5cb550` |
| `shadowPenumbra` | 8 | `5cb5a0` | `5cb5e0` | `5cb5f0` |

各 setter は `485120`/`485130` の OR/AND 経路を使い、自分の bit だけを書き換える。toggle も自分の bit を反転する。共通状態は VA `d71e28`、PE 画像内初期 byte は `01`。従って四項目は独立で、影だけが初期 ON。設定スクリプト適用後の値までは断定しない。`lua-flags.asm`、`lua-toggle.asm`、`registrations.asm` は Lua 呼出しと登録名の対応を保存する。

## 表面の対象

`target-setup.asm` の `549970` 付近は mask 3 を調べ、`Io`、`Europa`、`Ganymede`、`Calliso` の四衛星と `Jupiter` を名前 lookup して表面 wrapper `542bc0` へ渡す。第四名は `Callisto` ではない。Earth/Moon の専用経路は `earth-callers.asm`、`moon-callers.asm`、`surface-wrappers.asm` に分けて保存した。公式通常版の Saturn←Titan という登録を、この Plus の確認済み分岐へ移していない。

native は既存 snapshot の同一時刻・同一出典・原行 ID と親位置を検証する。原版の大域コンテナを推測再構築せず、最初の一致名が未評価なら理由を表示する。物理半径での通常表示を採用し、元 wrapper の表示半径倍率を未接続の chart モードへ自動拡張しない。

## 空間円錐の引数と座標

wrapper `542f30` が `4c87e0` へ渡す `ebp+c` は受光惑星位置、`+10` はその表示半径、`+14`/`+18` は遮蔽衛星位置と表示半径、`+1c` は Sun 原点、`+24` は惑星姿勢行列。半径はそれぞれの取得関数と表示倍率から来る。以下は幾何の算術であり、native では同一 JD の物理 AU に統一して使う。

Sun 中心を S、遮蔽体を O、受光体を C、単位軸を `n=(O−S)/D`、`D=|O−S|`、半径を Rs/Ro/Rc とする。本影頂点 U は `S+n*Lu`、半影頂点 P は `S+n*Lp`、`Lu=Rs*D/(Rs−Ro)`、`Lp=Rs*D/(Rs+Ro)`。円周方向の単位ベクトルを r とする。

### 本影

`4c888b`、`4c897a`、`4c8a36–4c8ac6` から、接線 rim は `B=S+n*aU+r*bU`、`aU=Rs²/D`、`bU=sqrt(Rs²−aU²)`。分母は Lu ではなく D。`4c9aca` の fan は U の alpha 0.5 から B の 0 へ張る。

`q=1−|C−S|/Lu` が `0<=q<1`、C が U から太陽側の軸正方向、軸からの中心距離が Rc より小さい場合、`4c9775` の strip が `U+q*(B−U)` の alpha 0.5 と B の 0 を結ぶ。q は中心の太陽距離を使う。厳密な球面交点による切断ではない。

### 半影の二面

`aP=Rs²/Lp`、`bP=sqrt(Rs²−aP²)`。太陽側の rim は `S+n*aP+r*bP`。`4c8d05–4c8ff7` は P の alpha 0.5 から rim の 0 へ fan を張る。

直後の `4c9000–4c960e` は別の下流 fan であり、分岐で片方を選ぶものではない。初期終端長 `L=max(Lu,|C−S|)−Lp`、終端半径 `L*aP/bP`、終端位置 `P+n*L+r*(L*aP/bP)`。`4c910a` は alpha を再び 0.5 に設定し、頂点と終端の両方が 0.5 になる。

`4c911f–4c9519` は終端母線ごとに再切断する。`V=初期終端−P`、`W=C−P` として `dot(W,V)>=0` かつ `|W|²−dot(W,V)²/|V|²<Rc²` のときだけ、長さを `|C−S|−Lp`、半径をその長さ×`aP/bP` へ置き換える。接線一致は置き換えず、負の長さも元の算術に残る。これも最初の ray/sphere 交点ではなく、受光中心の太陽距離による平面である。

## native の差と検証

原版は円周 64 分割の GL fan/strip。native は同じ有限面の算術を連続円錐の ray 評価へ移し、最近不透明球まで描く。同じ赤の面を source-over 合成するが、原 GL の mesh、depth や blend 状態と画素一致は主張しない。表面も球を使い、扁平率や模式半径を追加しない。

初期実装にあった半影一面・下流 0.5→0 の解釈は、この追加監査で撤回し UNIT7 内で修正した。最終の二面・alpha・母線切断・負の終端について独立読取レビューを受け、必須修正の指摘なし。surface/display/cone/scene の三構成の局所検証と、修正直後に失敗した scene fixture の条件は [GUI provenance](../../../native/gui/ECLIPSE_RENDERING.md) と archive に記録する。
