# N13 食・影表示の原典と接続前の契約

この文書は UNIT6 固定中の接続前調査を保持する履歴である。以下の「未接続」「未確定」は当時の判定であり、UNIT7 の最終状態は [追加の Plus 実効契約](n13-plus-display-contracts.md) と [GUI provenance](../../../native/gui/ECLIPSE_RENDERING.md) を参照する。

2026-10-30。UNIT6 の表示実装を固定した状態で、ローカル原典を読み取り、次の単位の純計算を新規ファイルだけに追加した。当時は食の GUI / Lua 表示は未接続。計算式・境界処理・検証結果は [core provenance](../../../native/core/ECLIPSE_PROVENANCE.md) を参照する。

## 原典の区別

- 公式ソース O: `sources/official/mitaka_source/Mitaka/`、Mitaka 1.3.1。公開式の参照として採用する。
- ローカル Plus P: `/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka`、互換対象は Windows 1.5.4 build101013。同梱 API 説明書は 1.3.0 / 2007 表記のため、現バイナリとの完全一致を前提にしない。
- 今回は原本の起動・編集・書換え、入力画像の再生成を行っていない。以下の Lua 根拠はローカル文書とスクリプトの読取であり、バイナリの実効分岐を確認したものではない。

## 公式ソースから採用した範囲

| 原典 | 確認した内容 | native の扱い |
| --- | --- | --- |
| O `mtk_eclipse.cpp:52–66` | 影軸と球面の近い交点、未命中の原点 sentinel | 前方半直線の optional 交点。接線保持・異常値拒否を追加 |
| O `mtk_eclipse.cpp:74–120` | 本影・半影の円錐、中心距離と半影による候補除外 | 明示球幾何を使う純関数。等半径円柱は未対応 |
| O `mtk_eclipse.cpp:125–145` | 正規化された平面円盤の重なり面積比 | 同じ面積式を数値的に安定化し、公式抽出関数と比較 |
| O `mtk_eclipse.cpp:150–297` | `asin` 視半径と視中心角、明るい半球の標本、扁平率・三角形生成 | 球外点の視半径・中心角だけを分離。mesh と扁平率は未対応 |
| O `mtk_eclipse.cpp:306–399` | 視点が内部なら抑止、画素角閾値、独立した影フラグ、乗算合成 | RGB 乗数だけを分離。表示閾値・GUI は未接続 |
| O `mtk_eclipse.cpp:403` 以降 | 独立した境界フラグ、円錐と受影面の交線、半径倍率 1.004 | 未実装。単なる円や影軸で代用しない |

O `mtk_planet_eclipse.cpp:55–73` は月の影色を `(0.3,0,0)` に初期化する。82–106 行では planetarium の太陽に物理半径を使い、他モードでは `get_sun_radius(mode)` を使う。116–185 行の惑星・衛星経路には受影体の半径、扁平率、月の別位置関数の差がある。native へは同一 snapshot の明示中心・半径を渡す境界を用意したが、これらの旧モードの選択規則はまだ接続しない。

O `mtk_planets.cpp:486–507` では Earth←Moon、Jupiter←Io/Europa/Ganymede/Callisto、Saturn←Titan を黒い影として登録する。O `mtk_satellites.cpp:191–196` は Moon←Earth を赤い影として登録する。O `mtk_switches.h:71–72` と `mtk_switches.cpp:115` は表示と境界を独立した bit とし、公式の初期値は影だけ ON。この初期値や固定組合せを Plus の確認済み仕様として転用しない。

## Plus の公開項目と未確定部分

| ローカル根拠 | 確認できた項目 | 追加確認が必要な点 |
| --- | --- | --- |
| P `doc/script_jp/planets.html:68` | `Planets.shadows` / `toggleShadows`、表面の影の真偽値 | 現バイナリの対象天体・半径モード・初期値 |
| P `doc/script_jp/planets.html:76` | `shadowBorders` / `toggleShadowBorders`、表面の影境界 | 輪郭の定義と他フラグへの依存 |
| P `scripts/gui_jp.lua:99–100` | `shadowUmbra` / `toggleShadowUmbra` と `shadowPenumbra` / `toggleShadowPenumbra`、本影・半影コーン | コーンの描画長・範囲・色・透過・切断条件 |
| P `scripts/gui.lua:96` | 4 項目を別々に参照し切り替える UI | `shadows` が他項目の master かどうかは未確定 |
| P `scripts/screenmenu.lua:19` | 本影・半影の境界に対応する別名の項目 | 表面境界と円錐境界の同一性を推測しない |

P `ui/scripts/eclipse_20090722.lua:16–19` は 4 フラグを true、尺度を `(1,1,1,1)`、`KEEP_RADIUS` とする。`eclipse_diagram.lua:16–19` は同じフラグで尺度を `(1000,25,100,5)` とする。これらは例の設定であり、起動初期値の証明ではない。`scripts/init.lua:8` が参照する `state/init.lua` は現物で空、`option.lua` にも該当フラグを確認していない。

## 次の接続で固定する境界

1. snapshot の source、数値 JD、座標系を一致させ、未評価の衛星を推測位置で補わない。
2. 太陽・遮蔽体・受影体の半径を明示する。物理球と模式球の半径を混ぜない。
3. 表面への乗算、地表の輪郭、空間円錐を別の描画処理とし、確認した対象だけを実装する。
4. 受影面の夜側と不透明深度を既存 surface renderer で扱う。core の候補円錐だけで可視性を決めない。
5. 旧 Plus の未確定 getter / setter / toggle は成功扱いする仮 API を追加せず、公開根拠または実効分岐を確認してから接続する。

## 局所検証と変更管理

純 kernel 10,179 checks と公式式比較 7,993 checks が通常・ASan/UBSan・x86_64 の各構成で成功した。保存ログは [logs/n13](logs/n13/COMMANDS.md)。原本の hash を記録し、新しい外部依存は追加していない。

この担当は新規 core / test / provenance / 証跡だけを作成し、既存 Makefile、App、renderer、全体方針、policy gate を変更していない。stage・commit は全体担当へ委ねる。親担当の独立読取レビューは修正必須の指摘なし。正確な名前の `/simplifier-lai` は利用できず、手動で責務・既存依存・境界処理を確認した。
