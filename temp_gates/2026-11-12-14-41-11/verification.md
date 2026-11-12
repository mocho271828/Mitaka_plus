# Gate: ビルド・検証・変更管理

## 目的

同梱コードとデータの渡し方を、再現可能なビルドと検証で確認する。

対象は PR #8 にローカル5件を統合した `ebca717`。試験ログは Git 管理外の `local/verification/pr8-integration/first/` に保存した。コンソールと描画品質の専用試験はルートの test が呼び、`lua-compatibility-test` と `terrain-real-data-test` は個別にも実行した。

## 判定条件

- [x] `make build` と `make test` が成功する。
  - `ebca717` の `first/results` で `build`、`test` はともに終了0。`first/test.log` のうちコンソール UI は29件、描画品質 controller は107件、コンソール helper の専用実行も成功した。
- [x] データや同梱コードを変更した場合、同梱データを指定した `make data-test` と `make reference-test` が成功する。公式比較には CF96・自転・月・大気・食を含める。
  - 同じ `ebca717` で `data-test` と `reference-test` はともに終了0。参照件数は CF96 5,427、自転33,129、月12,108、大気の単一散乱12,606・多重散乱792、食7,993、天の川22。GUI の別ターゲット `terrain-real-data-test` も同じデータで終了0。
- [x] `DATA_ROOT` は絶対パスの `data` ディレクトリとして受け取り、コアのデータテストにはその親ディレクトリを渡す。
  - ルート Makefile は `check-data` で DATA_ROOT の絶対パスを要求し、core の data-test だけ dirname で親へ変換する。今回の `run.zsh` と `first/data-test.log` でスナップショットの `resources/data` を指定して成功した。負例 `relative-data-root.log` は相対パスを拒否した。
- [x] `DATA_ROOT` の既定値は本リポジトリ内を指し、データ不足の場合は手順を示すエラーで停止する。
  - Makefile の既定値は `$(abspath resources/data)`。今回の `missing-data-root.log` では実在する `hip.dat`・`cf96.dat` が必要と表示され、`check-data` が失敗した。
- [x] クリーンなビルドは Lua ソースのダウンロードや他リポジトリを必要としない。
  - `native/gui/tools/build_lua.sh` は同梱 tar.gz を使い、`native/gui/Makefile` が liblua を静的リンクする。Lua 関連の追加ターゲットは既存 helper を前提にしている。
- [x] 作業完了時に `git status`、変更ファイル、差分量を確認し、300 行以上の変更では原則 commit する。
  - `git diff --name-status`、`--shortstat` と `--check 8335aba ebca717` を確認した。差分は49ファイル、追加2,396、削除64、空白違反0。統合コミットは `1f474db`、`35a7985`、`ebca717`。この判定の対象は `ebca717` のソースで、後続の検証記録自体の登録差分は主担当の完了報告に記す。
- [x] commit 前に `/simplifier-lai` skill の利用可否と依存関係を確認し、利用できない場合は報告する。
  - `rg --files --hidden` で skills と plugin cache を検索し、同名 `/simplifier-lai` は見つからなかった。追加依存はなく、コンソールは同梱 Lua と ScriptController、設定画面は AppKit と既存の画質モデルを利用する。
- [x] gate 検証用コピーに判定を記録し、実施したテストと未実施の確認を作業報告へ残す。
  - 同一ディレクトリに3原本を複写し、各条件の根拠と最終判定を記入した。ルート `VALIDATION.md` の2026-11-12付の統合記録には、今回の8項目の結果と未実施の旧 Plus・他機種の検証を記載した。
- [x] 追加衛星・描画品質・全画面・HTML を採用する場合、共通側の対応試験と採用 SHA を特定する。HTML helper の構成、実 OS 通知、実機・複数画面など未確認の範囲を成功扱いしない。
  - 描画品質の採用元は `a5c9ce4`。今回の `first/test.log` に107件成功、`first/smoke.log` に4つの画質設定とセッション復元の成功がある。手動の設定画面操作は `renderer-options-validation.md` の過去の確認。物理複数画面・実 OS の完全遮蔽通知・旧 Plus の画素一致は今回未検証。
- [x] 単位7の採用時は、JSON v7 の正常復元・不正 ID/出典不一致/上限超過による全体拒否、小天体・衛星の表示集合、PTH 探査機、全天図・地平図の星座集合・星座絵・天の川、恒星名選択・明るさ、雲・夜景・大気、食と影・風景・時間操作・原地点IDについて共通側の試験を特定し、ラッパーからの検証結果と区別して記録する。
  - 過去の単位7の検証は `vendor/mitaka/investigation/native-plus/unit7/README.md` にあり、ルート `VALIDATION.md` に採用時の結果がある。今回の統合で単位7を再採用する変更はない。
- [x] `VALIDATION.md` と gate の判定には実際の対象と実施結果だけを記録し、未検証の機能を検証済みと説明しない。
  - `first/commit` の SHA は `ebca7179ca3570d96b78e393a52fe88e503142f8`。`first/results` の全8項目が終了0。Lua 互換監査168件は原本12本をコンパイルのみで確認し、9本を受理、既知の拒否3本を確認した。旧 Plus 実機、Intel Mac、macOS 13、sanitizer は今回再実施していない。

## 不合格条件

- [ ] 失敗した検証を成功として報告する。
  - 旧ブランチの成功と今回未実施の検証を区別して記載した。
- [ ] 別リポジトリの内容を、同梱せずに本リポジトリに保存されたと扱う。
  - 実装と必須データの Git 追跡を確認し、別リポジトリを必須にしていない。

## 判定

YES
