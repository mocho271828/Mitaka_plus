# 探査機の PPI と PTH の実データ比較

PR #8 の `3f50687` を出発点として、2026-11-12 に Apple M4 / macOS 26.6.2 で測定した。Plus 同梱データと比較用の通常版は、それぞれのディレクトリを独立に指定した。

## 配布物と座標の記載

Plus 1.5.4 は7軌跡・14定義（英語・日本語）をすべて PTH で収録する。7本の SHA-256 は、旧 Plus 作者配布の同版 ZIP（SHA-256 `6904536fdff95afe48cfac26712556c5171cb32f365d0b98e86d38891212190f`）と一致した。PPI は 0 本だった。PTH は日心 J2000 黄道 AU の数値 JD 標本を線形補間する。物理時系は未確認。[原データ一覧](spacecraft-sources.tsv)・[PTH の旧版位置評価契約](../../vendor/mitaka/native/core/SPACECRAFT_POSITION_PROVENANCE.md)

比較用の国立天文台版 1.7.4a 軽量版（223,705,277 bytes、SHA-256 `1e3aa2a14b4a10e397685cb78724ab3ad7ae1e84cb6dfd687df41c0691ec67ee`）には、探査機の PPI が13本、計16,606区間ある。1区間には4組の時刻と3軸の km 座標が入る。13定義はすべて `ORIGIN` を明記し、`SS_BC`（太陽系重心）10機、`EARTH`（Gaia、TESS）2機、`SUN`（あかつき）1機。通常版1.3.1の描画経路でも、既知の9機をJ2000黄道座標として扱う。日付・座標系は個別の出典で照合した。通常版の配布物・観測原表はローカルの検証ディレクトリに保存した。[公式配布](https://4d2u.nao.ac.jp/mitaka/download/)・[1.3.1 の座標経路](../../vendor/mitaka/investigation/native-plus/orbit-contracts-audit.md)

## 原標本と提供元データの照合

1.7.4a 同梱説明書「クレジット」は探査機軌道の出典を JPL HORIZONS、あかつきを JAXA DARTS と記載する。[公式説明書](https://4d2u.nao.ac.jp/wp-content/uploads/mitaka/manual/mitaka_manual_J.pdf)

- HORIZONS の12機はそれぞれ、PPIの全区間に含まれる原時刻を重複なしで昇順に並べ、添字 `floor((件数−1)×p)` の `p=0.1, 0.4, 0.8` を測った。公開 API で同じ数値 JD、原定義に対応する中心（`500@0` または `500@399`）、`VECTORS`、`VEC_TABLE=2`、`TIME_TYPE=TDB`、`REF_SYSTEM=ICRF`、`REF_PLANE=ECLIPTIC`、`VEC_CORR=NONE`、`OUT_UNITS=KM-S` を指定した。3次元の位置差は、36組のうち8機18組で1 m未満だった。その18組をJ2000赤道面と仮定した対照では最小129,280 km、速度×65秒を加えた時刻ずれの一次近似対照では最小12.7 kmだった。一方、同一条件で Juno の1組は約749.7万 km違う。配布当時の軌道解や予測を、今回の応答だけでは再構成できない。全ファイル・全時刻への物理時系や精度の一律保証には用いていない。[36標本の差と応答ハッシュ](spacecraft-horizons.tsv)・[JPL API仕様](https://ssd-api.jpl.nasa.gov/doc/horizons.html)
- あかつきは、DARTS「Akatsuki2010May-2020Dec_1d.txt」（SHA-256 `fdd65efd5e99e8d9bac932c800f421eb314b70c3119ec407e573a230f2d67c27`）のUTC・日心J2000赤道・kmを使用した。日次の原時刻から0.002日以内にある最も近いPPI原標本を取り、赤道座標をJ2000黄道傾斜23.43929111111111°で黄道へ回転した。1,888組のうち、2010-05-22〜2011-12-06の478組で差が1 cm以内。この478組で PPI の JD と DARTS の UTC 表記の差は66.184秒（当時のTT−UTC）だった。期間後方にはこの原表と位置が合わない標本があり、参照表にも予測期間が含まれる。これらの時刻差では TT と TDB のミリ秒級の差まで識別できない。[年別比較](spacecraft-akatsuki.tsv)・[JAXA データ仕様](https://darts.isas.jaxa.jp/en/datasets/darts%3Aakatsuki-orbit-data-2016)・[比較に使用した日次原表](https://data.darts.isas.jaxa.jp/pub/akatsuki/orbit/Akatsuki2010May-2020Dec_1d.txt)

## 実ウィンドウでの結果と修正

統合版の製品オブジェクトに観測用の入口をリンクし、AppKit の探査機一覧を開き、Voyager I 行を選んで「中央へ」の動作を実行した。同じカメラで探査機を表示／非表示にし、WindowServer の PID とウィンドウ番号を照合した ScreenCaptureKit の画像を採取した。比較領域は1,928×1,058物理画素の地図である。[5試行のカメラ・位置・画像ハッシュ](spacecraft-windows.tsv)

| 入力 | 実測 |
| --- | --- |
| Plus 1.5.4 同梱、JD 2453695.0 | 14定義すべて位置あり。Voyager Iは原行10302と10303の中点で、選択・注視後に天体が地図中央に出た。切替で中央72×72内の504画素が変わり、地図の残りは一致。 |
| 同じ Plus、JD 2454400.5 | 最終原行10709への端点固定を明示し、カメラの対象位置が元座標と一致。修正前後とも504画素が変化。 |
| 通常版1.7.4a、JD 2454400.5 | 13定義を保持し、表示位置は0件。Voyager I の一覧・選択には202 PPI区間、原定義の `ORIGIN=SS_BC`、現時点の表示座標と時系の未認定を表示。中央表示を操作してもカメラ対象は(0,0,0)のまま。切替前後の全2,039,824画素が一致。 |

修正前は正常なPTHの選択詳細に「日心 J2000 黄道 AU」と、単独のバイナリローダーが発行した「単位・原点・面・一般補間契約は未解決」が同時に出ていた。ブラウザの一覧説明と選択詳細で、ローダー段階だけの暫定メッセージを除き、位置評価器が判定した契約と現時点の時系・入力診断を表示するよう修正した。原記録と元ローダー診断は保持する。修正後の実画面で暫定メッセージの消失、PTHの補間／端点表示、PPIの未認定診断と描画抑止を確認した。モデル試験は Plus 95件・通常版65件、AppKit コントローラ試験62件が成功した。ローカル原画像と計測用入口は `local/verification/p4-spacecraft/` に保存している。
