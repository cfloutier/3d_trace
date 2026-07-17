class TubeDistributionData extends MeshDistributionData
{
  TubeDistributionData()
  {
    super("Tube");
  }

  int   radial_count = 24;
  int   levels = 8;
  float radius = 450;
  float height_span = 600;
  float spacing = 90;
  float box_height = 120;

  @Override
  void createMeshes(ArrayList<Mesh> out_meshes)
  {
    out_meshes.clear();

    int rc = max(3, radial_count);
    int lv = max(1, levels);

    float safe_radius = max(1, radius);
    float safe_height_span = max(0, height_span);
    float size_x = spacing * 0.35;
    float size_z = spacing * 0.35;
    float size_y = box_height;

    for (int level = 0; level < lv; level++)
    {
      float center_y = (lv <= 1) ? 0 : map(level, 0, lv - 1, -safe_height_span * 0.5, safe_height_span * 0.5);

      for (int i = 0; i < rc; i++)
      {
        float a = TWO_PI * i / rc;
        float center_x = cos(a) * safe_radius;
        float center_z = sin(a) * safe_radius;
        out_meshes.add(new Box3D(center_x, center_y, center_z, size_x, size_y, size_z));
      }
    }
  }
}

class TubeDistributionGUI
{
  TubeDistributionData data;
  ControlsGroup controls;

  Slider radial_count;
  Slider levels;
  Slider radius;
  Slider height_span;
  Slider spacing;
  Slider box_height;

  TubeDistributionGUI(TubeDistributionData data)
  {
    this.data = data;
  }

  void setupControls(BoxesGUI panel)
  {
    controls = new ControlsGroup(data);

    panel.space();
    panel.addLabel("Tube");
    radial_count = panel.addIntSlider("radial_count", "Radial Count", data, 3, 240);
    controls.add(radial_count);
    levels = panel.addIntSlider("levels", "Levels", data, 1, 120);
    controls.add(levels);
    panel.nextLine();

    radius = panel.addSlider("radius", "Radius", data, 10, 2500);
    controls.add(radius);
    height_span = panel.addSlider("height_span", "Height Span", data, 0, 2500);
    controls.add(height_span);
    panel.nextLine();

    spacing = panel.addSlider("spacing", "Box Spacing", data, 10, 400);
    controls.add(spacing);
    box_height = panel.addSlider("box_height", "Box Height", data, 10, 1000);
    controls.add(box_height);
  }

  void setGUIValues()
  {
    controls.updateFromData();
  }

  void setVisible(boolean visible)
  {
    if (visible) controls.show();
    else controls.hide();
  }
}
