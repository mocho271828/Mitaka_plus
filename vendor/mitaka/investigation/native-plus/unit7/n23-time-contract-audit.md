# Plusの時刻ステップ・暦・再生速度

Windows 版 Plus 1.5.4 build101013 が使う時刻の単位と計算を示す。ネイティブ版での UTC と地方時は [Lua ガイド](../../../native/gui/SCRIPTING.md) を参照。[定数の読取手順](probes/extract-time.sh)

| 原典 | SHA-256 | 用途 |
| --- | --- | --- |
| `mitakaPlus.exe` | `48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457` | PE32 x86、image base `0x400000`。登録・状態・演算 |
| `doc/script_jp/time.html` | `8249eca831cfd2b6f9235f60e245ea08a8d0eb9f74f54fadf2f41da174f2d4e6` | 同梱説明書、CP932。表記は v1.3.0 |
| `scripts/gui.lua` | `49abcc449bb0925ca4bce492767159a7ff972e7ae4c924321d5c850a1038c2f5` | 同梱 UI の API 使用 |
| `scripts/shortcuts.lua` | `64a0592f69d834a6884e0010e663e28a482d7506a18d10a87214342d5d0132f2` | 同梱ショートカットの使用 |

アドレスは VA。対象 EXE やデータのコピー・改変は行っていない。

## 登録された step と日数状態

`0x669070..0x6699e0` の登録では `mtk.Time`、下表の定数とメソッドを登録する。定数は文字列だけから推測せず、登録呼出しの整数引数と照合した。native は同じ定数を `mtk` とグローバルへ公開する。

| 定数 | 値 | 直接 step 代入後の stepValue（日） |
| --- | ---: | ---: |
| `STEP_SEC` | 0 | 1 / 86400 |
| `STEP_10SEC` | 1 | 10 / 86400 |
| `STEP_MIN` | 2 | 60 / 86400 |
| `STEP_10MIN` | 3 | 600 / 86400 |
| `STEP_HOUR` | 4 | 3600 / 86400 |
| `STEP_DAY` | 5 | 1 |
| `STEP_WEEK` | 6 | 7 |
| `STEP_MONTH` | 7 | 31 |
| `STEP_YEAR` | 8 | 365 |
| `STEP_10YEAR` | 9 | 3650 |
| `STEP_100YEAR` | 10 | 36500 |
| `STEP_VALUE` | 11 | 0 |

`Time.step` wrapper `0x6680d0` → `0x5ec3b0` → `0x485330` は日数表 `0xd70660` を double 状態 `0xfe90c0` へ代入し、enum byte `0xd70e60` を更新する。`stepValue` wrapper `0x6681a0` → `0x5ec410` → `0x485350` は double をそのまま保持し、enum を 11 に切り替える。custom の forward `0x5e9746` / rewind `0x5ea326` はその double を JD に直接加減するため、単位は**日**である。負値と 0 を除く分岐はない。

`prevStep` (`0x5ec3d0`) は `max(step - 1, 0)`、`nextStep` (`0x5ec3f0`) は `min(step + 1, 9)`。両方とも enum byte だけを書き、日数表を読み直さない。特に next は 9、10、11 のいずれからも 9 となる。native も enum と日数を独立に保持する。

説明書 73–78 行は `STEP_SEC` と数値を記載せず、`stepValue` を int・秒と説明する。実装の登録・double 保存・JD 消費に従い、native は 12 値と日単位の有限数を公開する。

## 単発移動と暦の繰り越し

登録された戻りメソッドは `rewind`（登録 `0x66927d..0x669283`、wrapper `0x665ff0` → `0x5e9ba0`）。説明書 93 行の `backward` は登録されず、同名 NUL 終端文字列も対象 EXE に存在しない。未確認 alias は追加しない。

forward は `0x665fd0` → `0x5e8fc0`、rewind は上記経路。JD getter `0x59c3f0` の状態 `0x110bd40` を Gregorian 変換 `0x41e410` に渡し、秒・分・時・日・月・年の対応成分を変更する。月・年の分岐は `__timezone` を読まない。**単発 step の暦は UTC 相当の JD 暦**である。

戻し変換 `0x41e180` は月を正規化し、月初からの経過日数として day を加算する。月末に clamp しない。2001-01-31 の月 +1 は 2001-03-03、2000-01-31 は 2000-03-02、2000-02-29 の年 +1 は 2001-03-01 となる。年・10 年・100 年は Gregorian 整数年成分の変更であり、単発で 365 日等を足すものではない。

native `PlusTimeStepState::stepped_julian_date` は既存 core の `GregorianDateTime` / `julian_date` / `gregorian_date_time` を再利用し、月初＋経過日数でこの境界を表す。天体暦の共通期間は host が適用前に検証する。native UI の `TimeSettings` は従来の秒単位 custom・月末 clamp を維持し、互換経路とは混ぜない。

## UTC 日時成分

`setTime` は wrapper `0x666410` → `0x5eab30` → `0x41e180`。getter は `0x666550` → `0x5eabb0`。year は int32、month/day/hour/minute は signed byte、second は double の暦構造へ渡る。Lua の各整数 setter からの成分変更も同じ変換を通る。month 0、day 0、時分秒の超過を繰り越す。

native `plus_julian_date` は年 -4712..9999、月・日・時・分 -128..127、秒 int32 の整数、有限値を先に検証する。原版の暗黙 narrow/wrap、範囲外 float→int 変換、年 -4713 の特殊な no-op は再現しない。結果も core 暦範囲と host 暦表期間で検証し、不正入力では状態を変更しない。暦公式の再実装や独立 timezone library は導入しない。

原版の current wrapper (`0x666010` → `0x5ea360`)、current UTC/JD adapter (`0x5ea930` / `0x5eaad0`) は `_time64` → `_gmtime64` の秒精度。native の登録名 `Time.setCurrent()` も現在 Unix 秒の整数部分から JD を作る。既存 native getter は JD の丸め誤差を避けるため最近傍秒へ丸めるため、原版 getter の秒切捨てと全境界で逐値一致するとは称さない。

## speed と連続再生

wrapper `0x668230` は Lua number を `cvttsd2si` で int32 へ 0 方向に切り捨て、`0x5ec440` に渡す。そこで realtime を解除し (`0x5ec472`)、speed `0x1081b3c` を保存する (`0x5ec47d`)。getter `0x5ec920` はこの整数を返す。時計消費 `0x511804..0x51191f` は速度×日数状態×実経過時間を JD に加算する。月年も連続再生中は日数表を使う。

native の型は `PlusTimeState { PlusTimeStepState step; int32_t speed; }`。finite number を切捨て、int32 外と `stepValue * speed * 86400` の overflow を適用前に拒否する。負 custom×負 speed は順方向、0 custom×非零 speed は再生中だが JD 不変である。

`PlaybackController` が host 状態を所有し、Lua worker の作成・終了では reset しない。native 初期値の hour / 1⁄24 日 / speed 0 は新 GUI の明示設計であり、原版の起動設定を推測した値ではない。既存 `PlaybackClock` を再利用し、互換用の停止中 rate setter だけを追加した。通常 GUI の rate 上限・下限は変更していない。

手動日時変更、停止、native GUI 再生への移行、範囲端、1 秒を超える割込み、sleep/hidden、invalidate で speed を 0 にし、自動再開しない。通常の steady clock、範囲端停止、1 秒中断条件は維持する。realtime は別の実時計追従状態で、sleep 復帰時は最新 UTC に合わせる。Session7 は enum と日数・速度を保存するが、復元は検証後に speed 0 とする。

local getter `0x5eb490` は `JD - __timezone / 24 / 3600`、setter `0x5eb3f0` は暦 JD に同じ値を加える。currentLocal adapter `0x5ea9f0` も UTC JD から減算する。IAT `0xc25670` は `_time64`、`0xc256dc` は `_gmtime64`、`0xc256e0` は `__timezone`。日付ごとの DST 計算はこの経路にはない。
