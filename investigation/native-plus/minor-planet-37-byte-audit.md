# 小惑星・外縁天体 37 byte 形式の追加監査

追試（2026-11-12）：[ネイティブ版と旧 Plus 1.5.4 の実データと実画面](orbit-window-validation.md)。以下は元の監査時点の記録。

調査日: 2026-11-05。対象はローカルの旧 Windows Plus 環境。これは静的解析とデータの比較であり、実行時の読み込みや画面表示の検証ではない。元の実行ファイル、データ、Wine prefix は変更していない。

## 結論

- `mitakaPlus.exe` では 36 byte の `mp.dat` / `TNO.dat` の読み込みが確認済みで、37 byte の `mp2.dat` / `TNO2.dat` の読み込みは未確認。実行ファイル中に両ファイル名の ASCII と UTF-16LE 完全一致はないが、この事実だけで動的生成された名前や別経路での利用を否定できない。
- 同じ環境には別製品の Mitaka++ 1.3.1 の実行ファイル `mitaka_pp.exe` と `mitaka_pp_VC.exe` がある。両者に 37 byte ファイル名が UTF-16LE で存在する。後者の静的追跡では、名前を用いてファイルを開き、成功時に 37 byte 単位に相当する読み込み関数を呼ぶ経路が確認できる。これは旧 Plus 本体がその経路を実行する証拠ではない。
- Mitaka++ の 37 byte レコードの offset 4 は読み込み後に符号拡張され、値 1 または 2 のとき `COLOR_LABEL_DWARF_PLANET`、それ以外のとき `COLOR_LABEL_SMALL_BODY` のキーが選択される。ラベル色の分類に使われることは分かるが、1 と 2 の区別や他の用途、Plus における意味は確定しない。
- この結果は 37 byte を Plus の軌道に接続する根拠にはならない。既存 36 byte の読込経路と 37 byte の出典・未解明の契約を区別する。

## 対象と識別

`P` は Windows 版 Mitaka Plus の実行ファイルと `data/` が並ぶディレクトリとする。原本は読み取り専用で調査した。

| ファイル | SHA-256 |
|---|---|
| `P/mitakaPlus.exe` | `48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457` |
| `P/mitaka_pp.exe` | `fe0c5e59b79973a5834e2b81f09ec18836cdadd4215b6794b63bde04cb33cf63` |
| `P/mitaka_pp_VC.exe` | `ed14d88b503118573a643eea054c0708306fe7eb98e39bfb5c6173502790f718` |
| `P/data/mp2.dat` | `988377799653ad09a0d6030a248b88e8a4ddd25276ea2065bb2f25bb8ed684c6` |
| `P/data/TNO2.dat` | `85c05722ec0a907f07226a3611dae8dc9ceefafc41eb3b3b982f32393694ed35` |

`P/mitaka_pp_readme_J.txt` は CP932。2 行に Mitaka++ 1.3.1、9–19 行に Mitaka からの派生、86–96 行に両 `pp` 実行ファイルでの起動が記載されている。README の配置や共通データの存在は、Plus 本体が Mitaka++ の処理を呼ぶ証明にはならない。

## 既存監査の訂正

[orbit-contracts-audit.md](../../vendor/mitaka/investigation/native-plus/orbit-contracts-audit.md) 307 行の「5 個のローカル実行ファイルに対する完全一致文字列検索では `mp2.dat / TNO2.dat` は得られなかった」は、文字コードを限定しない記述としては誤り。下の全バイト検索で `mitaka_pp.exe` と `mitaka_pp_VC.exe` に UTF-16LE の両名前が見つかる。過去の検索で何が漏れたかまでは未確認。[minor-planet-position-contracts.md](../../vendor/mitaka/investigation/native-plus/unit5/minor-planet-position-contracts.md) 121 行の対象 `mitakaPlus.exe` についての **ASCII** 不在の記述とは矛盾しない。

| 実行ファイル | `mp2.dat` UTF-16LE ファイル offset | `TNO2.dat` UTF-16LE ファイル offset |
|---|---:|---:|
| `mitakaPlus.exe` | なし | なし |
| `mitaka_pp.exe` | `0x2128c0` | `0x2128e8` |
| `mitaka_pp_VC.exe` | `0x145aa4` | `0x145ab4` |

この 3 ファイルでは両名前の ASCII 完全一致は見つからない。ここでいう offset はファイル先頭からの位置であり、以下の実行時仮想アドレスとは異なる。

## 静的追跡

- `mitaka_pp_VC.exe` の `0x412b3a–0x412bd9` は、`0x545aa4` と `0x545ab4` 付近にある UTF-16LE 名を配列へコピーする。`0x412c30–0x412c9f` は 2 件を処理するループで、各ファイルの open が成功したとき `0x44ef60` を呼ぶ。open の失敗時には異なる経路へ分岐するため、常に両方が読まれるとは限らない。
- `0x44ef60–0x44f015` の読み取り呼び出しは 4、1、8、4、4、4、4、4、4 byte の順で、計 37 byte。`0x44f24d–0x44f262` で次の 4 byte を読み、レコードを繰り返す。この記録は正常なレコードの読み取り経路を対象とし、破損・途中切れに対する安全な振る舞いを保証しない。
- `0x44f02a` は追加 1 byte を符号拡張し、`0x44f05f` が保持する。`0x44f179–0x44f1a5` はその値を 1 と 2 に比較し、どちらかなら文字列 `COLOR_LABEL_DWARF_PLANET` のアドレス `0x548d20`、それ以外なら `COLOR_LABEL_SMALL_BODY` のアドレス `0x548d3c` を選択する。色キー名と分岐は確認できるが、この分岐だけから値の全意味や画面描画結果は確定できない。
- 旧 Plus 本体側の `mp.dat` / `TNO.dat` と 36 byte リーダーの静的追跡は [minor-planet-position-contracts.md](../../vendor/mitaka/investigation/native-plus/unit5/minor-planet-position-contracts.md) 28–52 行を参照。

## データ比較と未解明点

[local-orbits-audit.md](../../vendor/mitaka/investigation/native-plus/local-orbits-audit.md) 24–54 行および [minor-planet-position-contracts.md](../../vendor/mitaka/investigation/native-plus/unit5/minor-planet-position-contracts.md) 117–153 行を参照。`mp2.dat` の全 7,317 件は offset 4 を除くと対応する `mp.dat` と順序を含め一致する。`TNO2.dat` の 1,193 件中、同じ操作で `TNO.dat` の 1,134 件に一致し、59 件は対応しない。データの類似は対象バージョンの採用、優先順位、座標計算の互換性の証明ではない。

原本の追加 byte の非ゼロ値は `mp2.dat` の番号 1 で 1、`TNO2.dat` の番号 136199、136472、136108 で 2。同梱 `P/data/orbits/asteroids/2005fy9.dat:5–7` と `2003el61.dat:5–7` では番号 136472、136108 に `DwarfPlanet: 0` が記載されている。データの時点・由来は未確認であり、別ファイルのフィールドと同一視したり、食い違いから直ちに全く別の概念と断定したりしない。

公式の別バージョン Mitaka 1.3.1 の [mtk_minor_planets.cpp](../../vendor/mitaka/sources/official/mitaka_source/Mitaka/mtk_minor_planets.cpp) 200–240 行はテキストデータの `dp_flg` を扱う。これは 37 byte のバイナリ仕様や Plus の利用を証明しない。

未確認なのは、Plus 本体が 37 byte を実際に読む経路の有無、1 と 2 の違いと色以外の用途、異なるカタログの選択・重複時の扱い、ファイルの時間尺度や天体分類の完全な契約、欠落・破損時の旧版動作である。

## 再現手順

`P` に手元の旧 Plus の場所を指定して実行する。`objdump` のアドレスは上表の `mitaka_pp_VC.exe` の SHA-256 にのみ対応する。ファイル名に空白があるため変数は必ず引用する。

```sh
export P='/path/to/Mitaka Plus'
shasum -a 256 "$P/mitakaPlus.exe" "$P/mitaka_pp.exe" "$P/mitaka_pp_VC.exe" "$P/data/mp2.dat" "$P/data/TNO2.dat"
/usr/bin/objdump -d --start-address=0x412b3a --stop-address=0x412ca5 "$P/mitaka_pp_VC.exe"
/usr/bin/objdump -d --start-address=0x44ef60 --stop-address=0x44f270 "$P/mitaka_pp_VC.exe"
```

以下の Python は完全一致のバイト位置と非ゼロ値を表示する。符号付き byte を用いるのは上記 `movsbl` と合わせるためである。

```sh
python3 - <<'PY'
from os import environ
from pathlib import Path
from struct import iter_unpack

p = Path(environ['P'])
for name in ('mitakaPlus.exe', 'mitaka_pp.exe', 'mitaka_pp_VC.exe'):
    content = (p / name).read_bytes()
    for filename in ('mp2.dat', 'TNO2.dat'):
        for encoding in ('ascii', 'utf-16le'):
            offset = content.find(filename.encode(encoding))
            print(name, filename, encoding, hex(offset) if offset >= 0 else 'not found')
content = (p / 'mitaka_pp_VC.exe').read_bytes()
for key in (b'COLOR_LABEL_DWARF_PLANET', b'COLOR_LABEL_SMALL_BODY'):
    offset = content.find(key)
    print(key.decode('ascii'), hex(offset) if offset >= 0 else 'not found')
for name in ('mp2.dat', 'TNO2.dat'):
    content = (p / 'data' / name).read_bytes()
    print(name, 'bytes', len(content), 'nonzero',
          [(row[0], row[1]) for row in iter_unpack('<ibd6f', content) if row[1]])
PY
```

読み取りのみの解析であり、旧 Plus / Mitaka++ を今回実行していない。過去の起動時トレースにおける未読込は、設定変更後を含む全実行経路の否定にはならない。
