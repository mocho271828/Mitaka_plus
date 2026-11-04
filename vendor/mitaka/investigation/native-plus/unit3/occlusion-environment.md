# UNIT3: 投影ウィンドウ遮蔽試験の環境制約

確認日: 2026-10-29。macOS 26.6.2 (25G83)、Retina backing scale 2、対話デスクトップ上で確認した。

## 結論

`test_display_output` の既存 baseline を単独で通常実行すると、`test projection did not become occluded` で失敗する。遮蔽ウィンドウを確実に描画し、四辺を拡張し、最前面にあることを確認しても、投影側の `NSWindowOcclusionStateVisible` が解除されなかった。

この結果だけでは製品側の不具合と断定できない。このデスクトップ環境では、実際の重なりから完全遮蔽の通知を得る統合試験を完了できなかった。遮蔽中の更新停止・復帰を確認済みとは扱わない。アプリの smoke 成功は、この未完了項目の代替にはならない。

原因が解消したと確認できる変更が得られなかったため、別プロセス cover と `NSApplication.run` の実験コードは採用しなかった。製品の可視性判定やタイマー抑止処理は変更していない。通常試験は後述のウィンドウ生成境界で責務を分離し、実 OS の遮蔽試験を明示的な別モードとして保持した。

## 再現と切り分け

専用出力先 `native/gui/build-unit3-time-occlusion` を使用し、他の GUI 試験が終了した状態で実行した。

```sh
make BUILD_DIR=build-unit3-time-occlusion build-unit3-time-occlusion/test_display_output
build-unit3-time-occlusion/test_display_output
```

baseline では、投影の frame と同寸法の borderless ウィンドウを同じ Floating level で前面へ出す。これが完全遮蔽の条件になったかを改めて調査した。

| 切り分け | 結果 |
| --- | --- |
| baseline 単独通常実行 | 完全遮蔽待ちで失敗 |
| cover を四辺それぞれ 64 pt 拡張 | 同じ失敗 |
| cover を明示 opaque、影なし、黒背景、opaque な専用 NSView に変更 | 同じ失敗 |
| `drawRect:` 完了を bounded condition wait で確認 | 描画は完了するが、投影の Visible は残る |
| cover の level を投影より上げる、または titled の key window にする | 同じ失敗 |
| 投影中心の `windowNumberAtPoint:belowWindowWithWindowNumber:` を確認 | cover の window number と一致する |
| cover を別プロセスで生成 | 同じ失敗。同一アプリ内の重なりだけが原因とは言えない |
| 通知待ちを 2 秒から 5 秒へ延長 | 同じ失敗。短い固定待機だけでは説明できない |
| `NSApplication.run` を開始した中から試験を実行 | 同じ失敗。手動イベントループだけが原因とは言えない |

最後の実行では投影 frame が `{{315, 240}, {1024, 752}}`、cover frame が `{{251, 176}, {1152, 880}}`、cover は visible / opaque がともに真、alpha が 1 だった。中心にある最上位 window number は cover と一致した。投影の `occlusionState` は 8194 であり、公開された Visible ビットが立ったままだった。その他のビットの意味は推測していない。

`display` の呼出し直後は `drawRect:` がまだ実行されていない場合も観測した。ただし、その完了を確認してから待っても失敗したため、これだけを根本原因とした修正は採用していない。

## ログ

調査時の生ログは次に保存した。元データのパスや内容は変更していない。

- `/tmp/mitaka-unit3-occlusion-baseline.log`: 未変更 baseline のビルドと通常単独実行の失敗。
- `/tmp/mitaka-unit3-occlusion-diagnostics.log`: 同一プロセスでの寸法・描画・window ordering の確認。
- `/tmp/mitaka-unit3-occlusion-process.log`: 別プロセス cover の描画と前後関係を確認しても失敗。
- `/tmp/mitaka-unit3-occlusion-real-run-build.log`: `NSApplication.run` 切り分け版の Werror ビルド成功。
- `/tmp/mitaka-unit3-occlusion-real-run.log`: `NSApplication.run` 切り分け版の実行失敗。

原因未解消の通常実行で同じ失敗を確認した時点で、OS 通知の切り分けを終了した。親タスクで観測した sanitizer / x86_64 の OS 遮蔽試験失敗と、ここで独立再現した通常実行の失敗を区別する。

## コントローラ試験と OS 試験の分離

`DisplayOutputController` の NSWindow 生成だけを private factory `makeProjectionWindowWithContentRect:styleMask:` へ分離した。通常の製品動作は以前と同じ NSWindow を生成する。`updateTimer` の条件、タイマー間隔、sleep / wake / visibility の通知ハンドラは変更していない。

引数なしの `test_display_output` は試験 subclass の factory から、`occlusionState` を明示的に制御する NSWindow を返す。公開の `NSWindowDidChangeOcclusionStateNotification` を送り、visible → occluded → sleep / wake → visible の経路と capture 回数を検証する。遮蔽直後、遮蔽したまま wake、非表示の wake、再表示、close、invalidate の停止・復帰 assert を維持する。これは OS の遮蔽検出を検証する試験ではない。

`test_display_output --system-occlusion` は製品の factory と実 NSWindow を使う。四辺を 64 pt 拡張した不透明な cover の描画完了を待ち、同じ lifecycle の assert を実際の OS 通知で検証する。通知が来なければ exit 1 とし、成功扱いや自動 skip にしない。

通常の制御付き試験は、Werror の通常 / ASan・UBSan / x86_64 ビルドをそれぞれ逐次実行し、すべて 46 checks、exit 0 で通過した。結果は次のログに保存した。

- `/tmp/mitaka-unit3-occlusion-controller-normal.log`
- `/tmp/mitaka-unit3-occlusion-controller-san.log`
- `/tmp/mitaka-unit3-occlusion-controller-x86.log`

追加した実 OS モードも単独実行し、完全遮蔽待ちで exit 1 になることを確認した。ログは `/tmp/mitaka-unit3-occlusion-system.log`。制御付き試験の成功と、この未通過を分けて記録する。

最終確認として `controller-test` 一式を通常 → ASan / UBSan → x86_64 の順に逐次実行し、3 構成とも exit 0 で通過した。各構成で Script、small-body 23 checks、solar small-body 19 checks、media 43 checks、catalog browser 23 checks、PlaybackController、DisplayOutputController 46 checks を確認した。実 OS の遮蔽試験はこの target に含めず、上記の未通過を維持する。

- `/tmp/mitaka-unit3-controller-suite-normal.log`
- `/tmp/mitaka-unit3-controller-suite-san.log`
- `/tmp/mitaka-unit3-controller-suite-x86.log`

OS 遮蔽の再確認には、完全遮蔽通知を実際に受けられる対話セッションが必要である。OS 試験を成功扱いするために制御付きウィンドウへ切り替えたり、遮蔽 assert を削除したり、製品の更新停止条件を外したりしない。
