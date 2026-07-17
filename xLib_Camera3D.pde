import controlP5.*;


class CameraGUI extends GUIPanel
{
  CameraData camera;

  myRadioButton projection_mode;
  Slider fov;
  Slider target_distance;
  Slider focal_distance;
  Slider ortho_zoom;
  Slider yaw;
  Slider pitch;

  CameraGUI(CameraData camera)
  {
    super("Camera", camera);
    this.camera = camera;
  }

  void setupControls()
  {
    super.Init();

    addButton("Front").plugTo(this, "lookFront");
    addButton("Back").plugTo(this, "lookBack");
    addButton("Left").plugTo(this, "lookLeft");
    addButton("Right").plugTo(this, "lookRight");
    addButton("Iso").plugTo(this, "lookIso");
    addButton("Top").plugTo(this, "lookTop");
    nextLine();

    yaw = addSlider("yaw", "Yaw", -PI, PI);
    pitch = addSlider("pitch", "Pitch", -HALF_PI + 0.005, HALF_PI - 0.005);
    target_distance = addSlider("target_distance", "Distance", CameraData.TARGET_DISTANCE_MIN, CameraData.TARGET_DISTANCE_MAX);
    nextLine();
    
    ArrayList<String> projection_modes = new ArrayList<String>();
    projection_modes.add("Ortho");
    projection_modes.add("Perspective");
    projection_mode = addRadio("projection_mode", projection_modes);
    float start_pos = xPos;
    fov = addSlider("fov", "FOV", 10, 180);
    focal_distance = addSlider("focal_distance", "Focal Distance", CameraData.FOCAL_DISTANCE_MIN, CameraData.FOCAL_DISTANCE_MAX);
    xPos = start_pos;
    ortho_zoom = addSlider("ortho_zoom", "Ortho Zoom", CameraData.ORTHO_ZOOM_MIN, CameraData.ORTHO_ZOOM_MAX);
}

  void setGUIValues()
  {
    fov.setValue(camera.fov);
    target_distance.setValue(camera.target_distance);
    focal_distance.setValue(camera.focal_distance);
    ortho_zoom.setValue(camera.ortho_zoom);
    yaw.setValue(camera.yaw);
    pitch.setValue(camera.pitch);
    projection_mode.activate(camera.projection_mode);
    updateProjectionControlsVisibility();
  }

  void updateProjectionControlsVisibility()
  {
    boolean is_ortho = camera.projection_mode == CameraData.PROJECTION_ORTHO;

    if (is_ortho)
    {
      fov.hide();
      focal_distance.hide();
      ortho_zoom.show();
    }
    else
    {
      fov.show();
      focal_distance.show();
      ortho_zoom.hide();
    }
  }

  void lookFront()  { camera.lookFront(); setGUIValues(); }
  void lookBack()   { camera.lookBack(); setGUIValues(); }
  void lookLeft()   { camera.lookLeft(); setGUIValues(); }
  void lookRight()  { camera.lookRight(); setGUIValues(); }
  void lookIso()    { camera.lookIso(); setGUIValues(); }
  void lookTop()    { camera.lookTop(); setGUIValues(); }

  void update_ui()
  {
    fov.setValue(camera.fov);
    target_distance.setValue(camera.target_distance);
    focal_distance.setValue(camera.focal_distance);
    ortho_zoom.setValue(camera.ortho_zoom);
    yaw.setValue(camera.yaw);
    pitch.setValue(camera.pitch);
    updateProjectionControlsVisibility();
  }
}


class CameraFrame
{
  PVector camera_pos;
  PVector right;
  PVector up;
  PVector forward;
  float focal;

  CameraFrame(PVector camera_pos, PVector right, PVector up, PVector forward, float focal)
  {
    this.camera_pos = camera_pos;
    this.right = right;
    this.up = up;
    this.forward = forward;
    this.focal = focal;
  }
}

class ProjectedPoint
{
  float x;
  float y;
  float z;
  float invz;

  ProjectedPoint(float x, float y, float z)
  {
    this.x = x;
    this.y = y;
    this.z = z;
    this.invz = (z > 1e-6) ? (1.0 / z) : 0;
  }
}

interface CameraProjector3D
{
  CameraFrame buildFrame();
  ProjectedPoint projectPointWithDepth(PVector world, CameraFrame frame);
  PVector projectPoint(PVector world);
}