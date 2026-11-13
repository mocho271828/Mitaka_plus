# 小天体の軌道計算と非同期更新

model は元 SmallBodyModel / SmallBodyDisplayModel、固定 TDB 区間、原行と同じ長さの optional paths、要求数・完了数・未評価数・取消状態を保持する。
display の orbit が有効な行だけを既存 TDB sampler で計算する。legacy numeric JD の位置 evaluator へ切り替えず、時系・参照面・要素が不明な行も標本の診断付きで残す。
未評価数は、計算した要求行のうち一つ以上の標本に位置がない行数であり、区間内に一部欠損のある行を含む。

入力は計算前に検証する。モデルと dataset の同一性、有限で昇順の区間、丸め後も異なる時刻、2～4096 標本、要求行数 × 標本数が 524,288 以下という条件を満たさなければ、全要求を説明付きで拒否する。
上限超過による原行の削除・要求行の切り詰めはしない。取消は各行の計算前と最終行後に確認する。
成功した隣接標本だけを結ぶ既存 sampler の契約を維持する。

controller は main thread で要求を検証し、serial queue で計算する。
世代番号の一致する完了だけを main thread へ返す。取消・再要求・invalidate・破棄後の旧 callback は適用しない。
cancel は成功 cache を保持して再利用でき、invalidate は cache を破棄する終端操作である。

cache のキーはモデルの同一性、要求行列、区間の両端と標本数である。
ラベル等の変更だけで要求行が同じなら幾何を再利用し、snapshot.display は計算要求時の由来を保持する。
描画側は最新の display で可視性を判定する。保留中の同じ要求は completion を更新し、完成済み cache の通知も非同期で行う。
入力拒否は、進行中の正常な要求を取り消さない。

C++17、既存 evaluator / sampler、Foundation、dispatch を再利用し、新しい依存や軌道数学は追加していない。
原本へ書き込む処理はない。

| 構成 | ビルド | model | controller |
| --- | --- | --- | --- |
| 通常 arm64 | exit 0 | 30,882 checks / exit 0 | 59 checks / exit 0 |
| ASan + UBSan arm64 | exit 0 | 30,882 checks / exit 0 | 59 checks / exit 0 |
| x86_64 / Rosetta | exit 0 | 30,882 checks / exit 0 | 59 checks / exit 0 |
