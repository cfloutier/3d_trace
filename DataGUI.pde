import controlP5.*;

class DataGUI extends MainPanel
{
  CircleLinesData data;
  FileGUI  file_ui;
  StyleGUI style_ui;
  CircleGUI circle_ui;

  public DataGUI(CircleLinesData data)
  {
    this.data = data;
    file_ui   = new FileGUI(data, true);
    style_ui  = new StyleGUI(data.style);
    circle_ui = new CircleGUI(data.circle);
  }

  void Init()
  {
    addTab(file_ui);
    addTab(style_ui);
    addTab(circle_ui);

    super.Init();

    cp5.getTab("Circle").bringToFront();
  }
}
