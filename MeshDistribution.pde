import controlP5.*;

abstract class MeshDistributionData extends GenericData
{
  MeshDistributionData(String chapter_name)
  {
    super(chapter_name);
  }

  abstract void createMeshes(ArrayList<Mesh> out_meshes);
}

class DataBoxes extends GenericData
{
  static final int MODE_GRID = 0;
  static final int MODE_TUBE = 1;

  int distribution_mode = MODE_GRID;

  GridDistributionData grid = new GridDistributionData();
  TubeDistributionData tube = new TubeDistributionData();

  DataBoxes()
  {
    super("Boxes");
    addChapter(grid);
    addChapter(tube);
  }

  void createMeshes(ArrayList<Mesh> out_meshes)
  {
    if (distribution_mode == MODE_TUBE)
      tube.createMeshes(out_meshes);
    else
      grid.createMeshes(out_meshes);
  }

  void LoadJson(JSONObject src)
  {
    if (src == null) return;

    distribution_mode = src.getInt("distribution_mode", distribution_mode);

    JSONObject grid_json = src.getJSONObject(grid.chapter_name);
    JSONObject tube_json = src.getJSONObject(tube.chapter_name);

    
    grid.LoadJson(grid_json);
    tube.LoadJson(tube_json);
  }

  JSONObject SaveJson()
  {
    JSONObject dest = new JSONObject();
    dest.setInt("distribution_mode", distribution_mode);
    dest.setJSONObject(grid.chapter_name, grid.SaveJson());
    dest.setJSONObject(tube.chapter_name, tube.SaveJson());
    return dest;
  }
}

class BoxesGUI extends GUIPanel
{
  DataBoxes boxes;
  myRadioButton distribution_mode;

  GridDistributionGUI grid_ui;
  TubeDistributionGUI tube_ui;

  BoxesGUI(DataBoxes boxes)
  {
    super("Meshes", boxes);
    this.boxes = boxes;
    this.grid_ui = new GridDistributionGUI(boxes.grid);
    this.tube_ui = new TubeDistributionGUI(boxes.tube);
  }

  void setupControls()
  {
    super.Init();

    ArrayList<String> distribution_modes = new ArrayList<String>();
    distribution_modes.add("Grid");
    distribution_modes.add("Tube");
    distribution_mode = addRadio("distribution_mode", distribution_modes);

    grid_ui.setupControls(this);
    tube_ui.setupControls(this);
  }

  void updateDistributionVisibility()
  {
    boolean is_grid = boxes.distribution_mode == DataBoxes.MODE_GRID;
    grid_ui.setVisible(is_grid);
    tube_ui.setVisible(!is_grid);
  }

  void setGUIValues()
  {
    if ((int)distribution_mode.getValue() != boxes.distribution_mode)
      distribution_mode.activate(boxes.distribution_mode);

    grid_ui.setGUIValues();
    tube_ui.setGUIValues();
    updateDistributionVisibility();
  }

  void update_ui()
  {
    if ((int)distribution_mode.getValue() != boxes.distribution_mode)
      distribution_mode.activate(boxes.distribution_mode);

    updateDistributionVisibility();
  }
}
