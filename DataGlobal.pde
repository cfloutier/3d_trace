class CircleLinesData extends DataGlobal
{
  Style style = new Style();
  DataCircle circle = new DataCircle();

  CircleLinesData()
  {
    addChapter(style);
    addChapter(circle);
  }

  void reset()
  {
    style.CopyFrom(new Style());
    circle.CopyFrom(new DataCircle());
  }
}
