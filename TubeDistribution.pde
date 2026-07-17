class TubeDistributionData extends MeshDistributionData
{
  TubeDistributionData()
  {
    super("Tube");
  }

  int   radial_count = 24;
  int   levels = 8;
  float radius_min = 300;
  float radius_max = 600;
  float base_y_min = -300;
  float base_y_max = 300;
  float spacing = 90;
  float box_length_min = 80;
  float box_length_max = 180;

  @Override
  void createMeshes(ArrayList<Mesh> out_meshes, int random_seed)
  {
    out_meshes.clear();
    randomSeed(random_seed);

    int rc = max(3, radial_count);
    int lv = max(1, levels);
    int total_boxes = rc * lv;

    float rMin = min(radius_min, radius_max);
    float rMax = max(radius_min, radius_max);

    float baseMin = min(base_y_min, base_y_max);
    float baseMax = max(base_y_min, base_y_max);

    float lenMin = max(1, min(box_length_min, box_length_max));
    float lenMax = max(1, max(box_length_min, box_length_max));

    float size_x = spacing * 0.35;
    float size_z = spacing * 0.35;

    for (int i = 0; i < total_boxes; i++)
    {
      float a = random(TWO_PI);
      float radius = random(rMin, rMax);
      float baseY = random(baseMin, baseMax);
      float size_y = random(lenMin, lenMax);

      float center_x = cos(a) * radius;
      float center_z = sin(a) * radius;
      float center_y = baseY + size_y * 0.5;

      out_meshes.add(new Box3D(center_x, center_y, center_z, size_x, size_y, size_z));
    }
  }
}

class TubeDistributionGUI
{
  TubeDistributionData data;
  ControlsGroup controls;

  Slider radial_count;
  Slider levels;
  Slider radius_min;
  Slider radius_max;
  Slider base_y_min;
  Slider base_y_max;
  Slider spacing;
  Slider box_length_min;
  Slider box_length_max;

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

    radius_min = panel.addSlider("radius_min", "Radius Min", data, 10, 2500);
    controls.add(radius_min);
    radius_max = panel.addSlider("radius_max", "Radius Max", data, 10, 2500);
    controls.add(radius_max);
    panel.nextLine();

    base_y_min = panel.addSlider("base_y_min", "Base Y Min", data, -2000, 2000);
    controls.add(base_y_min);
    base_y_max = panel.addSlider("base_y_max", "Base Y Max", data, -2000, 2000);
    controls.add(base_y_max);
    panel.nextLine();

    spacing = panel.addSlider("spacing", "Box Spacing", data, 10, 400);
    controls.add(spacing);
    box_length_min = panel.addSlider("box_length_min", "Length Min", data, 10, 2000);
    controls.add(box_length_min);
    box_length_max = panel.addSlider("box_length_max", "Length Max", data, 10, 2000);
    controls.add(box_length_max);
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
