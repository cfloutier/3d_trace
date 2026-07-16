import controlP5.*;

class DataBoxes extends GenericData
{
  DataBoxes()
  {
    super("Boxes");
  }

  int   count      = 16;
  float spacing    = 90;
  float box_height = 120;

  void LoadJson(JSONObject src)
  {
    if (src == null) return;
    count      = src.getInt("count", count);
    spacing    = src.getFloat("spacing", spacing);
    box_height = src.getFloat("box_height", box_height);
  }

  JSONObject SaveJson()
  {
    JSONObject dest = new JSONObject();
    dest.setInt("count", count);
    dest.setFloat("spacing", spacing);
    dest.setFloat("box_height", box_height);
    return dest;
  }
}


class BoxesGUI extends GUIPanel
{
  DataBoxes boxes;

  Slider spacing;
  Slider count;
  Slider box_height;

  BoxesGUI(DataBoxes boxes)
  {
    super("Boxes", boxes);
    this.boxes = boxes;
  }

  void setupControls()
  {
    super.Init();

    count      = addIntSlider("count", "Count", 1, 400);
    spacing    = addSlider("spacing", "Spacing", 10, 400);
    nextLine();
    box_height = addSlider("box_height", "Height", 10, 1000);
  }

  void setGUIValues()
  {
    count.setValue(boxes.count);
    spacing.setValue(boxes.spacing);
    box_height.setValue(boxes.box_height);
  }
}
