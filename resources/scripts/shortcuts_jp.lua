function toggleLabels()

  flag = false;
  if (not Time.timeInfo) or (not Stars.labels) or (not Planets.labels) or
     (not Constels.labels) or (not Constels.lines) then
     flag = true;
  end

  if Camera.mode == mtk.PLANETARIUM then
    Grids.ecliptic = flag;
    Constels.labels = flag;
    Constels.lines = flag;
  else
    Grids.circleScales = flag;
  end

  Time.timeInfo = flag;
  Stars.labels = flag;
  Planets.labels = flag;
  Satellites.labels = flag;
  Asteroids.labels = flag;
  TNObjects.labels = flag;

end

function togglePointer()

    if System.selectionInfo then
        System.selectionInfo = false;
        Targets.selectMode=mtk.SELECT_NONE;
        Targets:select("");
        Pointer.visible = false;
    else
        System.selectionInfo = true;
        Targets.selectMode=mtk.SELECT_MOUSEOVER;
        Pointer.visible = true;
    end

end

Input:addShortcut("X", false, "Movies:togglePlaying(); ScreenMenu:enter();", "スクリーンメニューを開く・実行");
Input:addShortcut("Z", false, "ScreenMenu:cancel();", "キャンセル");
Input:addShortcut("ENTER", false, "Movies:togglePlaying(); ScreenMenu:enter();", "スクリーンメニューを開く・実行");
Input:addShortcut("ESC", false, "if not ScreenMenu:isShown() then Scene:toggleMode(); else ScreenMenu:cancel(); end", "キャンセル");
Input:addShortcut("UP", true, "Input:up();", "視野回転、スクリーンメニュー選択");
Input:addShortcut("DOWN", true, "Input:down();", "視野回転、スクリーンメニュー選択");
Input:addShortcut("LEFT", true, "Input:left();", "視野回転");
Input:addShortcut("RIGHT", true, "Input:right();", "視野回転");
Input:addShortcut("PAGEUP", true, "Input:zoomUp();", "ズームイン");
Input:addShortcut("PAGEDOWN", true, "Input:zoomDown();", "ズームアウト");
Input:addShortcut("CTRL+LEFT", true, "Input:rollLeft();", "視野を左に傾ける（宇宙空間モード）");
Input:addShortcut("CTRL+RIGHT", true, "Input:rollRight();", "視野を右に傾ける（宇宙空間モード）");
Input:addShortcut("4", true, "Time:forward();", "時刻を進める");
Input:addShortcut("3", true, "Time:rewind();", "時刻を戻す");
Input:addShortcut("SHIFT+4", false, "Time:nextStep();", "時刻刻みを長くする（最大100年）");
Input:addShortcut("SHIFT+3", false, "Time:prevStep();", "時刻刻みを短くする（最小10秒）");
Input:addShortcut("A", false, "toggleLabels();", "ラベルの表示・非表示");
Input:addShortcut("S", false, "Camera:toggleModeTo();", "宇宙へ飛び出す・地上へ着陸する");
--Input:addShortcut("W", false, "Titles.index=0; Titles:toggle();", "エンドロールを表示");
--Input:addShortcut("Q", false, "Pointer:toggle();", "ポインタ・モードに移行");
--Input:addShortcut("L", false, "Planets:toggleCityLights();", "夜景表示の切り替え");
Input:addShortcut("H", false, "Camera:toggleHeadLight();", "ヘッドライトの切り替え");
Input:addShortcut("CTRL+F", false, "System:toggleFPSInfo();", "FPSの表示・非表示");
--Input:addShortcut("F1", false, "Input:toggleHelpInfo();", "ショートカットキーヘルプの表示・非表示");
Input:addShortcut("TAB", false, "togglePointer();", "ポインタの表示・非表示");

-- for ELECOM PS2/USB Converter
Input:addShortcut("JSBUTTON2", false, "Movies:togglePlaying(); ScreenMenu:enter();", "スクリーンメニューを開く・実行/ムービーの再生・停止");
Input:addShortcut("JSBUTTON3", false, "ScreenMenu:cancel()", "キャンセル");
Input:addShortcut("JSBUTTON1", false, "Camera:toggleModeTo();", "宇宙へ飛び出す・地上へ着陸する");
Input:addShortcut("JSBUTTON4", false, "toggleLabels();", "ラベルの表示・非表示");
Input:addShortcut("JSBUTTON7", true, "Time:rewind();", "時刻を戻す/ムービーを1/10戻す");
Input:addShortcut("JSBUTTON8", true, "Time:forward();", "時刻を進める/ムービーを1/10進める");
--Input:addShortcut("JSBUTTON9", false, "Titles.index=0; Titles:toggle();", "エンドロール、タイトルを表示");
--Input:addShortcut("JSBUTTON10", false, "Pointer:toggle();", "ポインタ・モードに移行");
--Input:addToggleShortcut("JSBUTTON5", "Launcher:toggle();", "スクリーンランチャーの表示");
--Input:addShortcut("JSBUTTON5", false, "Movies.frame=0;", "ムービーの先頭に移動");
Input:addShortcut("JSBUTTON6", false, "Movies.frame=Movies.frameLength;", "ムービーの最後に移動");
Input:addShortcut("JSBUTTON12", false, "ターゲット付近に移動", "Camera:jumpToTarget();");

-- for SANWA SUPPLY PS2/USB Converter
-- Input:addShortcut("JSBUTTON2", false, "Movies:togglePlaying(); ScreenMenu:enter();", "スクリーンメニューを開く・実行/ムービーの再生・停止");
-- Input:addShortcut("JSBUTTON1", false, "ScreenMenu:cancel();", "キャンセル");
-- Input:addShortcut("JSBUTTON4", false, "Camera:toggleModeTo();", "宇宙へ飛び出す・地上へ着陸する");
-- Input:addShortcut("JSBUTTON3", false, "toggleLabels();", "ラベルの表示・非表示");
-- Input:addShortcut("JSBUTTON5", true, "if not Movies.visible then Time:rewind(); else Movies.frame=Movies.frame-Movies.frameLength/10; end", "時刻を戻す/ムービーを1/10戻す");
-- Input:addShortcut("JSBUTTON7", true, "if not Movies.visible then Time:forward(); else Movies.frame=Movies.frame+Movies.frameLength/10; end", "時刻を進める/ムービーを1/10進める");
-- Input:addShortcut("JSBUTTON10", false, "Titles.index=0; Titles:toggle();", "エンドロール、タイトルを表示");
-- Input:addShortcut("JSBUTTON9", false, "Pointer:toggle();", "ポインタ・モードに移行");
-- Input:addShortcut("JSBUTTON6", false, "Movies.frame=0;", "ムービーの先頭に移動");
-- Input:addShortcut("JSBUTTON8", false, "Movies.frame=Movies.frameLength;", "ムービーの最後に移動");
-- Input:addShortcut("JSBUTTON12", false, "ターゲット付近に移動", "Camera:jumpToTarget();");

-- for Logicool Cordless Rumblepad 2
-- Input:addShortcut("JSBUTTON3", false, "Movies:togglePlaying(); ScreenMenu:enter();", "スクリーンメニューを開く・実行/ムービーの再生・停止");
-- Input:addShortcut("JSBUTTON2", false, "ScreenMenu:cancel();", "キャンセル");
-- Input:addShortcut("JSBUTTON4", false, "Camera:toggleModeTo();", "宇宙へ飛び出す・地上へ着陸する");
-- Input:addShortcut("JSBUTTON1", false, "toggleLabels();", "ラベルの表示・非表示");
-- Input:addShortcut("JSBUTTON5", true, "if not Movies.visible then Time:rewind(); else Movies.frame=Movies.frame-Movies.frameLength/10; end", "時刻を戻す/ムービーを1/10戻す");
-- Input:addShortcut("JSBUTTON6", true, "if not Movies.visible then Time:forward(); else Movies.frame=Movies.frame+Movies.frameLength/10; end", "時刻を進める/ムービーを1/10進める");
-- Input:addShortcut("JSBUTTON10", false, "Titles.index=0; Titles:toggle();", "エンドロール、タイトルを表示");
-- Input:addShortcut("JSBUTTON9", false, "Pointer:toggle();", "ポインタ・モードに移行");
-- Input:addShortcut("JSBUTTON7", false, "Movies.frame=0;", "ムービーの先頭に移動");
-- Input:addShortcut("JSBUTTON8", false, "Movies.frame=Movies.frameLength;", "ムービーの最後に移動");
-- Input:addShortcut("JSBUTTON12", false, "ターゲット付近に移動", "Camera:jumpToTarget();");

-- for Nintendo Wii controler and Nunchuk
Input:addShortcut("WIIMOTEA", false, "Movies:togglePlaying(); ScreenMenu:enter();", "スクリーンメニューを開く・実行");
Input:addShortcut("WIIMOTEB", false, "ScreenMenu:cancel();", "キャンセル");
Input:addShortcut("WIIMOTEUP", true, "Input:up();", "視野回転、スクリーンメニュー選択");
Input:addShortcut("WIIMOTEDOWN", true, "Input:down();", "視野回転、スクリーンメニュー選択");
Input:addShortcut("WIIMOTELEFT", true, "Input:left();", "視野回転");
Input:addShortcut("WIIMOTERIGHT", true, "Input:right();", "視野回転");
Input:addShortcut("WIIMOTEC", false, "Camera:toggleModeTo();", "宇宙へ飛び出す・地上へ着陸する");
Input:addShortcut("WIIMOTEPLUS", true, "Time:forward();", "時刻を進める");
Input:addShortcut("WIIMOTEMINUS", true, "Time:rewind();", "時刻を戻す");
Input:addShortcut("WIIMOTE1", false, "toggleLabels();", "ラベルの表示・非表示");
Input:addShortcut("WIIMOTE2", false, "Camera:toggleHeadLight();", "ヘッドライトの切り替え");
Input:addShortcut("WIIMOTEHOME", false, "Camera:jumpToHome();", "三鷹へ着陸");
