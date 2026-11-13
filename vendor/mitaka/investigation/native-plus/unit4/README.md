# 追加衛星とスクリプトからのウィンドウ操作

[衛星一覧](satellite-controller-validation.md)・[衛星の描画と選択](satellite-scene-validation.md)・[全画面切替](window-validation.md)・[再生タイマー](playback-smoke-validation.md)

衛星の式・定数・原版の処理順は、読み取り専用の限定静的監査で追跡した。[satellite-position-contracts.md](satellite-position-contracts.md) に命令位置と確定・未確定の境界を残す。旧アプリを実行して同じ画面や座標を比較した結果ではない。

成功登録の 9 惑星の ID と順序を確認できる場合だけ CF96 index に対応付ける。raw 親の J2000 赤道 AU から黄道への変換は一度だけで、通常衛星の回転済み相対 km を加える。最初の登録名一致の Earth / Moon、Pluto / Charon には原版の順序で重心補正を一度適用する。補正前・最終位置を別に保持し、片側未評価の対の最終位置や、他出典の代替位置を生成しない。

旧 Plus の数値 JD と UTC / UT1 / TT / TDB の物理的な対応は確定していない。CF96 の利用期間を衛星要素の精度保証期間とは扱わない。native の AU 定数、double 計算、公式 1.3.1 の月モデルを使うため、旧版の中間 float 丸めや旧月モデルとの bit 一致も保証しない。

詳細は [カタログ保持](../../../native/core/SATELLITE_CATALOG_PROVENANCE.md)、[回転](../../../native/core/SATELLITE_ROTATION_PROVENANCE.md)、[相対位置](../../../native/core/SATELLITE_POSITION_PROVENANCE.md)、[登録とモデル](../../../native/core/SATELLITE_MODEL_PROVENANCE.md)、[絶対位置・親天体](../../../native/core/SATELLITE_ABSOLUTE_PROVENANCE.md)、[一覧 controller](satellite-controller-validation.md)、[描画と選択](satellite-scene-validation.md) を参照する。探査機の保持・未確定事項は [SPACECRAFT_TRAJECTORY_PROVENANCE.md](../../../native/core/SPACECRAFT_TRAJECTORY_PROVENANCE.md)、PTH の補間規則は [spacecraft-position-contracts.md](spacecraft-position-contracts.md) に分ける。

## HTML と Lua の実行境界

最大 1 MiB のローカル HTML を読み、同じ読み取りで得た内容を表示する。canonical path、device / inode、SHA-256、メインページ、WebView と表示世代を検査し、別文書・別 frame・古い view へ信頼を継承しない。通常リンクの操作は移動を取り消した場合も信頼を失効させる。文書変更、閉じる操作、新しい文書の選択でも失効する。

ページ JavaScript を無効にしたうえで、アプリの分離した content world が実クリックと元の href を取得する。`mtkp://` は最大 64 KiB、UTF-8 の percent decode を一度だけ行い、不正 escape・NUL を拒否する。Lua は専用一時ファイルを経由して既存 helper で実行し、終了・中断後に一時ディレクトリを削除する。一時ディレクトリの所有権は worker dispatch 前に確定する。
