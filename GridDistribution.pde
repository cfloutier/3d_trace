class GridDistributionData extends MeshDistributionData
{
  GridDistributionData()
  {
    super("Grid");
  }

  int   count      = 16;
  float spacing    = 90;
  float box_height = 120;

  @Override
  void createMeshes(ArrayList<Mesh> out_meshes)
  {
    out_meshes.clear();

    int total_boxes = max(1, count);
    int columns = max(1, (int)ceil(sqrt((float)total_boxes)));
    int rows = max(1, (int)ceil((float)total_boxes / columns));

    float size_x = spacing * 0.35;
    float size_z = spacing * 0.35;
    float half_depth = (rows - 1) * spacing * 0.5;
    float base_center_y = 0;
    float size_y = box_height;

    for (int index = 0; index < total_boxes; index++)
    {
      int col = index % columns;
      int row = index / columns;
      int boxes_in_row = min(columns, total_boxes - row * columns);

      float row_half_width = (boxes_in_row - 1) * spacing * 0.5;
      float center_x = col * spacing - row_half_width;
      float center_z = row * spacing - half_depth;

      out_meshes.add(new Box3D(center_x, base_center_y, center_z, size_x, size_y, size_z));
    }
  }
}

class GridDistributionGUI
{
  GridDistributionData data;
  ControlsGroup controls;

  Slider count;
  Slider spacing;
  Slider box_height;

  GridDistributionGUI(GridDistributionData data)
  {
    this.data = data;
  }

  void setupControls(BoxesGUI panel)
  {
    controls = new ControlsGroup(data);

    panel.addLabel("Grid");
    count = panel.addIntSlider("count", "Count", data, 1, 4000);
    controls.add(count);
    spacing = panel.addSlider("spacing", "Spacing", data, 10, 400);
    controls.add(spacing);
    panel.nextLine();
    box_height = panel.addSlider("box_height", "Height", data, 10, 1000);
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
