# N16 次単位の pc 表示接続案

2026-10-30。既存コードの読み取りに基づく設計案であり、ここに示す型・UI・接続は未実装である。
UNIT7 は [SDSS/QSO モデル](n16-sdss-spatial-validation.md) と [原値保持 core reader](n16-galaxy-core-validation.md) までに閉じ、3D 表示は次単位とする。
利用者のローカル原本を使用し、欠損時の公開データへの置換や架空のデータ生成は提案しない。

## 現行の接点

| 接点 | 読取時点の既存契約 | 次単位で必要なこと |
| --- | --- | --- |
| `native/gui/include/solar_camera.hpp:12–29`、`src/solar_camera.cpp:11–47` | position/target/distance は AU。通常距離は `0.000005..1000` AU、frame view は下限が異なる。検証と near plane も AU 契約に依存する。 | pc を同じ数値のまま渡さない。1000 AU の上限を広げて銀河対応とはしない。 |
| `src/solar_camera.cpp:60–93,138–189` | 画面基底・透視投影・pan/zoom と既存 solar 操作。 | 単位に依存しない数学を小さな contract seam に分離できる。AU と pc の型別 adapter に境界値検証を残す。 |
| `include/sdss_spatial_model.hpp` | source+ordinal ID、元行を所有、原赤道 pc と native 黄道 pc を区別、全行 snapshot と取消。 | dataset identity と完了 snapshot を保持する scene。約 93 万行を不要に copy しない。 |
| core `galaxy_catalog.hpp` | Plus GC/NBG の原 bytes/行、別型の赤道・native 黄道 pc、行単位の位置診断。 | GC/NBG も family+source+ordinal を保つ immutable scene model へ。名前解決や形状の推測を混ぜない。 |
| core `our_galaxy_model.hpp` | 2 map と 4 raw pc 点群。原点・参照面は未確定。 | raw reader の所有まで利用可能。未確定の座標を同じ scene に渡さない。 |
| `include/extended_catalogs.hpp`、`src/extended_catalogs.cpp:29–55` | SDSS は既存 loader で読むが、返却値には各解決済み path の欄がない。optional 欠損は warning。 | 実際に読んだ path と明示形式を load result まで運ぶ。固定の推測パスを後付けしない。 |
| `src/AppController.mm:169–291` | data load は generation と非同期計算を使い、失敗時は直前のモデルを保持。 | 同じ世代に属する pc model/snapshot を原子的に採用。旧世代と取消結果を採用しない。 |

行番号は読取時点の目安であり、次単位開始時には symbol を使って差分を確認する。共有 App ファイルの実装は親担当が調整する。

## 独立した pc カメラと scene

最初は独立した銀河表示 view/panel とし、SolarSystemView の AU camera や地表・地球月モードを変更しない。
UI の配置は次単位で既存 native panel 様式に合わせる。太陽系から銀河へ連続移動する原版の操作を実装したとは扱わない。

新しい `GalaxyCameraPc` 相当の型は target と distance を pc と明示し、`GalaxyNativeEclipticPositionPc` または明示 adapter の値だけを受け取る。
SDSS と GC/NBG は同じ native J2000 黄道の契約に揃えられる。原赤道 pc は検証と別座標表示のために保持する。
既存の無印 `Vec3` を共通の公開入力にして AU と pc を取り違える構造を避ける。

投影の基底・内積・画面変換は既存 `solar_camera.cpp` の処理を再利用する候補とする。
再利用に必要な seam は「単位に依存しない位置差と基底を投影する小さな入力/出力」であり、汎用 utilities を増やすこと自体は目的にしない。
AU 側の limits・near・入力拒否と全回帰を維持し、pc 側は pc の finite limits・near を別に検証する。
初期 distance、zoom 上下限、fit のゼロ幅処理は native 契約として確定し、原版の未確認値と呼ばない。実データの現在の最大値だけを上限の根拠にしない。

初期表示と「全体を収める」操作は区別する。遠距離や外れ値があるからといって原行を切り捨てない。
選択・focus・pan で距離差を計算する際は、巨大な有限値、ほぼ同じ座標、原点、near の前後を検査し、overflow/NaN を既存 camera 状態へ反映しない。
計算不能な focus は元の camera を保って理由を示す。

## ロードとモデルの所有

1. source ごとに family、形式、実際の local path を持つ load plan を作る。Plus 40 byte GC/27 byte NBG と通常版 text を同じ名前で自動選択しない。明示形式の reader はファイル形式検出器ではない。
2. SDSS は既存 `load_sdss_catalog` を一度呼び、元列を移動できる ownership 境界を用意する。現行 2D と新規 3D のために同じ大きなファイルを再読込しない。共有 immutable model を使うか、既存 load result からの意図した copy を費用とともに決める。
3. GC/NBG/OurGalaxy の結果は原 bytes を所有する。名前 table は別 source のまま保持する。表を合成する名前解決は根拠が確定するまで行わない。
4. optional 欠損、構造不正、位置が作れない行、未対応形式を別状態で報告する。未対応を空の成功 dataset に読み替えない。失敗しても原本を書き換えない。
5. 最新 generation、model identity、取消状態を確認してから完了 snapshot を採用する。load 中のモデル交換や閉じた view へ古い callback を適用しない。

通常版 GC/NBG parser は現時点で未実装なので、その場合は理由付き未対応とする。P の `gc.dat/NBG2.dat` も reader の推測対象にしない。
NGC の角位置から新たな距離を作らず、距離のない種類は既存 2D 表示に残す。
OurGalaxy は原点・参照面と必要な描画式が確定するまで、raw source の情報と件数を示す段階にとどめる。

## 更新・描画・選択

pc 位置は現在の契約では JD や観測地点によらない。model identity と座標変換契約で snapshot を cache し、時刻更新だけで全行を再計算しない。
投影 cache は camera、view bounds、表示 flag、品質設定に依存する。非表示時は lazy に更新し、専用の常時 timer を増やさない。

元行と描画密度を分離する。全読込件数、位置を持つ件数、無効理由の件数、現在画面へ描いた件数を別々に保持する。
空間索引や pixel density による描画抑制を使っても source+ordinal は残し、最初の N 行だけを恒久的に残す方式にしない。
索引・描画配列・snapshot のメモリ予算を明記し、予算不足をカタログの成功件数に偽装しない。

ID は family/source/ordinal と model identity の組で扱う。別 source の同名行・同位置行を統合しない。
reload 後の選択継承には元 bytes の同一性確認を必要とする。SDSS モデル自身は raw bytes を保持しないため、現状では reload で選択を解除する方が契約に合う。
GC 名の NUL 後 bytes、NBG raw code、未解決の名前 table を表示名・Lua 名で暗黙に補完しない。

描画は既存 RendererQuality と CoreGraphics を再利用し、null context で描画しない、view rect へ clip、点/線/文字 scope を分離する。
GC/NBG の形状・色・texture を原版通りとするための追加根拠がない間、原版の見た目の再現は主張しない。

## 次単位の検証条件

- pc 型から AU camera への暗黙変換がなく、native 黄道の軸・極・RA 継ぎ目が独立式と一致する。
- 原点、距離 0、near の前後、背面、巨大有限値、ほぼ一致する camera/target、無効 viewport を検証し、拒否後の camera が変わらない。
- 既存 solar の全 camera/navigation/renderer 回帰を維持する。数学を共通化する場合も AU 挙動を変更しない。
- 索引候補を全行 oracle と比較し、同位置・同名・別 source の行を区別する。表示密度制限によって原行数が変わらない。
- 全体 fit・focus・選択解除・reload・非表示復帰を確認し、取消/旧世代の callback が現在 scene を上書きしない。
- 原本の missing/corrupt/unsupported、同名別形式、追加 source、元 bytes 変更を別々に試験する。公開 fallback や自動生成を使わない。
- 実 bitmap で clip、null context、点/線/文字品質、選択表示と pick を検証する。window を使う統合試験と CUA は親担当が実行する。
- Plus/通常の全原行照合と原本ハッシュ確認を行う。未実装の通常版 text、OurGalaxy 座標、名前解決を完了件数に含めない。

この文書の作成による製品コード・Makefile・policy・README の変更はない。N16 の次単位開始指示までは実装を追加しない。
