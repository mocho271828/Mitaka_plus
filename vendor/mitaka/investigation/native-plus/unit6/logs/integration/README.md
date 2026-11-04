# 単位 6 の統合ログ

主担当が実行したコマンドの出力を、そのまま保存した。`commands.sh` は再現用の整理であり、全呼出しの時刻順の transcript ではない。`SHA256SUMS` はこのディレクトリのファイルを照合する。

| ログ | 結果 |
| --- | --- |
| `core-{normal,san,x86}.log` | コアの全試験が各 exit 0。 |
| `root-{all-test,san-all-test,x86-all-test}.log` | GUI の全試験が各 exit 0。 |
| `root-controller.log`, `root-san-controller.log`, `final-controller-x86.log` | Lua を含むコントローラ試験が各 exit 0。 |
| `final2-app-plus-{normal,san,x86}.log` | Plus 原本を使う実アプリ試験が各 exit 0。Session v6 の不正入力10件、25レイヤー、3大気モード、明るさ・選択集合・再生・飛行を確認。 |
| `final2-app-regular-normal.log` | 通常版原本で実アプリ試験が exit 0。欠損カタログを Plus の件数で補わず、Session v6 の不正入力6件を確認。 |
| `gui-data-{plus,regular}.log`, `core-data-regular.log` | 実データ試験が各 exit 0。 |
| `core-data-plus.log` | 初回は CF96_DATA の指定漏れで参照比較が exit 2。直前の data、自転、月の試験は成功している。 |
| `core-cf96-plus.log` | 明示した CF96_DATA で参照比較が exit 0。 |
| `app-plus-normal.log` | 初回の full smoke は新メニュー項目追加前の期待値で失敗。期待値と実操作検証を更新した成功結果は final2。 |
| `clean-{core,gui}.log` | 単位5の新規 local clone に単位6の native 差分を適用し、既存のビルド生成物なしで all test が各 exit 0。 |
| `preservation.log` | 原本16,365 files、465 symlinks の追加・削除・変更なし。公式310ファイル一致。 |
| `private.log` | source / wrapper とも Private。 |

新規 clone の新規追加ファイルは `clean-files.txt`、実行先は `clean-path.txt` に記録した。UNIT7 の未接続 eclipse ファイルは含まない。最終ドキュメント更新はビルド結果を変えない。ASan/UBSan、Rosetta x86_64 の成功と、未実施の Intel / macOS 13 実機試験は区別する。
