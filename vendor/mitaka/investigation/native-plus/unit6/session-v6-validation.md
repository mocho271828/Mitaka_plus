# Session v6: codec の実装と検証

2026-10-29。本番投入前の新規プロジェクトとして schema を v6 に更新し、v5 を含む他 version を拒否する。App への適用は既存の単一境界に残し、codec の責務は全項目を検証した SessionState の生成と UTF-8 JSON の出力である。

## 追加した保存項目

| 項目 | codec の検証 |
| --- | --- |
| selected_star_name_hips | 必須配列。各要素は bool でない正の int32 整数。重複拒否。既知 HIP の照合は App 適用時 |
| stars.selected_proper_names_only | 必須 bool |
| stars.brightness | 必須数値。既存 checked_star_brightness / validate_star_display で正の有限 float、overflow / zero への underflow を拒否 |
| constellations.illustrations | 必須 bool |
| earth_layers.clouds / city_lights | 各必須 bool |
| atmosphere.mode | none / single / multiple の enum 値 0 / 1 / 2 |
| atmosphere.intensity | 必須数値。既存 validate_atmosphere_display で有限、0..FLT_MAX |

最大 1 MiB、Foundation NSJSONSerialization、既存の未知 key を無害な追加情報として無視する方針を維持する。未知 key の全階層拒否や生 JSON の重複 key parser は追加していない。再生・時計追従・飛行・スクリプトの実行状態を新規保存しない。ファイル I/O とモデル照合・適用は App 側に残す。

## 実行結果

既存 test_session_state を通常・ASan+UBSan・Rosetta x86_64 の三構成で実行し、すべて **1,464 checks、exit 0**。既存 Makefile の strict warning 設定を使用した。専用 build は `native/gui/build-unit6-time{,-san,-x86}`。ウィンドウを生成しない。

新規回帰は v6 roundtrip、旧 version 拒否、新規必須項目の欠落・null・型違い、HIP 端点・非整数・bool・重複、brightness の float 最小正値・最大値・overflow / underflow、大気三状態・強度ゼロ・非有限・上限、native encode 側の不正状態、未知 key の inert 許容、大集合の 1 MiB 上限を含む。

最初の局所 link では既存 validator の object が test target に不足していた。test_session_state の依存へ star_brightness、atmosphere_renderer、planet_surface、earth_layers を追加し、validator を複製せず再利用して再実行した。新たな外部 library は追加していない。

実ログは [logs/n09-n10/session-normal.log](logs/n09-n10/session-normal.log)、[session-san.log](logs/n09-n10/session-san.log)、[session-x86.log](logs/n09-n10/session-x86.log)。元のログは `/tmp/mitaka-unit6-session-{normal,san,x86}-test.log`。保管ログは同 directory の SHA256SUMS に追加した。

plus_spec_audit が指定 codec / header / test と既存 validator を独立に読み取り、修正必須の指摘なしと報告した。HIP の bool 分離・int32・重複、float 変換前の brightness 検証、共通の大気検証、必須項目、v5 拒否、未知 key、容量上限と encode 側の拒否を確認した。レビュー担当による追加実行はしていない。

App の unknown HIP 拒否・全体原子性・保存設定復帰・新規表示項目の同期は root の統合試験に委ねる。codec の単体成功だけで App 復元の完了とは扱わない。共有ツリーの stage / commit、IMPLEMENTATION_POLICY と policy gate は統合担当が処理する。
