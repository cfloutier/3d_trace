class LineBuilder
{
  static final int STAGE_IDLE = 0;
  static final int STAGE_COLLECT = 1;
  static final int STAGE_RASTERIZE = 2;
  static final int STAGE_EMIT = 3;

  BoxGridData data;
  PolylineGroup previewGroup = new PolylineGroup();

  ArrayList<Mesh> sourceMeshes = null;
  PolylineGroup finalGroup = null;
  ArrayList<EdgeProjected> edges = new ArrayList<EdgeProjected>();
  ArrayList<TriangleProjected> triangles = new ArrayList<TriangleProjected>();

  CameraFrame frame = null;
  double[] zbuf = null;
  float minX, maxX, minY, maxY;
  int zW = 0;
  int zH = 0;

  int stage = STAGE_IDLE;
  int meshIndex = 0;
  int triangleIndex = 0;
  int edgeIndex = 0;
  boolean busy = false;
  boolean occlusionMode = false;
  long startNs = 0;
  int last_occlusion_debug_ms = -100000;

  LineBuilder(BoxGridData data)
  {
    this.data = data;
  }

  void requestBuild(ArrayList<Mesh> meshList, PolylineGroup outGroup)
  {
    sourceMeshes = meshList;
    finalGroup = outGroup;
    startNs = System.nanoTime();

    if (data.occlusion.enabled)
    {
      previewGroup.clear();
      buildPreviewWireframe();
      beginOcclusionBuild();
      return;
    }

    stopBuild();
    finalGroup.clear();
    for (int i = 0; i < sourceMeshes.size(); i++)
      sourceMeshes.get(i).addWireframe(finalGroup, data.camera);
  }

  void buildPreviewWireframe()
  {
    previewGroup.clear();
    if (sourceMeshes == null) return;

    for (int i = 0; i < sourceMeshes.size(); i++)
      sourceMeshes.get(i).addWireframe(previewGroup, data.camera);
  }

  void beginOcclusionBuild()
  {
    busy = true;
    occlusionMode = true;
    stage = STAGE_COLLECT;
    meshIndex = 0;
    triangleIndex = 0;
    edgeIndex = 0;
    edges.clear();
    triangles.clear();
    frame = data.camera.buildFrame();
    zbuf = null;
  }

  void stopBuild()
  {
    busy = false;
    occlusionMode = false;
    stage = STAGE_IDLE;
  }

  boolean update(float timeBudgetSeconds)
  {
    if (!busy || !occlusionMode || sourceMeshes == null)
      return false;

    long deadlineNs = System.nanoTime() + (long)(max(0.01, timeBudgetSeconds) * 1000000000.0);

    while (busy && System.nanoTime() < deadlineNs)
    {
      if (stage == STAGE_COLLECT)
      {
        if (meshIndex >= sourceMeshes.size())
        {
          prepareRasterization();
          stage = STAGE_RASTERIZE;
          continue;
        }

        sourceMeshes.get(meshIndex).appendProjectedOcclusionGeometry(edges, triangles, data.camera, frame);
        meshIndex++;
      }
      else if (stage == STAGE_RASTERIZE)
      {
        if (triangleIndex >= triangles.size())
        {
          stage = STAGE_EMIT;
          finalGroup.clear();
          edgeIndex = 0;
          continue;
        }

        triangleIndex = rasterizeTrianglesToDepthBufferRange(triangleIndex, deadlineNs);
      }
      else if (stage == STAGE_EMIT)
      {
        if (edgeIndex >= edges.size())
        {
          previewGroup.clear();
          stopBuild();
          if (millis() - last_occlusion_debug_ms > 250)
            last_occlusion_debug_ms = millis();
          return true;
        }

        edgeIndex = emitVisibleEdgeSegmentsRange(edgeIndex, deadlineNs, finalGroup);
      }
      else
      {
        break;
      }
    }

    return !busy;
  }

  void prepareRasterization()
  {
    float[] domain = getOcclusionDomain();
    minX = domain[0];
    maxX = domain[1];
    minY = domain[2];
    maxY = domain[3];

    zW = max(64, (int)(width * data.occlusion.zbuffer_scale));
    zH = max(64, (int)(height * data.occlusion.zbuffer_scale));
    zbuf = new double[zW * zH];
    for (int i = 0; i < zbuf.length; i++)
      zbuf[i] = Double.MAX_VALUE;
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

  int rasterizeTrianglesToDepthBufferRange(int startIndex, long deadlineNs)
  {
    for (int i = startIndex; i < triangles.size(); i++)
    {
      if (System.nanoTime() >= deadlineNs)
        return i;

      TriangleProjected t = triangles.get(i);

      if (t.a.z <= 0 || t.b.z <= 0 || t.c.z <= 0)
        continue;

      double x0 = mapToBufferX((double)t.a.x, (double)minX, (double)maxX, zW);
      double y0 = mapToBufferY((double)t.a.y, (double)minY, (double)maxY, zH);
      double x1 = mapToBufferX((double)t.b.x, (double)minX, (double)maxX, zW);
      double y1 = mapToBufferY((double)t.b.y, (double)minY, (double)maxY, zH);
      double x2 = mapToBufferX((double)t.c.x, (double)minX, (double)maxX, zW);
      double y2 = mapToBufferY((double)t.c.y, (double)minY, (double)maxY, zH);

      double area = edgeFunctionD(x0, y0, x1, y1, x2, y2);
      if (Math.abs(area) < 1e-12)
        continue;

      int minPx = Math.max(0, (int)Math.floor(Math.min(x0, Math.min(x1, x2))));
      int maxPx = Math.min(zW - 1, (int)Math.ceil(Math.max(x0, Math.max(x1, x2))));
      int minPy = Math.max(0, (int)Math.floor(Math.min(y0, Math.min(y1, y2))));
      int maxPy = Math.min(zH - 1, (int)Math.ceil(Math.max(y0, Math.max(y1, y2))));

      for (int py = minPy; py <= maxPy; py++)
      {
        double cy = py + 0.5;
        for (int px = minPx; px <= maxPx; px++)
        {
          if (System.nanoTime() >= deadlineNs)
            return i;

          double cx = px + 0.5;

          double w0 = edgeFunctionD(x1, y1, x2, y2, cx, cy) / area;
          double w1 = edgeFunctionD(x2, y2, x0, y0, cx, cy) / area;
          double w2 = edgeFunctionD(x0, y0, x1, y1, cx, cy) / area;

          boolean inside = (w0 >= 0 && w1 >= 0 && w2 >= 0) || (w0 <= 0 && w1 <= 0 && w2 <= 0);
          if (!inside)
            continue;

          double z;
          if (data.camera.projection_mode == CameraData.PROJECTION_PERSPECTIVE)
          {
            double invz = w0 * t.a.invz + w1 * t.b.invz + w2 * t.c.invz;
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

    return triangles.size();
  }

  int emitVisibleEdgeSegmentsRange(int startIndex, long deadlineNs, PolylineGroup outGroup)
  {
    float stepPx = max(0.25, data.occlusion.sample_step_px);

    for (int i = startIndex; i < edges.size(); i++)
    {
      if (System.nanoTime() >= deadlineNs)
        return i;

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
        if (System.nanoTime() >= deadlineNs)
          return i;

        float t = s / (float)steps;

        float x = lerp(e.a.x, e.b.x, t);
        float y = lerp(e.a.y, e.b.y, t);
        float z;
        if (data.camera.projection_mode == CameraData.PROJECTION_PERSPECTIVE)
        {
          float invz = lerp(e.a.invz, e.b.invz, t);
          if (invz <= 1e-9)
            continue;
          z = 1.0 / invz;
        }
        else
        {
          z = lerp(e.a.z, e.b.z, t);
        }

        float sx = mapToBufferX(x, minX, maxX, zW);
        float sy = mapToBufferY(y, minY, maxY, zH);

        boolean visible = isVisibleAgainstDepth(z, sx, sy, zbuf, zW, zH, data.occlusion.depth_bias);

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

          if (hiddenStreak >= 2)
          {
            if (dist(runStartSX, runStartSY, runEndSX, runEndSY) >= data.occlusion.min_visible_segment_px)
            {
              Polyline line = new Polyline();
              line.addPoint(runStart2D);
              line.addPoint(runEnd2D);
              outGroup.add(line);
            }
            runVisible = false;
            hiddenStreak = 0;
          }
        }
      }

      if (runVisible && dist(runStartSX, runStartSY, runEndSX, runEndSY) >= data.occlusion.min_visible_segment_px)
      {
        Polyline line = new Polyline();
        line.addPoint(runStart2D);
        line.addPoint(runEnd2D);
        outGroup.add(line);
      }
    }

    return edges.size();
  }

  void draw(boolean clipping, float clipWidth, float clipHeight)
  {
    pushStyle();
    int c = data.style.lineColor.col;
    int previewAlpha = 128;
    current_graphics.stroke(red(c), green(c), blue(c), (busy && occlusionMode) ? previewAlpha : 255);

    if (busy && occlusionMode && previewGroup.size() > 0)
      previewGroup.draw(clipping, clipWidth, clipHeight);
    else if (finalGroup != null)
      finalGroup.draw(clipping, clipWidth, clipHeight);

    popStyle();
  }

  int getDisplayLineCount()
  {
    if (busy && occlusionMode)
      return previewGroup.size();

    return (finalGroup != null) ? finalGroup.size() : 0;
  }

  BoundingBox getDisplayBoundingBox(boolean clipping, float clipWidth, float clipHeight)
  {
    if (busy && occlusionMode && previewGroup.size() > 0)
      return previewGroup.getBoundingBox(clipping, clipWidth, clipHeight);

    if (finalGroup != null)
      return finalGroup.getBoundingBox(clipping, clipWidth, clipHeight);

    return new BoundingBox();
  }

  boolean isBusy()
  {
    return busy;
  }

  boolean isOcclusionBuilding()
  {
    return busy && occlusionMode;
  }

  float getProgress01()
  {
    if (!busy || sourceMeshes == null || sourceMeshes.size() == 0)
      return 1.0;

    float meshCount = max(1, sourceMeshes.size());
    if (stage == STAGE_COLLECT)
      return 0.33 * (meshIndex / meshCount);
    if (stage == STAGE_RASTERIZE)
      return 0.33 + 0.34 * (triangles.size() <= 0 ? 0 : triangleIndex / (float)max(1, triangles.size()));
    if (stage == STAGE_EMIT)
      return 0.67 + 0.33 * (edges.size() <= 0 ? 0 : edgeIndex / (float)max(1, edges.size()));

    return 0.0;
  }

  String getStatusText()
  {
    if (!busy)
      return "idle";

    if (stage == STAGE_COLLECT)
      return "collecting";
    if (stage == STAGE_RASTERIZE)
      return "rasterizing";
    if (stage == STAGE_EMIT)
      return "emitting";

    return "working";
  }

  float getElapsedMs()
  {
    return (System.nanoTime() - startNs) / 1000000.0;
  }

  boolean isVisibleAgainstDepth(float z, float sx, float sy, double[] zbuf, int zW, int zH, float depthBias)
  {
    int ix = (int)round(sx);
    int iy = (int)round(sy);
    if (ix < 0 || ix >= zW || iy < 0 || iy >= zH)
      return !data.page.clipping;

    double neighborhoodMax = -Double.MAX_VALUE;
    for (int oy = -1; oy <= 1; oy++)
    {
      int py = iy + oy;
      if (py < 0 || py >= zH) continue;
      for (int ox = -1; ox <= 1; ox++)
      {
        int px = ix + ox;
        if (px < 0 || px >= zW) continue;
        double zv = zbuf[px + py * zW];
        if (zv < Double.MAX_VALUE && zv > neighborhoodMax)
          neighborhoodMax = zv;
      }
    }

    if (neighborhoodMax == -Double.MAX_VALUE)
      return true;

    double effectiveBias = Math.max((double)depthBias, 0.0025 * z);
    return z <= neighborhoodMax + effectiveBias;
  }

  float mapToBufferX(float x, float minX, float maxX, int zW)
  {
    return (x - minX) / max(1e-6, maxX - minX) * (zW - 1);
  }

  double mapToBufferX(double x, double minX, double maxX, int zW)
  {
    return (x - minX) / Math.max(1e-12, maxX - minX) * (zW - 1);
  }

  float mapToBufferY(float y, float minY, float maxY, int zH)
  {
    return (y - minY) / max(1e-6, maxY - minY) * (zH - 1);
  }

  double mapToBufferY(double y, double minY, double maxY, int zH)
  {
    return (y - minY) / Math.max(1e-12, maxY - minY) * (zH - 1);
  }

  double edgeFunctionD(double ax, double ay, double bx, double by, double px, double py)
  {
    return (px - ax) * (by - ay) - (py - ay) * (bx - ax);
  }
}
