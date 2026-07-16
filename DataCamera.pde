import controlP5.*;

class CameraData extends GenericData
{
  static final int PROJECTION_ORTHO = 0;
  static final int PROJECTION_PERSPECTIVE = 1;

  CameraData()
  {
    super("Camera");
  }

  int projection_mode = PROJECTION_PERSPECTIVE;
  boolean table_top_mode = true;

  float fov = 45;
  float distance = 900;
  float yaw = 0;
  float pitch = -0.55;

  float target_x = 0;
  float target_y = 0;
  float target_z = 0;

  PVector projectPoint(PVector world)
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

    PVector relative = PVector.sub(world, camera_pos);
    float x = relative.dot(right);
    float y = relative.dot(up);
    float z = relative.dot(forward);

    if (projection_mode == PROJECTION_ORTHO)
      return new PVector(x, y);

    float safe_z = max(0.001, z);
    float focal = 1.0 / tan(radians(fov) * 0.5);
    return new PVector(x * focal / safe_z, y * focal / safe_z);
  }

  PVector getTarget()
  {
    return new PVector(target_x, target_y, target_z);
  }

  PVector getCameraPosition()
  {
    float cosPitch = cos(pitch);
    return new PVector(
      target_x + distance * cosPitch * sin(yaw),
      target_y + distance * sin(pitch),
      target_z + distance * cosPitch * cos(yaw)
    );
  }

  void markChanged()
  {
    changed = true;
  }

  void resetToView(float newYaw, float newPitch)
  {
    yaw = newYaw;
    pitch = newPitch;
    markChanged();
  }

  void lookFront()  { resetToView(0, -0.55); }
  void lookBack()   { resetToView(PI, -0.55); }
  void lookLeft()   { resetToView(-HALF_PI, -0.55); }
  void lookRight()  { resetToView(HALF_PI, -0.55); }
  void lookIso()    { resetToView(QUARTER_PI, -0.6); }
  void lookTop()    { resetToView(0, -1.45); }

  void LoadJson(JSONObject src)
  {
    if (src == null) return;

    projection_mode = src.getInt("projection_mode", projection_mode);
    table_top_mode = src.getBoolean("table_top_mode", table_top_mode);
    fov = src.getFloat("fov", fov);
    distance = src.getFloat("distance", distance);
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
    dest.setBoolean("table_top_mode", table_top_mode);
    dest.setFloat("fov", fov);
    dest.setFloat("distance", distance);
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
  Toggle table_top_mode;
  Slider fov;
  Slider distance;
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

    table_top_mode = addToggle("table_top_mode", "Table top", camera);
    fov = addSlider("fov", "FOV", 10, 120);
    nextLine();
    distance = addSlider("distance", "Distance", 100, 3000);
    yaw = addSlider("yaw", "Yaw", -PI, PI);
    nextLine();
    pitch = addSlider("pitch", "Pitch", -HALF_PI + 0.05, HALF_PI - 0.05);

    ArrayList<String> projection_modes = new ArrayList<String>();
    projection_modes.add("Ortho");
    projection_modes.add("Perspective");
    projection_mode = addRadio("projection_mode", projection_modes);
  }

  void setGUIValues()
  {
    table_top_mode.setValue(camera.table_top_mode);
    fov.setValue(camera.fov);
    distance.setValue(camera.distance);
    yaw.setValue(camera.yaw);
    pitch.setValue(camera.pitch);
    projection_mode.activate(camera.projection_mode);
  }

  void lookFront()  { camera.lookFront(); setGUIValues(); }
  void lookBack()   { camera.lookBack(); setGUIValues(); }
  void lookLeft()   { camera.lookLeft(); setGUIValues(); }
  void lookRight()  { camera.lookRight(); setGUIValues(); }
  void lookIso()    { camera.lookIso(); setGUIValues(); }
  void lookTop()    { camera.lookTop(); setGUIValues(); }

  void update_ui()
  {
    table_top_mode.setValue(camera.table_top_mode);
    fov.setValue(camera.fov);
    distance.setValue(camera.distance);
    yaw.setValue(camera.yaw);
    pitch.setValue(camera.pitch);
  }

  boolean mousePressed()
  {
    if (cp5.isMouseOver())
      return false;

    drag_start_mouse_x = mouseX;
    drag_start_mouse_y = mouseY;
    drag_start_yaw = camera.yaw;
    drag_start_pitch = camera.pitch;
    drag_start_distance = camera.distance;
    return true;
  }

  int drag_start_mouse_x;
  int drag_start_mouse_y;
  float drag_start_yaw;
  float drag_start_pitch;
  float drag_start_distance;

  void mouseDragged()
  {
    float dx = mouseX - drag_start_mouse_x;
    float dy = mouseY - drag_start_mouse_y;

    camera.yaw = drag_start_yaw + dx * 0.01;
    if (camera.table_top_mode)
    {
      camera.pitch = drag_start_pitch;
      camera.distance = max(50, drag_start_distance + dy * 2.0);
    }
    else
    {
      camera.pitch = constrain(drag_start_pitch + dy * 0.01, -HALF_PI + 0.05, HALF_PI - 0.05);
      camera.distance = drag_start_distance;
    }

    camera.markChanged();
    setGUIValues();
  }

  void mouseReleased()
  {
    camera.markChanged();
  }
}