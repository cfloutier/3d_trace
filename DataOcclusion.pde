import controlP5.*;

class DataOcclusion extends GenericData
{
  DataOcclusion()
  {
    super("Occlusion");
  }

  boolean enabled = false;

  float zbuffer_scale = 1.0;
  float sample_step_px = 2.0;
  float depth_bias = 0.01;
  float min_visible_segment_px = 1.5;

  void LoadJson(JSONObject src)
  {
    if (src == null) return;
    enabled = src.getBoolean("enabled", enabled);
    zbuffer_scale = src.getFloat("zbuffer_scale", zbuffer_scale);
    sample_step_px = src.getFloat("sample_step_px", sample_step_px);
    depth_bias = src.getFloat("depth_bias", depth_bias);
    min_visible_segment_px = src.getFloat("min_visible_segment_px", min_visible_segment_px);
  }

  JSONObject SaveJson()
  {
    JSONObject dest = new JSONObject();
    dest.setBoolean("enabled", enabled);
    dest.setFloat("zbuffer_scale", zbuffer_scale);
    dest.setFloat("sample_step_px", sample_step_px);
    dest.setFloat("depth_bias", depth_bias);
    dest.setFloat("min_visible_segment_px", min_visible_segment_px);
    return dest;
  }
}


class OcclusionGUI extends GUIPanel
{
  DataOcclusion occlusion;

  Toggle enabled;
  Slider zbuffer_scale;
  Slider sample_step_px;
  Slider depth_bias;
  Slider min_visible_segment_px;

  OcclusionGUI(DataOcclusion occlusion)
  {
    super("Occlusion", occlusion);
    this.occlusion = occlusion;
  }

  void setupControls()
  {
    super.Init();

    enabled = addToggle("enabled", "Enable HLR", occlusion);
    nextLine();

    zbuffer_scale = addSlider("zbuffer_scale", "ZBuffer Scale", 1, 4.0);
    sample_step_px = addSlider("sample_step_px", "Sample Step px", 0.5, 8.0);
    nextLine();
    depth_bias = addSlider("depth_bias", "Depth Bias", 0.0, 1.0);
    min_visible_segment_px = addSlider("min_visible_segment_px", "Min Segment px", 0.0, 20.0);
  }

  void setGUIValues()
  {
    enabled.setValue(occlusion.enabled);
    zbuffer_scale.setValue(occlusion.zbuffer_scale);
    sample_step_px.setValue(occlusion.sample_step_px);
    depth_bias.setValue(occlusion.depth_bias);
    min_visible_segment_px.setValue(occlusion.min_visible_segment_px);
  }

  void update_ui()
  {
    zbuffer_scale.setValue(occlusion.zbuffer_scale);
    sample_step_px.setValue(occlusion.sample_step_px);
    depth_bias.setValue(occlusion.depth_bias);
    min_visible_segment_px.setValue(occlusion.min_visible_segment_px);
  }
}