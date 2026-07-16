class BoxGridData extends DataGlobal
{
  Style style = new Style();
  DataBoxes boxes = new DataBoxes();
  CameraData camera = new CameraData();

  BoxGridData()
  {
    addChapter(style);
    addChapter(boxes);
    addChapter(camera);
  }

  void reset()
  {
    style.CopyFrom(new Style());
    boxes.CopyFrom(new DataBoxes());
    camera.CopyFrom(new CameraData());
  }
}
