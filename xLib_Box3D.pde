PVector projectBoxPoint(float x, float y, float z)
{
  final float iso_x = 0.8660254;
  final float iso_y = 0.5;

  float projected_x = (x - z) * iso_x;
  float projected_y = (x + z) * iso_y - y;

  return new PVector(projected_x, projected_y);
}


Polyline makeProjectedEdge(PVector a, PVector b)
{
  Polyline edge = new Polyline();
  edge.addPoint(projectBoxPoint(a.x, a.y, a.z));
  edge.addPoint(projectBoxPoint(b.x, b.y, b.z));
  return edge;
}


class Box3D
{
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

  void addWireframe(PolylineGroup group)
  {
    PVector[] vertices = getVertices();

    int[][] edges = {
      { 0, 1 }, { 1, 2 }, { 2, 3 }, { 3, 0 },
      { 4, 5 }, { 5, 6 }, { 6, 7 }, { 7, 4 },
      { 0, 4 }, { 1, 5 }, { 2, 6 }, { 3, 7 }
    };

    for (int i = 0; i < edges.length; i++)
    {
      group.add(makeProjectedEdge(vertices[edges[i][0]], vertices[edges[i][1]]));
    }
  }
}


void addBoxWireframe(PolylineGroup group, float center_x, float center_y, float center_z, float size_x, float size_y, float size_z)
{
  Box3D box = new Box3D(center_x, center_y, center_z, size_x, size_y, size_z);
  box.addWireframe(group);
}
