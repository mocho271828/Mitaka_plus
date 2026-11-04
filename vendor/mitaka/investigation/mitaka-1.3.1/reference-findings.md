# Mitaka macOS 参照実装の静的調査

調査日: 2026-10-29 (JST). 対象は非公式 [yoshikaz1228/Mitaka-macOS](https://github.com/yoshikaz1228/Mitaka-macOS) の commit `ab63d81723a9261b663c8ab1283de2e7607f1094`. 公式原本は `/Users/kota/mitaka/sources/official/mitaka_source`, 参照実装は `/Users/kota/mitaka/sources/reference/Mitaka-macOS`. この調査では両ツリーを編集せず, ビルドやテストを実行していない.

## 結論

この参照実装は, SwiftUI の画面, C ABI の接続, 9 天体の概略軌道表示を短期間で確認する出発点として有用である. 公式 Mitaka 全体の macOS 移植が完了したものではない. アプリがビルドするのは Swift 4 ファイルと独立した 144 行の C++ コアであり, 保存された公式ソース 310 ファイルはビルド対象に入っていない. [ビルド対象](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac.xcodeproj/project.pbxproj:150), [Upstream の扱い](/Users/kota/mitaka/sources/reference/Mitaka-macOS/Upstream/README.md:3)

そのまま長期基盤として採用するより, 画面・ビルド設定・C ABI の構成を参考にし, 天文計算の契約と精度検証, 実データの導入, 描画基盤を別々に評価するのが妥当である. SceneKit は Apple が maintenance mode としているため, 本格移植の描画実装をそこへ追加し続ける判断には制約がある. [Apple WWDC25, Bring your SceneKit project to RealityKit](https://developer.apple.com/videos/play/wwdc2025/288/)

## 公式原本との照合

参照 repo は yuk7/mitaka のミラーから回収したソースを保存したと説明している. 今回, 公式配布 ZIP から取得した 1.3.1 と `Upstream/mitaka-1.3.1` の全ファイルを相対パスと SHA-256 で照合したところ, **310 / 310 ファイルがバイト単位で一致**した. 片側だけのファイル 0, 内容差異 0. ミラーの説明だけでなく, 公式原本との一致を直接確認できた. [照合結果](/tmp/mitaka-131-upstream-comparison.json), [参照 repo の由来説明](/Users/kota/mitaka/sources/reference/Mitaka-macOS/Upstream/README.md:7)

照合元は [公式 1.3.1 ソース ZIP](https://4d2u.nao.ac.jp/wp-content/uploads/mitaka/software/mitaka_source_131.zip). 公式原本の [Readme.txt](/Users/kota/mitaka/sources/official/mitaka_source/Readme.txt:2) は version 1.3.1 / 2016-03-04 と明記する. この一致は 1.3.1 ソースについての結果であり, 手元の Windows 版 1.7.4a との機能・データ一致や, Mitaka Plus の変更取り込みを示すものではない.

## 実際に移植された天文計算

| 項目 | 参照実装 | 公式原本との関係 |
| --- | --- | --- |
| 天体・軌道表 | 水星〜海王星と冥王星の 9 件. 元期 JD 2452640.5. | 公式 `plnt_oe` の軌道要素を保持. UI 用の英日名・半径も同じレコードへ格納. [参照 Core:39,58](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/Core/MitakaCore.cpp:58), [公式:74](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_planet_position.cpp:74) |
| 平均近点角の更新 | `n = 0.985607669 / a^1.5`, 元期からの経過日数を使う. | 公式の平均軌道要素初期化と同じ係数. 保存される `periodYears` は計算には使用しない. [参照:88](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/Core/MitakaCore.cpp:88), [公式:247](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_planet_position.cpp:247) |
| Kepler 方程式 | Newton 反復による楕円軌道計算, 最大 100 回, 収束閾値 1e-10. | 公式 `calc_elliptical_orbit` を基に書き直したもの. 公式の閾値 1e-8, 未収束時ゼロベクトル, 反復中の sin/cos の扱いとは異なる. コードの完全コピーではない. [参照:75](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/Core/MitakaCore.cpp:75), [公式:48](/Users/kota/mitaka/sources/official/mitaka_source/common/astro/cele_mech.cpp:48) |
| 軌道面から 3D 座標への変換 | 昇交点黄経・軌道傾斜角・近日点引数による回転を直接展開. AU の座標を返す. | 公式は `orbital_elements` の回転行列を経由し, 惑星位置格納時に AU→pc へ変換する. 接続時には単位の違いを明示する必要がある. [参照:96](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/Core/MitakaCore.cpp:96), [公式回転:69](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_orbital_element.cpp:69), [公式格納:293](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_planet_position.cpp:293) |
| Unix time→Julian date | `unixTime / 86400 + 2440587.5` の 1 式. | Foundation の `Date` から呼ぶ新しい小さな変換. 公式の日付機能全体を移植したものではない. [参照 Core:142](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/Core/MitakaCore.cpp:142), [AppModel:67](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/AppModel.swift:67) |

公式は CF96 の適用範囲内では CF96 と軌跡データを用い, 範囲外で平均軌道要素へフォールバックする. 参照実装はこのうち平均軌道要素に相当する経路だけを持つ. **「公式と同じ惑星位置計算」と一括して扱わず, 簡易経路の移植と位置づける必要がある.** [公式分岐:258](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_planet_position.cpp:258)

未移植の例は CF96, 太陽の軌跡, 金星・冥王星の個別軌跡, 惑星速度, 月・衛星, 地球月/冥王星カロン系の重心補正, 接触軌道要素の更新, 双曲線軌道である. 根拠は [公式惑星・衛星更新:123](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_planet_position.cpp:123), [CF96/軌跡読み込み:181](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_planet_position.cpp:181), [速度・接触軌道:284](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_planet_position.cpp:284), [双曲線軌道:84](/Users/kota/mitaka/sources/official/mitaka_source/common/astro/cele_mech.cpp:84).

## C ブリッジと再利用の粒度

**ObjC++ の実装は存在しない.** `MitakaCore.h` の `extern "C"` が C++ 実装を C ABI として公開し, Swift bridging header がこのヘッダを読み込む構成である. `.mm` のアダプタも Objective-C のクラスもない. [C API](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/Core/MitakaCore.h:6), [bridging header](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/Support/MitakaMac-Bridging-Header.h:1)

この構成は再利用候補として良い. C++ コアは標準ライブラリの `array` / `cmath` 等と固定データのみを使い, Win32・SceneKit・SwiftUI・ファイル IO に依存しない. Swift は戻り値を自分の `Planet` モデルへ変換している. 計算層と表示層を分ける構成の実例になる. [Core:29](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/Core/MitakaCore.cpp:29), [AppModel:43](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/AppModel.swift:43)

一方, 本体移植へ拡張する前に次を明確にする必要がある.

- `MTKVector3` の単位・座標系・原点, Julian date の時間尺度, 有効な日時範囲を API 契約に記す. 現在ヘッダは xyz と double の宣言のみ. [Core.h:10](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/Core/MitakaCore.h:10)
- 無効 index は空文字/0 またはゼロベクトルを返し, NaN/Infinity の日時入力や非収束は明示的なエラーにならない. 汎用の天体 API にするなら失敗を有効な座標と区別する. [Core.cpp:128](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/Core/MitakaCore.cpp:128)
- 9 件の固定 index を UI の ID として使っている. カタログ・衛星・Plus の追加天体を統合するなら, 恒久 ID と並び順を分離する. 現状は Earth=2 をモデルとテストが前提にする. [AppModel:33](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/AppModel.swift:33), [Tests:14](/Users/kota/mitaka/sources/reference/Mitaka-macOS/Tests/MitakaCoreTests.cpp:14)
- 新しい C ABI を使うこと自体は, 公式の `mtk_*` 依存をほどいたことにはならない. 公式側の計算・座標・観測者・データローダーの依存分離は今後の作業として残る. 参照版に本体の全機能を載せ替えるための汎用アダプタはない.

## テストと検証の範囲

現在の C++ テストは, 天体数 9, Earth の識別子, J2000 の全座標が有限, 太陽距離が各長半径の 0.7〜1.3 倍, Unix epoch の Julian date 変換を確認する. これはビルドと概略的な健全性の確認であり, 軌道の向き・日時依存・公式版との数値一致を保証しない. [Tests/MitakaCoreTests.cpp:12](/Users/kota/mitaka/sources/reference/Mitaka-macOS/Tests/MitakaCoreTests.cpp:12)

移植の品質判定には, 複数日時での既知座標または公式平均軌道経路との回帰比較, 基準系・単位・元期の確認, 不正 index と非有限日時, 日付範囲の境界, 今後加わる CF96 や衛星との経路選択が必要になる. 数値精度の受入基準は, 簡易太陽系デモとプラネタリウムで分ける必要がある.

テスト実行スクリプトは C++17, `-Wall -Wextra -Werror` で core と test の 2 ファイルをコンパイルする. コアは OS 非依存だが, スクリプトは zsh と `xcrun` を使用するため macOS 用である. Xcode の XCTest / UI test やクロス OS の検証基盤まで備えた構成ではない. [scripts/test_core.sh:1](/Users/kota/mitaka/sources/reference/Mitaka-macOS/scripts/test_core.sh:1)

親担当からの検証結果: 既存 `scripts/test_core.sh` は成功. Xcode 27.1 / macOS 26.6.2 で `ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO CODE_SIGNING_ALLOWED=NO` の build は成功. 実アプリの起動・描画・操作は未検証. これらは本調査担当による実行結果ではなく, 親担当から共有された結果である.

## ライセンスの根拠と境界

公式 1.3.1 の Readme はソースを MIT License で配布すると明記し, 著作権表示を求める. 計算の出所となる `mtk_planet_position.cpp` と `cele_mech.cpp` にも MIT 本文がある. 非公式 repo のルート LICENSE は元の Mitaka 部分と 2026 年の macOS 部分を分けて MIT と記載し, 著作権・許諾表示をコピーまたは実質的部分に含める条件と無保証条項を持つ. [公式 Readme:10](/Users/kota/mitaka/sources/official/mitaka_source/Readme.txt:10), [公式惑星ソース:1](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_planet_position.cpp:1), [公式 Kepler:1](/Users/kota/mitaka/sources/official/mitaka_source/common/astro/cele_mech.cpp:1), [参照 LICENSE:1](/Users/kota/mitaka/sources/reference/Mitaka-macOS/LICENSE:1)

参照版の active core は元の著作権・MIT 本文と派生元を保持している. 同梱 `THIRD_PARTY_NOTICES.md` は軌道表/Kepler を 1.3.1 由来と明記する. 由来追跡の構成は参考にできる. [Core.cpp:1](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/Core/MitakaCore.cpp:1), [THIRD_PARTY_NOTICES:3](/Users/kota/mitaka/sources/reference/Mitaka-macOS/THIRD_PARTY_NOTICES.md:3)

これは公開ソースの根拠であり, 現行 Windows 配布物のテクスチャ・カタログ・地形・動画・ロゴ等の再配布条件を確認したことにはならない. 参照版自身もそれらを同梱せず, 取り込み時の個別確認を要求している. Plus 固有のコード/データについても別の由来確認が必要である. [README:61](/Users/kota/mitaka/sources/reference/Mitaka-macOS/README.md:61), [THIRD_PARTY_NOTICES:14](/Users/kota/mitaka/sources/reference/Mitaka-macOS/THIRD_PARTY_NOTICES.md:14)

## 調査時の変更・Git 状態

原本・参照 repo の変更なし. 参照 repo の `git status --short` と `git diff --stat` は空, HEAD は指定 commit と一致. 本報告および SHA-256 比較結果だけを `/tmp` に保存した. commit, `/simplifier-lai`, IMPLEMENTATION_POLICY / policy_gates の更新は実施していない. 実装変更がなく, 本担当は静的調査のみのためである.

## SwiftUI・SceneKit・Xcode の再利用判断

補助担当による [UI/Xcode 詳細調査](/tmp/mitaka-131-ui-findings.md) を統合すると, 再利用の範囲は次の通りになる.

| 部分 | 再利用できる構成 | 主な不足・条件 |
| --- | --- | --- |
| SwiftUI app | WindowGroup, 最小サイズ, 再生/停止・現在時刻の commands. [App:8](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/MitakaMacApp.swift:8) | app 所有 AppModel を全ウィンドウで共有するため, 独立した複数ビューを実現するなら状態所有を見直す. |
| 天体一覧・操作 | NavigationSplitView, 日英名検索, 選択, 軌道/名称表示. [ContentView:7](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/ContentView.swift:7) | 検索対象は組み込み 9 天体のみ. 日時は表示のみで任意日時入力・逆再生なし. |
| AppModel | MainActor の状態管理, C ABI→Swift model, timer. [AppModel:15](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/AppModel.swift:15) | 実時間の経過を 0.25 秒で cap するため, 停滞・復帰後には壁時計とずれる. [AppModel:84](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/AppModel.swift:84) |
| SwiftUI/表示境界 | NSViewRepresentable + Coordinator に日時・選択・表示フラグを渡す. [SceneView:24](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/UniverseSceneView.swift:24) | renderer を交換する接点として有用. SceneKit 自体への長期投資は保守状況を考慮する. |
| SceneKit 試作 | 球, 太陽光源, 土星の環, billboard ラベル, 軌道線, カメラ操作. [SceneView:92](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/UniverseSceneView.swift:92) | 実際の観測・宇宙規模表示を満たす renderer としては未検証. 独自 Metal pass は未実装. |
| Xcode | C++17 + C ABI + Swift の native app target, macOS 14 最低要件. [project:273](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac.xcodeproj/project.pbxproj:273) | Swift language mode 5.0 / strict concurrency minimal. 将来の背景読み込みと描画更新には並行性の検証が必要. |

描画の具体的な制約:

- **距離と半径は非線形に圧縮**される. 半径は `0.075 + log10(radiusEarth + 1) * 0.105`, 距離は `1.2 + log10(length + 1) * 3.35`. 図示モードと実寸・観測モードを分ける必要がある. Float 座標のままで地表〜宇宙大規模構造を扱う精度設計も未実施. [SceneView:150](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/UniverseSceneView.swift:150), [SceneView:265](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/UniverseSceneView.swift:265)
- **星空は固定 seed の乱数点 1,600 個**であり, 実在星表ではない. 惑星は固定配色で, テクスチャ・自転・軸の姿勢は反映しない. [SceneView:5](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/UniverseSceneView.swift:5), [SceneView:225](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/UniverseSceneView.swift:225)
- 選択時だけカメラを移動し, 天体を追尾しない. `nil` 選択で lastSelectedPlanetID を更新しないため, 解除後の同一 ID 再選択では focus が再実行されない条件もある. 3D 天体のクリック選択も未実装. [SceneView:77](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/UniverseSceneView.swift:77), [SceneView:252](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/UniverseSceneView.swift:252)
- 軌道線は固定元期と `365.256 * a^1.5` の周期で初回だけ生成する. 将来, 時間変動する詳細軌道へ切り替える際には再生成と表示位置との整合確認が必要. [SceneView:198](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/UniverseSceneView.swift:198)
- 本体の衛星/カタログ, 観測者モード, 銀河・大規模構造, stereo/dome, 動画/network は文書上も Planned. Plus 固有機能を実装済みとする根拠もない. [PORTING:23](/Users/kota/mitaka/sources/reference/Mitaka-macOS/docs/PORTING.md:23)

Xcode の配布・検証面では, shared scheme の TestAction に Testables がなく, Resources build phase は空. 星表・画像だけでなく LICENSE 文書を app に組み込む設定もない. UI に原作者表示はあるが, 配布時に必要な告知を同梱する手順は別途確認する必要がある. automatic signing/hardened runtime の設定はあるものの, 署名主体・notarization の完了は確認できない. [scheme:25](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac.xcodeproj/xcshareddata/xcschemes/MitakaMac.xcscheme:25), [Resources:139](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac.xcodeproj/project.pbxproj:139), [signing:274](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac.xcodeproj/project.pbxproj:274)

Apple は WWDC25 で SceneKit を soft deprecation / maintenance mode と説明し, 重大な不具合のみ対応, 新規アプリや大きな更新では推奨しないとしている. その説明時点では hard deprecation の計画はない. 既存デモの検証には使えても, 新しい本体 renderer の第一候補と決める前に RealityKit/Metal を天文精度・大量点描画・多視点出力の要件で比較すべきである. RealityKit が全要件に適合することまでは確認していない. [Apple WWDC25](https://developer.apple.com/videos/play/wwdc2025/288/)
