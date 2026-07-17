import controlP5.*;
import processing.pdf.*;
import processing.dxf.*;
import processing.svg.*;

BoxGridData data;
DataGUI dataGui;

PGraphics current_graphics;
ControlP5 cp5;

ArrayList<Mesh> meshList = new ArrayList<Mesh>();
PolylineGroup lineGroup = new PolylineGroup();
LineBuilder lineBuilder;

float hud_last_lines_gen_ms = 0;

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
  lineBuilder = new LineBuilder(data);

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
  boolean occlusion_changed = data.occlusion.changed;
  boolean page_changed   = data.page.changed;

  // if (occlusion_changed)
  // {
  //   println("[Occlusion] enabled=" + data.occlusion.enabled +
  //     " zbuffer_scale=" + nf(data.occlusion.zbuffer_scale, 1, 2) +
  //     " sample_step_px=" + nf(data.occlusion.sample_step_px, 1, 2) +
  //     " depth_bias=" + nf(data.occlusion.depth_bias, 1, 4) +
  //     " min_visible_segment_px=" + nf(data.occlusion.min_visible_segment_px, 1, 2));
  // }

  if (boxes_changed)
    buildBoxes();

  if (boxes_changed || camera_changed || occlusion_changed)
  {
    long lines_start_ns = System.nanoTime();
    lineBuilder.buildLinesFromMeshes(meshList, lineGroup);
    hud_last_lines_gen_ms = (System.nanoTime() - lines_start_ns) / 1000000.0;
  }

  if (boxes_changed || camera_changed || occlusion_changed || page_changed)
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
  drawHud();
}

void drawHud()
{
  if (_record)
    return;

  String hud_text = "Lines: " + lineGroup.size()
    + " | Lines gen: " + nf(hud_last_lines_gen_ms, 1, 2) + " ms";

  pushStyle();
  textAlign(LEFT, BOTTOM);
  textSize(13);

  float padding = 10;
  float tw = textWidth(hud_text);
  float th = textAscent() + textDescent();
  float x = padding;
  float y = height - padding;

  noStroke();
  fill(0, 150);
  rect(x - 6, y - th - 6, tw + 12, th + 10, 4);

  fill(255);
  text(hud_text, x, y);
  popStyle();
}

void buildBoxes()
{
  data.boxes.createMeshes(meshList);
}
