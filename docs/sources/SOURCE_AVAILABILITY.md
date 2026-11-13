# Mitaka / Mitaka Plus のソース入手先と利用条件

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


## Mitaka Plus

[作者の公式日本語ページ](http://orihalcon.jp/mitakaplus/)は開発終了と、2010年当時の環境を前提にした配布であることを説明している。

| 対象 | 公式入手先 | 配布物の識別情報 |
|---|---|---|
| Windows 1.5.4 | [mitakaPlus_154.zip](http://orihalcon.jp/mitakaplus/mitakaPlus_154.zip) | 33,695,639 bytes。更新欄は2010-10-19。収録ファイル一覧と README を確認 |
| Mac 1.0.0 | [mitakaPlus_100_j.sit](http://orihalcon.jp/mitakaplus/mitakaPlus_100_j.sit) | 2,180,461 bytes。OS X 10.3 以降向け Universal Binary と掲載。内部ファイルは未確認 |
| Plus 本体 C/C++ ソース | 公開入手先は未確認 | 公式日英ページ、公開リポジトリ・一般検索でソース版の配布を確認できず |

旧 Mac の Universal Binary という記載は、現行の Apple Silicon 対応を示すものではない。Windows 1.5.4 とも版が異なる。[英語ページ](http://orihalcon.jp/mitakaplus/index_e.html)は Windows 1.2.0 beta を掲載しており、日本語ページより古い。


## 補助的な公開ソース

| 入手先 | 版・条件 | 利用上の位置付け |
|---|---|---|
| [yuk7/mitaka](https://github.com/yuk7/mitaka) | 本家 1.3.1 のミラー。README と各ソースヘッダに MIT | root `LICENSE` の著作権者欄は… |
| [yoshikaz1228/Mitaka-macOS](https://github.com/yoshikaz1228/Mitaka-macOS) | 1.3.1 を基にした非公式の部分移植。[LICENSE](https://github.com/yoshikaz1228/Mitaka-macOS/blob/ab63d81723a9261b663c8ab1283de2e7607f1094/LICENSE) は元コードと移植部分を MIT と記載 | SwiftUI / SceneKit と C++ 軌道計算の試作参考。Plus のソースや、本家と同機能ではない |

[Mitaka++](http://www.magneticfield.jp/mitaka/) は加藤氏の別の派生版。独立版の 1.3.1（2009年）、本家 1.3.1（2016年）、Plus 1.5.4 は異なる配布物である。
