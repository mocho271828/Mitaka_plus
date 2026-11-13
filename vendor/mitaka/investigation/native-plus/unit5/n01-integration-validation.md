# 小天体の一覧・描画・選択

- `SmallBodyRenderer` は body / label / orbit / pick に同じ可視性判定を使う。native の visible は種別全体の master であり、名称・軌道はそれぞれの設定に加えて visible と集合条件を満たすときだけ描画する。旧 Plus の優先順位の再現を主張しない。軌道は既存の `project_solar_segment` へ日心 J2000 黄道 AU を渡し、隣接する成功標本だけを結ぶ。終始点を自動で閉じず、欠損を跨がない。既存の描画品質 scope を使って点・線・文字を分離し、map に clip する。
- `SolarSmallBodies` は表示モデルと位置・軌道 snapshot の同一 dataset / model を検証する。新モデルへ切り替えると旧軌道・選択を除き、同じモデルの日時更新では表示集合を維持する。単一の選択は表示集合を変更せず、惑星・小天体・衛星・探査機の選択は相互排他にする。
- `SmallBodyController` は3種類それぞれの4フラグ、複数行の集合への追加・除去、固定 TDB 開始・終了 JD と標本数を表示する。検索・500件ページ・出典・Dark Aqua を維持し、複数行選択中は単一天体への「中心へ」を無効にする。入力拒否は元の設定を維持し、理由を画面へ表示する。
- `AppScripting` は `Asteroids` / `TNObjects` / `Comets` の visible / labels / orbits / selectedOnly の snapshot と12種の変更 action を App の共通 setter へ接続する。

JPL 彗星は有限の TDB 区間、36 byte の小惑星・TNO は旧版の数値 JD を使う。位置を評価できない行は診断と原記録を保持する。

旧 Lua の英名による show / hide / isVisible は、複数 source の原記録への名前解決が未確定のため追加していない。native の source + ordinal 集合を旧英名と同一の仕様とは説明しない。

| 試験 | 通常 arm64 | ASan + UBSan arm64 | x86_64 / Rosetta |
| --- | --- | --- | --- |
| 小天体一覧 controller | 60 checks / exit 0 | 60 checks / exit 0 | 60 checks / exit 0 |
| 実 bitmap 描画、ローカル Plus データ | 148 checks / exit 0 | 148 checks / exit 0 | 148 checks / exit 0 |
| Solar 選択・追尾・overview 遷移 | 42 checks / exit 0 | 42 checks / exit 0 | 42 checks / exit 0 |
