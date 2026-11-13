# 恒星・星座・大気の保存項目

JSON v6 に導入された設定と値域を示す。現行の JSON v9 にはこれらの項目が含まれる。過去版の保存ファイルの読み込みはサポートしない。

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
