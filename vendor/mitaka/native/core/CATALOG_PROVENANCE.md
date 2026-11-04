# カタログローダーの由来と範囲

公式 Mitaka 1.3.1 のレコード配置を基に、読み込み処理を描画・Win32・グローバル状態から分離した。
元のファイルは変更していない。
`src/catalog.cpp` は元の著作権表示と MIT 許諾文を保持する。

| 参照した公式ソース | 対象処理 | 原本 SHA-256 |
| --- | --- | --- |
| `sources/official/mitaka_source/Mitaka/mtk_stars.cpp` | `read_a_Hipparcos_star`、205行以降 | `0d864869c5ffb570701c553ed7634bb885b425d22bcf9431b66a5c3fb8c547a9` |
| `sources/official/mitaka_source/Mitaka/mtk_constellation.cpp` | `read_a_constellation`、115行以降 | `007c0553e78c1ca3737d7882880e149a61e3f2fd50e8a275959549e02b879cf6` |

上表のパスはこのリポジトリのルートからの相対パス。
カタログファイル自体はライブラリへコピー、埋め込み、再配布していない。
ソースコードの MIT 許諾を天文データへ自動的に適用する判断も行っていない。
ユーザーのローカル原本・独自追加データを優先し、公式ソースは形式の参照に使う。公開データへの置換、既知の件数への切り詰め、原本の変換は行わない。

## 読み込む形式

- `hip.dat`: ヘッダーなし、45バイトのレコード列。`int32` HIP、IEEE 754 `float32` 8値、`int8` スペクトル情報2値、`uint8` 二重星フラグ、`int16` Flamsteed番号、`int8` 識別情報4値。
- `constellation_HIP.dat`: ヘッダーなし、6個の `uint8` 長さ付き文字列、`float32` 中心座標2値、`uint8` ポリライン数と各線の点数、`int32` HIP参照、`int16` 境界点数と `float32` 境界座標対。
- 多バイト値は little-endian として復号する。ホストの `long`、`bool`、構造体のサイズ・アラインメントへ依存しない。
- 星座境界の赤経は元ファイルの時単位を保持する。中心座標の赤経と赤緯は度単位。ヘッダーの識別子に単位を含めた。

## 公式処理から変更した点

- 負視差や大きな視差誤差の星も含め、全レコードを保持する。公式描画処理の視差誤差フィルタ、等級から輝度への変換、星名生成はローダーで行わない。
- 公式が読み飛ばす英名、所有格、日本語名、固有運動も保持する。日本語名は元のバイト列を返し、文字コード変換は行わない。
- 星座線の `resize(num)` 後に `push_back` する公式処理で生じる余分な空ポリラインは生成しない。ファイル上の線数と戻り値の線数を一致させる。
- ファイルの途中切断、負の境界点数、非有限浮動小数点値、不正な二重星フラグ、読み込み上限超過で `CatalogError` を返す。例外にファイルパスとバイト位置を含め、部分的な結果は返さない。
- 空ファイルは空カタログとして受理する。初期上限は256 MiB・100万レコード。独自の大きなカタログでは `CatalogLoadLimits` で上限を明示的に指定できる。
- 名前やHIP番号の範囲を既存カタログの値へ固定しない。カスタムデータの識別子・未知の名称を保持する。

## 検証

`test_catalog` は既知の45バイトHIPレコード、星座の可変長レコード、各バイト位置での途中切断、符号付き識別子、負視差保持、NaN、不正フラグ、負の境界点数、件数・バイト上限、空ファイル、不在ファイル、日本語・空白を含むパスを検証する。
標準 `assert` に依存しないため Release ビルドでも検証する。

任意の第1引数に既存 `hip.dat`、第2引数に既存 `constellation_HIP.dat` を指定できる。
この追加検証は今回の保全対象スナップショットの回帰テストで、HIP 117,956件・先頭HIP 1・末尾HIP 936850、星座89件・先頭Andを確認する。
独自データ全般の利用時に、これらの件数・IDをローダーが要求することはない。

今回確認した実ファイル:

- `mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data/hip.dat`: 117,956件。
- `mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data/hip.dat`: 117,956件。
- `mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data/constellation_HIP.dat`: 89件。

現行の `mitaka` 側は星座データがJSON形式で、旧 `constellation_HIP.dat` は存在しない。
星座 JSON は `catalog.cpp` の対象外である。
NGC/IC、SDSS 銀河・QSO、旧 Plus の恒星名テキスト、系外惑星恒星の HIP 一覧は別の `extended_catalog.cpp` で読み込む。形式の根拠、全件保持、任意カタログの失敗通知、独自ファイルの指定、実データ検証は [EXTENDED_CATALOG_PROVENANCE.md](EXTENDED_CATALOG_PROVENANCE.md) を参照。
旧 Plus の `Places:addPlace` 等の観測地定義は別の `place_catalog.cpp` で数値・文字列として解析する。任意の Lua 実行ではなく、公式 1.3.1 の地名テキスト形式とも異なる。根拠と未対応構文は [PLACE_CATALOG_PROVENANCE.md](PLACE_CATALOG_PROVENANCE.md) を参照。
近傍銀河・球状星団・追加軌道など、形式と計算契約が未確認のデータは対応済みと扱わない。
ファイルが保全されていることと、その全形式を読み込めることは別の検証項目である。
