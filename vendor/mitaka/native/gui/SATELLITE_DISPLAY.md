# 追加衛星の表示と瞬時軌道

## 表示設定と原行の保持

`SatelliteDisplayModel` は `SatelliteModel` の全原行を保持し、表示設定と表示集合だけを管理する。同名、同一出典内の重複、言語別出典、位置を評価できない行も削除しない。表示集合の識別子は `SatelliteRecordId {source_key, record_ordinal}`。`record_ordinal` は衛星だけに振り直した番号ではなく、元の定義ブロックの順番である。

native の初期値は `visible=true`、`labels=false`、`orbits=false`、`selected_only=false`、表示集合は空である。旧版の `Visible` 項目や初期表示集合との一致は主張しない。表示の判定は次のとおり。

```text
body  = visible AND (NOT selected_only OR member)
label = body AND labels
orbit = body AND orbits
```

この設定を一覧・Lua・セッション保存・太陽系ビューで共用する。描画とクリックは同じ集合で絞り込み、さらに位置の評価結果と画面内の可視性を判定する。地球・月の近接表示、表面観察、飛行中は追加衛星の概観表示を抑制する。クリック選択と表示集合は独立しており、視点移動だけでは集合や表示フラグを書き換えない。一覧から選ぶ操作は全体の `visible` を有効にするが、`selected_only` やその集合は変更しない。

一覧では、行の追加・除外、全行の追加、集合の消去を行える。「全行」は検索結果やページ内の行に限定しない。未知・重複 ID を渡した更新は全体を拒否し、更新前の集合を保つ。データの再読込では同じ ID かつ定義出典の原 bytes が完全一致する行だけを引き継ぎ、外れた ID を返す。出典の絶対配置、records vector の順番、軌道ファイルの変更だけでは定義 ID を別行に置き換えない。

セッション v5 は表示集合に参照された出典の SHA-256 とサイズを保存し、復元前に一致を検証する。詳細は `session_layers.hpp` の契約に従う。保存のために元データを書き換えない。

## 瞬時軌道の計算

`satellite_orbit_geometry()` は immutable な `SatelliteSnapshot` に対して一度計算し、同じ snapshot の描画にだけ使う。各原行に点列または診断を保持し、行数と行順を変えない。描画ループの中では軌道計算を行わない。

対象は、既存の登録・相対位置・絶対位置モデルが検証できる楕円 Kepler 行である。現在日時で得た親位置と相対軌道面の回転を固定し、離心近点角を 256 分割して閉じた 257 点を作る。半長軸を `a`、離心率を `e` とした軌道面の位置は次式で、既存の回転を適用して親位置を加える。

```text
x = a (cos(E) - e)
y = a sqrt(1 - e²) sin(E)
```

出力は日心 J2000 黄道座標の AU。現在日時の相対位置と絶対位置を既存計算と照合し、親補正を重ねない。Charon には既存モデルで確認済みの質量比補正を適用する。未知の連星補正、月の専用解析、出典不明、行数不一致、現在位置を再現できない行には点列を作らない。ローカル 340 行について、JD 2451545 と 2451546 の両方で 328 行が対象、月 2 行と未解決 10 行は診断を保持する。

これは現在日時の瞬時楕円であり、時刻を進めた日心軌跡ではない。旧版の描画標本数、線形状、精度期間の一致も主張しない。登録・親補正・回転の出典は [登録モデル](../core/SATELLITE_MODEL_PROVENANCE.md) と [座標契約監査](../../investigation/native-plus/unit4/satellite-position-contracts.md) に記録している。

## Lua と検証範囲

`Satellites.visible/labels/orbits/selectedOnly` の boolean 取得・設定・toggle を公開する。取得と toggle は最新の native 設定を読み、ホストが拒否した更新は Lua エラーを返す。名前による旧 `show/hide/isVisible` は未対応。Lua の `Satellite.<name>` は現在選択中の衛星と同じ出典に限って名前を解決し、未選択時は全出典中で一意の場合だけ解決する。同一出典内の同名行も曖昧として拒否する。位置が評価できた対象だけを移動・地平図の注視に使う。旧版の言語別出典の選択方式は未確定であり、native の選択方式との一致は主張しない。根拠は [Lua 契約監査](../../investigation/native-plus/unit5/lua-comet-satellite-contracts.md) を参照する。

専用試験は、表示集合と再読込の原子性、同名行、軌道の近点・遠点・回転・現在位置、不正 snapshot と描画領域の拒否、表示とクリックの一致、点・名称・軌道の画像差、一覧操作、Lua の厳密な型と最新 snapshot を検証する。原版 Windows の画像との比較試験ではない。実行ログと最終構成の結果は統合作業の記録を参照する。
