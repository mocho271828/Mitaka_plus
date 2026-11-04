# Plus 衛星モデルの登録順と相対位置

2026-10-29。対象はローカル Mitaka Plus 1.5.4 build101013 の `ssystem*.dat` と、各定義が参照する Orbit ファイルである。
実装は C++17 の標準ライブラリと既存 core の軌道計算を使う。元データは読み取り専用とし、別 bundle や公開データで補完しない。

## 根拠と範囲

入力保持の契約は [SATELLITE_CATALOG_PROVENANCE.md](SATELLITE_CATALOG_PROVENANCE.md)、位置式は [SATELLITE_POSITION_PROVENANCE.md](SATELLITE_POSITION_PROVENANCE.md) にある。
登録順・親参照・名前・更新順の根拠は [satellite-position-contracts.md](../../investigation/native-plus/unit4/satellite-position-contracts.md) の追加監査である。
静的監査による次の条件を採用した。公式 Mitaka 1.3.1 の異なるファイル形式を Plus へ当てはめてはいない。

- `Name:` の後の最初の空白区切り byte token が内部 ID になる。表示名の CP932 bytes は変換しない。
- 衛星の親は定義ブロック内の `Planet` である。Orbit 内の `Planet:` は親を上書きしない。
- Orbit の `fopen` 成功後、EOF に到達すると登録可用フラグが立つ。空ファイルや数値不正を、旧版の登録失敗と同一視しない。
- 衛星は親 Planet の追加より前に登録される。親の登録が失敗しても衛星は残り、旧 numeric parent index は次の Planet と衝突し得る。
- 名前検索は成功登録順の最初の一致で、大小文字を区別する。
- 新規ブロック読込中の `Mars` 検索は、まだ登録されていない構造親の index と一致しない。この経路では node の +43° 補正を適用しない。

原版の起動時にコンテナが空になる条件と、言語別の入力選択は未確認である。native で出典ごとの独立コンテナを構築する契約は、この未確認部分を証明したことにはしない。
また、原版 Orbit reader が受け付ける `omg` の意味は本モデルで未確定であり、loader は未知フィールドとして原文を保持する。`w` への暗黙変換は行わない。

## 登録コンテキスト

API は [satellite_model.hpp](include/mitaka/satellite_model.hpp) にある。
`SatelliteModel` は dataset を所有し、全出典・全定義・原 bytes を保持する。`records()` は全 Satellite ブロックを原順に持ち、同名、同じ Orbit への参照、言語別の行を統合しない。

`VerifiedSatelliteRegistration` は単一 source のコンテナ全体の成功順を指定する。source 内の定義 ordinal を Planet と Satellite ごとに列挙し、根拠と `origin` を持つ。
`verified_legacy_container` と `isolated_native_source` を区別し、構文 ordinal を成功 index へ暗黙変換しない。
重複した source、根拠なし、未知 origin、順序の逆転、不正 kind、未読 Orbit、既知の読取成功行の省略を検査し、失敗した証拠は部分採用しない。

`make_isolated_satellite_registration(dataset, source_key)` は、読み取り済み snapshot から native の独立空コンテナを構築する。
既知の `Ssystem → Sun → Planet → Satellite` 階層で、対象 source を構文読取でき、全 Planet / Satellite の Orbit を EOF まで読めた場合だけ結果を返す。
未読・曖昧な参照がある場合は、登録順を詰めて推定せず診断を返す。これは ENOENT に対しても保守的な扱いである。
上限超過や symlink 拒否などを、旧版でも読み込めなかった証拠にはしない。

`registration_contexts()` は検証に成功した source だけを返す。各 Planet の definition index・byte ID・成功登録 index と、Satellite の model record index を登録順で保持する。
`registrations()` の未検証入力とは用途を分ける。名前が欠落・重複フィールドで曖昧な場合は `*_identifiers_complete=false` とし、最初の名前一致を証明できない状態を残す。
同名の複数行は名前の欠落とは区別し、先頭を使う場合も後続を削除せず `shadowed_identifier` を付ける。

登録証拠で除外された親を持つ子も行を保持する。その子を次の成功 Planet へ付け替えず、`unregistered_parent` によって位置を未解決とする。
証拠がない場合、`registered` と `parent_registered` は `nullopt` であり、失敗を意味する `false` とは区別する。

## 相対位置評価

`evaluate(legacy_julian_date, parent_poles)` は `records()` と同数・同順の結果を返す。
位置が得られない行も、definition index と診断を保持する。原点のゼロベクトルを失敗の代わりに返さない。

- 通常衛星は同一数値 JD で回転と既存 Kepler 計算を行う。`a` は km、平均運動は `n − dw − dn` を一度だけ適用する。
- `L` / `I` / `E` は必要要素と構造親が解決すれば相対評価できる。`L` の極 RA / Decl の欠損を埋めない。
- `Q` は明示した同日・一意の親極を優先する。なければ検証済みの成功 Planet index に対応する原版係数を用いる。範囲外 index、重複極、時刻不一致は診断し、別の極へ代用しない。
- `C` は同一 source の検証済み成功順で最初の `Charon` に接続する。循環と範囲外は回転側で診断する。
- `Moon` は通常の Kepler 経路へ流さず、専用解析未接続として位置を返さない。別担当の絶対位置境界で、根拠付きの明示入力を扱う。

必須の数値は有限かつ一意でなければ使わない。Orbit 内の親 metadata と構造親の ID が異なる場合は、その差を診断しつつ構造親を使う。
相対モデルは絶対位置、Earth/Moon・Pluto/Charon の後補正、物理時系変換を実行しない。精度保証期間も定義しない。
原版の中間 float 丸めと native の double 計算が一致するとの主張や、原版との全実画面比較を完了したとの主張は含まない。

## 検証

独立した以下のビルドにより fixture とローカル Plus / 通常版を検証した。元データへの書込みはなく、fixture は一時ディレクトリに限定する。

```sh
clang++ -std=c++17 -Wall -Wextra -Wpedantic -Werror \
  -fsanitize=address,undefined -fno-omit-frame-pointer -I native/core/include \
  native/core/src/catalog.cpp native/core/src/satellite_catalog.cpp \
  native/core/src/satellite_catalog_parser.cpp native/core/src/astronomy.cpp \
  native/core/src/satellite_rotation.cpp native/core/src/satellite_position.cpp \
  native/core/src/satellite_model.cpp native/core/src/satellite_registration.cpp \
  native/core/tests/test_satellite_model.cpp -o /tmp/mitaka-test-satellite-model-sanitize
```

fixture は全行保持、CP932、Name token、失敗親の子、登録証拠の欠落・省略・逆順・重複、空/不正構文 Orbit の登録、Q の明示極と成功 index、先頭 Charon、同名行、C 循環、Moon、symlink、資源上限を検証する。
実データの試験は入力から行数を数え、既知の衛星数を採用上限や合否条件にしない。JD 2451545 とその前後36,525日において全行の同一性を確認し、位置が有限か、計算不可の診断が残ることを確認する。これは精度の保証ではない。

実測値は Plus の全340行保持、328行で相対位置を計算、Moon 2行と L 極欠損10行は未解決、同名 ID の後続4行である。
L 極欠損は `s2002_n1.dat`、`s2002_n2.dat`、`s2002_n3.dat`、`s2002_n4.dat`、`s2003_n1.dat` の各言語定義に対応する。通常版にはこの形式の衛星定義がなく0行となる。
Plus は2,158 checks、通常版は106 checks が PASS。AddressSanitizer / UndefinedBehaviorSanitizer の異常はない。
登録・親参照の独立読取レビューと、位置式 adapter の独立読取レビューはいずれも修正必須の指摘なし。絶対位置・GUI 接続の検証はこの単独試験に含まない。
