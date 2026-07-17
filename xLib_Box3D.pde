Polyline makeProjectedEdge(PVector a, PVector b, CameraProjector3D camera)
{
  Polyline edge = new Polyline();
  edge.addPoint(camera.projectPoint(a));
  edge.addPoint(camera.projectPoint(b));
  return edge;
}


class Box3D extends Mesh
{
  final int[][] EDGE_IDX = {
    { 0, 1 }, { 1, 2 }, { 2, 3 }, { 3, 0 },
    { 4, 5 }, { 5, 6 }, { 6, 7 }, { 7, 4 },
    { 0, 4 }, { 1, 5 }, { 2, 6 }, { 3, 7 }
  };

  final int[][] TRI_IDX = {
    { 0, 1, 2 }, { 0, 2, 3 },
    { 4, 6, 5 }, { 4, 7, 6 },
    { 0, 5, 1 }, { 0, 4, 5 },
    { 3, 2, 6 }, { 3, 6, 7 },
    { 0, 3, 7 }, { 0, 7, 4 },
    { 1, 5, 6 }, { 1, 6, 2 }
  };

  float center_x;
  float center_y;
  float center_z;

  float size_x;
  float size_y;
  float size_z;

  PVector rotation = new PVector(0, 0, 0);

  Box3D(float center_x, float center_y, float center_z, float size_x, float size_y, float size_z)
  {
    this.center_x = center_x;
    this.center_y = center_y;
    this.center_z = center_z;
    this.size_x = size_x;
    this.size_y = size_y;
    this.size_z = size_z;
  }

  Box3D(float center_x, float center_y, float center_z, float size_x, float size_y, float size_z, PVector rotation)
  {
    this(center_x, center_y, center_z, size_x, size_y, size_z);
    setRotation(rotation);
  }

  void setRotation(PVector rotation)
  {
    if (rotation == null)
      this.rotation = new PVector(0, 0, 0);
    else
      this.rotation = rotation.copy();
  }

  PVector[] getVertices()
  {
    PVector[] vertices = new PVector[8];

    float min_x = center_x - size_x;
    float max_x = center_x + size_x;
    float min_z = center_z - size_z;
    float max_z = center_z + size_z;
    float top_y = center_y + size_y;

    vertices[0] = new PVector(min_x, center_y, min_z);
    vertices[1] = new PVector(max_x, center_y, min_z);
    vertices[2] = new PVector(max_x, center_y, max_z);
    vertices[3] = new PVector(min_x, center_y, max_z);

    vertices[4] = new PVector(min_x, top_y, min_z);
    vertices[5] = new PVector(max_x, top_y, min_z);
    vertices[6] = new PVector(max_x, top_y, max_z);
    vertices[7] = new PVector(min_x, top_y, max_z);

    for (int i = 0; i < vertices.length; i++)
      vertices[i] = rotateAroundBaseCenter(vertices[i]);

    return vertices;
  }

  PVector rotateAroundBaseCenter(PVector point)
  {
    PVector rotated = point.copy();
    rotated.sub(center_x, center_y, center_z);

    if (rotation.x != 0) rotated = rotateXPoint(rotated, rotation.x);
    if (rotation.y != 0) rotated = rotateYPoint(rotated, rotation.y);
    if (rotation.z != 0) rotated = rotateZPoint(rotated, rotation.z);

    rotated.add(center_x, center_y, center_z);
    return rotated;
  }

  PVector rotateXPoint(PVector point, float angle)
  {
    float c = cos(angle);
    float s = sin(angle);
    return new PVector(point.x, point.y * c - point.z * s, point.y * s + point.z * c);
  }

  PVector rotateYPoint(PVector point, float angle)
  {
    float c = cos(angle);
    float s = sin(angle);
    return new PVector(point.x * c + point.z * s, point.y, -point.x * s + point.z * c);
  }

  PVector rotateZPoint(PVector point, float angle)
  {
    float c = cos(angle);
    float s = sin(angle);
    return new PVector(point.x * c - point.y * s, point.x * s + point.y * c, point.z);
  }

  ProjectedPoint[] getProjectedVertices(CameraProjector3D camera, CameraFrame frame)
  {
    PVector[] vertices = getVertices();
    ProjectedPoint[] projected = new ProjectedPoint[vertices.length];

    for (int i = 0; i < vertices.length; i++)
      projected[i] = camera.projectPointWithDepth(vertices[i], frame);

    return projected;
  }

  @Override
  void addWireframe(PolylineGroup group, CameraProjector3D camera)
  {
    PVector[] vertices = getVertices();

    for (int i = 0; i < EDGE_IDX.length; i++)
    {
      group.add(makeProjectedEdge(vertices[EDGE_IDX[i][0]], vertices[EDGE_IDX[i][1]], camera));
    }
  }

  @Override
  void appendProjectedOcclusionGeometry(
    ArrayList<EdgeProjected> edges,
    ArrayList<TriangleProjected> triangles,
    CameraProjector3D camera,
    CameraFrame frame)
  {
    ProjectedPoint[] p = getProjectedVertices(camera, frame);

    for (int i = 0; i < EDGE_IDX.length; i++)
      edges.add(new EdgeProjected(p[EDGE_IDX[i][0]], p[EDGE_IDX[i][1]]));

    for (int i = 0; i < TRI_IDX.length; i++)
      triangles.add(new TriangleProjected(p[TRI_IDX[i][0]], p[TRI_IDX[i][1]], p[TRI_IDX[i][2]]));
  }
}


void addBoxWireframe(PolylineGroup group, CameraProjector3D camera, float center_x, float center_y, float center_z, float size_x, float size_y, float size_z)
{
  Box3D box = new Box3D(center_x, center_y, center_z, size_x, size_y, size_z);
  box.addWireframe(group, camera);
}
