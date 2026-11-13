# Mitaka / Mitaka Plus のソース入手先と利用条件

確認日: 2026-10-29（日本時間）

## 結論

Mitaka は公式の 1.3.1 ソースを入手でき、MIT ライセンスの下で改変・再配布できる。実行版 1.7.4a に一致する公開ソースは確認できなかった。Mitaka Plus は Windows 1.5.4 と旧 Mac 1.0.0 の実行版が掲載されているが、独自 C/C++ ソースの入手先と改変・再配布許諾は未確認。

この記録は上記の日付で確認した配布物に関するもの。ネイティブアプリが実際に使用するコードの許諾表示は [第三者コード](native/gui/THIRD_PARTY_NOTICES.txt) と [Lua](native/gui/LUA_LICENSE.txt) に収録している。

## Mitaka の公式ソース

入手元は国立天文台 4D2U の [旧バージョン・ソースコード一覧](https://4d2u.nao.ac.jp/mitaka/download/download_old/#list04)。以下の9個は公式リンクから取得して ZIP の CRC、README の版、`Mitaka/main.cpp` の存在を確認した。

| ソースの版 | ソース欄の公開日 | 公式 ZIP |
|---|---|---|
| **1.3.1** | 2016-07-01 | [mitaka_source_131.zip](https://4d2u.nao.ac.jp/wp-content/uploads/mitaka/software/mitaka_source_131.zip) |
| 1.3.0 | 2015-11-24 | [mitaka_source_130.zip](https://4d2u.nao.ac.jp/wp-content/uploads/mitaka/software/mitaka_source_130.zip) |
| 1.2.5 | 2015-07-29 | [mitaka_source_125.zip](https://4d2u.nao.ac.jp/wp-content/uploads/mitaka/software/mitaka_source_125.zip) |
| 1.2.4 | 2015-06-12 | [mitaka_source_124.zip](https://4d2u.nao.ac.jp/wp-content/uploads/mitaka/software/mitaka_source_124.zip) |
| 1.2.3 | 2015-03-10 | [mitaka_source_123.zip](https://4d2u.nao.ac.jp/wp-content/uploads/mitaka/software/mitaka_source_123.zip) |
| 1.2.2 | 2014-12-16 | [mitaka_source_122.zip](https://4d2u.nao.ac.jp/wp-content/uploads/mitaka/software/mitaka_source_122.zip) |
| 1.2.1 | 2012-06-24 | [mitaka_source_121.zip](https://4d2u.nao.ac.jp/wp-content/uploads/mitaka/software/mitaka_source_121.zip) |
| 1.2.0 | 2008-05-26 | [mitaka_source_120.zip](https://4d2u.nao.ac.jp/wp-content/uploads/mitaka/software/mitaka_source_120.zip) |
| 1.1.0 | 2007-10-09 | [mitaka_source_110.zip](https://4d2u.nao.ac.jp/wp-content/uploads/mitaka/software/mitaka_source_110.zip) |

一覧には 1.0 の見出しもあるが、リンク先は 1.1.0 と同じ `mitaka_source_110.zip` で、実体の README も 1.1.0。そのため、1.0 の実入手確認には数えていない。

1.3.1 の README の日付は 2016-03-04、公式ソース欄の公開日は 2016-07-01。実行版のリリース日とソース公開日を区別する。[現行実行版の掲載](https://4d2u.nao.ac.jp/mitaka/download/)は 1.7.4a（2023-03-24）で、ソース一覧の最新掲載版とは異なる。

### 1.3.1 の現物と条件

- ZIP は 905,545 bytes、SHA-256 は `778c66bf6c81d2bf0bba380e9209882ecd961dd79cb9d2140758849d82314429`。
- `mitaka_source/Readme.txt` は 1.3.1 と MIT ライセンスを明記。`Mitaka/main.cpp` 冒頭に著作権表示と MIT 許諾全文がある。
- MIT 条件は利用・複製・改変・結合・公開・再配布・再許諾・販売を認める。複製または実質的部分に、元の著作権表示と許諾表示を残す必要がある。配布時は免責を含むライセンス全文を保持する。
- 変更したソースの公開義務や、非営利に限る条件は、この MIT 本文にはない。著作権者として加藤恒彦氏、4D2U Project / NAOJ の表示がある。
- 軽いライセンス走査では、310ファイル中306個の C/C++ ソース・ヘッダに MIT 許諾冒頭があった。残りはリソース、アイコン、README 等。別条件を示す追加通知は検出しなかったが、外部依存・実行時データまでを網羅する監査ではない。
- README は Windows 7、Visual Studio 2015、Intel C++ Composer XE 2016 の環境を説明し、DirectX SDK、JPEG、zlib、libpng、GLEW、FreeType 2.6 等を別途取得する手順を記載。macOS 用の完成したビルド環境を入手できたという意味ではない。

上記の条件は、[公式 ZIP](https://4d2u.nao.ac.jp/wp-content/uploads/mitaka/software/mitaka_source_131.zip) の README とソースヘッダを根拠とする。

### 配布パッケージ・データの条件は別に扱う

[NAOJ の一般利用規定](https://4d2u.nao.ac.jp/policy/)は、プログラム・サンプルデータ・説明文書等について非営利利用、第三者への再配布禁止、改変の事前書面許可等を定めている。MIT と明示されたソースの許諾を、現在の配布パッケージ全体や天文データ・画像・地形・モデル・フォントへ広げて扱わない。

[現行ダウンロードページ](https://4d2u.nao.ac.jp/mitaka/download/)には、v1.6.0 以降の次の対象は自由に改変・再配布できるという例外がある。

- 本体直下の `mitaka.ini`
- `programs/` の `.txt`、`.dat`、`.mcd`
- `locale/` 直下の `.lng`、`.dat`（`ja/`、`en/` 等の下は対象外）
- `media/` の `.mif`
- メニューの「状態をファイルに保存」で出力するファイル

この例外を Plus や古い版へ一律には適用しない。外部ライブラリについても、実際に採用する版のライセンス・表示義務を別途確認する必要がある。

## Mitaka Plus

[作者の公式日本語ページ](http://orihalcon.jp/mitakaplus/)は開発終了と、2010年当時の環境を前提にした配布であることを説明している。

| 対象 | 公式入手先 | 配布物の識別情報 |
|---|---|---|
| Windows 1.5.4 | [mitakaPlus_154.zip](http://orihalcon.jp/mitakaplus/mitakaPlus_154.zip) | 33,695,639 bytes。更新欄は2010-10-19。収録ファイル一覧と README を確認 |
| Mac 1.0.0 | [mitakaPlus_100_j.sit](http://orihalcon.jp/mitakaplus/mitakaPlus_100_j.sit) | 2,180,461 bytes。OS X 10.3 以降向け Universal Binary と掲載。内部ファイルは未確認 |
| Plus 本体 C/C++ ソース | 公開入手先は未確認 | 公式日英ページ、公開リポジトリ・一般検索でソース版の配布を確認できず |

旧 Mac の Universal Binary という記載は、現行の Apple Silicon 対応を示すものではない。Windows 1.5.4 とも版が異なる。[英語ページ](http://orihalcon.jp/mitakaplus/index_e.html)は Windows 1.2.0 beta を掲載しており、日本語ページより古い。

### バイナリ配布とライセンス確認

Windows ZIP の中央ディレクトリを調べたところ、690エントリ／688ファイルに C/C++ ソース・ビルド定義・`LICENSE`・`COPYING` に該当する名前はなかった。Lua は17ファイルあり、スクリプトの同梱と本体ソースの公開を区別する。

Windows ZIP に含まれる `ReadmeWin_J.txt` の版は **1.5.4 build101013**、README の SHA-256 は `a3549a1d491be012e63e7c5dc62c393bfbfb0ab10e251f7d8545b4ccdda37643`。

公式ページは本家 Mitaka の利用条件への参照と、個人・学校・博物館等での無償利用を説明する。README にもフリーソフトとしての開発・配布という説明があるが、Plus 独自コードの改変・再配布・ソース配布を認める明文は確認できなかった。ベースの Mitaka が MIT であることだけでは、Plus の追加コード全体が MIT とは判断できない。

## 補助的な公開ソース

| 入手先 | 版・条件 | 利用上の位置付け |
|---|---|---|
| [yuk7/mitaka](https://github.com/yuk7/mitaka) | 本家 1.3.1 のミラー。README と各ソースヘッダに MIT | 公式配布が取得できるため原本は公式 ZIP を優先。root `LICENSE` の著作権者欄は不完全で、元のソースヘッダを落とさない |
| [yoshikaz1228/Mitaka-macOS](https://github.com/yoshikaz1228/Mitaka-macOS) | 1.3.1 を基にした非公式の部分移植。[LICENSE](https://github.com/yoshikaz1228/Mitaka-macOS/blob/ab63d81723a9261b663c8ab1283de2e7607f1094/LICENSE) は元コードと移植部分を MIT と記載 | SwiftUI / SceneKit と C++ 軌道計算の試作参考。Plus のソースや、本家と同機能の完成版ではない |

非公式移植とのソース比較は [Mitaka 1.3.1 の移植調査](MITAKA_131_PORTING_AUDIT.md) に記載する。

[Mitaka++](http://www.magneticfield.jp/mitaka/) は加藤氏の別の派生版。独立版の 1.3.1（2009年）、本家 1.3.1（2016年）、Plus 1.5.4 は異なる配布物である。
