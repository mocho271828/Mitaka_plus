# N13 表面・円錐の局所検証と静的監査

作業ディレクトリは `/Users/kota/mitaka/repositories/Mitaka`。原本は読み取り専用で扱い、実行・画像再生成・依存導入を行っていない。全アプリの window/controller/smoke 試験は統合担当が別に記録する。

## 最終局所試験

```
make -C native/gui -j3 BUILD_DIR=build-unit7-eclipse eclipse-renderer-test
make -C native/gui -j3 BUILD_DIR=build-unit7-eclipse-san SANITIZE=address,undefined eclipse-renderer-test
make -C native/gui -j3 BUILD_DIR=build-unit7-eclipse-x86 ARCH=x86_64 eclipse-renderer-test
```

最新は `mitaka-unit7-n13-final4-{normal,san,x86}.log`。三構成とも exit 0、surface 1,021 / display 92 / cone 28,293 / scene 21 checks PASS。strict C++17、compiler は `compiler.log`。これらは offscreen 計算・画像試験であり、実ウィンドウ操作ではない。

`final-*` は半影追加監査前の成功記録であり、現在の二面実装の検証としては使わない。`final2-normal` は二面・切断を修正した後、scene の半影独立性で失敗した記録。121² 画素で切断後の面が subpixel になった fixture を、物理半径・天体位置を変えず、カメラ target 0.9995 AU、距離 0.0015 AU へ変更した。`final3-*` はその修正後の成功。`final4-*` は負の終端について実 raster 回帰を追加した最終結果であり、公差を緩めていない。

## 原本の静的読み取り

`pe-static-values.log` は対象パス、SHA-256、PE image base、四フラグの画像内初期 byte、登録対象の原文字列を保存する。Python 標準ライブラリで DOS header の `e_lfanew`、PE32 OptionalHeader の ImageBase、section の VirtualAddress/PointerToRawData を読み、VA を raw offset へ変換した。原本全体はこの archive に複写しない。

`.asm` は xcrun LLVM objdump の Intel 構文による限定範囲の逆アセンブル。例として円錐範囲を再取得するコマンドは次のとおり。既存抜粋の再現用であり、すべての保存ファイルを一つのコマンドで取得したという記録ではない。

```
xcrun llvm-objdump -d --x86-asm-syntax=intel \
  --start-address=0x4c84e0 --stop-address=0x4c9da8 \
  '/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe'
```

| 抜粋 | 対象 |
| --- | --- |
| `flag-state.asm`、`flag-write.asm` | 4 getter/setter/toggle と共通 bit 更新 |
| `lua-flags.asm`、`lua-toggle.asm`、`registrations.asm` | Lua と公開名の対応 |
| `draw-flag-refs.asm` | 表面・境界・円錐の各 bit 参照。複数の限定範囲を含む |
| `target-setup.asm` | 木星と 4 衛星名の lookup・登録 |
| `earth-callers.asm`、`moon-callers.asm`、`surface-wrappers.asm` | 表面対象と位置・半径の受渡し |
| `planetarium-cones.asm` | 円錐表示の呼出し側 |
| `cone-render.asm` | 本影、半影二面、alpha、母線終端の算術 |
| `cone-wrapper-independent-review.asm` | 別担当による引数の限定照合 |

独立レビューは最終 header/cpp/test と該当 asm の読取。二面・alpha・厳密接線・後方条件・負の終端に必須修正の指摘なし。レビュー担当による試験の再実行や、原 Windows アプリとの画素比較は行っていない。`SHA256SUMS` はこのファイル以外の保存ログ・asm を対象とする。
