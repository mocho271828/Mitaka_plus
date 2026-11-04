# リポジトリ分割前のファイル分類

調査日: 2026-10-29.
この記録は読み取り専用の棚卸し結果であり, 分割後の配置を確定するものではない.
ファイル数と容量は通常ファイルの論理サイズを集計した.
symlink のリンク先は走査せず, ディスク使用量とは区別する.

## 既存アプリと Wine の境界

双方のアプリ本体は次の位置にある.

```text
mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/
mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/
```

| 対象 | 通常ファイル数 | 論理サイズ (bytes) | 扱い |
| --- | ---: | ---: | --- |
| Mitaka 本体 | 304 | 3,447,927,807 | ユーザー追加分を含めて原位置で保持 |
| Mitaka 本体の外側 | 7,437 | 1,432,065,771 | Wine, wrapper, 仮想 Windows 環境などを含む移植対象外領域 |
| Mitaka_plus 本体 | 839 | 177,524,992 | ユーザー追加分を含めて原位置で保持 |
| Mitaka_plus 本体の外側 | 7,474 | 1,562,070,460 | Wine, wrapper, 仮想 Windows 環境などを含む移植対象外領域 |

`prefix/` 全体を Wine と分類するとアプリ本体と天文データまで除外されるため, 境界には使えない.
本体内の DLL は Windows アプリの依存ライブラリであり, Wine 由来とは一括分類しない.
`spacecraft/` の `.obj` には 3D モデルがあるため, コンパイル生成物として一括除外しない.

## 天文データと画像

以下は各本体ディレクトリからの相対パスである.

| 分類 | Mitaka: ファイル数 / bytes | Mitaka_plus: ファイル数 / bytes |
| --- | ---: | ---: |
| `data/`: 暦表, 恒星, 地形など | 39 / 2,200,633,505 | 456 / 30,721,498 |
| `textures/`: 惑星表面など | 42 / 42,769,036 | 53 / 14,850,980 |
| `images/`: 表示画像など | 15 / 5,284,420 | 15 / 2,988,952 |
| `spacecraft/`: 探査機モデルなど | 101 / 130,204,223 | 26 / 9,913,577 |
| 本体直下: 実行ファイル, 設定, 文書, 追加ファイルなど | 11 / 1,067,095,202 | 54 / 60,783,960 |

Plus 側には上記以外にも `fonts/`, `etc/`, `scripts/`, `state/`, `ui/` などがある.
既存調査では Lua のソースが 17 ファイル確認されているが, Plus 独自部分の C/C++ ソースは確認されていない.
本体直下の画像, PowerPoint, キャプチャ, ショートカットや保存状態は, 配布物とユーザー追加分の由来を一律には判定できないため保持対象とする.

Mitaka 本体にある 50 MiB 以上のファイルは次の 8 個である.

| 相対パス | bytes |
| --- | ---: |
| `Gaia_MW_intensity_map.dat` | 990,492,687 |
| `data/Gaia_MW_intensity_map.dat` | 990,492,687 |
| `data/moon_topo.dat` | 761,562,016 |
| `data/mars_topo/mars_topo.dat` | 213,945,124 |
| `data/earth_topo/earth_topo.dat` | 81,822,538 |
| `data/mercury_topo.dat` | 59,713,216 |
| `H_alpha_intensity_map.dat` | 59,142,858 |
| `data/H_alpha_intensity_map.dat` | 59,142,858 |

本体直下と `data/` に同名の大型データが存在する.
参照関係とユーザーの意図を変更せず, 重複解消の対象にはしない.
Plus 本体に 50 MiB 以上のファイルはない.

## ソースとネイティブ実装

| 対象 | 通常ファイル数 | bytes | 内容 |
| --- | ---: | ---: | --- |
| `sources/official/mitaka_source_131.zip` | 1 | 905,545 | 公式 ZIP 原本 |
| `sources/official/mitaka_source/` | 310 | 2,148,092 | 公式 1.3.1 展開原本 |
| `sources/reference/Mitaka-macOS/` | 328 | 2,201,458 | `.git` を除く非公式 macOS 移植の参照用取得物 |
| `native/core/` | 31 | 182,334 | build と `.DS_Store` を除くソース, テスト, 文書 |
| `native/gui/` | 43 | 375,519 | build* と `.DS_Store` を除くソース, テスト, 文書 |

公式 ZIP の SHA-256 は `778c66bf6c81d2bf0bba380e9209882ecd961dd79cb9d2140758849d82314429` であり, 取得記録と一致する.
原本の CP932 / CRLF を維持し, 新しいソース管理先へ収容する場合も内容を変換しない.
ソースの許諾とデータ・画像・実行ファイルの許諾は別に扱う.
詳細は [既存の入手先・許諾調査](../../SOURCE_AVAILABILITY.md) と [原本・参照取得記録](../../sources/README.md) を参照する.

現在の GUI は `native/gui/Makefile` から `../core` をビルドする単一実装である.
実行時の `--data-root` とテスト時の `DATA_ROOT` により, Mitaka と Mitaka_plus の既存 `data/` を選択できる.
惑星テクスチャは選択した `data/` の隣の `textures/` から読み取り専用で参照する.
離着陸や連続飛行もこの共通実装に含まれ, Plus 独自 C/C++ ソースを取得して移植したものではない.

## 2 リポジトリへの収容案

`Mitaka` に共通の `native/core/` と `native/gui/`, 原本, 出典, テストをまとめると, 現在の相対パスを維持できる.
`Mitaka_plus` は Plus データでのビルド・実行入口と固有文書を持ち, 共通実装を `Mitaka` の commit 固定 submodule として参照する構成が考えられる.
この場合, 共通実装を複製せずに 2 リポジトリを作成できる.
Private submodule の取得には両リポジトリへの権限が必要であることを手順に記載する.

既存バンドル, ユーザーの天文データ, Windows 実行ファイル, Wine, ビルド生成物はローカルの保持領域に残す.
リポジトリにはデータ参照手順と保全記録を収容し, 実データは実行時に明示指定する.
非公式参照リポジトリは既存取得物を保持し, 新リポジトリには取得元 URL と固定 commit を記録する方法で足りる.

この棚卸しでは本体・データ・公式原本・参照用リポジトリの内容を変更していない.
