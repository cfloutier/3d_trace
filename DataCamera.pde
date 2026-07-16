import controlP5.*;

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

class CameraData extends GenericData
{
  static final int PROJECTION_ORTHO = 0;
  static final int PROJECTION_PERSPECTIVE = 1;
  static final float TARGET_DISTANCE_MIN = 50;
  static final float TARGET_DISTANCE_MAX = 10000;
  static final float FOCAL_DISTANCE_MIN = 100;
  static final float FOCAL_DISTANCE_MAX = 4000;
  static final float ORTHO_ZOOM_MIN = 0.05;
  static final float ORTHO_ZOOM_MAX = 20;

  CameraData()
  {
    super("Camera");
  }

  int projection_mode = PROJECTION_PERSPECTIVE;

  float fov = 60;
  // Distance between camera and target (orbit radius).
  float target_distance = 900;
  // Perspective focal distance scale (camera lens strength).
  float focal_distance = 900;
  // Zoom factor used only in orthographic mode.
  float ortho_zoom = 1;
  float yaw = 0;
  float pitch = -0.55;

  float target_x = 0;
  float target_y = 0;
  float target_z = 0;

  CameraFrame buildFrame()
  {
    PVector camera_pos = getCameraPosition();
    PVector forward = PVector.sub(getTarget(), camera_pos);
    forward.normalize();

    PVector world_up = new PVector(0, 1, 0);
    PVector right = forward.cross(world_up, null);
    if (right.magSq() < 1e-6)
      right = new PVector(1, 0, 0);
    else
      right.normalize();

    PVector up = right.cross(forward, null);
    up.normalize();

    float focal = focal_distance / tan(radians(fov) * 0.5);
    return new CameraFrame(camera_pos, right, up, forward, focal);
  }

  ProjectedPoint projectPointWithDepth(PVector world, CameraFrame frame)
  {
    PVector relative = PVector.sub(world, frame.camera_pos);
    float x = relative.dot(frame.right);
    float y = relative.dot(frame.up);
    float z = relative.dot(frame.forward);

    if (projection_mode == PROJECTION_ORTHO)
      return new ProjectedPoint(x * ortho_zoom, y * ortho_zoom, z);

    float safe_z = max(0.001, z);
    return new ProjectedPoint(x * frame.focal / safe_z, y * frame.focal / safe_z, z);
  }

  PVector projectPoint(PVector world)
  {
    ProjectedPoint p = projectPointWithDepth(world, buildFrame());
    return new PVector(p.x, p.y);
  }

  PVector getTarget()
  {
    return new PVector(target_x, target_y, target_z);
  }

  PVector getCameraPosition()
  {
    float cosPitch = cos(pitch);
    return new PVector(
      target_x + target_distance * cosPitch * sin(yaw),
      target_y + target_distance * sin(pitch),
      target_z + target_distance * cosPitch * cos(yaw)
    );
  }

  void markChanged()
  {
    changed = true;
  }

  void setTargetDistance(float newDistance)
  {
    target_distance = constrain(newDistance, TARGET_DISTANCE_MIN, TARGET_DISTANCE_MAX);
    markChanged();
  }

  void zoomByWheel(float wheelCount)
  {
    // Mouse wheel > 0 means zoom out, < 0 means zoom in.
    float factor = pow(1.08, wheelCount);
    if (projection_mode == PROJECTION_ORTHO)
      setOrthoZoom(ortho_zoom / factor);
    else
      setTargetDistance(target_distance * factor);
  }

  void setOrthoZoom(float newZoom)
  {
    ortho_zoom = constrain(newZoom, ORTHO_ZOOM_MIN, ORTHO_ZOOM_MAX);
    markChanged();
  }

  void resetToView(float newYaw, float newPitch)
  {
    yaw = wrapAngle(newYaw);
    pitch = newPitch;
    markChanged();
  }

  float wrapAngle(float angle)
  {
    while (angle <= -PI) angle += TWO_PI;
    while (angle > PI) angle -= TWO_PI;
    return angle;
  }

  void lookFront()  { resetToView(0, -0.01); }
  void lookBack()   { resetToView(PI, -0.01); }
  void lookLeft()   { resetToView(-HALF_PI, -0.01); }
  void lookRight()  { resetToView(HALF_PI, -0.01); }
  void lookIso()    { resetToView(QUARTER_PI, -0.6); }
  void lookTop()    { resetToView(0, HALF_PI - 0.001); }

  void LoadJson(JSONObject src)
  {
    if (src == null) return;

    projection_mode = src.getInt("projection_mode", projection_mode);
    fov = src.getFloat("fov", fov);
    target_distance = src.getFloat("target_distance", target_distance);
    focal_distance = src.getFloat("focal_distance", focal_distance);
    ortho_zoom = src.getFloat("ortho_zoom", ortho_zoom);
    yaw = src.getFloat("yaw", yaw);
    pitch = src.getFloat("pitch", pitch);
    target_x = src.getFloat("target_x", target_x);
    target_y = src.getFloat("target_y", target_y);
    target_z = src.getFloat("target_z", target_z);
  }

  JSONObject SaveJson()
  {
    JSONObject dest = new JSONObject();
    dest.setInt("projection_mode", projection_mode);
    dest.setFloat("fov", fov);
    dest.setFloat("target_distance", target_distance);
    dest.setFloat("focal_distance", focal_distance);
    dest.setFloat("ortho_zoom", ortho_zoom);
    dest.setFloat("yaw", yaw);
    dest.setFloat("pitch", pitch);
    dest.setFloat("target_x", target_x);
    dest.setFloat("target_y", target_y);
    dest.setFloat("target_z", target_z);
    return dest;
  }
}


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