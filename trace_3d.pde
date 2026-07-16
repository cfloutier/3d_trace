import controlP5.*;
import processing.pdf.*;
import processing.dxf.*;
import processing.svg.*;

BoxGridData data;
DataGUI dataGui;

PGraphics current_graphics;
ControlP5 cp5;

ArrayList<Box3D> boxList = new ArrayList<Box3D>();
PolylineGroup lineGroup = new PolylineGroup();

void setup()
{
  size(1200, 800);
  pixelDensity(1);
  surface.setResizable(true);

  data = new BoxGridData();
  dataGui = new DataGUI(data);

  setupControls();

  data.LoadSettings("./Settings/default.json");
  dataGui.setGUIValues();

  file_ui.export_group = lineGroup;  // enable direct SVG export
}

void setupControls()
{
  cp5 = new ControlP5(this);
  cp5.getTab("default").setLabel("Hide GUI");
  dataGui.Init();
}

void draw()
{
  start_draw();

  boolean boxes_changed = data.boxes.changed;
  boolean camera_changed = data.camera.changed;
  boolean page_changed   = data.page.changed;

  if (boxes_changed)
    buildBoxes();

  if (boxes_changed || camera_changed)
    buildLinesFromBoxes();

  if (boxes_changed || camera_changed || page_changed)
    file_ui.updateExportScale(lineGroup.getBoundingBox(data.page.clipping, data.page.clip_width, data.page.clip_height));

  dataGui.update_ui();
  data.reset_all_changes();

  // Debug: draw clipping rect border
  //if (data.page.clipping) {
  //  current_graphics.noFill();
  //  current_graphics.stroke(data.style.lineColor.col);
  //  current_graphics.rect(-data.page.clip_width / 2, -data.page.clip_height / 2,
  //                         data.page.clip_width, data.page.clip_height);
  //}

  lineGroup.draw(data.page.clipping, data.page.clip_width, data.page.clip_height);

  end_draw();

  dataGui.draw();
}

void buildBoxes()
{
  boxList.clear();

  int total_boxes = max(1, data.boxes.count);
  int columns = max(1, (int)ceil(sqrt((float)total_boxes)));
  int rows = max(1, (int)ceil((float)total_boxes / columns));

  float spacing = data.boxes.spacing;
  float size_x = spacing * 0.35;
  float size_z = spacing * 0.35;
  float half_depth = (rows - 1) * spacing * 0.5;
  float base_center_y = 0;
  float size_y = data.boxes.box_height;

  for (int index = 0; index < total_boxes; index++)
  {
    int col = index % columns;
    int row = index / columns;
    int boxes_in_row = min(columns, total_boxes - row * columns);

    float row_half_width = (boxes_in_row - 1) * spacing * 0.5;
    float center_x = col * spacing - row_half_width;
    float center_z = row * spacing - half_depth;

    boxList.add(new Box3D(center_x, base_center_y, center_z, size_x, size_y, size_z));
  }
}


void buildLinesFromBoxes()
{
  lineGroup.clear();

  for (int i = 0; i < boxList.size(); i++)
  {
    boxList.get(i).addWireframe(lineGroup, data.camera);
  }
}
