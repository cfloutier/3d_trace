class BoxGridData extends DataGlobal
{
  Style style = new Style();
  DataBoxes boxes = new DataBoxes();

  BoxGridData()
  {
    addChapter(style);
    addChapter(boxes);
  }

  void reset()
  {
    style.CopyFrom(new Style());
    boxes.CopyFrom(new DataBoxes());
  }
}
