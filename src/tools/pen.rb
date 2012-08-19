class Pen < Tool
  def ms_left_pressed
    x, y = @window.map.get_mouse_tile_x, @window.map.get_mouse_tile_y
    if !@window.layer.event_layer?(@window.layer.index)
      # Autotile
      if @window.tileset.sel_mode == :autotile
        @undo_event = SetTilesEvent.new(@window, @window.layer.index, @window.map.map_width) if !@undo_event
        @window.map.set_autotile(x, y, @window.layer.index, true, @undo_event)
        return
      end
      # Tile
      for xx in (@window.tileset.start_sel[0])...@window.tileset.end_sel[0]
        for yy in @window.tileset.start_sel[1]...@window.tileset.end_sel[1]
          id = @window.tileset.get_tile_id(xx, yy)
          @undo_event = SetTilesEvent.new(@window, @window.layer.index, @window.map.map_width) if !@undo_event
          @window.map.set_tile(x + xx - @window.tileset.start_sel[0], y + yy - @window.tileset.start_sel[1], id, @window.layer.index, @undo_event)
        end
      end
    else
      # Event
      @undo_event = SetEventEvent.new(@window, @window.layer.index, @window.map.map_width) if !@undo_event
      @window.map.set_event(x, y, @window.event.event_name, @window.layer.index, @undo_event)
    end
  end
  
  def ms_right_pressed
    x, y = @window.map.get_mouse_tile_x, @window.map.get_mouse_tile_y
    if !@window.layer.event_layer?(@window.layer.index)
      # Autotile
      if @window.tileset.sel_mode == :autotile
        # TODO
        return
      end
      # Tile
      @undo_event = SetTilesEvent.new(@window, @window.layer.index, @window.map.map_width) if !@undo_event
      @window.map.set_tile(x, y, -1, @window.layer.index, @undo_event)
    else
      # Event
      @undo_event = SetEventEvent.new(@window, @window.layer.index, @window.map.map_width) if !@undo_event
      @window.map.set_event(x, y, nil, @window.layer.index, @undo_event)
    end
  end
  
  def ms_left_released
    @undo_event = nil
  end
  
  def ms_right_released
    @undo_event = nil
  end
end