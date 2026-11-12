# 検証記録

## 2026-11-11: 火星への連続降下中の地形更新

11月6日の修正（`215d9a2`）は画面外の地形を三角形上限に数えていた問題に対するもの。同じ日時での連続降下では、現行の描画経路で地形更新の停止は再現しなかった。飛行タイマー（公称30 Hz）の [`advanceFlightAtTime:`](vendor/mitaka/native/gui/src/SolarSystemNavigation.mm) が高度からカメラを更新して再描画を要求し、[`drawRect:`](vendor/mitaka/native/gui/src/SolarSystemView.mm) が [`refreshTerrain`](vendor/mitaka/native/gui/src/SolarTerrain.mm) を呼ぶ。[地形の世代管理](vendor/mitaka/native/gui/include/terrain_generation_coordinator.hpp)は計算中の要求を完了させ、その間の入力は最新の1件にまとめる。公開時は地形と計算元のカメラ・天体を組にし、描画側でも要求の一致を検査する。降下開始時の旧視点の破棄と、降下の各 tick を区別する。

既定の3秒降下を実タイマーとオフスクリーンの AppKit 描画で測定した（Apple M4、固定 JD 2451545、緯度・経度 0°、試験用の天体配置、テクスチャなし、各1回）。400×300 と 800×450 で着地前にそれぞれ7世代・6世代の火星地形を公開し、いずれも表示カメラと一致して地形との交点があった。800×450 では入力が基準球面上2 m に着いたのが開始3.112秒後、その高度の地形を公開したのが3.935秒後。途中の入力をすべて描くことや一定の応答時間は保証しない。

[実データ回帰](vendor/mitaka/native/gui/tests/test_terrain_real_generation.mm)を既存の `terrain-real-data-test` に追加した。方位45°・仰角−20°を保ち、火星の高度20 kmから2 mまで、試験時計で飛行を進めながら毎回160×100の地図を描画する。非同期計算は実装どおりに実行し、1 kmの上下でカメラと同じ世代の地形に有限の交点があること、着地後に最終カメラの地形へ到達することを検査する。今回の実行では途中12世代を観測した（17.5253 km、0.421462 kmを含む）。特定の公開回数や遅延時間は要求しない。一時ビルドで飛行中だけ `refreshTerrain` を抑止すると、同じ試験が途中の地形不足を検出して終了コード1になった。

地形ファイルはこの checkout では Git LFS のポインターだったため、同梱 Earth・Mars の LFS オブジェクトを一時的な `DATA_ROOT` に展開し、両方の SHA-256 が[出典記録](vendor/mitaka/native/core/TERRAIN_PROVENANCE.md)と一致することを確認した。実ファイルがある環境では `DATA_ROOT="$PWD/resources/data" make -C vendor/mitaka/native/gui terrain-real-data-test` で再実行できる。同ターゲット、`make build`、`make test`、`make data-test`、`make reference-test`、`make smoke`、`git lfs fsck` はいずれも成功。

固定日時の降下について描画スケジューラの変更を必要とする根拠は得られなかった。日時を連続変更する場合は、新しい日時に古い地形を重ねないよう計算を取り消すため、地形が間に合うまで基準球面になる。この制約は残る。元の操作の視点・負荷は不明で、実画面での操作感、旧 Plus との描画一致、他機種での速度は未検証。原本・依存・方針に変更なし。[今回の gate 検証コピー](temp_gates/2026-11-11-22-15-30/)。

## 2026-11-07: UI-07 同梱マニュアルの所在監査

別 PC との担当調整に従い、旧メニューが指定する PDF/CHM を調査したが、この checkout の resources には未収録だった。取得・再配布や任意 System.openDocument の実装は行わず、[所在監査](investigation/native-plus/manual-availability-audit.md)に制約と再開条件を記録した。文書のみの変更で、ビルド/テストは再実行せず親の LUA-03 の成功結果を継承する。方針原本・依存・データ・Rust文書は変更せず、[gate検証コピー](temp_gates/2026-11-07-03-14-14/)を記入した。

## 2026-11-07: P3 LUA-03 Lua 対話コンソール

独立ブランチ `codex/mitaka-lua-console`（基点 `84a6867`）で、複数行入力、式・文、結果と行番号付きエラー、履歴、取消を実装した。入力ごとに既存 helper の独立 Lua 環境を使い、権限・print・実行制限を維持する。履歴はメモリ内のみという仮定を画面に明記した。

`make build`、`make test`、`make data-test`、`make reference-test`、`make smoke` は終了コード0。実画面で正常入力・print・構文/実行エラー後の継続・履歴/下書き・取消を確認した。ダーク表示の文字色修正後、buildと専用UI29checks/実行回帰も成功した。旧版比較、Intel/macOS13実機、sanitizerは未実施。詳細・ログ・仮定・残課題は [LUA-03 検証記録](investigation/native-plus/lua-console-validation.md)、[gate 検証コピー](temp_gates/2026-11-07-03-02-25/) に記録した。

/simplifier-lai は同名skill不在で未実行。既存AppKit・Lua依存と差分を独立レビューし、新規依存・原本変更・Rust文書変更はない。方針とgateはコンソール入力の契約を追記した。push・他ブランチ統合・公開設定変更は行わない。

## 2026-11-07: P2 CAM-08 天体ブラウザの右クリック

天体ブラウザ検索結果の右クリック行を選択し、メニューから選択または中央表示を行う。元の基点 `a8b4a65` では対象試験 30 件と 5 種の make が成功している。統合基点は `cab9b90` であり、その検証結果は元の基点の結果と区別する。

統合基点では `make -j4 build`、`make -j4 test`、`make -j4 data-test`、`make -j4 reference-test`、`make smoke` は成功。全対象の統一階層と他ブラウザの右クリック、旧版との比較、実画面での対話確認は未完了。新規依存・方針原本への変更はない。[gate 検証コピー](temp_gates/2026-11-07-04-11-05/)に判定を記録した。

## 2026-11-07: P1-3 地形への着陸高度

選択データの地形を非同期に読み、着陸地点への動径と各 LOD の三角形との最大交点を求める。地形が基準球より高い場合はその最大交点の上 2 m を着陸目標とする。位置・倍率・データルートの変更や欠損・不正データでは古い高さを再利用せず、地形の取得が飛行の前後どちらに終わっても離陸の目標半径を一致させる。実データの地球・火星、Lua、倍率変更、移動の中断と地表モード終了を AppKit smoke で検証した。

基準球より低い地形では球面の上 2 m となる。また複数 LOD の最大高さを使うため、現在表示中の LOD より高い位置になる場合がある。地形の読込中は一時的に基準球を表示する。これらは未完了の制約であり、旧 Plus の動作・描画や手動 GUI との比較は未実施。

`make -j4 build`、`make -j4 test`、`make -j4 data-test`、`make -j4 reference-test`、`make -C vendor/mitaka/native/gui terrain-real-data-test`、`make smoke` は成功した。smoke は当初、地形取得のタイミングによって離陸の目標半径が変わるため 2 回失敗し、修正後の再実行で成功した。原本データ全件の再ハッシュは未実施。新規依存・方針原本への変更はなく、[gate 判定](temp_gates/2026-11-07-00-53-17/)を記録した。

## 2026-11-07: P1-3 地形の世代と時刻更新

地表から宇宙へ移行した後に日時を更新しても physical-space の状態を維持する。地球と火星の同梱・承認済み地形データを使い、同一日時の連続視点操作、リサイズ、日時変更時の基準球への切替と対応する新世代の公開、および欠損時の診断を検証した。非同期読み込みの間や連続日時変更時は基準球が表示される場合がある。旧 Plus との描画比較と手動画面操作は未実施。

`make -j4 build`、`make -j4 test`、`make -j4 data-test`、`make -j4 reference-test`、`make smoke`、`make -C vendor/mitaka/native/gui terrain-real-data-test` はすべて成功した。

## 2026-11-07: P1-2 地上の移動天体の視差

小天体と有効な PTH 探査機について、日心位置から同じ数値 JD における地球と観測地点の位置を差し引き、地平図の描画・選択・注視へ共通の測心位置を渡す。地球は球面・標高 0 と仮定する。実データの評価可能な小天体 10,839 件と探査機 14 件を 3 日時・3 地点で独立した計算と比較し、日周視差を検証した。

地球の扁平・標高、光行時間、大気差、時系の違いは補正しない。PPI の未確定形式は扱わない。実画面での操作と旧 Plus の比較は未実施。

`make -j4 build`、`make -j4 test`、`make -j4 data-test`、`make -j4 reference-test`、`make smoke` はすべて成功した。

## 2026-11-07: P1-1 遠方銀河の表示順と選択

preview と完成画像の描画順を SDSS/QSO、OurGalaxy の加算合成、HIP に揃えた。SDSS/QSO の投影位置が完全一致する点では距離の前後や出典にかかわらず、最後に描画される原行を選択する。visibility、複数出典、逆順、クリック位置を回帰試験する。

`make build`、`make test`、`make data-test`、`make reference-test`、`make smoke` は成功した。実データを使った SDSS の描画・選択・移動も smoke で通過した。同一画素に描かれても投影位置が異なる点、HIP と SDSS の重なり、加算・半透明合成に複数点が寄与する場合の選択は保証しない。全距離の実画面操作と旧 Plus の画像比較は未実施。

## 2026-11-06: P1-1 近傍銀河・球状星団の ID と対象半径

GC の原名と NBG の原コード・番号を選択情報に表示し、現在の出典内で一意に解決できる原 ID と名前で Lua 対象を往復できるようにした。NBG は `Galaxy.#N224` のような原 ID を受け入れ、既存の名前表と衝突する場合は曖昧として拒否する。名前表の変更・削除・重複時にも古い名前を別の天体として読み戻さない。ID はデータ交換後の恒久識別子ではない。点群へ近接位置から名前を付けない。

NBG の角直径を角半径へ変換する際の係数を修正し、対象半径は距離と角半径の積にした。これは [旧 Plus の静的解析](vendor/mitaka/investigation/native-plus/unit7/n16-galaxy-core-validation.md)と同じ小角近似で、旧版での実操作や浮動小数点丸めの完全一致は確認していない。不正・非有限・180°以上の直径は半径不明として扱う現行の制限を維持する。

`make build`、`make test`、`make data-test`、`make reference-test` は成功。GUI smoke の初回は、自動ロードがテスト用の銀河モデルを上書きして失敗した。fixture 設定中は読み込みを中断し、終了後に必要なら再開するよう修正した。再実行した `make smoke` は Lua からの GC・NBG 対象読み戻し、実 SDSS の描画・選択・移動、および月への移動を含めて成功した。実画面でのクリック操作と旧 Plus 比較は未実施。

## 2026-11-06: P1-1 天の川 preview の可視性

OurGalaxy の preview に完成描画と同じ距離フェードを適用し、画面外や非表示の点を選択しない。既存の完成描画に合わせて加算合成し、点を投影位置の中心へ描く。画面端の 1 倍・2 倍描画とフェード境界、不透明背景、選択を自動検証した。点の平滑化を preview 内で無効にしたため、端の見え方が変わり得る。旧 Plus の描画仕様・実画面との比較は未実施で、銀河の形状や外観全体の完成を意味しない。異なる奥行きや重なりによる選択と画素の不一致は残る。

最終変更後の `make build`、`make test`、`make data-test`、`make reference-test`、`make smoke` は成功した。ログは `/tmp/mitaka-04d-final-{build,test,data-test,reference-test,smoke}.log`。新規依存と方針原本の変更はない。[policy gate の検証コピー](temp_gates/2026-11-06-23-22-00/)に判定を記録した。原本データ全件の再ハッシュ、GUI での外観確認は未実施。`/simplifier-lai` は利用できず、類似の `simplify-lai` は LobbyAI 専用で対象外。P1-1 と第 4d 単位は部分実装のまま。

## 2026-11-07: P1-4 個別小惑星・外縁天体の位置と軌道

個別 a 指定楕円57本を位置・一周期軌道・GUI modelへ接続。旧 reader の静的根拠を別 PC と共有し、native double・全出典保持と旧 float 丸め・番号上書きとの差を記録した。明示 n、非楕円、37 byte は位置なし。極端 a の派生平均運動と37 byteの汎用評価迂回も拒否した。

`make build/test/data-test/reference-test/smoke`、専用5本の通常/実データ、core3本のASan/UBSan通常/実データは成功。実画面で日本語Ceresの独立出典・表示集合1件・軌道129標本・3D中心選択・+1日位置更新を確認。初回専用GUI試験のfixture ID不整合を修正して再検証した。旧実行比較・画素一致・物理時系は未確認。[監査](investigation/native-plus/minor-planet-individual-format-audit.md)、[検証記録](investigation/native-plus/minor-planet-individual-validation.md)、[gate](temp_gates/2026-11-07-03-59-05/)に詳細を記録。

原本57本は基点blobと一致。カメラ・地形・銀河・時刻実装、Rust関連Markdown、データ原本は未変更。方針とpreservation gateへ採用範囲を追記、新規依存なし、指定 `/simplifier-lai` は利用不可で独立レビューを実施。基点 `84a6867`、独立ブランチ `codex/mitaka-small-body-formats`。push・他作業ブランチへの統合は行わない。

## 2026-11-07: UI-04 描画品質ダイアログ

既存4項目の専用ダイアログを追加し、メニュー・Lua・保存状態の復元と共通設定を使用する。操作スタイルと全操作設定は未対応のまま。[実装範囲・仮定・検証結果](investigation/native-plus/renderer-options-validation.md)を参照。

## 2026-11-06: P1-1 遠方追従時のフレーム連続性

実 SDSS データの選択天体を追従し、1,000 AU と 1 pc を両方向にまたぐズームの各操作後に、表示要求のカメラ、選択 ID、追従状態、対象の投影中心を自動確認した。比較には pc 基準点に加え AU 残差、roll、軌道フレームを含め、それぞれ異なる古いフレームを拒否することも検査した。preview は対象を間引く場合があるため、各フレームで対象の画素表示までは検証していない。

`make build`、`make test`、`make data-test`、`make reference-test` は成功。`make smoke` は本単位の銀河追従を通過した後、月への連続飛行で失敗したが、単独再実行では成功した。原因は調査中。ログは `/tmp/mitaka-04c-{test,data-test,reference-test,smoke,smoke-retry}.log`。全距離の画像完成・背景や手動 GUI・旧 Plus 比較は未検証であり、P1-1 と第 4c 単位は部分実施のまま。既存の月への飛行 smoke は断続失敗が観測されており、原因は未確定である。

新規依存や方針原本の変更はない。`resources/` と `vendor/mitaka/sources/` に差分はないが原本全件の再ハッシュは未実施。[policy gate の検証コピー](temp_gates/2026-11-06-23-12-56/)に判定を記録した。`/simplifier-lai` は利用できず、類似 `simplify-lai` は LobbyAI 専用で対象外。

## 2026-11-06: P1-1 遠方対象付近の共有カメラ精度

遠方の対象を単一の AU 座標に丸めると、1 AU 距離での小さな pan が消えるため、pc の基準点と AU の差分を太陽系・銀河・共有カメラで保持する。投影・選択・描画要求の比較、Lua 対象移動、追従、拡散銀河描画にも同じ位置を伝える。差分が距離に比べ大きい場合は標準 C++ の FMA と加算誤差を用いて再基準化する。JSON v9 は任意の精密位置を追加し、既存の近似 AU `target` も残す。精密位置があれば優先し、なければ従来値を使う。不完全・非有限な精密値は全体適用前に拒否する。二つの double にも精度限界があり、極端な移動量と小距離の組合せで任意の微小移動を保証しない。

`make build`、`make test`、`make data-test`、`make reference-test`、`make smoke` は成功した。追加した実データ試験を含む最終 `make data-test` は GAL と QSO の各原行 0 を読み、1 AU 距離の描画画素・元の選択 ID・pan 往復を確認した。これは自動描画試験であり、実画面操作の確認ではない。カメラの極端な移動後の 1 point pan、共有カメラの最小距離での 3 種の姿勢と pan、セッション保存・復元、不正値、Lua 移動の中断・再指定、追従先の太陽系帰還を回帰試験で検証した。地形要求の一致判定にも姿勢と精密位置を追加し、残差だけが異なる場合の再生成を単体試験で検証した。最終変更前の smoke は月への連続飛行で失敗し、単独の再実行は成功した。失敗原因は未確定。ログは `/tmp/mitaka-precision-final-smoke.log`、`/tmp/mitaka-precision-final-smoke-retry.log` および最終変更後の `/tmp/mitaka-precision-terrain-{build,test,data-test,reference-test,smoke}.log`。

実画面でアプリ起動を確認したが、同梱 data フォルダを選択しても Open が有効にならず、その画面での遠方移動は確認できなかった。実操作時の描画収束、距離間の連続性、旧 Plus との比較は次の作業に残る。既存 smoke の表示カメラ比較は残差と roll を比較しないため、古い frame を誤認する可能性があり、次の連続性作業で検証する。P1-1 は部分実装のまま。

新規依存はなく、精密位置の方針を `IMPLEMENTATION_POLICY.md` と `policy_gates/shared_implementation.md` に追加した。`resources/` と `vendor/mitaka/sources/` に Git 差分はないが、原本全件の再照合はしていない。指定 `/simplifier-lai` は利用できず、類似の `simplify-lai` は LobbyAI 専用で対象外。[policy gate の検証コピー](temp_gates/2026-11-06-22-33-13/)に判定を記録した。

## 2026-11-06: P1-1 SDSS 銀河の eClass 配色

SDSS 銀河の `eClass` を視等級ではなく分類値として扱い、同梱の通常 Mitaka 1.3.1 の `mtk_galaxies.cpp` にある 5 分類と B−V 色を基に、preview と complete の両描画に配色を追加した。非有限の分類値を描画対象外とするのは現行実装の判断であり、旧 Plus の仕様と確認したものではない。QSO は従来の赤方偏移に基づく色を維持する。データの出典・原行 ID を保持し、座標から実在天体の名前を推測しない。通常版の色の根拠は `vendor/mitaka/sources/official/mitaka_source/Mitaka/mtk_galaxies.cpp` と `common/graphics/color.cpp`、データの解釈は [出典記録](vendor/mitaka/native/core/EXTENDED_CATALOG_PROVENANCE.md)を参照。

同梱 GAL 実データの 826,360 行は分類値が有限で、5 階級の行数は順に 55,622、542,126、139,256、62,694、26,662。これはデータ分布の確認であり、配色の現行 GUI 実画面や旧 Plus との一致の確認ではない。点が完全に重なる場合、描画では後の点が見え、既存の選択処理は先の点を選ぶため、表示と選択の不一致が未解消。色以外の点サイズ・測光・フェード・密度、および preview から完成描画への連続性の旧版比較も残る。GAL-03 と P1-1 は部分実装のまま。

最終変更後の `make build`、`make test`、`make data-test`、`make reference-test`、`make smoke` は成功した。途中の `make test` は追加テストのコンパイルエラーで失敗し、修正後の全体再実行で成功した。ログは `/tmp/mitaka-eclass-{build,test-rerun,data-test,reference-test,smoke}.log`。実画面で SDSS 実データの原行 1 の選択、座標と分類値を確認したが、約 1.69×10^11 pc の視点で画面は描画待ちの表示のままで、配色や全点描画完了は確認できなかった。描画開始時に状態ラベルが通知されない場合があり、ウィンドウ遮蔽中は要求を保留するため、この表示だけでは原因を特定できない。アプリの終了は終了操作による正常終了だった。

描画の限定性能測定は 800×600、1 倍、各条件ウォームアップ 1 回と測定 2 回。実データ約 93 万行では、変更前／変更後が yaw 0° で 7039・6989 ms／1608・1554 ms、yaw 90° で 4117・4103 ms／1291・1383 ms。一方、異なる色の 5 万点を同一画素へ交互に重ねる合成例は 1.317・1.222 ms／81.103・79.866 ms で、変更前は単色で出力が異なる。測定回数が少なく、実操作での負荷や並行処理の影響は未評価。

新規依存と方針原本の変更はない。`resources/` と `vendor/mitaka/sources/` に差分はないが、原本全件の再照合は行っていない。指定 `/simplifier-lai` は利用できず、類似の `simplify-lai` は LobbyAI 専用で対象外。[policy gate の検証コピー](temp_gates/2026-11-06-22-14-52/)に判定を記録した。変更ファイルと差分量を確認し、この単位を commit する。

## 2026-11-06: P1-1 天の川点群の個別選択

天の川の点を出典モデル内の群と原順 ordinal で識別し、描画中の preview / complete に対応した点を選択・注視追従できるようにした。preview の間引き、complete の座標変換と吸収、画面内判定を描画と揃える。距離と奥行き、群と原順で順位を決め、古い非同期結果は破棄する。点と既存天体名を結び付ける根拠はないため、名前を推測しない。選択は session v9 に保存しない。旧 Plus の選択操作・表示との一致は未確認であり、GAL-02 と P1-1 全体は部分実装のままである。[設計と制約](investigation/native-plus/our-galaxy-point-selection-design.md)。

最終変更後の `make build`、`make test`、`make data-test`、`make reference-test` は成功した。`make smoke` は初回に銀河関連の確認を通過した後、月への連続飛行テストで失敗した。実画面検証用プロセスを終了後の単独再実行は全体で成功したが、初回失敗の原因は未確定である。ログは `/tmp/mitaka-galaxy-final-{build,test,data-test,reference-test,smoke}.log` と `/tmp/mitaka-galaxy-final-smoke-retry.log`。実画面では実データの銀河ブラウザーまで到達したが、その後 CUA がタイムアウトしたため、点の選択・追従操作は確認できていない。

新規依存や方針原本の変更はない。今回 `resources/` と `vendor/mitaka/sources/` に Git 差分はないが、元データの全件再照合は実施していない。指定の `/simplifier-lai` は利用できず、類似の `simplify-lai` は LobbyAI 専用のため対象外。[policy gate の検証コピー](temp_gates/2026-11-06-21-44-55/)で判定した。変更ファイルと差分量を確認し、この作業単位を commit する。

## 2026-11-06: P1-1 地球地平図の視野角

地球地平図に `Camera.fov`、`Camera:setFovTo`、45° 復帰操作を追加した。旧資料の画角が縦・横、全角・半角のいずれかは確定できないため、縦方向の全画角と仮定する。設定範囲は有限な 0° 超 90° 以下であり、従来の起動時表示は 180° を返す。補間の時間省略は `Camera.duration` を使い、再指定時は現在値から開始する。地平図以外、投影遷移中の FOV 操作は拒否する。状態保存は小さな画角と従来の v9 倍率の復元に対応する。

投影・逆投影・描画と選択の整合、姿勢補間との同時実行、手動操作と状態復元などによる中断について試験を追加した。最終変更後の `make build`、`make test`、`make data-test`、`make reference-test`、`make smoke` は全て終了コード 0（主担当報告。ログは `/tmp/mitaka-fov-final4-{build,test,data-test,reference-test,smoke}.log`）。`make test` では地平線分 940,533、背景ビュー 461,593、状態 1,826 checks に成功。実画面では同梱データの HIP 117,956 件、地平図の表示と 45° 復帰を確認した（主担当報告）。

途中の `make test` で音声の準備完了または自動再生の一括判定が失敗したが、音声単体の再実行は 4 回とも成功し、最終全体試験も成功した。失敗原因は未確定。極小画角は描画上の計算下限を使い、混合投影や極付近、有限の評価予算到達時には未解決線分を省略するため、画素誤差と完全な線分表示は保証しない。旧 Plus との比較は未実施。非地球 3D 地表の FOV は未対応であり、P1-1 全体は部分実装のままとする。[設計と制約](investigation/native-plus/fov-projection-design.md)。

## 2026-11-06: P1-1 カメラ距離の時間補間（検証中）

Lua の `Camera.zoom` と同じ pc 単位で距離の線形 `setZoomTo`・対数 `setZoomLogTo` を追加し、省略時は `Camera.duration` を用いる。旧版の時間曲線は未確認のため、距離または距離の自然対数に対する等速補間を仮定した。無効な値の拒否、再指定と操作の中断、地上・地平図での拒否、既存の天体内部への進入防止を含む。詳細と未対応範囲は[優先順位表](investigation/native-plus/feature-priorities.md)と[機能対応表](vendor/mitaka/PLUS_FEATURE_MATRIX.md)を参照する。FOV は別の作業単位であり CAM-03 全体は部分対応のままとする。

別 bundle ID の一時コピーを使う実画面検証では、実データの太陽系 3D を開き、`Camera:setZoomTo(10 * UNIT_AU, 2)` を含む手作成 Lua をメニューから選択して「スクリプトを実行しました」と表示された。操作後の距離・画面の変化は CUA のタイムアウトにより未確認。表面画像は 0/11 の読込警告が出た。旧 Plus との比較は未実施。対象移動中のズーム競合を修正し、関連試験の 79 checks は成功した（主担当報告）。

最終変更後の `make build`、`make test`、`make data-test`、`make reference-test`、`make smoke` はいずれも終了コード 0（主担当報告）。途中の `make test` は追加テストの宣言エラーで失敗し、その後の試験は修正のため中断された。Git の変更範囲と差分を確認し、commit した。[policy gate 検証コピー](temp_gates/2026-11-06-20-33-32/)では全 gate を YES と判定した。指定 skill の利用不可と未確認事項は作業経過で報告した。

## 2026-11-06: 火星地表付近の地形描画

火星への降下時に地形が基準球面へ切り替わった原因は、画面外の区画も含む全区画のメッシュを三角形上限に加算していたことだった。同梱火星データで視点を基準半径の 1.01 倍に置く計算例では、約 1,582 万三角形となり描画側の上限 838 万を超える。公式同梱ソースの `vendor/mitaka/sources/official/mitaka_source/common/graphics/topograph.{h,cpp}` と `vendor/mitaka/native/core/TERRAIN_PROVENANCE.md` で形式を確認した。この上限は描画処理の制限であり、地形ファイルの形式上の上限ではない。

既存 Plus の `vendor/mitaka/native/gui` に、標高の全範囲を含む保守的な境界を使った画面外区画の除外を追加した。投影と同じ視野角を使い、除外の安全性を保証できない場合は従来どおり区画を処理する。データ形式、原本、LOD と安全上限は変更していない。新規依存もない。

地球・火星の実データを用いる Controller と描画の結合テストでは、火星の緯度・経度 0 度、基準球面から高度 2 m、方位 45 度、仰角 −20 度および +20 度、400×300 画素の両条件で地形との交点と基準球面との差を確認した。三角形数はそれぞれ 2,326,528 と 606,208。実操作時の正確な視点は記録されていないため、その操作の完全再現や GUI の手動再確認は未実施。連続移動中の地形更新の既知の制約も今回の対象外。

`make build`、`make test`、`make data-test`、`make reference-test`、`terrain-real-data-test` は成功した。地形の合成回帰では画面端や回転姿勢を含むカリング有無の全画素比較を実施した。全体テスト中に判明したスクリプト操作の列挙値不足、星座絵の地平表示における期待値の投影誤り、v9 セッションにおける省略可能項目の必須扱いを、各テスト側で修正した。[今回の policy gate 判定](temp_gates/2026-11-06-17-54-42/)を記録した。

## 2026-11-06: P1-5〜P1-8 の追加実装

選択中の惑星・月へ、近傍から時間指定で降下する機能を追加した。3D 地表、地球地平図、飛行中は観測位置を保って姿勢・ロールを設定でき、地球への降下時にもロールを引き継ぐ。`lookTo` の完了後の対象追尾と、登録地点の `Planet.Earth.<地点ID>` 指定・読み戻し、および地球上の地点間の時間指定移動を追加した。宇宙からの登録地点への自転追従を追加したが、実画面での日時変更・時間指定移動中の追従は未確認。継続追尾と地点間の経路は旧仕様未確認のため推測である。地球以外の地表から地球の地点への時間指定移動は未対応。

最終追加後の `make -j4 build` は成功した。途中の GUI 確認では、火星への時間指定降下後の地表、および地球地平図で `setEuler(10, 20, 30)` を設定し、`getEuler()` から同じ値を得た。地平図での地点移動は日本語設定で読み込まれない `Planet.Earth.Greenwich` を指定して停止し、正しい ID を使った再実行はファイル選択画面で Open が無効となり実行できなかった。地点移動、飛行中の姿勢設定、自転追従、`Other.SolarSystem`・`Other.LSS` の実画面確認と旧版との一致は未確認。[追加分の policy gate 判定](temp_gates/2026-11-06-17-00-55/)は全体試験未実施により検証 gate が NO。

地球以外の天体でも Lua の強制的な地表・宇宙切替、地表での方位・高度の設定と補間、太陽系天体や恒星などへの注視を扱えるようにした。`Other.M31`、`Other.M13`、`Other.M87` の対象指定と、対象選択時の `zoomMode` にも対応した。M87 をおとめ座銀河団の中心として扱うこと、半径からズーム距離を求める方法、遠方からの着陸位置などは旧版での動作を確認できていないため仮定である。

独立した銀河ブラウザーのカメラ、未解決の対象種別など、旧版との対応には残りがある。[優先順位表](investigation/native-plus/feature-priorities.md)と[機能対応表](vendor/mitaka/PLUS_FEATURE_MATRIX.md)に対応範囲を記載した。旧版との動作・描画一致は未確認。

`make -j4 build` は成功した。GUI から一時 Lua を一度実行し、`ZOOM_ALWAYS` で火星を選択した際の距離調整、火星地表への `forceMode`、方位 45 度・高度 20 度の設定と読み戻し、太陽への注視と地表・選択状態の維持を確認した。火星地形は `mars_topo.dat: terrain triangle limit exceeded` の警告が出て基準球面で表示されたため、地形表示は確認できていない。他天体、時間補間、宇宙への復帰は今回未確認。

ユーザーの指示に沿い、失敗注入を含む `make test` と全体の `make data-test`・`make reference-test` は実施していない。[今回の policy gate 判定](temp_gates/2026-11-06-16-32-34/)では検証 gate が NO であり、全 gate 通過ではない。新規ライブラリ依存はない。`/simplifier-lai` は利用可能な skill に存在せず、LobbyAI 専用の `simplify-lai` は適用対象外。地平図のロール保存に伴い、`IMPLEMENTATION_POLICY.md` と `policy_gates/shared_implementation.md` を更新した。

## 2026-11-05: P1-5〜P1-8 の途中実装

地球の地上・宇宙間の移動と Lua mode API、投影の補間、太陽系・銀河のロール、太陽系通常視点の姿勢 API、地平図の方位・高度設定と補間を追加した。Lua 対象と地平図の注視には、恒星の HIP 番号・英語名、一意に解決でき位置を評価できる小天体・探査機・衛星・球状星団、天の川銀河などを追加した。星座の正式英語名・略号による注視にも対応する。各項目の残りは[優先順位表](investigation/native-plus/feature-priorities.md)と[機能対応表](vendor/mitaka/PLUS_FEATURE_MATRIX.md)を参照する。P1-5〜P1-8 の全機能の完成や旧版との一致は主張しない。

近傍銀河の英語名も原本の名前表とカタログを照合して対象指定へ接続した。名前表の 66 名中 65 名は一意に位置を解決でき、M62 は対応レコードがない。Plus の NBG データで南天を表す 270〜360 度の赤緯を符号付きの赤緯に直す。旧実行ファイルの赤緯計算は `vendor/mitaka/investigation/native-plus/unit7/logs/n16-galaxy-core/plus-nbg-record.txt` の逆アセンブル記録を参照した。旧版の別名表との優先順位は未確認。

統合 `make -j4 build` は成功した。途中段階では既存の関連する地表移動・方位高度・姿勢・Lua・状態保存の確認も成功し、地平図の投影・風景などの関連試験も通過した。実アプリでは、Lua から姿勢を設定し、恒星名で対象を選び、地平図で方位・高度を指定して太陽へ注視する通常操作を確認した。修正後の地球での離陸と降下も画面で確認した。姿勢補間と手動操作の競合修正、追加した全対象の操作、旧版との描画一致や速度は未確認。

失敗注入を含む `make test` および全体の `make data-test`・`make reference-test` は今回実行していない。[今回の policy gate 判定](temp_gates/2026-11-05-21-27-47/)では検証 gate が NO で、全 gate 通過ではない。新規ライブラリ依存はない。`/simplifier-lai` は利用可能な skill に存在せず、LobbyAI 専用の `simplify-lai` は適用対象外。

## 2026-11-05: P1-1〜P1-4 の実装と確認状況

- **P1-1:** 太陽系、3D 恒星、天の川銀河、大規模構造を共有カメラで接続した。旧 Plus との座標・色・形状・操作の一致には未確認の項目が残る。
- **P1-2:** 地平図に彗星・小惑星・有効な PTH 探査機の描画、選択、日時追従、表示切替を接続した。地心近似を用い、視差・光行時間・大気差・時系変換は未補正。PPI と旧 Plus との比較は未対応・未確認。
- **P1-3:** 承認を得た国立天文台の別配布地形データを使い、地球・火星の地形表示を接続した。両データを旧 Plus が読み込み表示できることを確認したが、旧版との描画一致は未確認。月・水星の地形データは同梱しておらず、旧 Plus での提供自体も未確認。日時を高速に連続変更すると、時刻整合を保つため地形の代わりに基準球が表示される場合がある。
- **P1-4:** 36 byte 小惑星・TNO の数値 JD による一周期の軌道を描画し、離心近点角を等分して標本化する。丸めで時刻を区別できない場合は等時間に戻す。既定は非表示で、`selectedOnly` による表示集合への限定も可能。実データ全 8,451 軌道を使った局所試験と旧等時間方式の描画負荷測定を実施した。離心近点角の標本化後、隔離コピーの `make build`、`make test`、`make data-test`、`make reference-test` は成功した。実データでは 36 byte の先頭行の二時点と TNO 1 行の高離心率軌道を 9 視点で確認したが、全軌道・全視点の精度は保証しない。この変更後の GUI smoke・負荷測定と旧 Plus 比較は未実施。小天体の物理時系、旧版の軌道標本法と表示一致は未確認。37 byte 形式の旧 Plus での利用も未確認で、Mitaka++ の仕様と同一視しない。

小天体の位置・軌道の局所回帰試験は通常構成と ASan/UBSan 構成で通過した。描画負荷の測定条件と結果は[機能優先順位](investigation/native-plus/feature-priorities.md)を参照する。Intel Mac・macOS 13 の実機、複数物理ディスプレイ、旧 Plus との全画素一致は未確認。Mitaka++ の有用な機能の調査・採用は [Issue #1](https://github.com/mocho271828/Mitaka_plus/issues/1) で管理する。新規依存は追加していない。

P1-1〜P1-4 を含む `make build`、`make test`、`make data-test`、`make reference-test`、`make smoke` はすべて成功した。公式比較は CF96・自転・月・大気・食・銀河を含む。新規 clone でのビルド・単体テストと `git lfs fsck` も成功した。地球・火星の実データによる地形表示と、地球の連続 20 回の視点操作を確認した。全機能の旧版一致や Intel Mac・macOS 13 実機での動作を保証するものではない。

上記の P1 検証は Codex（主担当と作業担当サブエージェント）が実施し、対象コードは commit `c582d01` とする。追加テストは行わず、[今回の gate 判定](temp_gates/2026-11-05-20-10-00/)を既存の記録に基づいて確認した。

## 2026-11-05: UNIT8 表示半径の採用

Mitaka `73d3457969f8bcce88937492b66889a90b22d4bd` の表示半径と依存する UNIT8 の native 実装を `vendor/mitaka/` に取り込んだ。Plus 用のデータパスと同梱 Lua のオフラインビルドを維持した。表示半径の UI・Lua・描画・JSON v9 への接続に加え、依存する地形・銀河・時刻コードを含む。宇宙倍率変更の `KEEP_RADIUS`、`setScaleTo`、旧版との画素一致は未対応または未確認。

独立したビルドディレクトリでのクリーンビルドと、Plus データを使う `make build`、`make test`、`make data-test`、`make reference-test`、`make smoke` が成功。表示半径 controller 150 checks、session state 1,770 checks、Plus state 988 checks、実データ表示 192 checks が通過し、smoke は Lua の radius と session v9 を含む。元リポジトリの過去の sanitizer・x86 検証は今回の Plus 環境での再実行と区別する。

`resources/` と `vendor/mitaka/sources/` の開始時ファイル 885 件は作業後の SHA-256 が一致した。新規依存なし。`/simplifier-lai` は利用できず、LobbyAI 専用の類似 skill は対象外。方針と gate を更新し、[今回の gate 検証](temp_gates/2026-11-05-00-56-52/VALIDATION.md)を記録した。

## 2026-10-30: 風景・食と影・時間操作とローカルデータ基盤の採用

共通実装を `b901489c9b08a85742ff2d5a0ce1d9db522fe246` に固定した。fetch済みorigin/mainに存在し、submodule内はclean。風景、食の4設定と物理半径による影、旧Plusの時間step・連続再生、原地点ID、JSON v7、地形・銀河の読込と数値モデルを採用した。地形・銀河3D描画はこの単位に含めない。

独自追加を含むローカルPlusのdataを指定した `make build test data-test reference-test` は終了コード0。[統合ログ](verification/unit7-final-pin-tests.log)と[4ログのSHA-256](verification/unit7-SHA256SUMS)を保存した。公式比較はCF96 5,427、自転33,129、月12,108、大気12,606+792、食7,993成分が成功。submodule未取得、空・相対DATA_ROOTは[負例ログ](verification/unit7-negative.log)のとおり案内付き終了コード2で拒否する。

共通側の通常・ASan/UBSan・Rosetta x86_64のcore/GUI/controller、Plus full smoke 3構成、通常版full smoke、実データ、公式比較、新規cloneは[単位7記録](vendor/mitaka/investigation/native-plus/unit7/README.md)と[統合記録](vendor/mitaka/investigation/native-plus/unit7/logs/integration/README.md)を参照する。JSON v7はID・座標・出典・設定を全体検証し、通常再生・時計追従・旧Plus連続再生を停止して復元する。食は衛星マーク表示と独立、風景の画像失敗は他定義への差替えで隠さない。原本保全は16,365 files、6,622,642,667 bytes、465 symlinks、変更0。公式原本310ファイル一致。ラッパーではsanitizer・x86_64・full smokeを重複実行せず、採用SHAの結果を参照した。Intel/macOS13実機、複数画面、実OSの完全遮蔽通知、旧Plusとの全画素一致は未確認として残す。

[Mitaka](verification/unit7-source-private.log)と[Mitaka_plus](verification/unit7-private.log)は双方Private。データ/原本の複製登録、新規依存なし。既存Makefileに大気・食の公式比較を追加し、README、IMPLEMENTATION_POLICY、3 gateを更新した。exact `/simplifier-lai` は利用不可・未実行、類似skillはLobbyAI専用のため不適用。既存依存・差分・登録範囲を手動レビューし、[3 gate / 39条件](temp_gates/2026-10-30-02-12-29/VALIDATION.md)をYESとした。Git状態・差分量・diff --checkを確認しcommit/pushする。

## 2026-10-30: 星座絵・恒星名と明るさ・地球層・大気の採用

共通実装を `d1c361a750b2a1d71d71c423194954c4eade7a81` に固定した。fetch済みorigin/mainに存在し、submodule内はclean。地平図の天の川、全天図・地平図のCAB星座絵、恒星名のHIP選択と明るさ補間、地球の雲・夜景、大気のモードと強度、観測地点の読込規則、JSON v6を採用した。

独自追加を含むローカルPlusのdataを指定し、`make build test data-test reference-test` は終了コード0。[統合ログ](verification/unit6-final-pin-tests.log)と[4ログのSHA-256](verification/unit6-SHA256SUMS)を保存した。公式比較はCF96 5,427、自転33,129、月12,108成分が成功。submodule未取得、空・相対DATA_ROOTも[負例ログ](verification/unit6-negative.log)のとおり案内付き終了コード2で拒否する。

共通側の通常・ASan/UBSan・Rosetta x86_64のcore/GUI/controller、Plus full smoke 3構成、通常版full smoke、実データ、公式比較、新規cloneは[単位6記録](vendor/mitaka/investigation/native-plus/unit6/README.md)を参照する。JSON v6は恒星名HIP、明るさ、地球層、大気を全体検証し、不正入力で正常状態や明るさ補間を失わない。原本保全は16,365 files、6,622,642,667 bytes、465 symlinks、変更0。公式原本310ファイル一致。ラッパーではsanitizer・x86_64・full smokeを重複実行せず、採用SHAの結果を参照した。Intel/macOS13実機、複数画面、実OSの完全遮蔽通知、旧Plusとの全画素一致は未確認として残す。

[Mitaka](verification/unit6-source-private.log)と[Mitaka_plus](verification/unit6-private.log)は双方Private。データ/原本の複製登録、新規依存、Makefile変更なし。README、IMPLEMENTATION_POLICY、3 gateを更新した。exact `/simplifier-lai` は利用不可・未実行、類似skillはLobbyAI専用のため不適用。既存依存・差分・登録範囲を手動レビューし、[3 gate / 37条件](temp_gates/2026-10-30-00-31-57/VALIDATION.md)をYESとした。Git状態・差分量・diff --checkを確認しcommit/pushする。

## 2026-10-29: 小天体・衛星集合、探査機、星座集合の採用

共通実装を `5dd3409f8c551ff94666d84f4504f6f92f7047c7` に固定した。fetch後のorigin/mainに存在し、submodule内はclean。小天体・衛星の表示集合と軌道、PTH探査機の一覧・位置・軌跡、星座略号ごとの表示、JSON v5を採用した。

独自追加を含むローカルPlusのdataを指定し、`make build test data-test reference-test` は終了コード0。[統合ログ](verification/unit5-final-pin-tests.log)と[ログのSHA-256](verification/unit5-SHA256SUMS)を保存した。公式比較はCF96 5,427、自転33,129、月12,108成分が成功。submodule未取得、空・相対DATA_ROOTも[負例ログ](verification/unit5-negative.log)のとおり案内付き終了コード2で拒否する。

共通側の通常・ASan/UBSan・Rosetta x86_64のtest/script-test/controller-test、Plus/通常版のfull smoke、新規clone、JSON v5の正常復元と不正ID/出典不一致/上限超過の全体拒否は[単位5記録](vendor/mitaka/investigation/native-plus/unit5/README.md)を参照する。原本保全は16,365 files、6,622,642,667 bytes、465 symlinks、変更0。ラッパーではsanitizer・x86_64・full smokeを重複実行せず、採用SHAの結果を参照した。Intel/macOS13実機、複数画面、実OSの完全遮蔽通知、旧Plusとの全画素一致は確認済みと扱わない。

[Mitaka](verification/unit5-source-private.log)と[Mitaka_plus](verification/unit5-private.log)は双方Private。データ/原本の複製登録、新規依存、Makefile変更なし。README、IMPLEMENTATION_POLICY、3 gateを更新した。exact `/simplifier-lai` は利用不可・未実行、類似skillはLobbyAI専用のため不適用。既存依存・差分・登録範囲を手動レビューし、[3 gate / 35条件](temp_gates/2026-10-29-23-05-13/VALIDATION.md)をYESとした。Git状態・差分量・diff --checkを確認しcommit/pushする。

## 2026-10-29: 衛星表示・描画品質・全画面・信頼したローカル HTML の採用

共通実装を `002adcf663fd5005e14ac86c343a3ec7e56fa706` に固定した。fetch 後の `origin/main` に存在し、submodule 内の未保存差分がないことを確認した。追加衛星の表示・検索・日時追従、描画品質 4 項目、非同期全画面/About、信頼したローカル HTML の実クリックからの Lua、JSON v4 を採用した。

`DATA_ROOT` に独自追加を含むローカル Plus の `data` を指定し、`make build test data-test reference-test` が終了コード 0 で完了した。[統合ログ](verification/unit4-final-pin-tests.log) と [5 ログの SHA-256](verification/unit4-SHA256SUMS) を保存した。衛星 340 行を保持し 330 行の位置を評価した。renderer 64、HTML policy 80、session 964、satellite controller 38、solar satellite 99、controlled fullscreen 31、controlled occlusion 46 checks が成功した。公式比較は CF96 5,427、自転 33,129、月 12,108 成分が成功した。

submodule 未取得、空の DATA_ROOT、相対 DATA_ROOT はすべて案内付き終了コード 2 で停止した。[負例ログ](verification/unit4-negative.log) に記録する。通常データ経路は `data` を GUI、その親を core へ渡しており、Makefile の既存契約を変更していない。

共通側の通常・ASan/UBSan・Rosetta x86_64 の全 test / script-test / controller-test / Plus full smoke、通常版データと smoke、新規 clone、原本保全の結果は [共通単位4記録](vendor/mitaka/investigation/native-plus/unit4/README.md) を参照する。原本保全は 16,365 files、6,622,642,667 bytes、465 symlinks、変更 0。ラッパーでは sanitizer・x86_64・full smoke・HTML 実ブラウザ結合を重複実行せず、採用 SHA の記録を参照した。個別 HTML host 試験で使った通常 arm64 helper と、共通 script-test の各構成 helper は区別されている。

controlled occlusion は試験値による停止・復帰条件の検証であり、実 OS の完全遮蔽通知は未通過のまま残る。共通側の全画面実 OS 試験の成功を、複数画面や全操作の網羅と扱わない。Intel Mac と macOS 13 の実機確認も未実施。SAN timer、月 FMA、JSON 丸め、HTML 通常リンクの途中失敗と修正は共通側の記録を保持し、最終成功で隠さない。

[Mitaka](verification/unit4-source-private.log) と [Mitaka_plus](verification/unit4-private.log) の双方が Private であることを再確認した。共通コード・原本・天文データの複製登録や新規依存はない。README、IMPLEMENTATION_POLICY.md、3 gate を JSON v4 と衛星・HTML・全画面の契約に更新した。物理時系・精度期間、衛星表面/自転・個体別可視性、探査機 GUI、旧 Lua の全 API は未対応のまま明記する。

正確な `/simplifier-lai` は利用できず未実行。類似の `simplify-lai` は LobbyAI 専用のため対象外。既存依存、Makefile、gitlink、差分、登録範囲を手動レビューした。[今回の gate](temp_gates/2026-10-29-21-36-01/VALIDATION.md) は 3 gate / 26 条件を YES とした。Git 状態・変更ファイル・差分量と `git diff --check` を確認し、この採用を commit / push する。

## 2026-10-29: 表示設定・座標格子・カレンダーの更新

共通実装を `cf4fcbfe5447adf554e5bca0b0caf5ae5f529505` に固定した。Mitaka の `origin/main` に存在し、submodule 自体に未保存の差分がないことを確認した。

`DATA_ROOT` に独自追加を含むローカル Plus の `data` を指定し、`make build test data-test reference-test` の終了コード 0 を確認した。記録は [verification/unit3-final-pin-tests.log](verification/unit3-final-pin-tests.log)、ログの SHA-256 は [verification/unit3-SHA256SUMS](verification/unit3-SHA256SUMS)。小天体 19,475 行を保持し、そのうち 2,388 行の位置を評価した。カタログ一覧は 1,059,477 行を保持し、500 行ずつ表示する契約を確認した。公式計算との比較は CF96 5,427 成分、自転 33,129 成分、月 12,108 成分が成功した。

最初の呼び出しでは `DATA_ROOT` の指定がなく、ビルドとテストの成功後、`check-data` が案内を出して終了コード 2 で停止した。[初回ログ](verification/unit3-initial-invocation.log) を保持し、指定を加えて全ターゲットを再実行した。submodule 未取得と相対 `DATA_ROOT` も、[異常系ログ](verification/unit3-negative.log) のとおり案内付きエラーで停止する。

投影ウィンドウのテストは、試験ウィンドウに遮蔽状態を注入してタイマー条件を検証するもので、46 checks が成功した。実 OS の完全遮蔽通知は共通側で未通過のまま保持しており、この結果を実 OS 通知の成功とは扱わない。共通側の通常・ASan/UBSan・Rosetta x86_64 のコントローラ試験、4 回の GUI smoke、原本保全の結果と制約は [共通側の単位3記録](vendor/mitaka/investigation/native-plus/unit3/README.md) を参照。ラッパーでは sanitizer・x86_64・smoke を重複実行せず、Intel Mac と macOS 13 の実機確認も未実施である。

両 GitHub リポジトリが Private であることを再確認した。共通コードの複製、新規依存、原本・天文データの登録はない。`IMPLEMENTATION_POLICY.md` と対応 gate に、明示的に信頼したローカル HTML のみ Lua 呼び出しを許可する方針を追記した。HTML ブラウザの実装完了は主張しない。

正確な名前の `/simplifier-lai` は利用できず未実行。類似名の `simplify-lai` は LobbyAI 専用のため対象外である。既存 Makefile と Git submodule の利用、差分、依存と登録範囲を手動レビューした。[今回の gate 記録](temp_gates/2026-10-29-20-13-42/VALIDATION.md) は 3 gate と 22 条件を YES とし、不合格条件の未チェックは該当なしを示す。Git 状態・変更ファイル・差分量を確認し、この更新を commit / push する。

## 2026-10-29: ローカル Plus データ対応の更新

共通実装を `ae300e1e396c5ed0e6eb5129ad8a6f0069489597` に固定した。Mitaka の `origin/main` に存在し、submodule 自体に未保存の差分がないことを確認した。

この固定コミットで `make build test data-test reference-test` が終了コード 0。記録は [verification/unit2-final-pin-tests.log](verification/unit2-final-pin-tests.log)。Plus 原本を指定し、独自追加を含む小天体・画像一覧・天の川背景、既存カタログ、GUI と Lua コントローラを検証した。公式比較は CF96 5,427 成分、自転 33,129 成分、月 12,108 成分が成功した。

共通側の sanitizer、Rosetta x86_64、GUI smoke、画面操作、原本保全は [共通側の検証記録](vendor/mitaka/investigation/native-plus/unit2/README.md) を参照。Intel Mac と macOS 13 の実機確認は未実施。

両 GitHub リポジトリが Private であることを再確認した。新規依存やコードの複製はなく、画像・動画は共通実装の ImageIO / AVKit を使う。`/simplifier-lai` は利用できず未実行。類似名の `simplify-lai` は LobbyAI 専用のため対象外。依存・差分・登録範囲を手動レビューした。

今回の変更は共通参照、README、検証記録のみであり、既存の方針を変更していない。3 gate の検証コピーへ判定を記録し、Git 状態・変更ファイル・差分量を確認して commit する。

確認日: 2026-10-29。macOS 26.6.2 / arm64。

## 固定参照

`vendor/mitaka` は Private リポジトリ `https://github.com/mocho271828/Mitaka.git` の Git submodule。
採用コミットは `94c9af3d968fcdb9591e4d3efcf2992954293f01`。
このコミットは GitHub の `main` に push 済みであることを fetch で確認した。
初回取得した `67c4779c879454763c30e5e5858011c4eacc96d9` との差分は作業規則・案内・検証記録だけで、`native/` と `sources/` に差分はない。
共通コードの複製、新規の実行時依存、既存データの登録は行っていない。

## 実行した検証

GitHub から取得した共通コードで初回ビルドとコア・GUI・コントローラのテストが成功した。
最終コミットへ参照を更新した後にも、以下をすべて実行して終了コード 0 を確認した。

```sh
make build test data-test reference-test
```

`DATA_ROOT` はローカルに保持した Mitaka_plus の `data` を明示した。
空白を含む絶対パスの受け渡し、既存データの読み込み、11 枚の画像、全着陸対象、CF96・自転・月の公式計算との比較が成功した。
記録は [verification/final-pin-tests.log](verification/final-pin-tests.log)。
submodule 未取得とデータ指定不足で案内付きエラーになることも確認した。

共通実装の AppKit smoke test、元ファイルの保全照合、依存と登録範囲の独立レビューは [共通リポジトリの検証記録](vendor/mitaka/investigation/repository-organization/VALIDATION.md) を参照。
実装コードは変更していないため、sanitizer は今回再実行せず既存の結果を保持した。
Intel Mac、macOS 13 実機、全操作の人手による再確認は今回行っていない。

## 方針と変更管理

両 GitHub リポジトリの `isPrivate: true` と `visibility: PRIVATE` を確認した。
`IMPLEMENTATION_POLICY.md` と 3 つの policy gate に共通参照、登録範囲、データ保全、検証手順を記録した。
gate は `temp_gates/` にコピーし、判定条件をチェックして YES とした。
不合格条件の未チェックは該当なしを表す。

正確な名前の `/simplifier-lai` は提供されておらず未実行。
類似の `simplify-lai` は非 LobbyAI プロジェクトを適用対象外としているため使用していない。
既存 Makefile と Git submodule の利用、不要な独自実装がないことを独立レビューで確認した。
登録前に Git 状態・追加ファイル・差分量と `git diff --check` を確認し、初回ファイルと固定参照を commit / push する。

## 2026-11-07: P1-4 37 byte の契約隔離

`mp2.dat`・`TNO2.dat` の 37 byte 行は原行と flag を保持し、フレームと時系を外から設定しても汎用位置評価で位置を返さない。隔離コピーの回帰試験で部分末尾の入力拒否と他ファイルの継続読み込み、汎用軌道の位置・線分なしを確認した。実データでは 37 byte 8,510 行を検証し、catalog 46,432 checks、orbit 17,352 checks が成功した。旧 Plus がこれらのファイルを使用したか、flag や位置計算の契約は未確認であり、Mitaka++ の解釈を同一視しない。

同一 checkout で `make -j4 build`, `make test`, `make data-test`, `make reference-test` は成功。`make smoke` は飛行中断後のカメラ不変条件で失敗し、原因を調査中。手動 GUI と旧 Plus 比較は未実施。新規依存や原データの変更はない。

## 2026-11-07: P1-1 全天背景の連続投影

地表と宇宙で全天画像を共有カメラから投影し、太陽から 1,000〜2,700 pc の距離範囲で既存 3D 銀河モデルに合わせて暫定的に減衰する。実画像 3 種と姿勢・日時を含む 256 条件で従来の地平背景と画素比較し、最大差は 8 bit で 1。操作中は背景画像の最大寸法を 512 px、停止後は 1,024 px とする。別環境の測定では前者約 7.4〜7.8 ms、後者約 30〜31 ms であり、マウス操作以外の連続更新には負荷が残る。実画面での視覚確認、全距離での描画収束と旧 Plus 比較は未実施。原データと依存は変更していない。

同一 checkout の `make -j4 build`、`make -j4 test`、`make -j4 data-test`、`make -j4 reference-test` は成功。`make smoke` は飛行中断後のカメラ不変検査で失敗した。非同期地形反映との競合が独立に再現され、検査条件の分離を後続で適用する。

## 2026-11-07: P1-3 負標高の地形と着陸

地形高の符号を保持し、基準球より低い地表からの描画・深度・選択と地表星空を整合させた。実地形では地球 (31.5°, 135°) 約 −1.43853 km、火星 (31.5°, 35.5°) 約 −0.590033 km の地点と倍率 1・2・20 を検査し、地形とカメラおよび中心深度・選択の 2 m 以内の整合を確認した。各 LOD の最大高さを使用するため表示中 LOD より浮く場合がある。地形待ち・失敗中に視点が基準球内にある場合は不透明黒を代替表示し、その深度を選択にも使う。地形の穴は透明のまま、基準球内の雲・大気は省略する。手動 GUI、旧 Plus との表示比較と表示遅延は未検証。

飛行中断の smoke は、停止後の非同期地形更新によって独立した検査のカメラ完全一致が破られ得るため、中断・再開試験中だけ地形を退避し、継続飛行試験前に戻す。実地形・中断・倍率変更は別の地形専用 smoke でも検査する。過去の同 smoke の失敗がこの競合だったかは値が記録されておらず未確定。

同一 checkout で `make -j4 build`、`make -j4 test`、`make -j4 data-test`、`make -j4 reference-test`、`make -C vendor/mitaka/native/gui terrain-real-data-test`、`make smoke` は成功。負標高で強制的に通常宇宙へ切り替えた後、地表に戻る操作では復元が失敗することを別環境で確認し、修正中。

## 2026-11-07: P1-1 地上・全天図から銀河への遷移

主画面で Plus 銀河データの読込を明示すると、成功後に全天図または地平図から太陽系 3D の銀河全景へ遷移する。読込中に表示モードが変わると自動遷移を抑止し、取消・失敗・欠損時はそれまでのデータとモードを保持する。既に太陽系 3D の場合は読込のみ行い、カメラは移動しない。別の隔離ビルドで自動 AppKit smoke が成功し、実画面でも両モードからの遷移、点群、および球状星団 139 件・近傍銀河 2,371 件の読込表示を確認した。点群の分類ごとの実描画と旧 Plus の外観比較は未確認。描画点数の診断は他の銀河カタログも含む合計である。新規依存や原データ変更はない。

同一 checkout の `make -j4 build`、`make -j4 test`、`make -j4 data-test`、`make -j4 reference-test`、`make smoke` は成功。銀河ホスト smoke は 76 checks、実データの全天図・地平図からの遷移も成功した。

## 2026-11-07: P1-4 36 byte の軌道標本化

36 byte の小惑星・TNO は、一周期を離心近点角で等分して近点付近の描画誤差を低減する。標本時刻が浮動小数点で重複する場合は等時間標本へ戻す。実データ全 8,451 軌道、1,090,179 標本を含む 1,099,457 checks と、描画試験 256 checks が隔離環境で成功。TNO の高離心率 1 軌道を 9 視点で調べたが、全軌道・全視点での精度は保証しない。極端に大きな平均近点角で位置と標本時刻の位相がずれる問題も回帰試験で修正したが、極端値の時刻変化には浮動小数点の精度限界が残る。旧 Plus の標本化・時系・画面との一致と、この変更後の描画負荷は未確認。新規依存や原データ変更はない。

同一 checkout の `make -j6 build`、`make -j6 test`、`make -j6 data-test`、`make -j6 reference-test`、`make smoke` は成功。軌道描画の手動 GUI および旧 Plus 比較は未実施。

## 2026-11-07: P1-5 負標高地点の宇宙往復

負標高の地球・火星から宇宙に出て同じ地点へ戻る際、保存した地形高を再利用し、地形の再取得中も基準球への一時的な跳ねを防ぐ。天体・データルート・倍率が一致し、地点の単位球上の差が 2e-11 以下の場合に同一地点とみなす。極付近は緯度を atan2 と hypot で復元し、経度が不定でも位置の一致を扱う。異なる地点には古い地形高を流用しない。隔離環境の AppKit 統合試験では実データの通常復帰、強制復帰、取得待ちと地点変更を確認した。地球以外の地平図、風景・遮蔽の遷移、手動 GUI と旧 Plus との比較は未検証。新規依存・原データ・全体方針の変更はない。

同一 checkout の `make -j6 build`、`make -j6 test`、`make -j6 data-test`、`make -j6 reference-test`、`make -C vendor/mitaka/native/gui terrain-real-data-test`、`make smoke` は成功。

## 2026-11-07: P1-6・P1-7 姿勢と方位・高度の再指定

有限な quaternion は最大成分で先に縮尺を揃えてから正規化し、最大値および非正規化浮動小数点でも有限な姿勢を得る。ゼロ・無限大・NaN は拒否する。方位・高度の補間または対象追尾中に再指定された場合は、直近の timer tick ではなく現在時刻まで姿勢を更新してから新たな補間を始める。隔離環境の姿勢テスト、Lua script 試験および全体ビルドは成功した。全天図と独立銀河ブラウザの姿勢 API、旧 Plus との比較は未対応・未実施。新規依存・原データ・全体方針の変更はない。

同一 checkout の `make -j6 build`、`make -j6 test`、`make -j6 data-test`、`make -j6 reference-test`、`make -C vendor/mitaka/native/gui plus-camera-orientation-test`、`make smoke` は成功。手動 GUI と旧 Plus 比較は未実施。

## 2026-11-07: P1-7 地表の天頂・天底操作

非地球 3D 地表のドラッグ時の高度制限を ±89° から API と同じ ±90° に変更した。端点で横方向にドラッグしても視点位置と中心方向を保持し、縦操作で再び端点から戻せることをテストする。旧 Plus との比較と実画面操作は未実施。新規依存・原データ・全体方針の変更はない。

同一 checkout の `make -j6 build`、`make -j6 test`、`make -j6 data-test`、`make -j6 reference-test`、`make smoke` は成功。

## 2026-11-07: P1-8 GUI 選択対象の Lua 読み戻し

GUI で選択された小惑星・TNO・彗星・探査機について、選択時刻に位置を評価でき、一意に解決して元の選択へ戻せる ASCII の名前または番号を Camera.target へ返す。探査機は既存の Name・DisplayName に加え KEY と NAME フィールドも照合する。曖昧な名前、位置を評価できない行、ASCII 表記を取得できない行などは空にし、別の天体に結び付けない。4,095 byte 上限と埋め込み NUL、同梱データ、Lua の往復を隔離環境で検査した。非 ASCII 名のみの自動読み戻しや旧 Plus との比較は未対応・未実施。新規依存・原データ・全体方針の変更はない。

同一 checkout の `make -j6 build`、`make -j6 test`、`make -j6 data-test`、`make -j6 reference-test`、`make -C vendor/mitaka/native/gui script-object-lua-test`、`make smoke` は成功。手動 GUI と旧 Plus 比較は未実施。

## 2026-11-07: P1-1 遠方点群の重なり選択

SDSS/QSO の preview の矩形と完成画像の円の内部では、異なる投影位置でも後から描画された原行を選ぶ。形状外は従来の近傍選択を維持する。モデルの原 ID は変更しない。テストで異なる位置の重なり、矩形・円の内外と既存の選択を確認した。アンチエイリアス境界、HIP・天の川など別レイヤーとの重なり、実画面と旧 Plus 比較は未確認。新規依存・原データ・全体方針の変更はない。

同一 checkout の `make -j6 build`、`make -j6 test`、`make -j6 data-test`、`make -j6 reference-test`、`make smoke` は成功。

## 2026-11-07: P1-1 銀河点群の異種レイヤー選択

HIP、天の川モデル、SDSS/QSO が重なるとき、選択候補の描画形状に入る場合は描画順に従い後のレイヤーを選ぶ。天の川は加算合成で複数点が同時に見えるため、後描き優先は仮定である。preview と完成画像、HIP 非表示、天の川と SDSS の重なりを隔離テストで検証した。天の川レイヤー内部の候補抽出、アンチエイリアス境界、実画面と旧 Plus 比較は未確認。新規依存・原データ・全体方針の変更はない。

同一 checkout の `make -j6 build`、`make -j6 test`、`make -j6 data-test`、`make -j6 reference-test`、`make smoke` は成功。

## 2026-11-07: P1-5 非地球の 3D 地表の星空

観測座標を同一フレームの任意天体姿勢から構築し、火星・月などの 3D 地表でも恒星・星座の投影をカメラに揃える。姿勢は右手正規直交基底に限定する。恒星は J2000 無限遠方向で、視差や大気差分は含まない。火星と月の複数時刻、極、負標高、ロール、および地球の変換回帰を隔離試験で確認した。非地球地表の恒星クリック、専用 HorizonView、地表以外の天体の完全対応、実画面と旧 Plus 比較は未確認または未実装。新規依存・原データ・全体方針の変更はない。

同一 checkout の `make -j6 build`、`make -j6 test`、`make -j6 data-test`、`make -j6 reference-test`、`make smoke` は成功。

初回の全体試験では新規テストのループ変数コピー警告が `-Werror` によりエラーとなったため参照に修正し、上記の全検証を再実行した。

## 2026-11-07: P1-8 地球・火星・月の登録地点

有効な地点ファイル内の地球・火星・月の ID を Lua から指定・読み戻しでき、宇宙からの自転追従と同一天体地表間の時間指定移動に対応した。地表から別天体への直接移動は拒否し、地球の観測地点を維持する。大円補間は旧版未確認の仮定。同梱日本語設定では利用者用ファイルが既定ファイルに優先し、地球の 4 地点のみ有効である。旧版バイナリの解析記録も同じ優先関係を示す。火星・月は有効ファイルに定義がある場合に利用できる。実データ、Lua と実 AppController の往復、同一天体移動、途中再指定と異天体の拒否を試験した。実 GUI・旧版比較、GUI 地点編集と他天体着陸の確認は未実施。原データ・依存・全体方針の変更はない。

同一 checkout の `make -j6 build`、`make -j6 test`、`make -j6 data-test`、`make -j6 reference-test`、`make smoke` は成功。

## 2026-11-07: P1-5 非地球地表の恒星・星座選択

火星・月などの 3D 地表で、描画された恒星と星座の線・境界を選択できる。描画済みフレームの可視設定と地形・基準球の遮蔽を使い、恒星選択時は以前の天体・地点選択や追尾を解除する。空白・星座選択でも古い選択を解除し、Lua は恒星の HIP を返し、未選択・星座では空とする。実データと AppController・Lua による選択状態、地形遮蔽、表示設定を試験した。星座名・絵のクリック、他の前景ラベル・記号による遮蔽、独立した非地球 HorizonView、星座の Lua 読み戻し、手動 GUI と旧 Plus 比較は未対応または未実施。新規依存・原データ・全体方針の変更はない。

同一 checkout の `make -j6 build`、`make -j6 test`、`make -j6 data-test`、`make -j6 reference-test`、`make smoke` は成功。

## 2026-11-07: P1-1 非地球地表の視野角

火星・月などの静止 3D 地表で `Camera.fov` と `setFovTo`、45° 復帰を利用でき、縦全画角を射影・逆射影、地形・背景・銀河、恒星・星座の描画と選択で共有する。移動・地形読込・姿勢や地点の再指定でも画角を維持し、地球の地平図への遷移では透視投影側に引き継ぐ。旧版未確認のため縦方向の全角と画角維持は仮定である。補間と中断、極端な値、描画・選択、実データの移動を試験した。地表位置を含むセッション復元、非地球地表の手動 GUI と旧 Plus 比較は未対応または未実施。新規依存・原データ・全体方針の変更はない。

同一 checkout の `make -j6 build`、`make -j6 test`、`make -j6 data-test`、`make -j6 reference-test`、`make -j6 smoke` は成功。

## 2026-11-07: P1-1 天の川同一レイヤーの重なり選択

天の川モデルの同一レイヤー内で、描画形状が重なる点の選択を描画順に揃える。preview の矩形と完成画像の円を区別し、透明な点と形状外は従来の候補規則を維持する。点の元データと識別子は変更しない。隔離環境では実データの renderer と overlay を検証し、5 種の make が成功した。

統合後の checkout では `make -j6 build`、`make -j6 test`、`make -j6 data-test`、`make -j6 reference-test` が成功。`make -j6 smoke` は Lua アニメーションの途中値を検査する `host.lua:21` の assertion で失敗し、原因は未確定のため再検証が必要。手動 GUI と旧 Plus 比較も未実施。新規依存・原データ・全体方針の変更はない。

## 2026-11-07: P1-2 地平風景による選択遮蔽

AppKit の HorizonView において、小天体・探査機の選択を不透明な地平風景の背後で抑止する。透明・半透明、画像欠損、非表示と黒い地面 fallback は選択可能。補間境界では 4×4 画素がすべて完全不透明のときだけ選択を抑止するという仮定を採った。クリック位置に応じた判定を透明・不透明の両側で検証した。旧 Plus の挙動、実画面における補間境界の完全一致と手動操作は未確認であり、OBJ-15 は部分実装。原データ、依存、全体方針の変更はない。

基点 `815b362` の隔離 checkout で `make -j4 build`、`make -j6 test`、`make -j6 data-test`、`make -j4 reference-test`、`make smoke` は成功した。HorizonView は実データで 148 checks、Earth landscape は 2608 checks。隔離 checkout の LFS 実体が未展開のため、同じリポジトリの共有 checkout にある `resources/data` を `DATA_ROOT` に読み取り専用で指定した。

統合後の checkout では `make -j6 build`、`make -j6 test`、`make -j6 data-test`、`make -j6 reference-test`、`make -j6 smoke` が成功。手動 GUI は未実施である。

天の川同一レイヤーの重なり選択についても、地平風景の変更を重ねた統合 checkout で smoke が成功した。先行する統合状態の初回失敗の原因は引き続き未確定である。

## 2026-11-07: P1-3 基準球外縁の描画と選択

地形待ち・欠損時に描画する基準球の選択位置を、不透明判定と同じ描画画素の中心に揃える。外縁では同じ画素内でも解析上の球との交差が反転するが、その場合も表示された画素に基づき選択する。基準球内外の両方向を含む `solar terrain: 76 checks PASS` を確認した。実画面操作と旧 Plus との比較は未実施。新規依存、原データおよび全体方針の変更はない。

隔離 worktree にて `make -j4 build`、`make -j4 test`、`make -j4 data-test`、`make -j4 reference-test` が成功。地球・火星の LFS 実体は主 worktree の `resources/data` を `DATA_ROOT` に指定して読み取り専用で使用した。`make smoke` も成功。

統合検証: 親 `62bbc36` に P1-3 の `98c4f90` を適用し、FOV 変更を含む隔離統合状態で `make -j4 build`、`make -j4 test`、`make -j4 data-test`、`make -j4 reference-test` が成功。`solar terrain: 91 checks PASS` にて 45°・60°・75°・90° の球外縁で描画と選択の一致を確認。`make smoke` は初回に飛行完了の待機で失敗し、再試行は成功した。失敗の原因は未確定。

共有 checkout では、地平風景の選択遮蔽を含む親 `a5be624` に統合し、`make -j6 build`、`make -j6 test`、`make -j6 data-test`、`make -j6 reference-test`、`make -j6 smoke` が成功した。

## 2026-11-07: P1-2 地平風景で遮蔽された候補の選択

地平風景の不透明画素で候補天体の中心が隠れる場合、透明な近傍をクリックしても選ばない。小天体・探査機・恒星・惑星と拡大惑星を対象とし、既存の半透明・4×4 画素の補間境界判定を維持する。中心が遮蔽されていれば記号の一部が見える場合も選択しない仮定とした。小天体と探査機が重なる場合の選択順位、および隠れた候補を除いた近くの可視候補の選択を実ビューで検証。回帰試験は修正前に失敗し、修正後に拡大惑星の 8 px 超の fallback を含め 165 checks 成功。旧 Plus 比較と手動 GUI は未実施。原データ・依存・全体方針の変更はない。

独立作業の親は `09196de`。隔離 worktree で `make -j4 build`、`make -j4 test`、`make -j4 data-test`、`make -j4 reference-test` が成功。その後、実装を変えず拡大惑星の回帰試験を追加し、対象の HorizonView 試験を再実行した。LFS 実体は共有 checkout の `resources/data` を読み取り専用の `DATA_ROOT` に指定した。`make smoke` は各 AppKit smoke の一部が成功した後、`flight did not complete` で失敗。原因は未確定で再検証が必要。
### P1-8 地表星座の Lua 読み戻し（独立作業）

`35a32c7` 上で、実データの非地球地表における星座選択から `Camera.target` の読み戻し、`Camera:look` への受け渡し、選択解除、未対応 setter による選択保持を `script-place-controller-test` で確認した。モデル不一致は空として扱う。`make build`、`make test`、`make data-test`、`make reference-test` は成功。`make smoke` も成功したが、地表星座をクリックして Lua で読み戻す専用の実画面操作は含まない。旧 Plus 比較、星座の `Camera.target` への指定・時間指定移動は未対応または未検証。

## 2026-11-07: P1-6 Lua 姿勢の精度と銀河表示への伝達

`Camera:getOrient()` の読み戻しで内部 quaternion を単精度に丸めず、内部の倍精度を保つ。Lua の任意姿勢を補間途中に再指定し、読み戻しと銀河 overlay の表示済みフレームの基底を照合する smoke を追加した。旧 Plus との精度や動作の比較、手動 GUI による画面確認は未実施。新規依存・原データ・全体方針の変更はない。

基点 `f27914c` の隔離 checkout で `make -j4 build`、`make -j4 test`、`make -j4 data-test`、`make -j4 reference-test`、`make -C vendor/mitaka/native/gui plus-camera-orientation-test`、`make -C vendor/mitaka/native/gui script-test` が成功。LFS 実体が隔離 checkout に揃わないため、データ検証では共有 checkout の `resources/data` を `DATA_ROOT` に指定し、読み取り専用で使用した。同じ `DATA_ROOT` を用いた `make smoke` も成功し、Lua の読み戻しと銀河 overlay の表示済みフレームの基底を確認した。

## 2026-11-07: 飛行 smoke の完了待機

再開後の飛行完了を最大 8 秒、同じ run loop のタイマーで待つ。成功には飛行の停止、地表状態、既存の完了通知、有限な期待半径をすべて要求し、時間空白による中断や半径不一致を成功扱いしない。失敗時は経過時間、飛行・地表状態、通知、実際と期待の距離を出力する。飛行本体の 1 秒の安全閾値は変更しない。従来の間欠的な失敗は原因が特定できておらず、待機変更で解決したとはまだ判断できない。

隔離 worktree、基点 `35a32c7`、共有 checkout の `resources/data` を読み取り専用に指定して `make -j4 build`、`make -j4 test`、`make -j4 data-test`、`make -j4 reference-test` は成功。`make -j4 smoke` も成功し、実タイマーで飛行中断・再開・完了と、目標半径への到達を確認した。`make test` には AppKit のウィンドウを表示する検査も含まれる。故意の時間空白を実タイマーで注入する試験と、旧 Plus 比較は未実施。新規依存・原データ・全体方針の変更はない。

統合 checkout の `a862f53` で `make -j6 build`、`make -j6 test`、`make -j6 data-test`、`make -j6 reference-test`、`make -j6 smoke` がすべて成功。地平風景の候補遮蔽、地形読み込みの中断、地表星座の Lua 読み戻し、姿勢精度、飛行テスト改善を含む統合状態で確認した。旧 Plus の手動比較と地表星座の実マウス操作は未実施。

## 2026-11-07: P1-2 地球の楕円体観測位置（OBJ-15）

地平図の小天体・探査機について、地球の観測位置を測地緯度、標高 0、既存の赤道半径と WGS84 扁平率から計算し、描画・選択・注視と Lua の対象視点で共用する。地平風景と地形の基準は従来の球面であり、標高・地形、屈折、光行時間、物理的時系は考慮しない。旧 Plus との一致は未検証である。

基点 `a862f53` の隔離 worktree で、独立計算による赤道・極・中緯度・経度・日時の境界と不正緯度、小天体 10,839 件と PTH 14 件の実データ、AppKit ビューの描画画素・クリック選択・注視・Lua 対象視点を確認した。`make -j2 build`、`make -j2 test`（horizon objects 115 checks）、`make -j2 data-test`（HorizonView 173 checks）、`make -j2 reference-test`、`make -j2 smoke` は成功した。初回 `data-test` は GUI 資源の調整のためコンパイル中に中断し、実行枠確保後に再実行して成功した。LFS 実体が隔離 checkout に揃わないため、共有 checkout の `resources/data` を `DATA_ROOT` に指定して読み取り専用で用いた。smoke は OBJ-15 専用の手動操作ではない。実画面の手動操作と旧 Plus 比較は未実施。新規依存、原データ、リポジトリ全体方針の変更はない。

## 2026-11-07: P2 CAM-07 選択モードの統合

`Targets.selectMode` で全天図・地平図・宇宙図の選択を無効・ホバー・クリックに切り替える。定数値は旧版未確認の仮定である。地表 3D の恒星・星座も同じ選択イベントを通る。銀河の非同期選択はモード変更、表示領域外への移動、ビュー退出で失効する。地平風景の遮蔽判定はクリックとホバーで共通に使う。新規依存・原データ・全体方針の変更はない。

統合基点 `a862f53`。`make build`、`make test`、`make data-test`、`make reference-test`、`make smoke` は成功。隔離 checkout の LFS 実体が不足するため、実データ試験には共有 checkout の `resources/data` を読み取り専用で指定した。ホバー時の地平風景遮蔽と銀河の未完了選択の失効を回帰試験で確認した。初回の追加テストは fixture のコンパイル不備で失敗し、修正後に再実行して成功した。既存の P1-8 は地表で選択済みの恒星・星座を Lua から読み戻す試験を含むが、実マウスによる地表選択から Lua までの通し検証ではない。座標指定 API、旧 Plus 比較、実画面の対話操作は未対応または未実施。

統合 checkout の `cab9b90` に、測地緯度 45 度の近距離天体をホバーで選択・注視し、表示位置と一致することを確認する回帰試験を追加した。共有 checkout で `make -j6 build`、`make -j6 test`、`make -j6 data-test`、`make -j6 reference-test`、`make -j6 smoke` がすべて成功した。旧 Plus との比較と実マウスによる手動操作は未実施。

## 2026-11-07: P1-4 個別軌道形式の統合

別 Mac の `3c10fcbe`（親 `84a6867`）を基点 `cab9b90` へ統合し、既存の離心近点角標本化・37 byte 拒否と両立させた。個別 a 指定楕円の小惑星・外縁天体の位置、表示集合、選択と一周期軌道を扱う。36 byte と個別形式の両方について高離心率・大きな平均近点角を回帰検証した。地上の実データでは個別形式の可視天体を選び、地平図の実クリックと注視を検証した（HorizonView 201 checks）。この追加試験は描画画素を比較していない。

隔離 worktree で `make -j2 build`、`make -j2 test`、`make -j2 data-test`、`make -j2 reference-test`、`make -j2 smoke` はすべて成功。LFS 実体を共有 checkout の `resources/data` から読み取り専用で指定した。別 Mac の実画面確認は [記録](investigation/native-plus/minor-planet-individual-validation.md) を参照する。統合後の専用手動 GUI、旧 Plus との実行・画素比較、物理的時系と観測精度、37 byte・明示 n・非楕円の位置は未確認または未対応。原データ・旧環境は変更せず、新規依存なし。既存の C++ evaluator と標本化を使用する。`/simplifier-lai` は提供されておらず未実行。[gate 判定](temp_gates/2026-11-07-04-16-05/)を記録した。

共有 checkout の `9b5537a` に統合した状態でも、`make -j6 build`、`make -j6 test`、`make -j6 data-test`、`make -j6 reference-test`、`make -j6 smoke` がすべて成功した。Rust 移行文書の並行編集は index に含めず保持した。

## 2026-11-07: 小天体一覧の評価候補数

一覧の「位置計算対応」を「位置評価候補（未対応を含む）」に変更し、候補数に未対応形式が含まれることを明示した。明示 n、放物軌道、37 byte の候補が評価対象となっても位置計算済みと誤認されないことをモデルと controller の回帰試験で確認した。共有 checkout で `make -j6 build`、`make -j6 test`、`make -j6 data-test`、`make -j6 reference-test`、`make -j6 smoke` がすべて成功。旧 Plus 比較と専用の手動 GUI 確認は未実施。新規依存、原データ、全体方針の変更はない。[gate 判定](temp_gates/2026-11-07-04-30-00/)を記録した。

共有 checkout の `1427dfe` に CAM-08 のカタログ一覧を統合し、`make -j4 build`、`make -j4 test`、`make -j4 data-test`、`make -j4 reference-test`、`make -j4 smoke` がすべて成功した。[gate 判定](temp_gates/2026-11-07-04-39-00/)を記録した。旧 Plus 比較、専用の手動 GUI 確認、他ブラウザと共通階層は未実施または未対応。

## 2026-11-07: P1-4 個別小天体の明示平均運動

個別 Asteroid / TNObject の楕円軌道で、有限の `a > 0` と `n > 0` の両指定を受け付け、明示 `n` を位置と一周期軌道に使用する。`n` がなければ既存どおり `a` から導出する。`n` のみ、非楕円、37 byte は対応しない。不正な `n` は診断し、外部で組み立てたレコードの明示値と軌道値の不一致も拒否する。旧 Plus 実行版との比較、物理的時系、画面・数値の一致は未検証。

基点 `1427dfe` の隔離 worktree で、loader の原文保持と正常・不正値、独立した円軌道の位置と周期を合成データで検証した。`test_small_body_catalog` 436 checks、`test_minor_planet_position` 91,022 checks、`test_minor_planet_orbit_path` 1,641 checks、`make build`、`make reference-test` は成功。Foundation の model 合成回帰は 20,151 と 74 checks、共有 checkout の原データを読み取り専用で指定した model 回帰は 59,036 と 1,145,458 checks ともに成功。model の合成例は手構築 record であり、loader から画面までの通し検証ではない。GUI 実行枠確保後、同じ隔離 worktree で `make -j4 test`、共有 checkout の原データを読み取り専用に指定した `make -j4 data-test`、`make -j4 smoke` がすべて成功。明示 n 専用の手動 GUI 操作は未実施。新規依存・原データの変更はない。小天体の判定条件を `IMPLEMENTATION_POLICY.md` と preservation gate に反映した。`/simplifier-lai` は LobbyAI 専用であり利用不可。[gate 判定](temp_gates/2026-11-07-04-38-49/)を記録。並行作業で追加された Rust 移行の gate は含まず、統合先で再判定する。

共有 checkout の `8f2e3fb` に統合した状態でも `make -j4 build`、`make -j4 test`、`make -j4 data-test`、`make -j4 reference-test`、`make -j4 smoke` はすべて成功した。[gate 判定](temp_gates/2026-11-07-04-50-00/)を記録した。Rust 移行関連の並行編集は保持し、コミットには小天体方針の変更だけを含める。

## 2026-11-07: P2 時刻の整数秒往復と再入

JD の量子化と地方時オフセットの計算誤差を考慮し、誤差幅内の整数秒について UTC・地方時・文字列表現と各成分 setter の読み戻しを一致させる。誤差幅より外の小数秒は切り捨てる仮定を採り、分・日・年境界、閏日、範囲端および複数の時差を回帰試験で確認した。Lua 成分の読み戻しを同じ setter に渡しても追従が解除されず、JD の保存復元も同値を保持する。停止通知の同期 callback が再生を再開した場合はその再生を維持し、時計追従を再開した場合は二重開始を避ける。旧 Plus の小数秒境界・時計追従再入の挙動、夏時間と UTC/UT1/TT/TDB 変換、手動 GUI は未確認。原データ・依存・全体方針の変更はない。

原コミット `9098140` の基点 `815b362` における検証では、隔離 worktree で `make -j6 build`、`make -j6 test`、`make -j6 data-test`、`make -j6 reference-test`、`make smoke` は成功。通常・データ・参照試験は元 checkout の同梱 `DATA_ROOT`、smoke は当該 worktree で Git LFS により復元した同梱データを使用した。時刻暦は 14,443 checks、状態復元は 1,878 checks、PlaybackController は AppKit の再入回帰を含み成功した。

統合基点 `eb913ea` では、停止 callback が時計追従や時刻補間を再開した場合、先行する再生要求で上書きしない回帰を追加した。`make -j2 build`、`make -j2 test`、`make -j2 data-test`、`make -j2 reference-test`、`make -j2 smoke` はすべて成功。時刻暦は 14,443 checks、状態復元は 1,900 checks。独立 checkout の LFS 実体不足のため、共有 checkout の `resources/data` を `DATA_ROOT` に読み取り専用で指定した。`configureWithJulianDate` と `setSimulationRate` における停止通知の再入時の状態整合性は当時未修正で、下記の追加単位で対処した。旧 Plus の比較と時刻専用の実画面手動操作は未実施。依存とリポジトリ全体方針の変更はなく、既存の C++ 標準ライブラリと PlaybackController を使用する。`/simplifier-lai` は利用できず、LobbyAI 専用の `simplify-lai` は本件に適用されない。[gate 判定](temp_gates/2026-11-07-04-35-13/)を記録した。

## 2026-11-07: P2 時刻設定と速度変更の停止通知再入

新しい日時・範囲・有効状態を停止通知より先に設定し、通知内の再設定・追従・再生・補間を古い操作で上書きしない。速度要求は停止状態の通知世代とは別に管理し、同値を含む再指定を優先しつつ `didStop` と速度・方向の選択表示を整合させる。GUI の順方向・逆方向・実時間再生と Lua の速度設定は、速度変更が再入で置換された場合に古い再生要求を続けない。Lua の戻り値は従来どおり維持する。

基点 `966aac1` の隔離 worktree で対象 PlaybackController AppKit 回帰、`make -j2 build`、`make -j2 test`、`make -j2 data-test`、`make -j2 reference-test`、`make -j2 smoke` が成功。実データは共有 checkout の同梱 `DATA_ROOT` を読み取り専用で参照した。回帰は新旧設定の再入、無効設定、再生・追従・補間、速度の同値／異値再指定、適用失敗、実際の速度・方向 UI action と停止通知を対象とする。通常の Lua 時刻操作は smoke で通過したが、Lua 経由で callback が再入する経路は未試験。旧 Plus の再入時仕様との比較と時刻専用の手動 GUI 検証は未実施。依存追加、原データ、リポジトリ全体方針の変更はない。`/simplifier-lai` は利用できず、LobbyAI 専用 `simplify-lai` は本件に適用されない。[gate 判定](temp_gates/2026-11-07-04-40-45/)を記録した。

共有 checkout の `a59e2ad` に時刻関連の両変更を統合した状態でも、`make -j4 build`、`make -j4 test`、`make -j4 data-test`、`make -j4 reference-test`、`make -j4 smoke` はすべて成功した。[gate 判定](temp_gates/2026-11-07-04-54-00/)を記録した。旧 Plus 比較、Lua 経由の callback 再入、時刻専用の手動 GUI は未実施。

## 2026-11-07: P1-1 拡張天体の描画・選択と後続 P1 の検証

統合基点は `c626ae4`。GC の半光度半径と NBG の距離・角直径から求めた半径を円盤へ投影し、完成画像・プレビュー・選択・表示判定で共通形状を使う。中心が画面外でも可視の円盤を表示・選択する。Quartz に渡せない巨大円は画面内の矩形群へ近似し、選択にも同じ結果を使う。取消で途中結果を破棄し、微小 viewport の画素数切上げもクリップ基準に含める。分割予算後の解析円との画素誤差、画像 atlas・姿勢と旧 Plus の外観一致は保証しない。[設計と残件](investigation/native-plus/galaxy-extended-shape-design.md)を参照。

最終の形状試験は合成 193 checks、同梱データ 933,718 行で 3,735,071 checks、renderer は 201,064 checks が成功した。実データ精度試験は SDSS GAL/QSO の原行 0 に加え、GC の原行 138・NBG の原行 2,370 を含む全カタログを保持し、1 AU 接近・画面外への pan と復帰・1x/2x の描画画素と原 ID の選択を確認した。

P1-5 の星座絵・文字の地形遮蔽は既存実装で成立していたため、製品コードは変更せず回帰を追加した。実データの CAB と星座ラベルを SolarSystemView で描画し、火星・月、ロール 0/37°、透明・全面・部分の人工深度による遮蔽を確認した。月の実地形データは使用していない。既存の地球・火星の連続地形要求、時刻整合、resize、欠損データ診断を含む `test_terrain_real_generation` が成功した。この専用試験は通常の `make data-test` とは別に実行した。

P1-8 では、補間完了後も追尾中の対象から `lookTo` を再指定した際に、古い姿勢を開始点に使う不具合を修正した。現在時刻まで追尾を更新してから開始点を取得する。火星・月の地表で、日付変更後の星座への再注視、開始・中間・終了、時間省略、不正入力の状態保持、観測地点の保持、手動姿勢変更による追尾停止を Lua controller 回帰で確認した。星座への移動と `Targets.select` 座標指定は、距離・原点・単位等を推定せず、ユーザー指定により旧版の実動作確認まで保留する。

AppKit overlay の専用回帰も成功した。通常円・中心が画面外の円・半径 1e12/1e18 point の巨大円について、アンチエイリアスを無効にした内部・外部標本と非同期 pick を preview/complete、1x/2x で照合した。画素格子とずらした巨大円では、分割予算後の矩形形状と実画素が一致し、元の解析円とは異なる画素を各 mode/scale で選び、選択が描画に従うことを確認した。部分被覆や端画素の完全一致を保証する試験ではない。単独実行は 14.75 秒、最大 RSS 327,909,376 bytes。初期の追加 fixture では実ビューと異なる上下方向、NBG 半径の途中 float 丸め、境界標本不足で失敗し、fixture を修正して再実行した。実データ精度試験は 0.19 秒、最大 RSS 120,799,232 bytes。これらはテストプロセス全体の測定で、ウィンドウ操作時の FPS ではない。

最終統合状態で `make -j6 build`、`make -j6 test`、`make -j6 data-test`、`make -j6 smoke` がすべて成功した。`make -j6 reference-test` も同じ作業単位で GUI 修正前に成功し、その後の core・データ変更はない。公式比較は CF96 5,427 件、自転 33,129 件、月 12,108 件、大気の単一散乱 12,606 件・多重散乱 792 件、食 7,993 件を含む。同梱 `resources/data` を読み取り専用で利用した。新規依存、原データ、リポジトリ全体方針の変更はない。既存の C++ 標準ライブラリ、AppKit/CoreGraphics を使用する。`/simplifier-lai` は利用できず、LobbyAI 専用の `simplify-lai` は本件に適用されない。[gate 判定](temp_gates/2026-11-07-05-25-22/)を記録した。

旧 Plus の実動作比較と手動 GUI の全距離操作は未実施であり、今回の自動試験だけでは旧版の外観・移動契約の一致を確定できない。星座への移動と座標指定は前記のユーザー判断に従って保留する。別チャットで編集中の Rust 移行文書・元 gate・既存検証コピーは変更せず、本変更の commit に含めない。今回の検証は現 Mac 版を対象とし、Rust 移行や 3 OS 対応の完了を示すものではない。

## 2026-11-07: CAM-08 各ブラウザの右クリック操作

基点は `d7bae2c`。小天体・衛星・探査機ブラウザに右クリックメニューを追加し、既存ボタンと同じ「選択・診断を表示」「選択して3Dの中心へ」を呼び出す。メニューを開く際はクリックした1行だけを選択し、操作を確定するまで callback を実行しない。未評価・未解決の行と同名の別出典を保持し、位置評価と中心化可否は既存の選択処理に委譲する。

既存の天体ブラウザも含め、メニューを開いた時点の検索世代と原本 index（天体ブラウザでは種類も含む）を保持する。実行時に現在の選択と照合し、検索・出典変更・ページ切替・再読込後に残るメニューを別対象へ適用しない。4ブラウザの実装と回帰を分担し、共有 checkout に統合した。

リポジトリ全体の方針、新規依存、原データの変更はない。既存の AppKit と C++ の検索モデル・選択 callback を利用する。`/simplifier-lai` は利用できず、利用可能な `simplify-lai` は LobbyAI 専用のため適用しない。機能表と優先順位表を更新し、CAM-08 は部分対応のままとする。全対象の統一階層、ジャンプ・向き変更・地上追従を分ける操作、旧 Plus との実動作比較は今回の対象外。手動のメニュー操作は未確認で、自動試験による旧版一致を主張しない。

別チャットの Rust 移行文書・元 gate・既存の検証コピーを保持し、今回の commit には含めない。本変更は移行 A0 より前の Mac 版への機能追加・修正であり、Rust の移行実装は未着手。Windows・Linux の動作は検証していない。

macOS 26.6.2 / arm64、Apple clang 21.0.0、C++17 と Objective-C ARC、`-Wall -Wextra -Wpedantic -Werror` で、最終実装の `make -j6 build`、`make -j6 test`、`make -j6 data-test` が成功した。4ブラウザの controller 回帰は小天体81件、衛星69件、探査機62件、天体47件、合計259件。実際の AppKit `menuForEvent:` と action dispatch を使い、クリック行・同名別出典・未解決行・空白・選択変更・検索・再読込・ページ切替を検証した。既存テストを含む件数であり、259件すべてが今回の追加ではない。

`make -j6 reference-test` も成功した。CF96 5,427件、自転33,129件、月12,108件、大気の単一散乱12,606件・多重散乱792件、食7,993件、天の川22比較を含む。同梱 `resources/data` を読み取り専用で利用した。実装者とは別の担当が差分と文書を確認し、追加の修正指摘はなかった。Rust 関連4文書と既存 gate 記録269ファイルの SHA-256 は作業前の値と一致した。

`make -j6 smoke` も成功し、Lua・実データ選択・描画・JSON v9 復元・地形着陸・連続飛行まで通過した。ログにある date presentation の injected failure は既存の異常系試験によるもの。[gate 判定](temp_gates/2026-11-07-05-44-21/)に4件の YES と未実施範囲を記録した。今回は既存 checkout での検証であり、クリーン環境の新設や旧 Plus の操作比較は行っていない。
