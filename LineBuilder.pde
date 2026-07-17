class LineBuilder
{
  BoxGridData data;
  int last_occlusion_debug_ms = -100000;

  LineBuilder(BoxGridData data)
  {
    this.data = data;
  }

  void buildLinesFromMeshes(ArrayList<Mesh> meshList, PolylineGroup outGroup)
  {
    if (data.occlusion.enabled)
    {
      buildOccludedLinesFromMeshes(meshList, outGroup);
      return;
    }

    outGroup.clear();
    for (int i = 0; i < meshList.size(); i++)
      meshList.get(i).addWireframe(outGroup, data.camera);
  }

  void buildOccludedLinesFromMeshes(ArrayList<Mesh> meshList, PolylineGroup outGroup)
  {
    outGroup.clear();

    if (meshList.size() == 0)
      return;

    CameraFrame frame = data.camera.buildFrame();

    ArrayList<EdgeProjected> edges = new ArrayList<EdgeProjected>();
    ArrayList<TriangleProjected> triangles = new ArrayList<TriangleProjected>();

    for (int i = 0; i < meshList.size(); i++)
      meshList.get(i).appendProjectedOcclusionGeometry(edges, triangles, data.camera, frame);

    float[] domain = getOcclusionDomain();
    float minX = domain[0];
    float maxX = domain[1];
    float minY = domain[2];
    float maxY = domain[3];

    int zW = max(64, (int)(width * data.occlusion.zbuffer_scale));
    int zH = max(64, (int)(height * data.occlusion.zbuffer_scale));
    double[] zbuf = new double[zW * zH];
    for (int i = 0; i < zbuf.length; i++) zbuf[i] = Double.MAX_VALUE;

    rasterizeTrianglesToDepthBuffer(triangles, zbuf, zW, zH, minX, maxX, minY, maxY);

    emitVisibleEdgeSegments(edges, zbuf, zW, zH, minX, maxX, minY, maxY,
      data.occlusion.sample_step_px,
      data.occlusion.depth_bias,
      data.occlusion.min_visible_segment_px,
      outGroup);

    if (millis() - last_occlusion_debug_ms > 250)
      last_occlusion_debug_ms = millis();
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

  void rasterizeTrianglesToDepthBuffer(ArrayList<TriangleProjected> triangles, double[] zbuf,
    int zW, int zH, float minX, float maxX, float minY, float maxY)
  {
    for (int i = 0; i < triangles.size(); i++)
    {
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
  }

  int emitVisibleEdgeSegments(ArrayList<EdgeProjected> edges, double[] zbuf,
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
        float z;
        if (data.camera.projection_mode == CameraData.PROJECTION_PERSPECTIVE)
        {
          // Perspective-correct depth along projected edges to avoid false mid-segment occlusion.
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
