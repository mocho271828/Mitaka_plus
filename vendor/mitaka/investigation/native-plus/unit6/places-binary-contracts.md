# N07 Places の原版バイナリ契約

2026-10-29。[先行監査](places-earth-layers-audit.md) で未確定だった起動時のファイル選択、風景の引数順、定義の更新キー、ラベルの距離・サイズ、ポインタ別名を、ローカル Plus の静的解析で追加確認した。製品コードは変更せず、原版の実行、設定変更、原本への書込みも行っていない。

## 対象と証拠の範囲

対象は `/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe`。SHA-256 は `48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457`。以下のアドレスはこの PE の仮想アドレスである。同梱 API 文書は 1.3.0 版なので、Plus 1.5.4 build101013 の実装と食い違う場合はその差を明記する。公式標準版ソースとの同一性は仮定しない。

REA provider が利用できなかったため、ローカル `/usr/bin/objdump` と PE セクション・定数の読取りを使用した。保存先 `/tmp/mitaka-n07-binary-audit/` は一時的な調査ログであり、永続的な識別根拠は上記ハッシュと各節のアドレスである。原画像やデータをリポジトリへ複製していない。

| 論点 | 確認結果 |
| --- | --- |
| 利用者用・既定ファイル | 利用者用が存在すればそれだけを実行。存在しない場合に既定を実行する |
| 言語 | 日本語系設定では `_jp` が存在すると優先。英語設定では無接尾辞を使用 |
| 風景の末尾引数 | バイナリでは垂直 offset、水平角度の順。文書の引数名と逆 |
| ラベル群更新 | 群名の完全一致で更新。最初の挿入位置を維持 |
| 風景更新 | 対象と風景名から作る修飾キーの完全一致で更新 |
| 地点更新 | 表示名ではなく、保存された target と resolver が作った完全地点 ID の比較 |
| ラベル distance / size | 距離判定はモデル変換後の幾何量、サイズは距離補償付き billboard 倍率。画素単位とは確定できない |
| `Grids.surfacePointer` | このバイナリの登録・文字列・同梱スクリプトに現行 alias の根拠なし |

## 起動時の利用者用・既定ファイル選択

起動処理 `0x5c2525–0x5c2803` は `data/places.dat` を言語 resolver `0x41c0d0` へ渡し、解決先の `QFileInfo::exists` を `0x5c2625` で呼ぶ。`0x5c2630` の条件分岐は次の排他的な処理である。

1. 存在する場合は利用者用パスを再度解決し、`0x5c2698` からスクリプト読込 `0xa63a10` を呼ぶ。`0x5c271a` で既定ファイル分岐を飛ばす。
2. 存在しない場合だけ `data/defaultplaces.dat` を `0x5c2766` で解決し、`0x5c2781` で実行する。

これは「利用者用の解析が成功しなければ既定へ戻る」という判定ではない。存在したファイルの解析失敗、両方の欠損、Lua 内部のエラー処理はこの監査で確定していない。

言語 resolver は `0x41c149` で設定値を取得し、`0x41c151` で値 `2` と比較する。値 `0/1` は拡張子の直前に `_jp` を入れた候補を作り、`0x41c1f7` の存在確認で採用する。存在しなければ `0x41c379` から元の無接尾辞パスを返す。値 `2` は英語設定で、接尾辞候補を作らない。言語設定の対応は N10 の `language-config.txt` / `language-accessors.txt` と照合した。

したがって日本語系の選択順は次のとおりであり、選んだファイル同士を合算しない。

```text
user = places_jp.dat が存在すればそれ、なければ places.dat
user が存在する → user だけを実行
user が存在しない → defaultplaces_jp.dat が存在すればそれ、なければ defaultplaces.dat を実行
```

ローカル `places_jp.dat` は 4 地点、`Default` ラベル群、2 風景の宣言を持つ。ファイル全体に既定ファイルの `dofile` / include はない。別の初期化 `0x5360e0` は組込み `Default` 群を作る処理であり、既定地点ファイルを読み足す処理ではない。

同梱の無接尾辞 `places.dat` は `OBJECT:` / `TYPE:` を使う別形式である。この内容が Lua 読込経路で有効になるとは認定しない。読み取ったファイルの形式と、起動コードが選ぶパスは区別する。

監査開始時の native GUI は `defaultplaces_jp.dat` と `places_jp.dat` を合算していた。この方式は原版の上記分岐と一致しない。独自地点と原定義を保存する要求は維持しつつ、「原版と同じ実効選択」と「全出典の原定義保持」を別の契約として扱う必要がある。

証拠: `places-startup.txt`、`script-file-call.txt`、`places-default-init.txt`、`local-lua-references.txt`。言語 resolver は `/tmp/mitaka-n10-init-audit/language-resolver.txt`。

## 実効定義のキーと更新順

主要容器はグローバル `0x1106f80` が指すオブジェクトである。以下はその内部配置の観測結果であり、native の公開データ形式として採用する指示ではない。

| 定義 | 配列と要素サイズ | 比較と更新 |
| --- | --- | --- |
| ラベル群 | begin `+0x04` / end `+0x08`、stride `0x34` | `0x529147` で群名の完全一致を探す。最初の一致を `0x5294ab–0x529750` で更新し、なければ追加 |
| 風景 | begin `+0x14` / end `+0x18`、stride `0x6c` | `0x52ab5b` で record `+0x24` の修飾キーを完全比較。一致は `0x52adcc–0x52ae31` で更新し、なければ追加 |
| 地点 | begin `+0x24` / end `+0x28`、stride `0x9c` | `0x52e50c–0x52e54a` で既存 record `+0x24` と resolver の完全 target を比較。一致は `0x52e8c2–0x52e97e` で更新し、なければ追加 |

同じキーの後の呼出しは値を上書きする。更新は配列末尾への再挿入ではなく、既存位置を保つ。比較は文字列の完全一致で、大小文字の補正を確認できない。`city2` と `City2` を同じ名前としない。

風景キーは `0x52a590` の target resolver 呼出し後に構成される。対象が文字列 `Planet` / `Satellite` の場合は、それぞれ `Planet.<風景名>` / `Satellite.<風景名>` を作る。その他は入力 target に `.` と風景名を加える。対象天体と風景名の組を使い、風景名だけを全域キーにしない。

地点の表示名は record `+0x40` に保存され、更新比較には使われない。入力 target は `+0x24`、resolver が抽出した地点 suffix は `+0x08` に保存される。resolver `0x5901b0` は `.` で分解し、通常の惑星・衛星について `0x591370` から天体名と suffix を再構成する。`0x591652–0x5916c6` で `.<suffix>` を完全 target へ追加する。

そのため通常の `Planet.Earth.<地点ID>` は、表示名を変更しても同じ完全地点 ID なら既存地点を更新する。一方、保存される入力文字列と比較に使う正規化結果は別である。全別名の正規化、未知天体、不正 ID、4 成分以上の target を未調査のまま同じ規則へ広げない。

証拠: `places-class.txt`、`target-resolver.txt`、`target-resolver-rest.txt`、`target-place-suffix.txt`。群・風景が未解決の場合の全 fallback 経路は今回確定していない。

## 風景の引数順と局所投影

Lua wrapper `0x649f90` は self を除く `target, name, file, scale, offset1, offset2` を順番通りに adapter `0x5c9720`、登録処理 `0x52a590` へ渡す。`0x52aacf–0x52aaeb` の格納先と描画側を対応させると、実効順序は次になる。

```text
Places:addLandscape(target, name, file, scale, verticalOffset, horizontalDegrees)
```

record `+0x60` が scale、`+0x64` が最後の引数、`+0x68` が最後から二番目の引数である。`+0x64` は `0x533c10–0x533c2f` で Z 軸まわりの `glRotatef` に直接入り、`+0x68` はテクスチャ V 座標から減算される。同梱文書の `scale, horOffset, verOffset` という順序とは逆である。原引数は保持し、描画へ渡す境界でこの順序を明示する。

画像ありの `0x5336a0` 内経路は、`i=0..18`、`j=0..72`、`θ=5°i`、`φ=5°j` に対して次の局所座標と UV を作る。式の根拠は `0x533a93–0x533b6b`。

```text
position = (cosφ sin(2θ), sinφ sin(2θ), -cos(2θ))
u = 1 - j/72
v = 0.5 + (i/18 - 0.5)/scale - verticalOffset
position の描画行列へ Rz(horizontalDegrees) を合成
```

画像ありでは水平 5°、極角 10°刻みの 72×18 四角形となり、球全体の極角を覆う。S/T wrap は `0x533be1–0x533c02` で `GL_CLAMP_TO_EDGE` を指定する。画像なしの分岐は極角が `θ` の黒い半球であり、画像ありの式と同一ではない。

ここで確定したのは描画関数内の局所座標である。絶対方位の北、呼出元のカメラ座標、画像 upload 時の上下反転、選択地点用の別分岐 `0x534648`、全画面 clip は未確定である。この式だけで native `HorizonView` の方位基準へ直接接続し、原版と一致したとは扱わない。

証拠: `label-landscape-wrappers.txt`、`places-adapter.txt`、`places-class.txt`、`imports.txt`。

## ラベル群の distance と size

Lua `addLabelGroup` は `name, distance, size, r, g, b, alpha` を wrapper `0x649920`、adapter `0x5c96f0`、登録 `0x528fe0` へ順番通りに渡す。群 record の distance は `+0x1c`、size は `+0x20`。

描画 `0x532470` のうち surface object が非 null の分岐を追跡した。モデルビュー行列の第 0 列の二乗ノルムを `k²`、経緯度から作った局所位置を倍率 `1.001999974` で置いた後の平行移動成分の二乗ノルムを `r²` とすると、`0x5328c4–0x5328e9` の表示判定量は次になる。

```text
q = k² * distance² / r²
q <= 0.0006853892118670046 なら表示を省略
fade = min(1, (q - 0.0006853892118670046) / 0.0012184695806354284)
```

選択地点と完全 target が一致する場合は `0x532940–0x53294a` で `distance²` の代わりに `0.25` を用いる。さらに近距離の減衰、全ラベル fade、呼出元 fade を掛け、低 alpha を省略する。距離は変換後の幾何量の比であり、リテラルな画素数や km の閾値とは認定できない。

サイズは `0x532b70–0x532b97` で `S = Places.labelSize * perBodySize * group.size / 1.2` を作る。billboard helper `0x5279c0` がモデルビューの平行移動成分と eye offset の距離 `L` を返し、`0x532c11–0x532c5b` は次の `glScalef` を設定する。

```text
scale = S * callerA * (L/callerB) / 180
```

これは距離を補償する billboard の倍率であり、`group.size` 自体を文字のピクセル高と解釈しない。呼出元 `0x54a8cb` では A/B にグローバル `0x110752c` / `0x1107528`、天体別 size に object `+0x230` が使われるが、A/B の FOV・画面寸法との全対応は未確定である。この呼出しは surface object が null の別分岐へ入り、その全式は未確認である。

証拠: `places-class.txt`、`places-labels-region.txt`、`labels-caller.txt`、`imports.txt`。全呼出元、遮蔽条件、天体の物理半径と単位、null 分岐を未確認のまま共通の画素式へ縮約しない。

## ポインタの登録と旧文書の別名

`Places.pointer` の getter / setter は `0x64cab0` / `0x64cae0`。`setPointer` / `getPointer` / `togglePointer` の wrapper は `0x64c860` / `0x64c8a0` / `0x64c8d0` で、adapter を経て Lua Places オブジェクトの `+0x04` の fade 状態を操作する。この状態の存在は確認できるが、ポインタ形状の全描画は今回追跡していない。

`Grids` 登録範囲 `0x63e740–0x63eaba` に `surfacePointer` の登録はない。バイナリ全 bytes の ASCII 検索でも `surfacePointer` / `toggleSurfacePointer` は見つからない。同梱の Lua / dat / HTML / text の調査範囲では、該当名は旧 `grids.html` の説明にだけ現れ、alias を定義する Lua shim は見つからなかった。

したがって「この版で `Grids.surfacePointer` が `Places.pointer` と同一実体を指す」という証拠はない。現行 Places の状態操作と旧文書の表記を分ける。任意の外部スクリプトが動的に alias を追加する可能性まで否定したものではない。

証拠: `places-properties.txt`、`places-registration.txt`、`grids-registration.txt`、`string-xrefs.txt`、`local-lua-references.txt`。

## 実装への引継ぎと未実施事項

- 実効ファイルは上記の存在・言語分岐で選ぶ。全出典と原定義の保存を、起動時の合算と同義にしない。
- キー更新、配列順、CP932 の名称 bytes、大小文字、原 target を保持する。表示名を地点の更新キーにしない。
- 風景引数は原順を保持し、垂直 offset と水平角度を取込境界で明示する。絶対方位は追加の呼出元調査が必要。
- ラベル distance / size を未確認の画素単位へ置き換えない。surface object の有無と各呼出元の倍率を確定してから互換描画へ接続する。
- 別名 API、未解決 target の補正、別形式 `places.dat` の自動解釈を、この調査の確定事項として追加しない。

今回の検証は保存済み逆アセンブルの照合、定数と IAT の確認、ローカル定義の読取りである。製品テスト、旧 Plus の画面比較、描画結果の一致、policy gate の実装合格を認定していない。ソース・依存・永続化形式の変更がないため、実装テストの再実行は行っていない。

## 後続実装の確認（2026-10-29 作業ツリー）

上記監査の後、`native/gui/src/observer_places.cpp` に排他的な選択を反映した。`ObserverPlaces::sources` は存在した全 4 候補の原 bytes、全定義、解析エラーを保持し、`selected_source` が唯一の実効元を指す。読取制限超過・I/O 失敗では原 bytes を取得できないため、その出典と失敗理由を保持する。存在する user の解析失敗・空ファイルは default への切替条件にしない。日本語と英語の選択を明示した型を追加し、現在の GUI 呼出しは日本語を既定とする。

地点更新は、既知の惑星の正規名と単一地点 suffix からなる完全 ID に限定した。更新時は初出位置を維持し、勝った原行への provenance を保持する。未知 target、別名、空 suffix、余分な成分は独立行のまま保持して未解決診断を付ける。地球へ適用できるのは `Planet.Earth.<単一地点ID>` だけとし、似た target を地球に読み替えない。

担当 subagent が Apple Clang の `-Werror` で純粋 C++ テストを実行した。通常 arm64、ASan/UBSan arm64、x86_64 の実行はいずれも 445 checks が通過。各構成の実データ検証では Plus が 472 checks（実効 4 地点、全候補の原定義 108 地点）、通常版が 458 checks（旧形式 `places.dat` の原文と未対応診断を保持）で通過した。ファイル存在の 16 通り × 2 言語、失敗時の非 fallback、空入力、全候補の原 bytes、完全 ID 更新、未知 ID を検証している。ログは `/tmp/mitaka-n07-tests/`。

core の終端確認は `peek()` 後の `badbit` も検査するよう修正した。I/O 障害の決定的な注入試験は追加していない。確認したのはコード上の分岐と既存 parser 試験である。

この実装検証には GUI 起動、旧 Plus 実行、画像比較、全体 policy gate 判定を含めていない。ラベル群・風景は原定義を保持する段階であり、未確定の描画 frame や倍率を推測して Horizon へ接続していない。
