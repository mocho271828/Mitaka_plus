# N01: 種類別表示・表示集合・彗星軌道の接続計画

## 状態と所有範囲

2026-10-29。UNIT4 の commit `002adcf663fd5005e14ac86c343a3ec7e56fa706` 後に、ここで定めた画面・描画・Lua 接続を実装した。本書は接続契約の記録であり、全機能の互換完了判定ではない。独立 helper の結果は [helper 検証](comet-display-helper-validation.md)、非同期計算は [pipeline 検証](orbit-pipeline-validation.md)、画面・描画の確認範囲は [接続検証](n01-integration-validation.md) に分けて記録する。

- N01 担当: SmallBodyRenderer、SolarSmallBodies、SmallBodyController、AppSmallBodyCommands、小天体に限る AppScripting の接続、新規 orbit model / controller、対応テスト。
- 統合担当: AppControllerInternal、SolarSystemView.h / Internal、SolarSystemView.mm、SolarSystemNavigation、SolarSceneRenderer.h / .mm の共有 call site、AppController、AppWindow、SessionState、Makefile。
- N04 core 担当と observation_model 担当: minor planet core と small_body_model の位置評価。N01 はこのファイルを編集しない。
- Lua transport と共通 ScriptSnapshot / ScriptAction の所有は N02 担当と調整する。英名解決は [原典監査](lua-comet-satellite-contracts.md) の未確定事項が解消するまで推測で追加しない。

## 共有する描画境界

SmallBodyRenderer の公開引数を次に統一する。display は const SmallBodyDisplayModel&、orbit snapshot は null を許す pointer。

```cpp
visible_small_bodies(snapshot, display, camera, map);
pick_small_body(snapshot, display, camera, map, point);
draw_small_bodies(context, snapshot, display, orbitSnapshot,
                  camera, map, selection, quality);
```

body / label / orbit の判定は display.visibility(row) を共通利用する。採用した native 契約では visible が種別全体の master であり、body は visible AND 集合条件、label / orbit は body に各フラグを AND した値になる。visible=false のまま名称や軌道だけを表示する設定はない。この優先順位を旧 Plus の確定仕様とは扱わない。

クリックによる単一選択、追尾、複数行の表示集合は別の状態として保持する。selected_only によって不可視になった行は pick できず、同じ行の軌道・ラベルも表示しない。クリック選択を変えたときに表示集合を書き換えない。

SolarScene の末尾に次のフィールドを追加し、既存の aggregate 順序を変えない。

```cpp
const mitaka::gui::SmallBodyDisplayModel* small_body_display = nullptr;
const mitaka::gui::SmallBodyOrbitSnapshot* small_body_orbits = nullptr;
```

SolarSystemView は setSmallBodyDisplayModel: と setSmallBodyOrbitSnapshot: を持ち、model / dataset の一致を先に検証する。新しい位置 snapshot に切り替える途中で旧モデルの軌跡を利用しない。単一選択の説明・camera / follow の既存契約は維持する。座標は sampler が返す日心 J2000 黄道 AU を既存 project_solar / project_solar_segment に渡し、追加回転・親位置補正を入れない。

## 新規 orbit model と非同期 controller

small_body_orbit_model.hpp / .cpp を位置評価モデルから分離する。SmallBodyOrbitSnapshot は元 SmallBodyModel、sampling、原行と同じ長さの optional paths、要求・未評価件数、取消状態を持つ。計算は evaluate_small_body_orbit_snapshot(model, display, sampling, cancelledFn) に閉じる。

- display の orbit が有効な要求行だけを計算する。非要求行・参照面や時系が未確定の行も元の index を保つ。
- sampler は既存 TDB evaluator だけを使用する。N04 が追加する legacy numeric JD の位置評価を TDB 軌道 sampler と混用しない。
- 行の間で取消を確認し、取消結果を完成結果として適用しない。未評価理由と実際の標本の診断を保持する。
- 原本行数と標本数は別である。1 行 2～4096 点に加え、要求行数 × 標本数の **総標本上限 524,288** を事前に検証する。統合担当と合意した native の作業量上限であり、超過は全要求を説明付きで拒否し、原本の件数や要求行を切り詰めない。この上限は科学的精度や正確な RSS 上限の保証ではない。

SmallBodyOrbitController.h / .mm は serial queue と世代番号を所有する。worker は immutable な model / display / sampling を保持し、main callback は最新の世代・モデル・設定だけを適用する。再読込開始、終了、全体表示の無効化、設定変更で取消できる。過去の callback が旧結果を戻したり終了後に UI を操作したりしない。

## 表示期間

統合担当と合意した native 契約は、画面に表示する **固定の絶対 TDB JD 区間**。初回は現在 JD ±182.625 日、129 点とする。開始 TDB JD、終了 TDB JD、標本数を利用者が変更でき、入力は既存の厳密な数値検証に揃える。文字の桁区切りや非有限値を暗黙に受理しない。

日時変更でも結果の有効性を確認するが、元モデル・表示要求・絶対区間が同じなら軌道線を再計算しない。現在の点の位置は既存の同 JD snapshot で更新する。軌道の区間が現在時刻に追従するという表現は使わない。区間・標本数・精度保証なしを画面で区別する。原版の期間・点数・周期処理との互換は未確認。

## App state と共有宣言

```objc
std::shared_ptr<const SmallBodyDisplayModel> _smallBodyDisplay;
std::shared_ptr<const SmallBodyOrbitSnapshot> _smallBodyOrbits;
SmallBodyOrbitController *_smallBodyOrbitController;
mitaka::SmallBodyOrbitSampling _smallBodyOrbitSampling;

- (std::shared_ptr<const SmallBodyDisplayModel>)smallBodyDisplayModel;
- (void)resetSmallBodyDisplayForCurrentModel;
- (void)setSmallBodyDisplayModel:(std::shared_ptr<const SmallBodyDisplayModel>)display;
- (SmallBodyKindDisplayOptions)smallBodyDisplayOptionsForKind:(mitaka::SmallBodyKind)kind;
- (void)setSmallBodyDisplayOptions:(SmallBodyKindDisplayOptions)options
                          forKind:(mitaka::SmallBodyKind)kind;
- (void)setSmallBodyDisplayIds:(const std::vector<mitaka::SmallBodyId>&)ids;
- (void)setSmallBodyOrbitSampling:(mitaka::SmallBodyOrbitSampling)sampling;
- (void)refreshSmallBodyOrbits;
- (void)invalidateSmallBodyOrbits;
```

main thread で状態をコピー・検証してから一括適用する。dataset の shared ownership は既存 SmallBodyModel の const& getter と標準 shared_ptr aliasing constructor で維持でき、N04 の model getter 追加は不要。

resetSmallBodyDisplayForCurrentModel は model と初期 JD の代入後、snapshot 適用前に呼ぶ。旧 display の rebind は同 source + ordinal、同 kind、source 原 bytes の完全一致を要求し、解除した行を報告する。初期の kind 設定は visible=true、labels/orbits/selected_only=false。既存の全小天体表示 master を併用する。

invalidateSmallBodyOrbits は終了・再読込開始時に呼ぶ。読込失敗で直前のモデルを維持するときは、その表示条件で要求を再開する。日時更新の applySmallBodySnapshot / refreshSmallBodies から orbit の有効性も確認し、AppController.setDate の中へ重複する独自計算を追加しない。overviewVisibilityChanged は航行の最終状態が変わったときにだけ通知し、地球・月表示や表面表示からの復帰で要求を再開する。航行中の一時的な内部状態から計算を始めない。

## 画面と Lua の接続範囲

小天体一覧は既存の AppKit・Dark Aqua・検索ページ・出典表示を維持する。kind ごとの 4 設定と、複数行を表示集合へ追加・除去する操作を追加する。単一行の「選択」「中心へ」と集合操作を別にし、検索やページ移動によって表示集合を失わない。

Lua は原典で確定した Asteroids / TNObjects / Comets の property と toggle のみを先行接続できる。共通 snapshot を毎回読み、GUI 側の変更を getter へ反映する。旧 show / hide / isVisible、target の英名を全 source の first match で解決しない。必要な名前解決根拠が得られるまで未対応を明示する。

session の静的設定・集合・区間の永続化は統合担当が所有する。元 bytes の再確認、1 MiB 上限、保存対象の厳密な型を満たす必要があり、ここで将来の保存対応を実装済みとは扱わない。標本配列は session に保存しない。

## 接続後の検証条件

- kind と 4 bool の全組合せについて、body / label / orbit / pick が一致し、非表示行を click できない。
- 複数集合が単一選択・検索・ページングと独立し、同名別行・言語別定義を保持する。
- 元 bytes 変更・行入替・source 欠損・不正 model の切替で、表示集合の保持条件と原子拒否を満たす。
- 軌道線は隣接成功点だけを結び、欠損を跨がず、終始点を自動で閉じない。点・線・文字の RendererQuality scope を分離する。
- sampling の上限、総標本上限、非有限値、丸め、取消、旧世代 callback、非表示・再読込・終了を検証する。
- 同区間の日時更新でキャッシュを利用し、位置 snapshot は新 JD のまま。区間変更・表示要求変更・model 変更で必要な軌道線を更新する。
- controller / 実 AppKit 描画 / Lua readback の通常・ASan/UBSan・x86_64 試験を行い、統合担当の smoke と原本保全検査へ引き渡す。

新規依存は追加せず、C++17、既存 evaluator / projection / 数値入力契約、Foundation / AppKit の queue・UI を再利用する。既存ファイルが 500 行の目安を超える場合、行数だけの分割ではなく、orbit 計算の非同期責務と一覧 UI を分離してレビューする。
