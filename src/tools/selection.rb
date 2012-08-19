class Selection < Tool
  attr_accessor :selection
  attr_reader :selection_drag
  attr_reader :start_sel
  attr_reader :end_sel
  
  def start_sel=(value)
    @start_sel = value
    @start_sel2 = @start_sel.dup
    @end_sel = value
  end

  def end_sel=(value)
    2.times{|i|
      @start_sel[i] += 1 if @start_sel2[i] == @start_sel[i] && value[i] < @start_sel[i]
      @start_sel[i] = @start_sel2[i] if @start_sel2[i] != @start_sel[i] && value[i] >= @start_sel[i]
    }
    @end_sel = value
    return if !value
    @end_sel[0] += 1 if (@end_sel[0] - @start_sel[0]) >= 0
    @end_sel[1] += 1 if (@end_sel[1] - @start_sel[1]) >= 0
    @window.need_redraw = true
  end
  
  def set_selection(id)
    xx = [@start_sel[0], @end_sel[0]]
    yy = [@start_sel[1], @end_sel[1]]
    event = @window.layer.event_layer?(@window.layer.index)
    @undo_event = SetEventEvent.new(@window, @window.layer.index, @window.map.map_width) if event
    @undo_event = SetTilesEvent.new(@window, @window.layer.index, @window.map.map_width) if !event
    id = -1 if !event && !id
    for x in xx.min.to_i...xx.max.to_i
      for y in yy.min.to_i...yy.max.to_i
         if event
           @window.map.set_event(x, y, id, @window.layer.index, @undo_event)
         else
           @window.map.set_tile(x, y, id, @window.layer.index, @undo_event)
         end
      end
    end
    @window.need_redraw = true
  end
  
  def ms_left_triggered
    x, y = @window.map.get_mouse_tile_x, @window.map.get_mouse_tile_y
    self.start_sel = [x, y]
    @selection_drag = true
  end
  
  def ms_left_pressed
    x, y = @window.map.get_mouse_tile_x, @window.map.get_mouse_tile_y
    return if !@selection_drag
    self.end_sel = [x, y]
  end
  
  def ms_left_released
    x, y = @window.map.get_mouse_tile_x, @window.map.get_mouse_tile_y
    return until @selection_drag
    if @start_sel == [x, y]
      @selection_drag = false
      @selection = false
    else
      @selection_drag = false
      @selection = true
    end
    @window.need_redraw = true
  end
  
  def button_triggered(id)
    set_selection(nil) if id == Gosu::KbDelete && @selection
  end
end