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

int last_occlusion_debug_ms = -100000;

class EdgeProjected
{
  ProjectedPoint a;
  ProjectedPoint b;

  EdgeProjected(ProjectedPoint a, ProjectedPoint b)
  {
    this.a = a;
    this.b = b;
  }
}

class TriangleProjected
{
  ProjectedPoint a;
  ProjectedPoint b;
  ProjectedPoint c;

  TriangleProjected(ProjectedPoint a, ProjectedPoint b, ProjectedPoint c)
  {
    this.a = a;
    this.b = b;
    this.c = c;
  }
}

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
    if (millis() - last_occlusion_debug_ms > 250)
    {
      // println("[Render] rebuild lines | boxes_changed=" + boxes_changed +
      //   " camera_changed=" + camera_changed +
      //   " occlusion_changed=" + occlusion_changed +
      //   " occlusion_enabled=" + data.occlusion.enabled +
      //   " boxes=" + boxList.size());
      last_occlusion_debug_ms = millis();
    }
    buildLinesFromBoxes();
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
  if (data.occlusion.enabled)
  {
    // println("[Render] using occlusion path");
    buildOccludedLinesFromBoxes();
    return;
  }

  // println("[Render] using normal wireframe path");

  lineGroup.clear();

  for (int i = 0; i < boxList.size(); i++)
  {
    boxList.get(i).addWireframe(lineGroup, data.camera);
  }
}


void buildOccludedLinesFromBoxes()
{
  lineGroup.clear();

  if (boxList.size() == 0)
    return;

  CameraFrame frame = data.camera.buildFrame();

  ArrayList<EdgeProjected> edges = new ArrayList<EdgeProjected>();
  ArrayList<TriangleProjected> triangles = new ArrayList<TriangleProjected>();

  final int[][] EDGE_IDX = {
    {0, 1}, {1, 2}, {2, 3}, {3, 0},
    {4, 5}, {5, 6}, {6, 7}, {7, 4},
    {0, 4}, {1, 5}, {2, 6}, {3, 7}
  };

  final int[][] TRI_IDX = {
    {0, 1, 2}, {0, 2, 3},
    {4, 6, 5}, {4, 7, 6},
    {0, 5, 1}, {0, 4, 5},
    {3, 2, 6}, {3, 6, 7},
    {0, 3, 7}, {0, 7, 4},
    {1, 5, 6}, {1, 6, 2}
  };

  for (int b = 0; b < boxList.size(); b++)
  {
    PVector[] v = boxList.get(b).getVertices();
    ProjectedPoint[] p = new ProjectedPoint[8];

    for (int i = 0; i < 8; i++)
    {
      p[i] = data.camera.projectPointWithDepth(v[i], frame);
    }

    for (int i = 0; i < EDGE_IDX.length; i++)
      edges.add(new EdgeProjected(p[EDGE_IDX[i][0]], p[EDGE_IDX[i][1]]));

    for (int i = 0; i < TRI_IDX.length; i++)
      triangles.add(new TriangleProjected(p[TRI_IDX[i][0]], p[TRI_IDX[i][1]], p[TRI_IDX[i][2]]));
  }

  float[] domain = getOcclusionDomain();
  float minX = domain[0];
  float maxX = domain[1];
  float minY = domain[2];
  float maxY = domain[3];

  int zW = max(64, (int)(width * data.occlusion.zbuffer_scale));
  int zH = max(64, (int)(height * data.occlusion.zbuffer_scale));
  float[] zbuf = new float[zW * zH];
  for (int i = 0; i < zbuf.length; i++) zbuf[i] = Float.MAX_VALUE;

  rasterizeTrianglesToDepthBuffer(triangles, zbuf, zW, zH, minX, maxX, minY, maxY);

  int kept = emitVisibleEdgeSegments(edges, zbuf, zW, zH, minX, maxX, minY, maxY,
    data.occlusion.sample_step_px,
    data.occlusion.depth_bias,
    data.occlusion.min_visible_segment_px,
    lineGroup);

  if (millis() - last_occlusion_debug_ms > 250)
  {
    // println("[Occlusion] boxes=" + boxList.size() + " edges=" + edges.size() + " tris=" + triangles.size() +
    //   " zbuf=" + zW + "x" + zH + " kept_segments=" + kept +
    //   " domain=[" + nf(minX, 1, 1) + "," + nf(maxX, 1, 1) + "]x[" + nf(minY, 1, 1) + "," + nf(maxY, 1, 1) + "]");
    last_occlusion_debug_ms = millis();
  }
}


float[] getOcclusionDomain()
{
  float safeScale = max(0.001, data.page.global_scale);
  float halfW = width / (2.0 * safeScale);
  float halfH = height / (2.0 * safeScale);

  if (data.page.clipping)
  {
    halfW = min(halfW, data.page.clip_width * 0.5);
    halfH = min(halfH, data.page.clip_height * 0.5);
  }

  return new float[] { -halfW, halfW, -halfH, halfH };
}


void rasterizeTrianglesToDepthBuffer(ArrayList<TriangleProjected> triangles, float[] zbuf,
  int zW, int zH, float minX, float maxX, float minY, float maxY)
{
  for (int i = 0; i < triangles.size(); i++)
  {
    TriangleProjected t = triangles.get(i);

    if (t.a.z <= 0 || t.b.z <= 0 || t.c.z <= 0)
      continue;

    float x0 = mapToBufferX(t.a.x, minX, maxX, zW);
    float y0 = mapToBufferY(t.a.y, minY, maxY, zH);
    float x1 = mapToBufferX(t.b.x, minX, maxX, zW);
    float y1 = mapToBufferY(t.b.y, minY, maxY, zH);
    float x2 = mapToBufferX(t.c.x, minX, maxX, zW);
    float y2 = mapToBufferY(t.c.y, minY, maxY, zH);

    float area = edgeFunction(x0, y0, x1, y1, x2, y2);
    if (abs(area) < 1e-9)
      continue;

    int minPx = max(0, (int)floor(min(x0, min(x1, x2))));
    int maxPx = min(zW - 1, (int)ceil(max(x0, max(x1, x2))));
    int minPy = max(0, (int)floor(min(y0, min(y1, y2))));
    int maxPy = min(zH - 1, (int)ceil(max(y0, max(y1, y2))));

    for (int py = minPy; py <= maxPy; py++)
    {
      float cy = py + 0.5;
      for (int px = minPx; px <= maxPx; px++)
      {
        float cx = px + 0.5;

        float w0 = edgeFunction(x1, y1, x2, y2, cx, cy) / area;
        float w1 = edgeFunction(x2, y2, x0, y0, cx, cy) / area;
        float w2 = edgeFunction(x0, y0, x1, y1, cx, cy) / area;

        boolean inside = (w0 >= 0 && w1 >= 0 && w2 >= 0) || (w0 <= 0 && w1 <= 0 && w2 <= 0);
        if (!inside)
          continue;

        float z;
        if (data.camera.projection_mode == CameraData.PROJECTION_PERSPECTIVE)
        {
          float invz = w0 * t.a.invz + w1 * t.b.invz + w2 * t.c.invz;
          if (invz <= 1e-9)
            continue;
          z = 1.0 / invz;
        }
        else
        {
          z = w0 * t.a.z + w1 * t.b.z + w2 * t.c.z;
          if (z <= 0)
            continue;
        }

        int idx = px + py * zW;
        if (z < zbuf[idx])
          zbuf[idx] = z;
      }
    }
  }
}


int emitVisibleEdgeSegments(ArrayList<EdgeProjected> edges, float[] zbuf,
  int zW, int zH, float minX, float maxX, float minY, float maxY,
  float sampleStepPx, float depthBias, float minVisibleSegmentPx,
  PolylineGroup outGroup)
{
  int kept = 0;
  float stepPx = max(0.25, sampleStepPx);

  for (int i = 0; i < edges.size(); i++)
  {
    EdgeProjected e = edges.get(i);
    if (e.a.z <= 0 || e.b.z <= 0)
      continue;

    float sx0 = mapToBufferX(e.a.x, minX, maxX, zW);
    float sy0 = mapToBufferY(e.a.y, minY, maxY, zH);
    float sx1 = mapToBufferX(e.b.x, minX, maxX, zW);
    float sy1 = mapToBufferY(e.b.y, minY, maxY, zH);

    float segLenPx = dist(sx0, sy0, sx1, sy1);
    int steps = max(1, (int)ceil(segLenPx / stepPx));

    boolean runVisible = false;
    int hiddenStreak = 0;
    PVector runStart2D = null;
    PVector runEnd2D = null;
    float runStartSX = 0;
    float runStartSY = 0;
    float runEndSX = 0;
    float runEndSY = 0;

    for (int s = 0; s <= steps; s++)
    {
      float t = s / (float)steps;

      float x = lerp(e.a.x, e.b.x, t);
      float y = lerp(e.a.y, e.b.y, t);
      float z = lerp(e.a.z, e.b.z, t);

      float sx = mapToBufferX(x, minX, maxX, zW);
      float sy = mapToBufferY(y, minY, maxY, zH);

      boolean visible = isVisibleAgainstDepth(z, sx, sy, zbuf, zW, zH, depthBias);

      if (visible)
      {
        hiddenStreak = 0;
        if (!runVisible)
        {
          runVisible = true;
          runStart2D = new PVector(x, y);
          runEnd2D = new PVector(x, y);
          runStartSX = sx;
          runStartSY = sy;
          runEndSX = sx;
          runEndSY = sy;
        }
        else
        {
          runEnd2D = new PVector(x, y);
          runEndSX = sx;
          runEndSY = sy;
        }
      }
      else if (runVisible)
      {
        hiddenStreak++;

        // Ignore isolated hidden samples to avoid dashed cracks.
        if (hiddenStreak >= 2)
        {
          if (dist(runStartSX, runStartSY, runEndSX, runEndSY) >= minVisibleSegmentPx)
          {
            Polyline line = new Polyline();
            line.addPoint(runStart2D);
            line.addPoint(runEnd2D);
            outGroup.add(line);
            kept++;
          }
          runVisible = false;
          hiddenStreak = 0;
        }
      }
    }

    if (runVisible && dist(runStartSX, runStartSY, runEndSX, runEndSY) >= minVisibleSegmentPx)
    {
      Polyline line = new Polyline();
      line.addPoint(runStart2D);
      line.addPoint(runEnd2D);
      outGroup.add(line);
      kept++;
    }
  }

  return kept;
}


boolean isVisibleAgainstDepth(float z, float sx, float sy, float[] zbuf, int zW, int zH, float depthBias)
{
  int ix = (int)round(sx);
  int iy = (int)round(sy);
  if (ix < 0 || ix >= zW || iy < 0 || iy >= zH)
    return true;

  // Conservative edge-friendly test: use the max depth in a 3x3 neighborhood
  // to avoid falsely hiding boundary lines at low z-buffer resolutions.
  float neighborhoodMax = -Float.MAX_VALUE;
  for (int oy = -1; oy <= 1; oy++)
  {
    int py = iy + oy;
    if (py < 0 || py >= zH) continue;
    for (int ox = -1; ox <= 1; ox++)
    {
      int px = ix + ox;
      if (px < 0 || px >= zW) continue;
      float zv = zbuf[px + py * zW];
      if (zv < Float.MAX_VALUE && zv > neighborhoodMax)
        neighborhoodMax = zv;
    }
  }

  if (neighborhoodMax == -Float.MAX_VALUE)
    return true;

  float effectiveBias = max(depthBias, 0.0025 * z);
  return z <= neighborhoodMax + effectiveBias;
}


float mapToBufferX(float x, float minX, float maxX, int zW)
{
  return (x - minX) / max(1e-6, maxX - minX) * (zW - 1);
}

float mapToBufferY(float y, float minY, float maxY, int zH)
{
  return (y - minY) / max(1e-6, maxY - minY) * (zH - 1);
}

float edgeFunction(float ax, float ay, float bx, float by, float px, float py)
{
  return (px - ax) * (by - ay) - (py - ay) * (bx - ax);
}
