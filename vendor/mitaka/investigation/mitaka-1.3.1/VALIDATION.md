# Mitaka 1.3.1 調査の検証記録

実施日: 2026-10-29。以下は実行結果の記録であり、自動テストスイートではない。

## 環境

- macOS 26.6.2（25G83）、arm64 ホスト。
- Xcode 27.1（27A9275）、Apple clang 21.0.0。
- Developer directory: `/Applications/Xcode.app/Contents/Developer`。
- 参照リポジトリの commit: `ab63d81723a9261b663c8ab1283de2e7607f1094`。

## 公式ソースの構文チェック

作業ディレクトリは `/Users/kota/mitaka/sources/official/mitaka_source`。
各翻訳単位に次を実行し、終了コードと診断を確認した。

```sh
xcrun clang++ -std=c++17 -fsyntax-only <source.cpp>
```

| 結果 | 対象 |
|---|---|
| 成功（10） | `common/astro/cele_mech.cpp`, `astrometry.cpp`, `cf96.cpp`; `common/math/fast_pow.cpp`, `random.cpp`, `Triangulation.cpp`; `common/text/unicode.cpp`, `unicode_string.cpp`, `string_util.cpp`, `key_value_file.cpp` |
| 失敗（5） | `Mitaka/main.cpp` と `common/JulianDate.cpp`: `windows.h`; `common/astro/constellation.cpp` と `star_name.cpp`: `stricmp`; `common/text/unicode_string_table.cpp`: `tchar.h` |

`Triangulation.cpp` は include の大文字小文字の警告あり。
`star_name.cpp` は CP932 の文字列リテラルに関する警告もある。
各ファイルの診断は [syntax](/Users/kota/mitaka/investigation/mitaka-1.3.1/syntax) に保存。
成功は構文確認の範囲であり、リンク・実行・数値精度の保証ではない。

## 型のサイズ

Clang のターゲット別定義を以下のコマンドで確認した。

```sh
xcrun clang -target arm64-apple-macos14 -dM -E -x c /dev/null
xcrun clang -target x86_64-pc-windows-msvc -dM -E -x c /dev/null
```

| 対象 | int | long | pointer | wchar_t |
|---|---:|---:|---:|---:|
| arm64 macOS | 4 | 8 | 8 | 4 |
| x86_64 Windows/MSVC | 4 | 4 | 8 | 2 |

単位は byte。Windows ターゲットのコンパイル・実行を行ったという意味ではない。

## 非公式移植の既存コアテスト

`/Users/kota/mitaka/sources/reference/Mitaka-macOS` で `bash scripts/test_core.sh` を実行。
終了コード0、出力は `MitakaCore tests passed`。
C++17、`-Wall -Wextra -Werror` でコンパイルする既存テスト。
9天体、地球の識別、J2000 における全9天体の有限座標・概略距離、Unix epoch から Julian Date への変換を確認する。
元の Mitaka、CF96 暦、長期間の天体位置との精度比較は含まれない。

## 非公式移植の universal build

同じ作業ディレクトリで実行。

```sh
xcodebuild -project MitakaMac.xcodeproj -scheme MitakaMac \
  -destination 'generic/platform=macOS' \
  -derivedDataPath /tmp/mitaka-131-reference-build \
  CODE_SIGNING_ALLOWED=NO ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO build
```

終了コード0、`BUILD SUCCEEDED`。
`file` と `lipo -archs` で出力実行ファイルに `x86_64 arm64` が含まれることを確認。
ビルドログは [reference-build.log](/Users/kota/mitaka/investigation/mitaka-1.3.1/reference-build.log)。
AppIntents の依存がないためメタデータ抽出を省略した警告があり、ビルドは成功した。

- 出力: `/tmp/mitaka-131-reference-build/Build/Products/Debug/MitakaMac.app`
- 署名・公証・配布は未実施。
- GUI 起動、描画・操作・性能の確認、Intel 実機での実行は未実施。
- 公式1.3.1の全体ビルドではなく、非公式の部分移植をビルドした結果。

## ソースの保全

ZIP と公式展開物のバイト一致を確認。
公式展開物と参照リポジトリ内の上流コピーの比較結果は [upstream-comparison.json](/Users/kota/mitaka/investigation/mitaka-1.3.1/upstream-comparison.json)。
ビルド後、参照リポジトリの `git status --short` と `git diff --stat` は変更なし。
親ディレクトリ `/Users/kota/mitaka` は Git リポジトリではない。
