import controlP5.*;

class DataGUI extends MainPanel
{
  BoxGridData data;
  FileGUI  file_ui;
  StyleGUI style_ui;
  BoxesGUI boxes_ui;
  CameraGUI camera_ui;
  OcclusionGUI occlusion_ui;

  public DataGUI(BoxGridData data)
  {
    this.data = data;
    file_ui   = new FileGUI(data, true);
    style_ui  = new StyleGUI(data.style);
    boxes_ui  = new BoxesGUI(data.boxes);
    camera_ui = new CameraGUI(data.camera);
    occlusion_ui = new OcclusionGUI(data.occlusion);
  }

  void Init()
  {
    addTab(file_ui);
    addTab(style_ui);
    addTab(boxes_ui);
    addTab(camera_ui);
    addTab(occlusion_ui);

    super.Init();

    cp5.getTab("Camera").bringToFront();
  }

  @Override
  void mouseDragged()
  {
    super.mouseDragged();

    // Camera interactions apply only when dragging the canvas, not GUI widgets/tabs.
    if (dragging_panel == null && !cp5.isMouseOver())
    {
      float dx = mouseX - pmouseX;
      float dy = mouseY - pmouseY;

      if (mouseButton == RIGHT)
      {
        data.camera.panTargetByScreenDelta(dx, dy, data.page.global_scale);
      }
      else
      {
        data.camera.yaw = data.camera.wrapAngle(data.camera.yaw + dx * 0.01);
        data.camera.pitch = constrain(data.camera.pitch + dy * 0.01, -HALF_PI + 0.001, HALF_PI - 0.001);
        data.camera.markChanged();
      }
    }
  }

  @Override
  void mouseWheel(processing.event.MouseEvent event)
  {
    if (dragging_panel != null || cp5.isMouseOver())
      return;

    data.camera.zoomByWheel(event.getCount());
  }
}
