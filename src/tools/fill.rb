class Fill < Tool
  def ms_left_triggered
    x, y = @window.map.get_mouse_tile_x, @window.map.get_mouse_tile_y
    id = @window.tileset.get_tile_id(@window.tileset.start_sel[0], @window.tileset.start_sel[1])
    return if @last_xy == [x, y]
    @window.tileset.sel_mode == :autotile ? flood_fill_autotile(x, y, true) : flood_fill(x, y, id, true)
    @last_xy = [x, y]
  end
  
  def ms_right_triggered
    x, y = @window.map.get_mouse_tile_x, @window.map.get_mouse_tile_y
    flood_fill(x, y, -1, true)
  end
  
  # - Flood fill algorithm
  def flood_fill(x, y, id, event = true)
    return if !x.between?(0, @window.map.map_width-1) || !y.between?(0, @window.map.map_height-1)
    tile_to_fill = @window.map.get_tile(x, y)
    return if tile_to_fill == id
    event = FillTilesEvent.new(@window, @window.layer.index, @window.map.map_width, tile_to_fill) if event
    q = Array.new
    q.push(y * @window.map.map_width + x)
    while !q.empty?
      n = q.shift
      x, y = n%@window.map.map_width, n/@window.map.map_width
      if @window.map.get_tile(x, y) == tile_to_fill
        @window.map.get_tile(x, y)
        @window.map.set_tile(x, y, id)
        event.add_tile(x, y) if event
        q.push(n + 1) if x+1 < @window.map.map_width
        q.push(n - 1) if x-1 >= 0
        q.push(n + @window.map.map_width) if y+1 < @window.map.map_height
        q.push(n - @window.map.map_width) if y-1 >= 0
      end
    end
    @window.need_redraw = true
  end
  
  def flood_fill_autotile(x, y, use_event = true)
    return if !x.between?(0, @window.map.map_width-1) || !y.between?(0, @window.map.map_height-1)
    tile_to_fill = @window.map.get_tile(x, y)
    event = use_event ? SetTilesEvent.new(@window, @window.layer.index, @window.map.map_width) : nil
    q = Array.new
    q.push(y * @window.map.map_width + x)
    while !q.empty?
      n = q.shift
      x, y = n%@window.map.map_width, n/@window.map.map_width
      if @window.map.get_tile(x, y) == tile_to_fill
        @window.map.get_tile(x, y)
        @window.map.set_autotile(x, y, @window.layer.index, true, event)
        q.push(n + 1) if x+1 < @window.map.map_width
        q.push(n - 1) if x-1 >= 0
        q.push(n + @window.map.map_width) if y+1 < @window.map.map_height
        q.push(n - @window.map.map_width) if y-1 >= 0
      end
    end
    @window.need_redraw = true
  end
end