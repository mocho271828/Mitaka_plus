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
        Desktop.pointer = false;
    else
        System.selectionInfo = true;
        Targets.selectMode=mtk.SELECT_MOUSEOVER;
        Desktop.pointer = true;
    end

end

Input:addShortcut("X", false, "Movies:togglePlaying(); ScreenMenu:enter();", "Open/Execute Screen Menu");
Input:addShortcut("Z", false, "ScreenMenu:cancel();", "Cancel");
Input:addShortcut("ENTER", false, "Movies:togglePlaying(); ScreenMenu:enter();", "Open/Execute Screen Menu");
Input:addShortcut("ESC", false, "if not ScreenMenu:isShown() then Desktop:toggleActive(); else ScreenMenu:cancel(); end", "Cancel");
Input:addShortcut("UP", true, "Input:up();", "View rotation, Select ScreenMenu item");
Input:addShortcut("DOWN", true, "Input:down();", "View rotation, Select ScreenMenu item");
Input:addShortcut("LEFT", true, "Input:left();", "View rotation");
Input:addShortcut("RIGHT", true, "Input:right();", "View rotation");
Input:addShortcut("PAGEUP", true, "Input:zoomUp();", "Zoom in");
Input:addShortcut("PAGEDOWN", true, "Input:zoomDown();", "Zoom out");
Input:addShortcut("CTRL+LEFT", true, "Input:rollLeft();", "Roll left (in Space mode)");
Input:addShortcut("CTRL+RIGHT", true, "Input:rollRight();", "Roll right (in Space mode)");
Input:addShortcut("4", true, "Time:forward();", "Forward the simulation time");
Input:addShortcut("3", true, "Time:rewind();", "Rewind the simulation time");
Input:addShortcut("SHIFT+4", false, "Time:nextStep();", "Widen the simulation time step (max: 100 years)");
Input:addShortcut("SHIFT+3", false, "Time:prevStep();", "Shorten the simulation time step (min: 10 sec)");
Input:addShortcut("A", false, "toggleLabels();", "Toggle Labels");
Input:addShortcut("S", false, "Camera:toggleModeTo();", "Launching / Landing");
Input:addShortcut("W", false, "Titles.index=0; Titles:toggle();", "Show Credits");
Input:addShortcut("Q", false, "Pointer:toggle();", "Switch to Pointer mode");
Input:addShortcut("L", false, "Planets:toggleCityLights();", "Toggle City lights");
Input:addShortcut("H", false, "Camera:toggleHeadLight();", "Toggle Head Light");
Input:addShortcut("CTRL+F", false, "System:toggleFPSInfo();", "Toggle FPS");
--Input:addShortcut("F1", false, "Input:toggleHelpInfo();", "Toggle Shortcut keys help");
Input:addShortcut("TAB", false, "togglePointer();", "Toggle Pointer");

-- for ELECOM PS2/USB Converter
Input:addShortcut("JSBUTTON2", false, "Movies:togglePlaying(); ScreenMenu:enter();", "Open/Execute Screen Menu");
Input:addShortcut("JSBUTTON3", false, "ScreenMenu:cancel();", "Cancel");
Input:addShortcut("JSBUTTON1", false, "Camera:toggleModeTo();", "Launching / Landing");
Input:addShortcut("JSBUTTON4", false, "toggleLabels();", "Toggle Labels");
Input:addShortcut("JSBUTTON7", true, "if not Movies.visible then Time:rewind(); else Movies.frame=Movies.frame-Movies.frameLength/10; end", "Rewind the simulation time / Rewind movie by 1/10");
Input:addShortcut("JSBUTTON8", true, "if not Movies.visible then Time:forward(); else Movies.frame=Movies.frame+Movies.frameLength/10; end", "Forward the simulation time / Forward movie by 1/10");
Input:addShortcut("JSBUTTON9", false, "Titles.index=0; Titles:toggle();", "Show Title / Credits");
Input:addShortcut("JSBUTTON10", false, "Pointer:toggle();", "Switch to Pointer mode");
Input:addShortcut("JSBUTTON5", false, "Movies.frame=0;", "Jump to start of the movie");
Input:addShortcut("JSBUTTON6", false, "Movies.frame=Movies.frameLength;", "Jump to end of the movie");
Input:addShortcut("JSBUTTON12", false, "Go to the Target", "Camera:jumpToTarget();");

-- for SANWA SUPPLY PS2/USB Converter
-- Input:addShortcut("JSBUTTON2", false, "Movies:togglePlaying(); ScreenMenu:enter();", "Open/Execute Screen Menu");
-- Input:addShortcut("JSBUTTON1", false, "ScreenMenu:cancel();", "Cancel");
-- Input:addShortcut("JSBUTTON4", false, "Camera:toggleModeTo();", "Launching / Landing");
-- Input:addShortcut("JSBUTTON3", false, "toggleLabels();", "Toggle Labels");
-- Input:addShortcut("JSBUTTON5", true, "if not Movies.visible then Time:rewind(); else Movies.frame=Movies.frame-Movies.frameLength/10; end", "Rewind the simulation time / Rewind movie by 1/10");
-- Input:addShortcut("JSBUTTON7", true, "if not Movies.visible then Time:forward(); else Movies.frame=Movies.frame+Movies.frameLength/10; end", "Forward the simulation time / Forward movie by 1/10");
-- Input:addShortcut("JSBUTTON10", false, "Titles.index=0; Titles:toggle();", "Show Title / Credits");
-- Input:addShortcut("JSBUTTON9", false, "Pointer:toggle();", "Switch to Pointer mode");
-- Input:addShortcut("JSBUTTON6", false, "Movies.frame=0;", "Jump to start of the movie");
-- Input:addShortcut("JSBUTTON8", false, "Movies.frame=Movies.frameLength;", "Jump to end of the movie");
-- Input:addShortcut("JSBUTTON12", false, "Go to the Target", "Camera:jumpToTarget();");

-- for Logicool Cordless Rumblepad 2
-- Input:addShortcut("JSBUTTON3", false, "Movies:togglePlaying(); ScreenMenu:enter();", "Open/Execute Screen Menu");
-- Input:addShortcut("JSBUTTON2", false, "ScreenMenu:cancel();", "Cancel");
-- Input:addShortcut("JSBUTTON4", false, "Camera:toggleModeTo();", "Launching / Landing");
-- Input:addShortcut("JSBUTTON1", false, "toggleLabels();", "Toggle Labels");
-- Input:addShortcut("JSBUTTON5", true, "if not Movies.visible then Time:rewind(); else Movies.frame=Movies.frame-Movies.frameLength/10; end", "Rewind the simulation time / Rewind movie by 1/10");
-- Input:addShortcut("JSBUTTON6", true, "if not Movies.visible then Time:forward(); else Movies.frame=Movies.frame+Movies.frameLength/10; end", "Forward the simulation time / Forward movie by 1/10");
-- Input:addShortcut("JSBUTTON10", false, "Titles.index=0; Titles:toggle();", "Show Title / Credits");
-- Input:addShortcut("JSBUTTON9", false, "Pointer:toggle();", "Switch to Pointer mode");
-- Input:addShortcut("JSBUTTON7", false, "Movies.frame=0;", "Jump to start of the movie");
-- Input:addShortcut("JSBUTTON8", false, "Movies.frame=Movies.frameLength;", "Jump to end of the movie");
-- Input:addShortcut("JSBUTTON12", false, "Go to the Target", "Camera:jumpToTarget();");

-- for Nintendo Wii controler and Nunchuk
Input:addShortcut("WIIMOTEA", false, "Movies:togglePlaying(); ScreenMenu:enter();", "Open/Execute Screen Menu");
Input:addShortcut("WIIMOTEB", false, "ScreenMenu:cancel();", "Cancel");
Input:addShortcut("WIIMOTEUP", true, "Input:up();", "View rotation, Select ScreenMenu item");
Input:addShortcut("WIIMOTEDOWN", true, "Input:down();", "View rotation, Select ScreenMenu item");
Input:addShortcut("WIIMOTELEFT", true, "Input:left();", "View rotation");
Input:addShortcut("WIIMOTERIGHT", true, "Input:right();", "View rotation");
Input:addShortcut("WIIMOTEC", false, "Camera:toggleModeTo();", "Launching / Landing");
Input:addShortcut("WIIMOTEPLUS", true, "Time:forward();", "Forward the simulation time");
Input:addShortcut("WIIMOTEMINUS", true, "Time:rewind();", "Rewind the simulation time");
Input:addShortcut("WIIMOTE1", false, "toggleLabels();", "Toggle Labels");
Input:addShortcut("WIIMOTE2", false, "Camera:toggleHeadLight();", "Toggle Head Light");
Input:addShortcut("WIIMOTEHOME", false, "Camera:jumpToHome();", "Landng on Home");
