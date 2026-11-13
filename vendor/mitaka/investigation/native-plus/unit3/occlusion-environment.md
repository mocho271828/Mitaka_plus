# 投影ウィンドウの遮蔽通知

投影の更新はウィンドウの表示状態に従う。制御された NSWindow に可視性変更を通知する test_display_output は、遮蔽・非表示・スリープ中にキャプチャを停止し、再表示時に再開することを検査する。

test_display_output --system-occlusion は実ウィンドウを不透明な別ウィンドウで覆い、OS が NSWindowOcclusionStateVisible を解除するかを調べる。macOS 26.6.2 の実測では、覆いが投影の四辺を各64 pt超え、中心の最前面ウィンドウも覆いと一致した状態で Visible が残った。実 OS の完全遮蔽通知による停止と復帰は未確認。
