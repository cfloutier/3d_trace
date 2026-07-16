class DataCircle extends GenericData
{
  DataCircle()
  {
    super("Circle");
  }

  float circle_size  = 400;
  float aspect_ratio = 1.0;
  int   resolution   = 128;
  int   count        = 50;

  void LoadJson(JSONObject src)
  {
    if (src == null) return;
    circle_size  = src.getFloat("circle_size",  circle_size);
    aspect_ratio = src.getFloat("aspect_ratio", aspect_ratio);
    resolution   = src.getInt("resolution",     resolution);
    count        = src.getInt("count",          count);
  }

  JSONObject SaveJson()
  {
    JSONObject dest = new JSONObject();
    dest.setFloat("circle_size",  circle_size);
    dest.setFloat("aspect_ratio", aspect_ratio);
    dest.setInt("resolution",     resolution);
    dest.setInt("count",          count);
    return dest;
  }
}


class CircleGUI extends GUIPanel
{
  DataCircle circle;

  Slider circle_size;
  Slider aspect_ratio;
  Slider resolution;
  Slider count;

  CircleGUI(DataCircle circle)
  {
    super("Circle", circle);
    this.circle = circle;
  }

  void setupControls()
  {
    super.Init();

    circle_size  = addSlider("circle_size",  "Circle Size",   10, 2000);
    aspect_ratio = addSlider("aspect_ratio", "Aspect Ratio", 0.1, 5.0);
    nextLine();
    resolution   = addIntSlider("resolution", "Resolution",    8, 512);
    count        = addIntSlider("count",       "Count",         1, 5000);
  }

  void setGUIValues()
  {
    circle_size.setValue(circle.circle_size);
    aspect_ratio.setValue(circle.aspect_ratio);
    resolution.setValue(circle.resolution);
    count.setValue(circle.count);
  }
}
