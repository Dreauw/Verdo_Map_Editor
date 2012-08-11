class MapProperties < MessageBox
  include Action
  def initialize(window)
    super(window, "Map Properties", "Tile Size  :\n\nMap Size :", ["OK"], 203)
    x = @text_image.width + 7
    add_widget(Spinner.new(@window, x, 2, 60, 20, @window.tile_width))
    add_widget(Spinner.new(@window, x+@widget.last.width+26, 2, 60, 20, @window.tile_height))
    add_widget(Spinner.new(@window, x, 32, 60, 20, @window.map.map_width))
    add_widget(Spinner.new(@window, x+@widget.last.width+26, 32, 60, 20, @window.map.map_height))
    set_action("OK", method(:on_ok_button))
  end

  def on_ok_button
    call_action(:ok)
    # Tile Size
    @window.tile_width = @widget[0].number
    @window.tile_height = @widget[1].number
    # Map Size
    @window.map.map_width = @widget[2].number
    @window.map.map_height = @widget[3].number
    @window.need_redraw = true
  end
end
