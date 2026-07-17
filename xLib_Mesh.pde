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

abstract class Mesh
{
  abstract void addWireframe(PolylineGroup group, CameraData camera);

  abstract void appendProjectedOcclusionGeometry(
    ArrayList<EdgeProjected> edges,
    ArrayList<TriangleProjected> triangles,
    CameraData camera,
    CameraFrame frame
  );
}