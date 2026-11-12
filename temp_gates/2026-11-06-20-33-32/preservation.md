# Gate: データ保全と登録範囲

## 目的

既存の天文データと原本を保持し、コードの許諾とデータ・旧アプリの許諾を混同しない。

11 月 12 日に親 215d9a2 と PR #2 の実装先端 06f7043 を比較して根拠を追記した。以下の Git 差分はこの二点間を指す。11 月 6 日以前の照合結果には出典を示す。

## 判定条件

- [x] 動作に必要な Plus 版の天文データ・画像・関連ファイルは `resources/` にあり、他リポジトリや旧アプリのパスを必要としない。
  - 判定: YES。Makefile の DATA_ROOT の既定値はリポジトリ内の resources/data。PR の差分にパスの変更はなく、今回 make check-source check-data に成功した。
- [x] `resources/` 内の動作に必要なデータと画像は Git に登録され、clone に含まれる。
  - 判定: YES。git ls-tree -r 06f7043 -- resources で 575 ファイル。git lfs ls-files のうち Earth / Mars の地形 2 件は LFS 管理で、今回の clone ではポインターを確認した。ローカル LFS ストレージから両方を展開し、実体の SHA-256 とポインターの OID が一致した。GitHub からの新規ダウンロードは試していない。
- [x] 元データは削除・上書きせず、同梱したデータは原本と比較して内容の一致を確認している。
  - 判定: YES。親 215d9a2 と 06f7043 の resources ツリーは同じ 0d02b5c98181。Earth / Mars の SHA-256 照合は直前の 17-54-42 の保全記録に基づく。全資源の原本との再照合は行っていない。
- [x] 旧アプリ、Wine 環境、認証情報、ビルド生成物を Git に登録していない。
  - 判定: YES。git diff --diff-filter=A --name-only 215d9a2 06f7043 の追加は設計・gate 文書 5 件と補間ヘッダー 1 件。旧アプリ、Wine、資格情報ファイル、生成物の新規登録はない。
- [x] データを利用する処理は選択された `DATA_ROOT` を読み取り専用で参照し、変換・移動・更新しない。
  - 判定: YES。ルート Makefile の DATA_ROOT 引渡しと native/core は親と同一。GUI の差分はカメラの表示状態とスクリプト命令を扱い、データの書戻しを追加していない。
- [x] 公式原本と第三者の著作権・許諾表示を改変せず、データの許諾をコードから推定していない。
  - 判定: YES。vendor/mitaka/sources のツリーは親と同じ 7962f1818d8e。README と LICENSE・NOTICE 名のパスにも差分はなく、PR に利用条件の追加解釈はない。
- [x] リポジトリの公開範囲は変更していない。
  - 判定: YES。11 月 6 日当日の GitHub 設定はこの Git 差分だけでは追認できない。11 月 12 日の gh repo view は PUBLIC。所有者が公開に切り替えたとの申告を確認した。今回のレビュー対応では設定を変更していない。
- [x] 独自追加を含むローカルデータを優先し、公開版のデータや件数で置換・切り詰めをしていない。
  - 判定: YES。resources の全ツリーが親と同一で、独自カタログのデータ置換はない。小天体・衛星の core loader にも差分はない。
- [x] Lua は信頼済みローカルスクリプトの明示選択、または信頼したローカル HTML のユーザー操作によって実行し、ユーザー権限のファイル・OS 操作を許可することを説明している。通常のデータ読み込みからコードを自動実行しない。
  - 判定: YES。ScriptWorker.mm と AppScripting.mm の追加は setZoomTo / setZoomLogTo の引数処理・カメラ更新。HTML、スクリプトの選択経路、自動実行やファイルアクセス権限はこの差分の対象外。
- [x] 小天体・衛星の原文・順序・重複を保持し、表示集合を出典・原行または原ブロック番号で識別する。同名行を統合せず、集合の復元時は参照する出典の SHA-256・バイト数を照合する。
  - 判定: YES。native/core の小天体・衛星 loader、gui/src/session_layers.mm と session_layers_json.mm に差分はない。後二者で出典 SHA-256 と byte_count を扱う。この項目の根拠は出典照合処理の差分確認。
- [x] 追加衛星の親位置と登録を出典・JD ごとに結び付け、重心補正を二重適用しない。瞬間楕円を将来の運動の積分結果と扱わず、未確定の時系・精度期間を保証しない。
  - 判定: YES。native/core/src/satellite_absolute.cpp、satellite_registration.cpp と SATELLITE_ABSOLUTE_PROVENANCE.md は親と同じ。元期・親位置や重心補正の評価器を変更していない。
- [x] 小天体の軌道標本上限超過は原記録を削らず拒否する。JPL 彗星の TDB 軌道と 36 byte 小惑星・外縁天体の数値 JD による位置・軌道評価を区別し、後者の物理的時系と旧版の軌道標本規則を未確定として扱う。
  - 判定: YES。native/core/src/small_body_orbit_path.cpp、MINOR_PLANET_POSITION_PROVENANCE.md と gui/src/small_body_orbit_model.cpp は差分外。標本上限や物理時系の検証を本 PR で追加した項目には含めない。
- [x] 探査機の PTH 元標本を保持し、範囲外の外挿や無効標本を跨ぐ線の補完をしない。表示契約が未確定の PPI を PTH と同じ描画対応に含めない。
  - 判定: YES。native/core/src/spacecraft_position.cpp と SPACECRAFT_POSITION_PROVENANCE.md は親と同じ。PTH evaluator と PPI の境界は既存仕様を参照し、今回の対象となるズーム試験から軌跡の結果は推論しない。
- [x] 星座の略号と同略号の複数図形を保持し、全天図・地平図の CAB 星座絵への対応と、未対応の 3D 星座絵を区別する。
  - 判定: YES。gui/src/constellation_art_model.cpp、constellation_art_projection.cpp と core/src/constellation_art.cpp は親と同じ。CAB と 3D 星座絵の区別は機能対応表 CONST-02 を参照。
- [x] 観測地点の全出典、CAB の全点・index、emmap の原 bytes を共通 loader で保持し、公開データによる置換や元画像の再保存を行わない。
  - 判定: YES。core/src/place_catalog.cpp、constellation_art.cpp、gui/src/planet_textures.mm と resources/data/emmap.dat の差分は空。地点の各出典、CAB、emmap の内容を再変換する変更はない。
- [x] 地形・銀河は選択した版の原本を使い、欠損を別版から補わない。ただし、ユーザーが使用を承認した国立天文台の公式別配布による Earth・Mars 地形データは出典を明示して利用できる。旧 Plus のデータとの同一性が未確認であることを示し、月・水星へこの例外を拡張せず、第三者への再配布許可を推定しない。風景画像の失敗を別定義への再選択で隠さない。
  - 判定: YES。core/TERRAIN_PROVENANCE.md、resources の地形・銀河データ、gui/src/landscape_selection.cpp は親と同じ。Earth / Mars の採用範囲は出典記録に従う。月・水星や再配布許諾への追加判断はない。

## 不合格条件

- [ ] 既存データ・原本を削除・上書きする、または許諾が未確認のまま公開範囲を変更する。
  - 該当: NO。resources の Git ツリーを照合した。今回の PR 作業による GitHub 公開設定の変更はない。
- [ ] 旧 Mitaka_plus 全体を MIT ライセンスとして扱う。
  - 該当: NO。README の由来と許諾表示は親と同じで、データや旧アプリを MIT とする変更はない。

## 判定

YES

チェック済みは条件を満たす項目。不合格条件は未チェックで該当なし。未チェックの判定条件は未完了。旧 Plus 比較、最終画面値、実画面での中断操作は未確認。
