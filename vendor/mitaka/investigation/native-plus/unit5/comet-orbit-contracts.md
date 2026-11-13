# 彗星の表示設定と軌道要素

元のカタログの名称・出典・重複を保持する。[軌道の標本と種類別設定](comet-display-helper-validation.md)・[計算の由来](../../../native/core/SMALL_BODY_PROVENANCE.md)

## 原典で確認できる表示契約

| 原本位置 | 確認できること | 確認できないこと |
| --- | --- | --- |
| `P/doc/script_jp/comets.html:12–19` | `Comets.visible` は read/write boolean、`toggle()` はその反転。 | 初期値、labels/orbits を含む全レイヤーとの厳密な優先順位。 |
| 同 `20–27` | `labels` と `toggleLabels()` は彗星名の表示設定。 | 衝突回避、最大件数、選択行を例外表示するか。 |
| 同 `28–35` | `orbits` と `toggleOrbits()` は軌道線の表示設定。 | 標本数、表示期間、視距離による範囲変更、閉曲線条件。 |
| 同 `36–43` | `selectedOnly` と `toggleSelectedOnly()` は一部のみを表示する設定。説明は `visible == true` の場合に有効とする。 | 初期集合、個別 `Visible` 属性との対応。 |
| 同 `44–55` | `show` / `hide` は固有英語名の空白区切り文字列を受け取り、`isVisible` は一つの名前から boolean を返す。 | 大小文字、未知名・重複名、空リスト、部分成功、グローバル表示設定との関係。 |
| `P/scripts/gui_jp.lua:134–138` | 上記四つにそれぞれ設定用のメニュー項目がある。 | visible と labels / orbits の優先順位、実行版における描画アルゴリズム。 |
| `P/ui/scripts/eclipse_20090722.lua:47–52` | `selectedOnly = true`、`hide("All")`、`show("Holmes Hale-Bopp(1995O1)")` を組み合わせる。 | `show("All")`、`isVisible("All")`、`All` と他名の混在。 |

`selectedOnly` はクリック中の一件とは別の、複数天体からなる表示集合を必要とする。同梱実例の二つの名前を、現在の `selectedSmallBodyIndex` 一件に読み替えてはいけない。クリック選択、追尾、検索結果、表示集合は別の状態である。

種類別の管理名も区別する。`P/doc/script_jp/asteroids.html:12–55` は `Asteroids`、`tnobjects.html:12–63` は **`TNObjects`**。後者の `oort` / `toggleOort` は `:44–51` の別機能である。Asteroids / TNObjects の `show` / `hide` は英語名または小惑星番号を文字列で受け取るが、Comets へ番号指定を一般化する根拠はない。`MinorPlanets` や `TNOs` という Lua alias も確認していない。

## 原本の名前と評価できる行

`P/doc/script_jp/abouttargets.html:29–31` は `Comet.<固有英語名>` を `data/orbits/comets/*.dat` の名前として説明する。一方、現在の native で座標評価できる彗星は、形式・参照面・時系を確認した固定幅 `data/comets.dat` の行である。この二つを自動対応させる根拠はない。

| 原本 | 保持すべき相違 |
| --- | --- |
| `data/orbits/comets/hale-bopp.dat:3–12` と `hale-bopp_jp.dat:3–12` | `Name: Hale-Bopp(1995O1)` は共通だが表示名は異なる。`Tp: 2450539.63709`、`Size: 500`、`Visible: 1` を含む。 |
| `data/orbits/comets/holmes.dat:3–12` と `holmes_jp.dat:3–12` | `Name: Holmes` は共通だが、q/e/i/w/Node/Tp に言語別の差がある。`Tp` は `20070504.49985` / `20070504.49994`。 |
| `data/comets.dat:1–4` | JPL ELEMENTS.COMET の URL、固定幅の列見出し、Halley の行がある。元列は Epoch/q/e/i/w/Node/Tp/Ref。 |
| `data/comets.dat:20,786` | 行名は `17P/Holmes` と `C/Hale-Bopp (1995 O1)`。個別ファイルの Name と一致しない。 |

個別四定義の `Tp` は JD に見える値と暦日形式に見える値が混在する。桁数だけで時系・参照面・日付解釈を決めない。言語別定義を重複として削除したり、JPL 行に差し替えたりしない。現コアはこれらを未解明行として保持し、位置を捏造しない。

[SMALL_BODY_PROVENANCE.md](../../../native/core/SMALL_BODY_PROVENANCE.md):62–85 は、固定幅原本の列と JPL の一次資料を照合した時系・参照面の根拠を記録している。Epoch は MJD TDB、Tp は暦日表現を変換した TDB JD、q は AU、角度は J2000 黄道系の度。1582-10-15 より前の暦は未解明としている。これらは固定幅形式についての確認であり、個別定義や packed mp/TNO 形式の根拠にはならない。
