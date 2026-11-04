GUI:resetWindows();
GUI.scriptEditor=false;
GUI.scriptOutput=false;
GUI.objectList=false;
GUI.objectProperty=false;
GUI.launcher=false;
GUI.uiBrowser=false;
GUI.timelineEditor=false;
GUI.soundControler=false;
GUI.option=false;
GUI.projection=false;
GUI.dualWindow=false;

Scene:clear();
Scene.mode = Scene.MODE_VIEW;
Renderer.style=Renderer.STYLE_LOOKAROUND;
Renderer:resetView();
