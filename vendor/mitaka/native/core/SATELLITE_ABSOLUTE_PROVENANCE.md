# Plus 衛星の絶対位置と親天体表示

2026-10-29。対象はローカル Mitaka Plus 1.5.4 build101013 の衛星定義と、同じ入力から読み込んだ CF96 暦表である。原データは読み取り専用で保持する。

## 根拠と適用範囲

原版の命令列、定数、更新順は [satellite-position-contracts.md](../../investigation/native-plus/unit4/satellite-position-contracts.md) に記録されている。対象 PE の SHA-256 は `48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457`。これは限定した手動静的監査であり、旧アプリを実行して座標を比較した結果ではない。

相対位置と登録順の契約は [SATELLITE_MODEL_PROVENANCE.md](SATELLITE_MODEL_PROVENANCE.md)、回転式は [SATELLITE_ROTATION_PROVENANCE.md](SATELLITE_ROTATION_PROVENANCE.md) にある。絶対位置は既存 `Cf96Ephemeris`、`SatelliteModel`、J2000 座標変換を再利用する。独自の暦表補間や月理論、行列ライブラリは追加していない。

旧 Plus の CF96 分岐は数値 JD `2415020.5 … 2487980.5`（両端を含む）にあり、本実装はさらに読み込んだ CF96 の実際の有効範囲に従う。既存の `Cf96Ephemeris::time_range()` も同じ期間との共通部分に制限済みである。絶対位置側の明示 gate は、旧版の未接続の別暦表分岐と、CF96 ファイル自体の収録欠落を別の診断にする。CF96 の期間を衛星要素の精度保証期間とは扱わない。

## 入力と所有権

API は [satellite_absolute.hpp](include/mitaka/satellite_absolute.hpp) にある。`evaluate_satellite_absolute` は model と ephemeris を呼出中だけ借用し、結果は出典、根拠、相対評価、診断を値として所有する。

- 呼出側は単一 `source_key` と、成功 Planet 登録 index が CF96 index に対応する根拠を明示する。空の根拠、未知出典、未検証の登録列では位置を返さない。
- `registration` は検証済みモデルから `origin` と根拠をコピーする。`isolated_native_source` は native が出典ごとに作る独立コンテナであり、旧 Plus 起動時のコンテナ状態を再現した証拠ではない。
- `positions` と保存する相対評価は `model.records()` と同数・同順。他出典、重複名、未解決行も削除しない。index は同じモデル snapshot 内だけで有効であり、再読込後の同一性を index だけで判断しない。
- `planets` は選択出典の成功登録順を保ち、補正前位置と最終位置を分ける。definition index と登録 index を現代の天体 enum と混同しない。

時刻は全層で同じ `legacy numeric JD` を受け渡す。UTC / UT1 / TT / TDB の物理的な時系は確定していないため変換しない。成功時も時系と精度期間が未確定である診断を保持する。

## 位置と補正の順序

補正前の親位置 `B` は、成功 Planet 登録 index を使う同日 raw CF96 の日心 J2000 赤道 AU から、既存 `j2000_equatorial_to_ecliptic` で一度だけ変換する。角度は `−23.43929111111111°` の X 軸回転である。この経路に太陽位置の追加はない。地月補正済みの `SkyModel::solar_bodies` を raw 親の代わりには使わない。

通常衛星は、すでに J2000 黄道方向へ回転された相対 km を `149597870.7 km/AU` で割り、raw 親に加える。L / I / E / C / Q の回転後に、さらに赤道から黄道への回転を重ねない。

```text
satellite_pre = B + relative_km / 149597870.7
delta = (B − satellite_pre) × mu
parent_final = B + delta
satellite_final = satellite_pre + delta
```

全衛星の加算が終わってから、成功登録順の最初の完全 byte 一致 `Earth` / `Moon` と `Pluto` / `Charon` にだけ補正を一度適用する。`mu` はそれぞれ `0.012150584133256915` と `0.07407407407407407`（2/27）。同名の後続衛星、Nix、Hydra は raw 親からの位置を保つ。補正後 Pluto をそれらの親として再加算しない。

対の片側が未解決なら両側の最終位置を公開せず診断する。登録名が不完全で先頭の名前検索を証明できない場合も、対象の最終位置を抑止する。raw 親、他の独立した衛星、全原行は保持する。ゼロベクトルや別出典の値で失敗を埋めない。

## 月の明示入力

`Moon` は通常 Kepler 経路へ流さず、同日の地心 J2000 黄道 km と根拠を `SatelliteAbsoluteMoonInput` で明示する。構造親にかかわらず同一出典の最初の `Earth` を使う原版の名前経路に従う。時刻不一致、非有限値、根拠なし、未解決 Earth は診断とする。

GUI の snapshot 作成側は既存の公式 Mitaka 1.3.1 由来 `lunar_position` をその有効範囲内だけ利用し、赤道 AU から黄道 km へ変換、倍率 1 として根拠を記録する。この入力は native の明示的な月モデルであり、未追跡の旧 Plus 月解析関数や可変設定倍率との同一性を主張しない。

## GUI への反映

[satellite_scene.hpp](../gui/include/satellite_scene.hpp) の `apply_satellite_parent_positions` は `SatelliteSnapshot` の最終位置を既存 `SolarBodies` へ反映する。入力 bodies と snapshot を同じ JD に揃える責任は呼出側にある。

出典指定時はその出典だけ、未指定時は最初の検証済み evaluation を使う。モデルの登録根拠と、Mercury から Pluto までの 9 個の ID / 登録 index / definition index 対応、時刻、行数を照合する。検証を通らない出典を天体名だけで採用しない。

補正後の黄道 AU を赤道 AU へ一度変換して、配列添字ではなく `Body` ID で置換する。月も同一出典で最初の Moon と同じ最終位置に置く。太陽と自転姿勢は維持する。位置の欠損、非有限値、変換の桁あふれでは入力値を維持し、選択出典の欠損を別出典や後続 Moon で補わない。絶対位置の置換なので、繰り返しても補正や回転は累積しない。

## 精度と未実施事項

native は既存 GUI と同じ AU 定数と double 計算を使い、旧版の中間 binary32 km/AU/旧 pc 丸めを再現しない。三角関数、月モデル、丸めを含む bit 一致、天文学的な誤差、旧版の全表示モードとの一致は検証していない。未確定の時系・精度期間・登録開始状態を、描画成功によって確定した扱いにはしない。

## 検証

`test_satellite_absolute` は独立した定数 CF96 fixture と既知の X 軸回転を使い、親加算、Earth/Moon・Pluto/Charon の符号と一度だけの補正、Nix/Hydra、先頭一致、別言語出典、欠損と不正 Moon、片側だけ未解決の対、名前欠損、CF96 端点と期間外、NaN、根拠の欠落を確認する。

通常・AddressSanitizer / UndefinedBehaviorSanitizer・x86_64 の各構成でローカル Plus を含む **1,750 checks PASS**。通常版は **304 checks PASS**。実測は全340行保持、出典ごとの位置165行である。行数を公開件数へ切り詰める処理や、実測件数を合否の固定条件にする処理はない。

旧 CF96 分岐の両端と、それぞれの `std::nextafter` による直前・直後を試験する。収録範囲が旧分岐より広い fixture でも、範囲外は全行と根拠を保持して位置を返さず、専用診断を出す。初回試験では「広い fixture なら CF96 自体も旧分岐の外側を評価する」という試験側の仮定で失敗した。既存の `time_range()` 契約を確認し、その拒否も検証するよう試験を修正した。実データの J2000 評価件数と位置の回帰は維持されている。

`test_satellite_scene` は出典選択、9 ID の対応、配列順の独立性、月の先頭一致、欠損の保持、時刻・登録根拠の不一致、非有限値と変換 overflow、再適用時の不変性を確認する。上記の3構成すべてで Plus **770 checks PASS**、通常版 **713 checks PASS**。

絶対位置の独立レビューでは補正不能時の最終位置抑止と登録根拠の所有コピーを追加し、再レビューで修正必須の指摘はなかった。GUI の追加 overflow 回帰では既存座標変換の `out_of_range` が伝播したため、その限定例外で入力を維持するよう修正した。元ファイルへの書込みはなく、試験 fixture は一時ディレクトリだけに作成する。

実行ログは `/tmp/mitaka-unit4-satellite-absolute-final-{normal,sanitize,x86}*.log` と、GUI の `/tmp/mitaka-unit4-satellite-parent-{normal,sanitize,x86}*.log`。継続保存する証跡の収録とリポジトリ全体の policy gate 判定は親の統合作業で行う。
