# N08 Earth layer / N12 scene 接続の局所証跡

2026-10-29。原本は読み取りのみ。担当の局所結果であり、App / Lua / session の統合合否は root の UNIT6 記録を参照する。

## 最終結果

- `*-{normal,sanitize,x86}-pure-final-test.log`: 各 `earth layers: 63 checks PASS` と既存 planet surface 試験成功。
- `*-scene-final-test.log`: 通常 53 checks PASS（回帰 50 と任意 benchmark 3）。`*-scene-{sanitize,x86}-final-test.log`: 各 50 checks PASS。
- `*-textures-final-test.log`、`*-{sanitize,x86}-textures-final-test.log`: fixture の loader 試験成功。
- `*-{plus,regular}-textures-final.log`: 元の各ローカルデータで、基底11件・Earth layer 2件を読み込み、emmap 983088 bytes と有効 map を確認。これは現物の観測値であり、実装の固定件数ではない。
- `*-final-build.log`: 対応した strict C++17 / Objective-C++ build の記録。

scene 最終版は空画像の AppKit 生成を抑止する guard と、非 Earth で雲・夜景設定が画素を変えない回帰を含む。通常の 800×800 人工シーン各1回の値は、大気なし 225.338 ms / single 801.211 ms / multiple 991.452 ms。並行作業の影響を含み、連続描画の性能保証ではない。

## 途中の記録

`final` を含まないログは作業途中の記録として保存した。`scene-build.log` の C++20 lambda 構文による初回 compile 失敗は C++17 の generic lambda へ修正し、最終3構成で解消した。`scene-normal-test.log` の 41 checks は後続の大気・非 Earth 回帰追加前であり、最終版の件数として扱わない。

`SHA256SUMS` はこのディレクトリの `.log` 全件を対象にする。
