import controlP5.*;

class DataGUI extends MainPanel
{
  BoxGridData data;
  FileGUI  file_ui;
  StyleGUI style_ui;
  BoxesGUI boxes_ui;

  public DataGUI(BoxGridData data)
  {
    this.data = data;
    file_ui   = new FileGUI(data, true);
    style_ui  = new StyleGUI(data.style);
    boxes_ui  = new BoxesGUI(data.boxes);
  }

  void Init()
  {
    addTab(file_ui);
    addTab(style_ui);
    addTab(boxes_ui);

    super.Init();

    cp5.getTab("Boxes").bringToFront();
  }
}
