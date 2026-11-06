# 個別小惑星・TNO 形式の根拠監査

確認日: 2026-11-07。初回監査基点は `84a6867884314f8eeeabe7b29b066e44c135e0d7`。
対象は同梱 `resources/data/orbits/asteroids/*.dat` の全 57 本である。
本書の実装参照行はこの基点に対するものとし、後続実装の検証結果とは区別する。
原本データは読み取り専用で調査し、内容・ファイル名・文字コードを変更していない。

## 結論と適用範囲

既存 native loader は個別 57 本を読み込み、原 bytes・全キー・名称・元番号と軌道要素候補を保持できる。
初回時点で未対応だったのは「個別ファイルを読むこと」ではなく、旧 Plus の個別 reader から evaluator までの契約、表示項目の適用、出典間の採用規則である。
初回の同梱資料だけでは位置評価の根拠が不足していた。その後、別 PC の原本静的解析で個別 reader と共通 evaluator の接続を確認し、a 指定の楕円に限定して native 位置・一周期軌道へ接続した。採用範囲と旧版との差は追加証拠節に記す。

36 byte の対応記録と数値が整合しても、個別ファイルをその記録へ置換したり、参照面・物理時系・優先順位を引き継いだりしない。
37 byte 形式の旧 Plus での使用・追加 byte の意味は [別の監査](minor-planet-37-byte-audit.md) の保留事項であり、本書で確定しない。
彗星 `orbits/comets/*.dat` の `Tp`、衛星、探査機は本書の対象外である。

## 全件の実測

| 項目 | 結果 |
| --- | --- |
| ファイル数 / 原 bytes 合計 | 57 / 12,891 bytes |
| `Type: Asteroid` / `Type: TNObject` | 42 / 15 ファイル |
| 異なる `No` | 50。すべて正数。番号は出典の一意識別子にしない |
| 通常版 / `_jp` 版 | 50 / 7 ファイル |
| 改行 / ファイル末尾 | 全 57 本で CRLF、末尾にも改行 |
| 名称 | 全 57 本に `Name` と `DisplayName`。CP932 として読める原 bytes を保持 |
| `DwarfPlanet` | `0` が 53 本、`1` が 4 本 |
| `Visible` | 6 本だけ存在し、すべて `1`。省略時の旧既定値は未確定 |

件数、ファイル名集合、値域、後述の SHA-256 はこの同梱データの監査記録である。
**runtime の固定件数条件、既知天体の許可リスト、値域の追加制限にはしない。**
形式が確認された追加記録も既存の容量・件数上限内で出典ごとに扱う。

### キーと既存の保持内容

全ファイルに次の 14 キーがある。`Visible` を持つ 6 本は 15 キーである。

| キー | 原値の形 / 実測 | 基点の native 処理 |
| --- | --- | --- |
| `Name`, `DisplayName` | 名称の bytes | 名称欄と `fields` に保持。表示時に CP932 を変換 |
| `No` | 整数 | int32 と原文字列を保持 |
| `Type` | `Asteroid` または `TNObject` | asteroid / trans_neptunian へ分類 |
| `Epoch` | 2451000.5–2454000.5 | 有限 double と原値を保持。物理時系を認定しない |
| `a` | 0.832036–485.999996 | 正の有限 double、長半径候補として保持 |
| `e` | 0.010391–0.890042 | 非負の有限 double、離心率候補として保持 |
| `M0` | 9.827832–357.600006 | 有限 double、平均近点角候補として保持 |
| `w` | 5.755145–355.970276 | 有限 double、近日点引数候補として保持 |
| `node` | 10.000000–324.410156 | 有限 double、昇交点角候補として保持 |
| `i` | 0.400000–68.023849 | 有限 double、軌道傾斜角候補として保持 |
| `Size` | 3 数値。各成分 300–1200 | 原文字列と `unknown_field` 診断。単位・半径/直径・描画適用は未確定 |
| `B_V` | 0.63–1.23 | 原文字列と `unknown_field` 診断。色変換を適用しない |
| `DwarfPlanet` | `0` または `1` | 原文字列と `unknown_field` 診断。ラベル分類へ適用しない |
| `Visible` | 省略または `1` | 存在する原文字列と `unknown_field` 診断。初期表示状態へ適用しない |

上表の軌道要素名は native の候補構造への対応である。
旧個別 reader による単位・参照面・元期解釈を証明したものではない。
`fields` は行の出現順に保持されるが、キー前後・値前後の空白は trim される。
空白・コメント・改行を含む厳密な原文は `SmallBodySource.bytes` と `raw_record_bytes` で保持する。
個別記録の ID は相対 `source_key` と ordinal `0`、source offset は `0` であり、番号や表示名で統合しない。

### 言語別・同番号の差

同じ `No` を持つ通常版 / 日本語版は Ceres、Eris、Itokawa、Juno、Pallas、Sedna、Vesta の 7 組。
6 組はフィールド値の差が `DisplayName` だけだが、Sedna はそれに加えて `B_V` が通常版 `1.23`、日本語版 `0.9` と異なる。
57 本を 50 行へまとめると、この数値差と出典が失われる。

`DwarfPlanet: 1` は `ceres.dat`、`ceres_jp.dat`、`eris.dat`、`eris_jp.dat`。
`Visible: 1` はこの 4 本に `sedna.dat`、`sedna_jp.dat` を加えた 6 本。
たとえば `2003el61.dat` と `2005fy9.dat` の `DwarfPlanet` はともに `0` である。
現代の名称・分類や 37 byte の flag から原値を修正しない。

### packed 出典との数値照合と派生値

Asteroid の各 `No` は `mp.dat` と `mp2.dat` の双方、TNObject の各 `No` は `TNO.dat` と `TNO2.dat` の双方に存在した。
各番号の対応候補を探すための照合であり、同番号を同一 source / ordinal に置き換える規則ではない。

36 byte 原記録を little-endian `int32 + binary64 + binary32 × 6` として読み、対応する個別ファイルの小数桁へ丸めると、
全 57 本で `Epoch, M0, w, node, i, e` が一致した。
36 byte の `n` から `a = pow(0.985607669 / n, 2/3)` を計算した値も、各 text の小数桁へ丸めると全 57 本の `a` に一致した。
これは値の対応を示す観測であり、旧個別ファイルの実行経路や同一の計算結果を証明しない。

基点の text parser は `n = 0.985607669 / a / sqrt(a)` を double で導出し、
`OrbitalElements{Epoch, a, e, M0, n, node, i, w}` を候補として保存する。
入力の丸められた `a` から導出するため、packed の binary32 `n` の拡張値と完全一致するわけではない。

| 例 | text の `a` | text から導出する `n` | 対応する 36 byte の `n` |
| --- | ---: | ---: | ---: |
| Ceres | 2.766180 | 0.21423154438883096 | 0.21423153579235077 |
| Sedna | 485.999996 | 0.00009199191835959911 | 0.00009199191845254973 |
| Ra-Shalom | 0.832036 | 1.2986463459404303 | 1.2986457347869873 |

この `n` は native 候補構造上では度/日として扱う値であり、旧個別 reader の導出精度を認定していない。
57 本では正かつ有限、範囲は約 `9.19919184e-5–1.29864635`。
入力 `a` が有限・正でも、任意の極小/極大入力からの派生値まで正・有限になるとは限らない。
その数値境界は実データの正常性とは別の実装・回帰試験事項である。

## 実装範囲と位置未対応の境界

以下の行番号は初回監査基点に対する参照である。

| 根拠 | 読み取れる契約 |
| --- | --- |
| [small_body_text.cpp](../../vendor/mitaka/native/core/src/small_body_text.cpp):79–96, 149–197 | 有限数 / int32 を読み、必須キー・重複キー・Type を検査。原文、全キー、候補軌道を保持。未解決の面・時系を診断する |
| [small_body_catalog.cpp](../../vendor/mitaka/native/core/src/small_body_catalog.cpp):12–52 | bytes を先に保持し、出典単位で成功/失敗を分離。失敗出典の部分記録を追加しない |
| [small_body_catalog.cpp](../../vendor/mitaka/native/core/src/small_body_catalog.cpp):55–91 | `.dat` をファイル名順で列挙。これは native の列挙順であり旧 Plus の上書き順ではない |
| [small_body_catalog.cpp](../../vendor/mitaka/native/core/src/small_body_catalog.cpp):95–125 | 汎用 evaluator は J2000 黄道面と TDB の確定を必要とし、未確定の個別記録に位置を返さない |
| [minor_planet_position.cpp](../../vendor/mitaka/native/core/src/minor_planet_position.cpp):60–75 | 専用 legacy-JD evaluator は `packed_36` に限定し、`element_text` と `packed_37` を拒否する |
| [small_body_model.mm](../../vendor/mitaka/native/gui/src/small_body_model.mm):13–34, 43–57, 120–123 | 名称の表示・検索は行う。個別 asteroid/TNO の評価 mode は unresolved のため位置 snapshot には採用しない |
| [test_small_body_catalog.cpp](../../vendor/mitaka/native/core/tests/test_small_body_catalog.cpp):43, 52–83, 115–141, 144–160 | 合成個別記録の原文・CP932・同番号保持、重複キー失敗、実データ全行の原 bytes 照合を既に試験する |

読取・検索の既存実装を再作成する必要はない。
候補 `OrbitalElements` が存在することを「評価契約が確定した」条件にしてはならない。
`time_scale=tdb` を便宜的に付ける変更や、同じ番号の packed 36 記録から位置を借りる変更も、この保留を解決しない。

## 証拠の出典と限界

- [既存ローカル軌道監査](../../vendor/mitaka/investigation/native-plus/local-orbits-audit.md):56–77 に、57 本・50 番号・キー集合・Sedna 差・優先順位未確定が記録されている。本書では同梱原 bytes を改めて照合した。
- [旧 Plus 位置契約監査](../../vendor/mitaka/investigation/native-plus/unit5/minor-planet-position-contracts.md):28–114 は packed 36 reader/evaluator の追跡である。同文書 155–172, 180–187 は公式別版との差と個別形式の保留を明示する。
- 同梱 [公式 Mitaka 1.3.1 mtk_minor_planets.cpp](../../vendor/mitaka/sources/official/mitaka_source/Mitaka/mtk_minor_planets.cpp):200–240 は `key_data` の数値列を読む別形式である。`No, Epoch, M0, w, node, i, e, n, type, dp_flg` の順と平均運動式は確認できるが、Plus の `Name:` / `a:` 形式を読む証拠ではない。float の保存精度や `dp_flg` の意味を転用しない。
- [現行 provenance](../../vendor/mitaka/native/core/SMALL_BODY_PROVENANCE.md) の「出典と識別子」「バイナリと個別要素の解釈」は、原値・候補値・未確定の表示仕様を分けている。
- この PC では過去の監査に記録された旧 Plus executable の原本パスを確認できず、旧 executable の新規静的解析・実行観測は本書の初回監査に含めていない。別 PC の静的監査で得られた根拠は次節へ追記する。

## 旧 reader / evaluator の追加証拠と採用範囲

2026-11-07、原本を保持する別 PC の[調整先セッション](codex://threads/01a1b078-eedd-7721-93cc-cbb56c26834a?hostId=remote-control%3Aenv_e_6a069ca0ce6083298f8a06c70a64b96e)が、`reverse-engineer-anything` による静的解析結果を共有した。この PC で原本 executable を再解析した証拠ではない。対象は Plus 1.5.4 build101013 の `mitakaPlus.exe`、SHA-256 は `48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457`。旧アプリは今回実行していない。

| 静的根拠 | 確認内容 |
| --- | --- |
| reader `0x503d10`、caller `0x503a90` | 起動時に packed を読み込んだ後、同じ管理 object で `orbits/asteroids/` を読む。番号が既存なら上書き、新規なら追加する |
| record `+0x40/+0x48/+0x50/+0x58/+0x60` | `Epoch/a/e/M0/n` を binary64 として保存する。記録配置は既存 evaluator `0x506220` と一致 |
| `0x414572–0x414583` | 各数値読取は一度 binary32 を経由する。`i/node/w` も同様 |
| `0x504c11–0x504c2d` | `n=0 && a≠0` なら `float(0.985607669 / (double(a) * sqrt(double(a))))` |
| `0x5043cd–0x5043fe` | `a=0 && n≠0` なら `a=(0.985607669/n)^(2/3)` を補完し、binary32 に丸める。両方非ゼロまたは両方ゼロでは補完しない |
| 回転と共通 evaluator | `Rz(node) Rx(i) Rz(w)`、角度の `π/180`、`(t-Epoch)*n+M0` に接続。時刻更新経路に時系変換や JD 原点調整は確認されない |
| 共通 getter | xyz に換算係数を掛ける。追加回転や親位置加算は確認されない。空間契約は既存 packed 36 の共通位置監査と合わせて日心 J2000 黄道 AU とする |

この経路が要求する空間契約と、個々の入力データが天文学的にその契約を満たすことの認証は異なる。物理 UTC/TT/TDB、精度期間、実機の位置・画素一致は未認定のままとする。

今回の native 契約は `mitaka-plus-1.5.4-element-text-legacy-jd-native-au-v1`。既存 loader が保持した `Type: Asteroid/TNObject`、正の有限な `a`、`0<=e<1`、その他有限要素を受理し、既存 `orbital_state` を再利用する。基点 `84a6867` の検証時は元期から `360/n` 日の等時間標本を用いた。`cab9b90` への統合後は離心近点角を等分し、標本時刻が区別できない場合は等時間に戻す。旧版の標本則と同一とは主張しない。

- native は既存の double 読取・`0.985607669 / a / sqrt(a)` を保持する。旧 reader の binary32 丸めを導入せず、旧数値結果との bit 一致を保証しない。元期も binary32 に丸めない。
- 今回は現57本が使う a 指定形式に限定する。明示 `n` があれば原値と未知項目診断を保持したまま位置を拒否する。旧版の補完条件は判明したが、n 指定・両指定形式の native 対応は未実装である。
- 極端な a から導出した n が非有限または非正になる場合は、a の行位置を持つ `invalid_source` で出典単位に拒否する。読み取った原 bytes は保持し、他ファイルは読み続ける。
- 同番号・同名・言語別を上書き統合しない。旧版の番号上書きとの差は、リポジトリの全出典保持方針に従う。表示集合は source + ordinal で指定できる。
- `Size/B_V/DwarfPlanet/Visible` の表示適用、37 byte、個別彗星の混在 Tp、非楕円は未対応のまま。37 byte は汎用評価器からも位置を返さない。
- 元 record の frame/time_scale/bytes は変更しない。成功結果だけで面の保留を解消し、物理時系・精度期間の診断は残す。

## 検証

原本57本の全件読取、CP932、キー・値域・言語差・No、packed値との丸め比較、byte数と SHA-256 を確認した。実装後は loader を通す合成入力、独立した円軌道・回転の期待値、離心率境界、派生値の overflow/underflow、原文保持、出典単位失敗、位置・一周期軌道、GUI model の表示集合・取消を検証する。実施結果と未実施事項は [検証記録](minor-planet-individual-validation.md) を参照。

## 原 bytes の一覧

相対パスの基点は `resources/data/orbits/asteroids/`。
A は原値 `Asteroid`、T は原値 `TNObject`。SHA-256 は改行を含むファイル全 bytes に対する値である。

| ファイル | No | Type | bytes | SHA-256 |
| --- | ---: | --- | ---: | --- |
| `1973na.dat` | 5496 | A | 228 | `64e973708cae409ce3027e9bf044a07d4ac90985c5d6f2f1693c1cb58684d47f` |
| `2003el61.dat` | 136108 | T | 240 | `c09b8aa8c7f8940a946df9c6764eab43de1de00af7f0d55e1f049787b76a24a0` |
| `2005fy9.dat` | 136472 | T | 232 | `318a6ee5384ef39206058693a9d3e3b18281af6a76e5241736e3a7a08b9d1a17` |
| `achilles.dat` | 588 | A | 231 | `bc7e701a95aa93618ea432a324b757ecbc8a654c39c98c5dacce722efbc10468` |
| `alinda.dat` | 887 | A | 223 | `84318256d5b38ba533e68261a10d392b449d8f3d08a39e8014591130de70eb5d` |
| `amor.dat` | 1221 | A | 219 | `eb2d3284de0e77a6610305886ce751280acbed263a139df20bfb0cf0f84e6a8c` |
| `apollo.dat` | 1862 | A | 224 | `aaf9700524d7556cf8594e54a79f3e2c8bca12f4193e61a88e186a3bea2ef5d8` |
| `aten.dat` | 2062 | A | 220 | `6b2610f0fe0680cb3797b3aaf918866f63d2671116f7304f8302c25b98bd2359` |
| `ceres.dat` | 1 | A | 230 | `a339ceb68b930d6ec06a71cbe08187daf1787618c2ac70ad3a8511033631fba7` |
| `ceres_jp.dat` | 1 | A | 231 | `09a2261398748c82f59766599c47075e8cced65249793aa65256f145c886ce20` |
| `chaos.dat` | 19521 | T | 223 | `0b5ede72cf48884db91d707e655db9ee9224fd6c725f1dfeaf1f6f0f042e2dfa` |
| `chiron.dat` | 2060 | A | 225 | `734e7efbb22d639e89081dcd816025a0b28e8b0e2073ba1365c3ba1599d99c18` |
| `cincinnati.dat` | 1373 | A | 237 | `99aea4ed5e240cbf4146ddbb057bc9dfc508fb98bdf001d725a2aa044ac017f1` |
| `deucalion.dat` | 53311 | T | 235 | `e80a63992764f3176af6ea03f6bd4f583f7cff3615c2888bf6a81225405ae4b1` |
| `eos.dat` | 221 | A | 216 | `9e36ffb73c7010525dc9e384fb69c8923467871c9dae6457767021e38ca822e2` |
| `eris.dat` | 136199 | T | 237 | `cbab3091a5bbeddb96c0746757c440789fb3c6a868f326625440335b39d730b8` |
| `eris_jp.dat` | 136199 | T | 239 | `716fbfa708998cff50241957e7d007b1c6f7db5039aa4959b4d1cc6f6e801f6b` |
| `eros.dat` | 433 | A | 219 | `fedd4887767ce68cbc0637271feb862ec8b4805395e9b86f74ee3d469cda249c` |
| `eureka.dat` | 5261 | A | 224 | `9fa3568cfb0576f1704314cdd6ddd539efe21a374d2ccc2f7f5052b32a2e5361` |
| `flora.dat` | 8 | A | 218 | `1cd04f12b9125a9a784037216818dd2aea7b7842b1d6788f3b5382fdec6064f4` |
| `hidalgo.dat` | 944 | A | 226 | `b30735f6406d4eb5d7b9625c74c2d2f0d74955801055ebe182079465c7ab6fc2` |
| `hilda.dat` | 153 | A | 220 | `165127a9ecdc65f8a4df4021545cdb070ecd9fd698775061667a6fda04f58b3a` |
| `hungaria.dat` | 434 | A | 231 | `622d7a591287e019e67b29668129c873369e0502252a645a2ad170b29c7f9da4` |
| `huya.dat` | 38628 | T | 221 | `f74fcf2a0ac821f4dd8aa092f50aac4cce20eecd132efeaaad8e17234a607958` |
| `hygiea.dat` | 10 | A | 223 | `14eea120642c873857c156234612d627fa7518856e3eb0ef82fc3dfea291ce9f` |
| `icarus.dat` | 1566 | A | 224 | `221e164b0f5cc0bbaafc7d7b95f895f7ae64ce2dbcda6cc571b0b5471e1816c6` |
| `ida.dat` | 243 | A | 215 | `1d9863b724f7e47c613e44ac036f5f0b6721530ec1183cbd1977251a13ea4563` |
| `itokawa.dat` | 25143 | A | 228 | `325d36fdbf1bd738ac08ebee2bc149dac4c5ef47d7c8ea7e46b717f0a29cb3db` |
| `itokawa_jp.dat` | 25143 | A | 229 | `7ce67ff066f72cd386f230a2f030c529cd3cd5eab0bea22284bd6a1f761dd4b4` |
| `ixion.dat` | 28978 | T | 224 | `95eaffb647175e1483e94a2e45acc4dcd87bce5e6c0ce737930387d8f37bc367` |
| `juno.dat` | 3 | A | 217 | `e3b3d53559260a7375cd2bd52ba055a23cd5a867d60a4468bdcb424a67e0361d` |
| `juno_jp.dat` | 3 | A | 221 | `768f945acc4fee3c2c088deaa312af0a0abba12a90e9e2df20111d6ccccbcc99` |
| `koronis.dat` | 158 | A | 227 | `8129e7ff4c7208d50c79ceff36838ab3acc4f6c63dd025c607754ce96ef92a2b` |
| `logos.dat` | 58534 | T | 223 | `7957a1c9e0cfeadf94eb16b507109b5da3fa2e44a96410a1dbaab26f13f2e093` |
| `maria.dat` | 170 | A | 222 | `60cf1d76605ec2fa7e9e034a60c4e68da5b117c823a4eafae3ecb9314e1f1a98` |
| `metis.dat` | 9 | A | 215 | `b3ba8d218c3b8ce6e70c0d90cc19b101070e40291a8f326dc8a339dc4e89cbcd` |
| `mitaka.dat` | 1088 | A | 224 | `93382df5e6db72d7e7f22304531e64f8b07bde4f4540d2d48ae64843c19ceff0` |
| `nealley.dat` | 903 | A | 228 | `42dce7a551f95c09965b93793d17acae9b59a504fd03b028ccf9ce0fabb15dea` |
| `nessus.dat` | 7066 | A | 225 | `9f4d2458a24feb8ff2a2bd35925e85d5b33911fa2e2988c1423aa551ccfa54cf` |
| `orcus.dat` | 90482 | T | 224 | `aa05eca8585029a593ffba7324fee9b88145a38e8f4632bf7bbda972ce7db0fa` |
| `ottilia.dat` | 401 | A | 226 | `6df0f430a2ee3b4da4cae1554d2204dbb944285a48e1f912610c6691d52baefa` |
| `pallas.dat` | 2 | A | 223 | `ad2115f6afe080188b22018285ec871e40e5d54e477b5e94c490a37dd8457522` |
| `pallas_jp.dat` | 2 | A | 223 | `1e63254fdc46a0aa3cf80a2780f3ad484c31b27612bed134e330cf18436a5003` |
| `patroclus.dat` | 617 | A | 233 | `d0f6332d116ff0b68cd5a8bdc25e08105ae4747617b3b8456af5b3d9e0f3b43d` |
| `phaethon.dat` | 3200 | A | 232 | `51690a17c1fb605828f750ffcb5b885e92d6fe1b289db48dfeb812265cb54a4a` |
| `phocaea.dat` | 25 | A | 226 | `9a95bc70342eadd4abced66acd741fc35117888207f5e5083fb5e83dc3db63a3` |
| `pholus.dat` | 5145 | A | 226 | `d7471a92ccb9296fd3ca7dd5ba9569bda6b50ce92a09f45cdf78ae8a5393aa90` |
| `quaoar.dat` | 50000 | T | 227 | `5c93005dcb8f6997b650a3fc1d6e6a5049b6811250a69098312ceda5dd6b922b` |
| `ra-shalom.dat` | 2100 | A | 235 | `bd7077ac297c54d5eaaf032f6972ea2375856fbcd1d00dc3a91a8688996845ed` |
| `rhadamanthus.dat` | 38083 | T | 243 | `f7f4203dfadcc4a85952109c934e226804a23e053c3a9994c9ea4b7ba51d038a` |
| `sedna.dat` | 90377 | T | 238 | `dc79893e2925b7682d18b703537efe6fb07657eb5469e6f1cb5a6a2d3f63e812` |
| `sedna_jp.dat` | 90377 | T | 238 | `100374b9d76ee4f22b8e3f8c3c5f522b808ee4384b3cf6f9a824562f8ec604c9` |
| `themis.dat` | 24 | A | 221 | `13fbfa2a2d87ed8f3f0804b420c639c5543818e8b1daad494d950cc79649d059` |
| `thule.dat` | 279 | A | 217 | `ca43ac8bd7838dfd1c2078febb6df9f586972c08d007576be470d3cbd19b4d4b` |
| `varuna.dat` | 20000 | T | 226 | `f04e3f3755c55bf68c0321f1f7116b05a090a2ccb80c282fb57b805d69402e07` |
| `vesta.dat` | 4 | A | 219 | `6f921ddec6d1e64a906a4e2b9f56721242c3d948d99ed60b809c6ae3b33c8812` |
| `vesta_jp.dat` | 4 | A | 220 | `78ad38c93be25f41ee5c77b09ece1272e8cd8d49e2689841304f39f85e657488` |
