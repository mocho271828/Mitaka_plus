# N16a SDSS/QSO の pc 座標モデル

記録日: 2026-10-30。対象は新規の純 C++ モデルと試験であり、GUI・カメラ・Lua・保存状態・既存 Makefile への接続は未実施である。
原典とローカルデータの監査は [n16-galaxy-catalog-contracts.md](n16-galaxy-catalog-contracts.md) を参照する。

## 実装した範囲

- `native/gui/include/sdss_spatial_model.hpp`: 出典と元行の所有、モデル内 ID、pc の座標型、診断、snapshot の契約。
- `native/gui/src/sdss_spatial_model.cpp`: 入力行の検証、赤道位置と native J2000 黄道位置の計算、取消対応。
- `native/gui/tests/test_sdss_spatial_model.cpp`: 合成境界、独立参照式、ローカル原本全行との照合。

入力は既存 `SdssRecord` の列である。`SdssSpatialSource` は種別、呼出し側が実際に読み取ったパス、元レコード列を値所有する。
出典順、出典内の原行順、同じパスの別出典、同一内容の重複行を保持する。モデルはパスの正規化、ファイルの再読込、重複統合をしない。
出典パスが空または種別が未知の場合はモデル全体を拒否する。各レコードの不正値は削除せず保持する。

`SdssSpatialRecordId {source_index, ordinal}` と平坦な行番号は相互変換できる。空の出典が前後や途中にあっても対応は変わらない。
ID は当該モデルの中だけで有効であり、同名パスの再読込後へ引き継ぐ契約はない。元ファイルの SHA-256 はこの検証記録に残すが、モデル自体にはハッシュや全 raw bytes を格納していない。
後続の保存・選択継承には別途、元 bytes の同一性を検証する境界が必要である。

モデルには変更用 setter を設けず、代入とモデル自体の move を禁止した。モデル全体の copy は独立した値として可能である。
snapshot は `shared_ptr<const SdssSpatialModel>` を保持し、結果も `shared_ptr<const SdssSpatialSnapshot>` として返す。

## 単位と座標系

`EquatorialPositionPc` と `NativeEclipticPositionPc` は別型で、各成分は `x_pc/y_pc/z_pc` の double である。
両型の間、または既存 AU 用途の `Vec3` への暗黙変換はない。元の RA/Dec、距離 pc、分類値はモデルから取得できる。

赤道方向は既存 core の `equatorial_direction`、黄道変換は `j2000_equatorial_to_ecliptic` を再利用する。
距離は読み込まれた float の pc 値を double にして方向へ乗じる。銀河の eClass と QSO の z は保存するが、位置・距離の再計算に使用しない。
新しい宇宙論、赤方偏移距離式、時刻依存補正、AU 変換は導入していない。

| 項目 | 原典の根拠 | 今回の契約と差 |
| --- | --- | --- |
| SDSS 入力と位置 | 公式 1.3.1 `Mitaka/mtk_galaxies.cpp:130–138,238–246` は RA/Dec/pc/分類値から `M_R2E*(distance*direction)` を生成する。ローカル P/R の全 16 byte レコードと一致する。 | 元の赤道 pc と native 黄道 pc を別々に生成する。 |
| 黄道傾斜 | 公式 `common/astro/astrometry.cpp:128–141` は `23.43870583` 度。 | 既存 native の `84381.448 / 3600` 度を使用する。原版と同じ画素・座標値だとは扱わない。独立試験で両傾斜の差を検出する。 |
| Plus 互換範囲 | 同梱 `doc/script_jp/galaxies.html` に SDSS/QSO の表示フラグがある。 | その Lua API や 3D 描画への接続は今回含まない。Plus 実行ファイルとの出力比較も未実施。 |

上表の公式ソースは `sources/official/mitaka_source/` 配下を指す。公式ソースは形式・数式の参照であり、利用者のローカルデータを置換していない。

## 無効行と取消

処理済みの各行は位置の有無と理由のビット集合を持つ。有限な RA は `[0,360)`、Dec は `[-90,90]`、距離は非負、分類値は有限であることを検証する。
複数列が不正ならすべての理由を残し、位置を生成しない。元の負数・NaN・Inf を正常値へ修正しない。
距離 0 は専用の理由を付けて原点の位置を生成する。別の列も不正なら位置はなく、距離 0 の理由は保持する。
非有限な分類値も既存 loader の検証契約に合わせて無効とする。有限な分類値の大小や符号は位置に影響しない。

snapshot の `rows` は取消時も含めて常に全原行数であり、完了した prefix の件数を `completed_count` に記録する。
`positioned_count + invalid_count == completed_count` で、`zero_distance_count` は処理済みの距離 0 の全行を数える。
取消は各行の前で確認し、残りは `not_evaluated` のまま保持する。`cancelled` の結果は完成 snapshot として採用してはいけない。
取消 callback の例外とメモリ確保の失敗は呼出し側へ伝播する。callback の例外を「正常な空結果」に置換しない。

既存 `load_sdss_catalog` は不正レコードを含むファイルを `CatalogError` で全体拒否する契約のままである。
今回のモデルは入力済みの行ごとの理由を保持できるが、不正なファイルから正常部分だけを読む parser は追加していない。
不正行の全理由は合成入力で確認し、ローカル実ファイルには無効行がなかった。

## 後続の接続契約

1. 選択したローカル原本から既存 loader で読み取り、実際の出典パス・種別・元の列を `SdssSpatialSource` として渡す。独自追加出典や同名出典を暗黙に統合しない。
2. `make_shared<const SdssSpatialModel>(std::move(sources))` で所有権をモデルへ渡す。約 93 万行の不要な copy を避けるため、呼出し側の一時列は move 可能な形で組み立てる。
3. `evaluate_sdss_spatial_snapshot(model, should_cancel)` をバックグラウンド計算に使用できる。呼出し側は generation とモデル identity を照合し、取消済みや古いモデルの結果を採用しない。
4. 後続の pc カメラ・投影層は、赤道か native 黄道かを明示して該当型を受け取る。現行 AU カメラへ無印の数値として渡さない。
5. 描画密度や空間索引の制限は、元の読み込み件数と分離する。無効・距離 0 の行を一覧から消す場合は別の明示的な UI 契約が必要である。

製品モデルのリンク依存は既存 core 天文変換と C++17 標準ライブラリだけである。AppKit や追加ライブラリは不要。
試験は原本読取のため既存 `catalog.cpp` / `extended_catalog.cpp` もリンクする。既存 Makefile の接続は親担当による次の統合作業に残す。

## 検証結果

最終ソースを `-Wall -Wextra -Wpedantic -Werror`、macOS deployment target 13.0 でビルドした。
通常 arm64、ASan+UBSan arm64、x86_64 を実行した。x86_64 は Apple Silicon 上の Rosetta 実行である。
各構成は合成試験 468 checks、Plus 原本・通常版原本それぞれ 18,624,636 checks に成功した。
各実ファイル組の 931,208 行すべてを保持し、距離 0 の 7 行も原点・理由付きで残った。

- 軸、北南極、RA 継ぎ目、float の最小非正規化正数と最大有限距離、±0、分類値への非依存を確認した。
- NaN/Inf、角度境界、負距離、複合理由、元値保持、空列・空出典・重複出典、範囲外 ID の拒否を確認した。
- 取消開始・出典境界・最終行直前・完了境界、未処理行、callback 例外後の再実行を確認した。
- production の座標関数を呼ばない long double の参照式で、全実行の赤道・黄道座標と距離を照合した。
- 元ファイルを別途 little-endian 16 byte 単位で全件読み取り、source/ordinal・RA/Dec・距離/分類値の bits・末尾一致を確認した。
- P/R の原本 SHA-256 は監査時の値から変わっていない。[原本ハッシュ](logs/n16-sdss/original-data-sha256.txt) に記録した。

原本 931,208 行では `SdssRecord` の列が 22,348,992 bytes、snapshot 行の列が 59,597,312 bytes となる。
元列と結果列の合計は 81,946,304 bytes であり、allocator・出典・プロセス等の別費用は含まない。
取消前にも全結果列を確保するため、取消が配列確保の費用をなくす設計ではない。索引や描画用追加配列の予算は後続実装で別に検証する。
`/usr/bin/time -l` による試験全体の時間・最大 RSS は各ログに残した。原本 I/O と独立 oracle を含む単発の実測であり、モデル単独の性能保証値ではない。

ログ・再現手順は [logs/n16-sdss/commands.sh](logs/n16-sdss/commands.sh)、実行環境は [environment.txt](logs/n16-sdss/environment.txt)、ログのハッシュは [SHA256SUMS](logs/n16-sdss/SHA256SUMS) を参照する。
`time_features` によるソースと試験の独立読取レビューは修正必須の指摘なし。レビュー担当による追加実行はない。

## 未実施と変更管理

AU/pc のカメラ・描画・索引、表示フラグ、Lua、選択、JSON、アプリへの model load 接続は未実装である。
OurGalaxy、球状星団、近傍銀河の parser/描画、Plus の画素一致は別の残件として維持する。
新規 3 ソースファイルと UNIT7 の文書・ログだけを追加し、既存 Makefile・製品 source・README・方針・gate は変更していない。
Git の確認は親担当の UNIT6 変更と区別した。差分は 300 行以上だが、commit は親担当が単位ごとに行う指示のため実施していない。
`/simplifier-lai` はこの担当作業では実行していない。通常の自己レビューと独立レビューを行い、新規依存の追加はない。
