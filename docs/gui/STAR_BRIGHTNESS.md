# 恒星の明るさと時間付き変更

旧 Plus のローカル文書と実行ファイルから、公開 `Stars.brightness` が描画の分母 `L_ref` であることを確認した。1 が標準、小さい値ほど明るい。`brighten()` は float の `10^-0.2` 倍、`darken()` は `10^+0.2` 倍、`defaultBrightness()` は 1 にする。

## 入力と状態

`StarDisplayOptions.brightness` は正の有限 float。Lua number は有限・正・float 最大値以内であることを検査し、float に丸めて 0 になる値も拒否する。正の subnormal は保持する。増減で overflow / underflow する場合も、状態や進行中の補間を変更しない。範囲制限は native の安全な入力契約であり、旧版が同じ検証をしていたという意味ではない。

共通設定を全天図・地平図へ反映する。等級上限、カタログ件数、ヒット判定、名称集合、クリック選択、星座や惑星の設定は変更しない。太陽系ビューに恒星 renderer はないため、この設定だけで 3D 恒星を描かない。

## 点描画

現在の native 点描画を基準として、等級 m について以下を使う。

```
r0 = clamp(2.8 - 0.32*m, 0.55, 3.6)
a = clamp(1.2 - 0.07*m, 0.3, 1) / brightness
radius = min(32, r0 * sqrt(max(1, a)))
opacity = min(1, a)
```

投影の alpha はこの opacity に掛ける。brightness=1 は変更前と同じ点になる。半径上限に達するまでは点の面積と alpha の積が `1/L_ref` に比例する。上限 32 px は過大描画を抑える native の制限。原版のテクスチャ、縮尺依存式、全モードの画素を再現したものではない。名称・番号・Binary / ExoPlanets マークの描画には倍率を掛けない。

## 補間と寿命

`Stars:setBrightnessTo(target, durationSeconds)` は 2 個の number を取り、戻り値なしで開始する。duration は有限かつ 0 以上。開始値と target は float、時間計算は double、更新値を float に丸める。既定の曲線は原版で確認した半余弦 `0.5-0.5*cos(pi*u)`。native では等価な凸結合で正値域を維持する。

- 呼出しは非同期。Lua は次へ進み、明示の `waitTime()` で待てる。
- 直接の brightness 代入は遷移を取り消す。新しい target は現在値を開始値として置換する。
- target が現在値と同じ float なら何もしない。既存の別 target への遷移は継続する。原版の早期 return と一致する。
- brighten / darken / defaultBrightness は遷移を取り消さない。次の更新で遷移値が再適用され得る。原版の raw store 経路と一致する。
- duration=0 は同期的に target を適用して終了する。原版のゼロ時間の残存登録を再現しない。経過時間が duration 以上で target を確定し、timer を破棄する（原版の解除条件は厳密な超過）。
- native は単調時計とメインスレッドの 30 Hz timer を使う。天文時刻の停止・逆再生とは独立する。逆行した時計、host の拒否、計算例外は遷移を止めて失敗通知する。
- Lua の終了・停止だけでは開始済みの表示遷移を取り消さない。アプリ終了、データ再ロード、セッション復元時はアプリ所有側が取り消す。保存するのは現在の brightness で、未完了 target / timer は保存しない。

最後の時計・寿命・保存の扱いは native の契約。旧版の GlobalTime は実時計と固定 step の分岐を持ち、全停止・export 状態や Lua 寿命との関係は未確定である。undocumented な第 4 引数、補間 userdata、`setBrightness` alias は提供しない。

## 未対応と検証

`fadeLabels` は旧版の 3D 恒星位置・カメラ位置・縮尺に依存する。現在の角度投影へ等級制限や明るさを代入して互換と称さず、未対応エラーを維持する。

既存 C++ 標準ライブラリと Foundation timer を利用し、新規依存はない。純粋計算は 1,084 checks、controller の置換・同値・逆時計・host 拒否・再入・破棄は 45 checks が通常・ASan/UBSan・x86_64 で成功した。Lua の strict 入力・host 拒否・取得を既存 script controller 試験で確認し、実描画の標準値復帰・明暗・名称/マーク不変を含む display 試験は 103 checks が三構成で成功した。これらは局所試験であり、全体アプリの統合結果とは区別する。
