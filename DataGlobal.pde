class BoxGridData extends DataGlobal
{
  Style style = new Style();
  DataBoxes boxes = new DataBoxes();
  CameraData camera = new CameraData();
  DataOcclusion occlusion = new DataOcclusion();

  BoxGridData()
  {
    addChapter(style);
    addChapter(boxes);
    addChapter(camera);
    addChapter(occlusion);
  }

  void reset()
  {
    style.CopyFrom(new Style());
    boxes.CopyFrom(new DataBoxes());
    camera.CopyFrom(new CameraData());
    occlusion.CopyFrom(new DataOcclusion());
  }
}
