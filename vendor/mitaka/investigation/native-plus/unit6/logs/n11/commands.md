# N11 と単位6 Lua の保存ログ

既に実行した通常・ASan/UBSan・x86_64（Rosetta）の局所試験ログを、そのまま保存した。保存作業では試験を再実行していない。コマンドの作業ディレクトリは `/Users/kota/mitaka/repositories/Mitaka`。結果と互換範囲は [Lua 表示 API の検証](../../lua-display-contracts.md)、数値と遷移の契約は [明るさ仕様](../../../../../native/gui/STAR_BRIGHTNESS.md) を参照する。

## 結果

各構成で `test_star_brightness` は 1,084 checks、`test_star_brightness_controller` は 45 checks、`test_display_rendering` は 103 checks を通過した。Lua helper を使う `test_script_controller` も各構成で成功した。実行時の終了コードはすべて 0。短い結果ログに終了コード自体が出力されているという意味ではない。

`script-normal.log` と `script-build-display-{san,x86}.log` は N09/N10 と地球・大気 API を追加した後の Lua 試験である。後二つは描画試験のコンパイルも含むが、描画試験の実行結果は `display-*.log` に分けた。`build-script-display-normal.log` はそれ以前の N11 描画・Lua ビルド記録として保持する。全体アプリ、新規 clone、原本保全の記録は [統合記録](../../README.md) に分ける。

## 再現コマンド

以下は同じ対象を再現するコマンドであり、保存ログのリダイレクトや当時の shell 呼出し全体を復元したものではない。各構成のビルド先を分け、`-Wall -Wextra -Wpedantic -Werror` を使う既存 Makefile で実行する。x86_64 バイナリの実行は Apple Silicon 上の Rosetta であり、Intel 実機試験ではない。

```sh
make -C native/gui BUILD_DIR=build-unit6-stars -j4 build-unit6-stars/test_star_brightness build-unit6-stars/test_star_brightness_controller build-unit6-stars/test_display_rendering script-test
native/gui/build-unit6-stars/test_star_brightness
native/gui/build-unit6-stars/test_star_brightness_controller
native/gui/build-unit6-stars/test_display_rendering

make -C native/gui BUILD_DIR=build-unit6-stars-san SANITIZE=address,undefined -j4 build-unit6-stars-san/test_star_brightness build-unit6-stars-san/test_star_brightness_controller build-unit6-stars-san/test_display_rendering script-test
native/gui/build-unit6-stars-san/test_star_brightness
native/gui/build-unit6-stars-san/test_star_brightness_controller
native/gui/build-unit6-stars-san/test_display_rendering

make -C native/gui BUILD_DIR=build-unit6-stars-x86 ARCH=x86_64 -j4 build-unit6-stars-x86/test_star_brightness build-unit6-stars-x86/test_star_brightness_controller build-unit6-stars-x86/test_display_rendering script-test
native/gui/build-unit6-stars-x86/test_star_brightness
native/gui/build-unit6-stars-x86/test_star_brightness_controller
native/gui/build-unit6-stars-x86/test_display_rendering
```

`script-test` は各 build 内の `test_script_controller` に、その build の `MitakaScript` の絶対パスを渡す。Make の呼出しとコンパイル引数は保存したビルドログからも確認できる。

## 静的証跡

対象の原版 EXE は 12,288,000 bytes、SHA-256 `48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457`。元 EXE は変更・同梱していない。採取は `/usr/bin/objdump --disassemble --x86-asm-syntax=intel --start-address=<VA> --stop-address=<VA> <EXE>` と、PE section に基づく定数・import 確認による。各範囲と解釈は [N11 監査](../../star-brightness-fade-contracts.md) および [Lua 監査](../../lua-display-contracts.md) に記載する。これは限定した読み取り追跡であり、旧アプリの実行比較や REA のデータフロー証明ではない。

## 保存元一覧

| 保存ファイル | 元ファイル |
| --- | --- |
| [test_star_brightness-normal.log](test_star_brightness-normal.log) | `/tmp/mitaka-unit6-build-unit6-stars-test_star_brightness.log` |
| [test_star_brightness_controller-normal.log](test_star_brightness_controller-normal.log) | `/tmp/mitaka-unit6-build-unit6-stars-test_star_brightness_controller.log` |
| [test_star_brightness-san.log](test_star_brightness-san.log) | `/tmp/mitaka-unit6-build-unit6-stars-san-test_star_brightness.log` |
| [test_star_brightness_controller-san.log](test_star_brightness_controller-san.log) | `/tmp/mitaka-unit6-build-unit6-stars-san-test_star_brightness_controller.log` |
| [test_star_brightness-x86.log](test_star_brightness-x86.log) | `/tmp/mitaka-unit6-build-unit6-stars-x86-test_star_brightness.log` |
| [test_star_brightness_controller-x86.log](test_star_brightness_controller-x86.log) | `/tmp/mitaka-unit6-build-unit6-stars-x86-test_star_brightness_controller.log` |
| [script-normal.log](script-normal.log) | `/tmp/mitaka-unit6-n12-script-normal.log` |
| [script-build-display-san.log](script-build-display-san.log) | `/tmp/mitaka-unit6-final-script-display-san.log` |
| [script-build-display-x86.log](script-build-display-x86.log) | `/tmp/mitaka-unit6-final-script-display-x86.log` |
| [build-script-display-normal.log](build-script-display-normal.log) | `/tmp/mitaka-unit6-n11-build-script-display-normal.log` |
| [display-normal.log](display-normal.log) | `/tmp/mitaka-unit6-n11-display_rendering-normal.log` |
| [display-san.log](display-san.log) | `/tmp/mitaka-unit6-final-display-san.log` |
| [display-x86.log](display-x86.log) | `/tmp/mitaka-unit6-final-display-x86.log` |
| [atmosphere-lua-static-evidence.txt](atmosphere-lua-static-evidence.txt) | `/tmp/mitaka-unit6-atmosphere-lua-static-evidence.txt` |
| [star-bindings.asm](star-bindings.asm) | `/tmp/mitaka-unit6-star-bindings.asm` |
| [star-api-evidence.asm](star-api-evidence.asm) | `/tmp/mitaka-unit6-star-api-evidence.asm` |
| [star-brightness-draw.asm](star-brightness-draw.asm) | `/tmp/mitaka-unit6-star-brightness-draw.asm` |
| [star-fade.asm](star-fade.asm) | `/tmp/mitaka-unit6-star-fade.asm` |
| [star-fade-caller-a.asm](star-fade-caller-a.asm) | `/tmp/mitaka-unit6-star-fade-caller-a.asm` |
| [star-fade-caller-b.asm](star-fade-caller-b.asm) | `/tmp/mitaka-unit6-star-fade-caller-b.asm` |
| [star-fade-parent.asm](star-fade-parent.asm) | `/tmp/mitaka-unit6-star-fade-parent.asm` |
| [star-interpolators.asm](star-interpolators.asm) | `/tmp/mitaka-unit6-star-interpolators.asm` |
| [star-interp-base.asm](star-interp-base.asm) | `/tmp/mitaka-unit6-star-interp-base.asm` |
| [star-interp-manager.asm](star-interp-manager.asm) | `/tmp/mitaka-unit6-star-interp-manager.asm` |
| [star-callback.asm](star-callback.asm) | `/tmp/mitaka-unit6-star-callback.asm` |
| [star-clock-source.asm](star-clock-source.asm) | `/tmp/mitaka-unit6-star-clock-source.asm` |
| [star-clock-loop.asm](star-clock-loop.asm) | `/tmp/mitaka-unit6-star-clock-loop.asm` |

各保存ファイルと本書の SHA-256 は [SHA256SUMS](SHA256SUMS) に記録した。
