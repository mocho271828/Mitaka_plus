# N13 純計算の局所検証記録

2026-10-30 JST。作業ディレクトリは `native/core`。原本は読み取り専用で使用した。採取時の `/tmp` ファイル名には `unit6` が含まれるが、N13 は次単位 UNIT7 の未接続実装として保存する。UNIT6 統合試験の結果ではない。

## 環境と結果

- Apple clang version 21.0.0 (clang-2100.3.34.2)
- Target: arm64-apple-darwin25.6.0、host `arm64`
- Xcode toolchain: `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin`
- 通常 arm64、ASan/UBSan arm64、x86_64 の各ビルド・実行は exit 0。
- 各構成 `eclipse: 10179 checks PASS`、公式抽出比較 `7993 checks PASS`。
- 公式比較の最大絶対差は各構成 `1.6320278461989801e-14`、許容上限 `5e-13`。
- `*-build.log` はコンパイラ診断がなかったため空ファイル。実行結果は別ログに保存した。

## 再現コマンド

各構成について次のコマンドを実行した。下の `BUILD` と `FLAGS` は表の値に置き換える。

| 構成 | BUILD | FLAGS |
| --- | --- | --- |
| normal | `build-unit6-eclipse` | `-O2` |
| san | `build-unit6-eclipse-sanitize` | `-O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer` |
| x86 | `build-unit6-eclipse-x86` | `-O2 -arch x86_64` |

```sh
mkdir -p BUILD
clang++ -std=c++17 -Wall -Wextra -Wpedantic -Werror FLAGS -Iinclude \
  src/eclipse.cpp tests/test_eclipse.cpp -o BUILD/test_eclipse
LC_ALL=C awk -f tests/extract_eclipse.awk \
  ../../sources/official/mitaka_source/Mitaka/mtk_eclipse.cpp > BUILD/eclipse_upstream.inc
clang++ -std=c++17 -Wall -Wextra -Wpedantic -Werror FLAGS -Iinclude -IBUILD \
  src/eclipse.cpp tests/test_eclipse_upstream.cpp -o BUILD/test_eclipse_upstream
BUILD/test_eclipse
BUILD/test_eclipse_upstream
```

公式原典は `native/core/ECLIPSE_PROVENANCE.md` に SHA-256 と採用範囲を記録した。抽出は原関数の算術を変更せず、CP932 コメントと CR を除く。`LC_ALL=C` は macOS awk が CP932 バイト列を UTF-8 と誤認しないために必要。

## 確認の範囲

独立面積積分、解析解、接触境界、巨大・微小半径比、異常値、回転・平行移動・尺度不変、円錐と影軸の検証であり、GUI、描画結果、Lua、session の試験ではない。原版との bit 単位一致や天体暦・実観測の精度を保証しない。親担当および別担当による読取レビューは必須修正なし。レビュー担当は試験を再実行していない。
