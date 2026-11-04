# Mitaka / Mitaka Plus のソース入手先と利用条件

確認日: 2026-10-29（日本時間）

## 結論

Mitaka は公式の 1.3.1 ソースを入手でき、MIT ライセンスの下で改変・再配布できる。手元の実行版 1.7.4a に一致する公開ソースは確認できなかった。Mitaka Plus は Windows 1.5.4 と旧 Mac 1.0.0 の実行版が掲載されているが、独自 C/C++ ソースの入手先と改変・再配布許諾は未確認。

本調査は入手可能性と公開された条件の確認であり、移植版の基準バージョンや実装方針を決定するものではない。Wine / Wineskin は対象外。

## Mitaka の公式ソース

入手元は国立天文台 4D2U の [旧バージョン・ソースコード一覧](https://4d2u.nao.ac.jp/mitaka/download/download_old/#list04)。以下の9個は公式リンクから実際に取得し、HTTP 200、ZIP 全エントリの CRC、README の版、`Mitaka/main.cpp` の存在を確認した。

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

[作者の公式日本語ページ](http://orihalcon.jp/mitakaplus/)は HTTP で取得できた。HTTPS は取得失敗。公式ページは開発終了と、2010年当時の環境を前提にした配布であることを説明している。

| 対象 | 公式入手先 | 今回確認した範囲 |
|---|---|---|
| Windows 1.5.4 | [mitakaPlus_154.zip](http://orihalcon.jp/mitakaplus/mitakaPlus_154.zip) | HTTP 200、33,695,639 bytes。更新欄は2010-10-19。ZIP の全ファイル名と README を範囲取得 |
| Mac 1.0.0 | [mitakaPlus_100_j.sit](http://orihalcon.jp/mitakaplus/mitakaPlus_100_j.sit) | HEAD 200、2,180,461 bytes。OS X 10.3 以降向け Universal Binary と掲載。内部ファイルは未確認 |
| Plus 本体 C/C++ ソース | 公開入手先は未確認 | 公式日英ページ、公開リポジトリ・一般検索でソース版の配布を確認できず |

旧 Mac の Universal Binary という記載は、現行の Apple Silicon 対応を示すものではない。Windows 1.5.4 とも版が異なる。[英語ページ](http://orihalcon.jp/mitakaplus/index_e.html)は Windows 1.2.0 beta を掲載しており、日本語ページより古い。

### バイナリ配布とライセンス確認

Windows ZIP の中央ディレクトリを調べたところ、690エントリ／688ファイルに C/C++ ソース・ビルド定義・`LICENSE`・`COPYING` に該当する名前はなかった。Lua は17ファイルあり、スクリプトの同梱と本体ソースの公開を区別する。

ZIP 内の `ReadmeWin_J.txt` を範囲取得して展開した結果、[手元の README](</Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/ReadmeWin_J.txt:3>)とバイト単位で一致した。版は **1.5.4 build101013**、README の SHA-256 は `a3549a1d491be012e63e7c5dc62c393bfbfb0ab10e251f7d8545b4ccdda37643`。

公式ページは本家 Mitaka の利用条件への参照と、個人・学校・博物館等での無償利用を説明する。README にもフリーソフトとしての開発・配布という説明があるが、Plus 独自コードの改変・再配布・ソース配布を認める明文は確認できなかった。ベースの Mitaka が MIT であることだけでは、Plus の追加コード全体が MIT とは判断できない。

したがって、Plus 独自実装を引き継ぐには、作者・権利者から対応ソースとその条件を入手することが未解決事項となる。連絡は実施していない。過去に公開された可能性は残るが、Wayback の照会サービスが利用できず、過去の全配布履歴は未確認。

## 補助的な公開ソース

| 入手先 | 版・条件 | 利用上の位置付け |
|---|---|---|
| [yuk7/mitaka](https://github.com/yuk7/mitaka) | 本家 1.3.1 のミラー。README と各ソースヘッダに MIT | 公式配布が取得できるため原本は公式 ZIP を優先。root `LICENSE` の著作権者欄は不完全で、元のソースヘッダを落とさない |
| [yoshikaz1228/Mitaka-macOS](https://github.com/yoshikaz1228/Mitaka-macOS) | 1.3.1 を基にした非公式の部分移植。[LICENSE](https://github.com/yoshikaz1228/Mitaka-macOS/blob/ab63d81723a9261b663c8ab1283de2e7607f1094/LICENSE) は元コードと移植部分を MIT と記載 | SwiftUI / SceneKit と C++ 軌道計算の試作参考。Plus のソースや、本家と同機能の完成版ではない |

macOS リポジトリは commit `ab63d81723a9261b663c8ab1283de2e7607f1094` のコード・Xcode project・ライセンスを確認した。[README](https://github.com/yoshikaz1228/Mitaka-macOS/blob/ab63d81723a9261b663c8ab1283de2e7607f1094/README.md)は macOS 14+、Xcode 16+、Apple Silicon / Intel を掲げる。追加調査では既存コアテストと arm64 / x86_64 の universal build に成功した。GUI 起動・表示精度は未確認。[移植状況](https://github.com/yoshikaz1228/Mitaka-macOS/blob/ab63d81723a9261b663c8ab1283de2e7607f1094/docs/PORTING.md)では、実移植は惑星の軌道計算・太陽系表示が中心で、地上プラネタリウム、銀河・大規模構造、ドーム、動画・通信等は未実装。

公式1.3.1を [sources/official](/Users/kota/mitaka/sources/official) に保存し、非公式版に含まれる上流310ファイルと全件一致を確認した。実際のビルド対象は別の小さな計算コアである。具体的な変更箇所・再利用範囲・検証結果は [1.3.1移植調査](/Users/kota/mitaka/MITAKA_131_PORTING_AUDIT.md) を参照。

手元に同居する [Mitaka++](http://www.magneticfield.jp/mitaka/) は加藤氏の別の派生版。独立版の 1.3.1（2009年）と、本家 1.3.1（2016年）、Plus 1.5.4 を同じ版として扱わない。今回、Mitaka++ 独立版のソース入手先は確定していない。

## 次の判断に必要なこと

1. **本家の移植調査は公式 1.3.1 ソースを使って開始できる。** 手元 1.7.4a の機能を維持する場合は、対応ソースの入手か、1.3.1 との機能差の整理が必要。
2. **Plus はソースと許諾が未解決。** MIT の本家から必要機能を別途実装する案と、Plus 自体を継続保守する案を混同しない。
3. **配布用データと外部依存は別確認が必要。** ソースの MIT 条件だけで、現在のパッケージをそのまま再配布できるとは判断しない。

## 作業・検証記録

- 入手先調査時、公式9版のソース ZIP は一時領域で取得・静的確認。その後の1.3.1調査では原本を作業フォルダへ保存し、一部の構文チェックと非公式版のテスト・ビルドを実施した。アプリ起動、既存データの変更・削除はしていない。
- Plus は ZIP の目録・README の範囲取得と Mac 配布物の HEAD 確認。Mac アーカイブの内容や現行 OS での動作は未検証。
- この調査書を追加し、既存の [macOS ネイティブ対応調査](/Users/kota/mitaka/MACOS_NATIVE_ASSESSMENT.md) のソース入手状況を更新した。
- 作業ディレクトリは Git リポジトリではない。Git 差分・commit は対象外。調査文書のみのためテスト・lint・型チェックは未実施。
- `/simplifier-lai` は未実行。実装方針は未決定のため、`IMPLEMENTATION_POLICY.md` / `policy_gates/` は更新していない。
