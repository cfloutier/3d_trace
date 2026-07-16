import controlP5.*;
import processing.pdf.*;
import processing.dxf.*;
import processing.svg.*;

CircleLinesData data;
DataGUI dataGui;

PGraphics current_graphics;
ControlP5 cp5;

PolylineGroup lineGroup = new PolylineGroup();

void setup()
{
  size(1200, 800);
  pixelDensity(1);
  surface.setResizable(true);

  data = new CircleLinesData();
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

  boolean circle_changed = data.circle.changed;
  boolean page_changed   = data.page.changed;
  data.reset_all_changes();

  if (circle_changed || page_changed)
    buildLines();

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

void buildLines()
{
  lineGroup.clear();

  int   n  = data.circle.resolution;
  int   nb = max(1, data.circle.count);

  for (int j = 1; j <= nb; j++)
  {
    float t  = (float)j / nb;                              // 0 (excluded) → 1
    float r  = t * data.circle.circle_size / 2.0;
    float rx = r * data.circle.aspect_ratio;
    float ry = r / data.circle.aspect_ratio;

    Polyline circle = new Polyline();
    for (int i = 0; i <= n; i++)
    {
      float a = TWO_PI * i / n;
      circle.addPoint(new PVector(cos(a) * rx, sin(a) * ry));
    }
    lineGroup.add(circle);
  }

  file_ui.updateExportScale(lineGroup.getBoundingBox(data.page.clipping, data.page.clip_width, data.page.clip_height));
}
