# N06 地平図の天の川: 実装と検証

2026-10-29。基点は UNIT5 `5dd3409f8c551ff94666d84f4504f6f92f7047c7`。これは N06 の専用実装・試験の記録であり、UNIT6 全体や旧 Plus の全機能の完了判定ではない。App / Lua / Session の共通設定接続と実ウィンドウ上の確認は統合担当が別途検証する。

## 実装した契約

原典と推定を分けた根拠は [horizon-milkyway-contracts.md](horizon-milkyway-contracts.md)。同文書は実装前監査として保持する。

- `render_horizon_background` は画素中心の地平方位・高度を既存 `ObservationFrame::to_equatorial` に渡し、既存の逆銀河変換・alpha を考慮した双線形補間を再利用する。方位は右、高度は上。U は周期、V は端で固定する。追加の黄道傾斜や時系変換は行わない。
- 画像と出力は各辺 1..1024、RGBA 長を検証する。viewport は既存の正規化に従い、非有限値・非正の倍率を拒否する。
- `HorizonView.milkyWayMode` と `setSkyBackgrounds:` を追加した。既存の N09 星座絵・恒星名集合の接続を保持する。
- 地平図は基礎色、天の川の PlusLighter 合成、不透明な地面、grid・天体の順に描く。天の川は `mapRect` に明示クリップする。既存の地面・周辺 UI の色を変えない。
- cache は画像モデルの同一性・mode・観測緯度経度・JD・viewport・出力寸法を含む。描画時に生成するため、隠れたビューの設定変更では生成しない。同じ JD・正規化済みの同じ範囲・選択だけの変更では再利用する。モデル交換は古い画像を破棄する。
- loader は既存のローカル `data` の兄弟 `textures` のみを使う。None / Normal / Bright / Infrared の選択値を維持し、画像欠損時に他 mode の画像へ代用しない。IR の正式名が欠損した場合のみ既存の小文字名 fallback を許す。破損・symlink の失敗を fallback で隠さない。

新規依存はない。ImageIO / CoreGraphics / AppKit、既存 ObservationFrame、SkyBackgrounds と renderer 品質 scope を再利用した。地平線下の不透明な地面、明るさ、円筒投影は native の設計であり、旧 Plus の画素一致・大気や屈折・3D 距離減衰を実装したとは扱わない。

## 実行した試験

専用 build directory は `native/gui/build-unit6-horizon-background-{normal,san,x86}`。全構成で `-Wall -Wextra -Wpedantic -Werror` を含む既存 Makefile の設定を使用した。SAN は `SANITIZE=address,undefined`、実行時 `ASAN_OPTIONS=detect_leaks=0`。x86 は `ARCH=x86_64` でビルドし、Rosetta の `arch -x86_64` で実行した。ウィンドウは生成していない。

| 構成 | strict build | pure + Plus ローカル画像 | pure + 通常版ローカル画像 | 無窓 view bitmap |
| --- | --- | --- | --- | --- |
| arm64 通常 | exit 0 | exit 0、3/3 slot | exit 0、1/3 slot、欠損 2 件の診断 | exit 0、461,593 checks |
| arm64 ASan + UBSan | exit 0 | exit 0、3/3 slot | exit 0、1/3 slot、欠損 2 件の診断 | exit 0、461,593 checks |
| x86_64 Rosetta | exit 0 | exit 0、3/3 slot | exit 0、1/3 slot、欠損 2 件の診断 | exit 0、461,593 checks |

pure 試験は銀河中心・東西・両極、観測地の両極を含む 4 地点・2 JD、方位の周期、天頂・天底、17×13 の投影画素、alpha 補間、画像の継ぎ目、最大寸法、不正入力を確認する。既知方向を地平へ投影して画像中の期待色と比較するため、単に同じ逆変換を二重に呼ぶ試験だけではない。

view 試験は実際の `drawRect:` を固定 sRGB bitmap に描き、3 mode、欠損 mode、map 外・地面の不変、背景の左右上下、cache の全キーと拒否後保持を確認する。初回の試験は `NSBitmapImageRep.colorAtX:` の device profile 再解釈で期待色と不一致になった。raw RGBA は基礎色 `(6,11,18)` から Normal 合成後 `(102,11,18)` と正しかったため、試験を固定 sRGB bitmap の raw RGBA 比較へ修正した。製品描画や許容値を変えて通過させてはいない。

ログ 12 本は [logs/n06-horizon-background](logs/n06-horizon-background/) に保存し、[SHA256SUMS](logs/n06-horizon-background/SHA256SUMS) で固定した。build log は最後の専用 build の実出力であり、通常構成では増分 build を含む。

## 保全・独立レビュー・残る境界

Plus の 3 画像と通常版 IR の SHA-256 を再読取し、実装前監査の値に全件一致した。原本の変換・再保存・Git 登録は行っていない。mtime の独立した前後比較はこの専用試験では行っていない。

`time_features` が製品と試験を読み取りレビューし、同一 ObservationFrame、方向、補間、cache、描画順、欠損非代用、遅延生成、拒否後保持と clip の契約に修正必須の指摘なしと報告した。試験実行は上表の担当実行と区別する。

N06 所有ファイルの `git diff --check` は成功。`HorizonView.mm` はこの時点で 428 行、新規 view 試験は 231 行。共有ツリーには他担当の UNIT6 差分もあるため、stage / commit は統合担当が実施する。main README、IMPLEMENTATION_POLICY、policy gate はこの担当では変更していない。旧 Plus の厳密な合成や `toggleType()` 巡回順を新たに確定していない。
