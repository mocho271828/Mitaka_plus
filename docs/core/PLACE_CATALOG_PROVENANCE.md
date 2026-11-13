# 旧Plus観測地データの契約と根拠

`place_catalog.hpp` / `place_catalog.cpp` は、ローカルの旧Plus観測地ファイルを
読み取り専用で解析する。Luaの実行や、参照された画像の読み込みは行わない。
任意のLuaスクリプトへの互換性を提供するAPIではない。

## 参照資料

以下は旧 Plus 1.5.4 のアプリフォルダを起点とする相対パス。記載の資料と実データを照合した。

| 相対パス | 根拠となる箇所 | SHA-256 |
| --- | --- | --- |
| `doc/script_jp/places.html` | 39〜47行: 3種のaddメソッドの引数、座標の符号、同名定義の更新 | `c5cb2f015242ec8ba41710ddda7de5d09604bea72ae89c662c30d00436aae9c4` |
| `doc/script_jp/abouttargets.html` | 53〜56行: 天体名にピリオドと観測地名を連結する規則 | `0d4fdf09fd437136a26315c5b0a4a6e9e669e2fa65ba5ef41624e4cae7127a5f` |
| `ReadmeWin_J.txt` | 95〜104行: 観測地の追加・編集、地名ラベル、地上風景 | `a3549a1d491be012e63e7c5dc62c393bfbfb0ab10e251f7d8545b4ccdda37643` |
| `data/defaultplaces.dat` | 既定観測地の英語表記 | `63957b4797482ba54da1ada418f647f6438e65ba360db0fcbc903642802ece34` |
| `data/defaultplaces_jp.dat` | 既定観測地のCP932日本語表記 | `6932bd9aabf13fefc5b7bae570fe903f107da96db57751e85373b2f60507c258` |
| `data/places_jp.dat` | ローカル追加観測地の4定義 | `d61680e75d480a46825d429b05487b7e96f2e6e17742bc9e454b7899f80bde0c` |

`data/places_jp.dat` には国立立山青少年自然の家、立少、北極、新規観測地の
表示名を持つ4件がある。入力座標を地名から補正せず、そのまま保持する。
このファイルの内容を配布物やテストfixtureに複製しない。

## 対応する入力

各行の次の3種の呼出しを解析する。

```text
Places:addPlace(targetName, name, lon, lat, labelGroup, landscape);
Places:addLabelGroup(name, distance, size, r, g, b, alpha);
Places:addLandscape(targetName, name, fileName, scale, offsetArgument1, offsetArgument2);
```

名前、ID、画像パスは引用符で囲んだ文字列、その他は有限の10進数リテラルとする。
`addPlace` は経度・緯度の順で、東経・北緯が正。緯度は `[-90, 90]`、
経度は有限値をそのまま返す。既知の天体や観測地IDとの照合はローダーでは行わない。
GUIが扱えない天体も読み込み時に破棄しない。

表示名などの文字列はCP932を含め原bytesを保持し、GUIが必要な文字コード変換を行う。
CP932の2バイト文字は組として保持し、「ソ」「能」「表」の第2byteに含まれる
`0x5c` をバックスラッシュによるエスケープと誤認しない。
空のラベルグループ・風景参照は原典のDefault参照を表すので保持する。
ラベル距離・サイズは0以上、RGBAは `[0, 1]`、風景の垂直倍率は正とする。
ラベルの表示距離の単位は説明書から確定できないため、原値で保持する。

説明書の `addLandscape` の見出しは末尾を `horOffset, verOffset` とするが、
本文の説明順とローカルの既定定義には整合しない点がある。
実装は第5・第6引数を `offset_arguments` に原順序で格納し、水平・垂直の意味や
単位を推定しない。これらを描画へ適用するには、旧Plus実装との追加照合が必要である。

空白行、`--` による1行コメント、CRLF、末尾の改行・セミコロン省略を受理する。
1行につき1呼出しとし、文字列は単一・二重引用符を受理する。
文字列のエスケープはバックスラッシュと引用符だけに限定する。
式、変数、長文字列、複数行・長コメント、未知のメソッド、末尾の別命令はエラーにする。
実データ3ファイルには、これら未対応の構文は存在しない。

同名の定義は、原典では後の定義が先の設定を上書きする。
本ローダーは各種の定義を入力順で保持し、重複も返す。
既定ファイルと追加ファイルを選ぶ処理、同名を後勝ちで適用する処理はGUIの責務とする。
データディレクトリや言語が異なるファイルを自動結合しない。

## 公式ソースとの差異

公式1.3.1の `vendor/mitaka/sources/official/mitaka_source/Mitaka/mtk_places.cpp:84 load_places`
と `mtk_places.h:49 PlaceItem` を照合した。
この実装は `OBJECT:` / `TYPE:` と地名キーのテキスト形式を読み、
旧Plusの `Places:addPlace` 形式は扱わない。したがって今回の解析器は、
その公式ローダーを互換ソースとして移植したものではない。

ローカルの通常版 `data/places.dat` は公式1.3.1の経度・緯度順に対応するが、
Plusの同名ファイルは緯度・経度順とN/S/E/W接尾辞を使う別形式である。
これらは今回のAPIで読み込まず、渡された場合は明示的な構文エラーにする。
ファイル名が同じという理由で形式を仮定しない。

## 検証とエラー

ファイルbytesと総定義数に `CatalogLoadLimits` を適用する。
既定の件数上限は配布件数と無関係の1,000,000で、呼び出し側が変更できる。
行長上限は4096 bytesでNULを拒否する。
内容エラーはパス・byte offset・1始まり行番号を持つ `CatalogError` で通知し、
ファイル全体の検証が終わるまで部分結果を返さない。

合成fixtureで、引用符内の区切り文字、CP932の保持、未知の天体ID、
重複定義、経度の保持、境界緯度、全切断位置、不正数値、上限超過、未対応命令を検証する。
元のローカルデータはfixtureに同梱しない。
2026-10-29、AddressSanitizer / UndefinedBehaviorSanitizer と
`-Wall -Wextra -Wpedantic -Werror` を有効にして、合成入力とローカル3ファイルの
読み込みテストが成功した。実データの件数は次のとおりで、テストの固定条件にはしない。

| ファイル | 観測地 | ラベルグループ | 風景参照 |
| --- | ---: | ---: | ---: |
| `defaultplaces.dat` | 52 | 4 | 21 |
| `defaultplaces_jp.dat` | 52 | 4 | 21 |
| `places_jp.dat` | 4 | 1 | 2 |
