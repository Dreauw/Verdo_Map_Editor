class Map < Window
  attr_reader :scale
  attr_accessor :map_width
  attr_accessor :map_height
  attr_accessor :layer
  attr_reader :scroll_x
  attr_reader :scroll_y
  attr_reader :start_sel
  attr_reader :end_sel

  GRID_COLOR = Gosu::Color.new(100, 191, 191, 191)

  def initialize(window, x, y, width, height)
    super(window, x, y, width, height, "Map - 100%")
    @layer = [[[]]]
    @map_width, @map_height = 30, 25
    @tools = add_caption_widget(ToggleButtons.new(window, 0, 0, ["P", "F", "S"], 16))
    add_caption_widget(Button.new(@window, 0, 0, "M", 16)).set_action(
      :release, Proc.new {MapProperties.new(@window)})
    add_caption_widget(Button.new(@window, 0, 0, "L", 16)).set_action(
      :release, method(:show_load_dialog))
    add_caption_widget(Button.new(@window, 0, 0, "S", 16)).set_action(
      :release, method(:show_save_dialog))
    @scale = 1
    @scroll_x = -(@width - @map_width*screen_tile(0)) / 2
    @scroll_y = -(@height - @map_height*screen_tile(1)) / 2
  end

  # - For the backup system

  def marshal_dump
    return [@scale, @map_width, @map_height, @layer, @scroll_x, @scroll_y]
  end

  def marshal_load(array)
    @scale, @map_width, @map_height, @layer, @scroll_x, @scroll_y = array
  end
  
  # - Save/Load map
  
  def show_save_dialog
    FileDialog.new(@window, :save, ["Verdo Map Editor File (*.vdo)", "All Files (*.*)"], "Untitled.vdo").set_action(
      :save, Proc.new{|f| save(f.file)})
  end

  def show_load_dialog
    FileDialog.new(@window, :load, ["Verdo Map Editor File (*.vdo)", "All Files (*.*)"]).set_action(
      :load, Proc.new{|f| load(f.file)})
  end
  
  def save(file)
    File.open(file, "w+") {|file|
      file << "width=#{@map_width}\n"
      file << "height=#{@map_height}"
      @layer.each_with_index{|a, i|
        if @window.layer.event_layer?(i)
          file << "\nevent_layer_#{i}="
        a.each{|key, value|
          file << "#{value}|#{key[0]}|#{key[1]},"
        }
        else
          file << "\ntile_layer_#{i}="
          for y in 0...@map_height
            for x in 0...@map_width
              file << get_tile(x, y, i).to_s
              file << ", " if x < @map_width-1
            end
            file << "|"
          end
          #file << a.to_s.gsub("]]", "").gsub(", [", "").gsub("[", "").gsub("]", "|")
        end
      }
    }
  end
  
  def load(file)
    @layer = []
    @window.layer.remove_all
    File.readlines(file).each{|line|
      split = line.split("=")
      if split[0].include?("tile")
        @window.layer.add_layer(0)
        split[1].split("|").each_with_index {|tl, y|
          tl.split(", ").each_with_index {|tc, x|
            set_tile(x, y, tc.to_i, @layer.size-1)
          }
          #@layer.last.push(tl.split(", ").map!{ |s| s.to_i })
        }
      elsif split[0] == "width"
        @map_width = split[1].to_i
      elsif split[0] == "height"
        @map_height = split[1].to_i
      elsif split[0].include?("event")
        @window.layer.add_layer(1)
        split[1].split(",").each {|i|
          v = i.split("|")
          @layer.last[[v[1].to_i, v[2].to_i]] = v[0]
        }
      end
    }
    @window.need_redraw = true
  end

  # - Get the mouse position in tile
  
  def get_mouse_tile_x
    return ((@window.mouse_x - @x + (@scroll_x*@scale))/screen_tile(0)).floor
  end

  def get_mouse_tile_y
    return ((@window.mouse_y - @y - CAPTION_HEIGHT + (@scroll_y*@scale))/screen_tile(1)).floor
  end

  # - Scale map

  def scale=(value)
    return if value == @scale
    @scale = value
    @window.need_redraw = true
  end

  # - Input handling methods

  def button_triggered(id)
    qsDfqsf if id == Gosu::KbA
    super_bool = !super(id)
    mouse_over = mouse_over?
    @ms_left_pressed = true if id == Gosu::MsLeft && mouse_over
    @ms_right_pressed = true if id == Gosu::MsRight && mouse_over
    if id == Gosu::KbDelete && @selection
      set_selection(nil)
    elsif id == Gosu::MsWheelUp && mouse_over
      return if (@scale * 100).floor>= 980
      self.scale = (@scale + 0.2).round(2)
      self.caption = "Map - #{(@scale*100).floor}%"
    elsif id == Gosu::MsWheelDown && mouse_over
      return if (@scale * 100).floor <= 20
      self.scale = (@scale - 0.2).round(2)
      self.caption = "Map - #{(@scale*100).floor}%"
    elsif @ms_left_pressed
      if @window.button_down?(Gosu::KbSpace)
        @scroll_drag = true
        @scroll_drag_start = [@window.mouse_x, @window.mouse_y]
        @initial_scroll = [@scroll_x, @scroll_y]
      elsif @tools.index == 2
        self.start_sel = [get_mouse_tile_x, get_mouse_tile_y]
        @selection_drag = true
      end
    end
    if @tools.index != 2 && @selection
      @selection = false
      @window.need_redraw = true
    end
    return (@ms_left_pressed || @ms_right_pressed || super_bool ? false : true)
  end
  
  def button_released(id)
    @ms_left_pressed = false if id == Gosu::MsLeft
    @ms_right_pressed = false if id == Gosu::MsRight
    @scroll_drag = false if @scroll_drag && !@ms_left_pressed
    @undo_event = nil if !@ms_left_pressed || !@ms_right_pressed
    
    if @selection_drag && !@ms_left_pressed
      if @start_sel == [get_mouse_tile_x, get_mouse_tile_y]
        @selection_drag = false
        @selection = false
      else
        @selection_drag = false
        @selection = true
      end
      @window.need_redraw = true
    end
    return super(id)
  end

  # - Update (each frame)
  
  def update
    super
    if @scroll_drag
      self.scroll_x = (@window.mouse_x - @scroll_drag_start[0] - @initial_scroll[0]*@scale)
      self.scroll_y = (@window.mouse_y - @scroll_drag_start[1] - @initial_scroll[1]*@scale)
    elsif @ms_left_pressed && !@drag_resize
      if @tools.index == 0
        x, y = get_mouse_tile_x, get_mouse_tile_y
        if !@window.layer.event_layer?(@window.layer.index)
          for xx in (@window.tileset.start_sel[0])...@window.tileset.end_sel[0]
            for yy in @window.tileset.start_sel[1]...@window.tileset.end_sel[1]
              id = @window.tileset.get_tile_id(xx, yy)
              @undo_event = SetTilesEvent.new(@window, @window.layer.index, @map_width) if !@undo_event
              set_tile(x + xx - @window.tileset.start_sel[0], y + yy - @window.tileset.start_sel[1], id, @window.layer.index, @undo_event)
            end
          end
        else
          @undo_event = SetEventEvent.new(@window, @window.layer.index, @map_width) if !@undo_event
          set_event(x, y, @window.event.event_name, @window.layer.index, @undo_event)
        end
      elsif @tools.index == 1
        x, y = get_mouse_tile_x, get_mouse_tile_y
        id = @window.tileset.get_tile_id(@window.tileset.start_sel[0], @window.tileset.start_sel[1])
        flood_fill(x, y, id, true)
      elsif @selection_drag && @tools.index == 2
        self.end_sel = [get_mouse_tile_x, get_mouse_tile_y]
      end
    elsif @ms_right_pressed && !@drag_resize
      if @tools.index == 0
        x, y = get_mouse_tile_x, get_mouse_tile_y
        if !@window.layer.event_layer?(@window.layer.index)
          @undo_event = SetTilesEvent.new(@window, @window.layer.index, @map_width) if !@undo_event
          set_tile(x, y, -1, @window.layer.index, @undo_event)
        else
          @undo_event = SetEventEvent.new(@window, @window.layer.index, @map_width) if !@undo_event
          set_event(x, y, nil, @window.layer.index, @undo_event)
        end
      elsif @tools.index == 1
        x, y = get_mouse_tile_x, get_mouse_tile_y
        flood_fill(x, y, -1, true)
      end
    end
  end

  # Layer manipulation
  def invert_layer(layer1, layer2)
    if @layer.size > layer1 && @layer.size > layer2
      tmp = @layer[layer2]
      @layer[layer2] = @layer[layer1]
      @layer[layer1] = tmp
      @window.need_redraw = true
    end
  end

  # - Get/Set tile/event

  def get_tile(x, y, layer = @window.layer.index)
    return nil if @window.layer.event_layer?(layer)
    return nil if !x.between?(0, @map_width-1) || !y.between?(0, @map_height-1)
    begin
      set_tile(x, y, -1, layer) if !@layer[layer][x][y]
      return @layer[layer][x][y]
    rescue
      return -1
    end
  end

  def get_event(x, y, layer = @window.layer.index)
    return nil if !@window.layer.event_layer?(layer)
    return @layer[layer][[x, y]] if @layer[layer].has_key?([x, y])
  end

  def set_tile(x, y, id, layer = @window.layer.index, event = nil)
    return if @window.layer.event_layer?(layer)
    return if !x.between?(0, @map_width-1) || !y.between?(0, @map_height-1)
    @layer += [Array.new] * ((layer - @layer.size)+1) if !@layer[layer]
    @layer[layer] += [Array.new] * ((x - @layer[layer].size)+1) if !@layer[layer][x]
    @layer[layer].each_index {|i| @layer[layer][i] += [-1] * ((y - @layer[layer][i].size)+1) if !@layer[layer][i][y]}
    previous_id = @layer[layer][x][y]
    return if previous_id == id
    @layer[layer][x][y] = id
    event.add_tile(x, y, previous_id) if event
    @window.need_redraw = true
  end
  
  def set_event(x, y, name, layer = @window.layer.index, event = nil)
    return if !@window.layer.event_layer?(layer)
    return if !x.between?(0, @map_width-1) || !y.between?(0, @map_height-1)
    previous_name = @layer[layer][[x, y]]
    return if previous_name == name
    !name ? @layer[layer].delete([x, y]) : @layer[layer][[x, y]] = name
    event.add_event(x, y, previous_name) if event
    @window.need_redraw = true
  end

  # - Tile "real" screen size

  def screen_tile(widthheight)
    return widthheight == 0 ? @window.tile_width * @scale : @window.tile_height * @scale
  end

  # - Flood fill algorithm

  def flood_fill(x, y, id, event = true)
    return if !x.between?(0, @map_width-1) || !y.between?(0, @map_height-1)
    tile_to_fill = get_tile(x, y)
    return if tile_to_fill == id
    event = FillTilesEvent.new(@window, @window.layer.index, @map_width, tile_to_fill) if event
    q = Array.new
    q.push(y * @map_width + x)
    while !q.empty?
      n = q.shift
      x, y = n%@map_width, n/@map_width
      if get_tile(x, y) == tile_to_fill
        get_tile(x, y)
        set_tile(x, y, id)
        event.add_tile(x, y) if event
        q.push(n + 1) if x+1 < @map_width
        q.push(n - 1) if x-1 >= 0
        q.push(n + @map_width) if y+1 < @map_height
        q.push(n - @map_width) if y-1 >= 0
      end
    end
    @window.need_redraw = true
  end
  
  def scroll_x=(value)
    return if @scroll_x == value
    @scroll_x = -value/@scale
    @window.need_redraw = true
  end

  def scroll_y=(value)
    return if @scroll_y == value
    @scroll_y = -value/@scale
    @window.need_redraw = true
  end


  # - Mouse selection methods

  def set_selection(id)
    xx = [@start_sel[0], @end_sel[0]]
    yy = [@start_sel[1], @end_sel[1]]
    event = @window.layer.event_layer?(@window.layer.index)
    @undo_event = SetEventEvent.new(@window, @window.layer.index, @map_width) if event
    @undo_event = SetTilesEvent.new(@window, @window.layer.index, @map_width) if !event
    id = -1 if !event && !id
    for x in xx.min.to_i...xx.max.to_i
      for y in yy.min.to_i...yy.max.to_i
         if event
           set_event(x, y, id, @window.layer.index, @undo_event)
         else
           set_tile(x, y, id, @window.layer.index, @undo_event)
         end
      end
    end
    @window.need_redraw = true
  end

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

  # - Draw
  def draw_content
    super
    @window.scale(@scale, @scale, @x, @y + CAPTION_HEIGHT) {
		tile_width = (@visible_rect[0] / screen_tile(0)).ceil + 2
		tile_height = (@visible_rect[1] / screen_tile(1)).ceil + 2
		scroll_tile_x = (@scroll_x/@window.tile_width).floor
		scroll_tile_y = (@scroll_y/@window.tile_height).floor
		if @window.tileset.image
		  for layer in 0...@layer.size
			next if !@window.layer.show_layer?(layer)
			if @window.layer.event_layer?(layer)
			  next if !@layer[layer].is_a?(Hash)
			  @layer[layer].each_key {|key|
				real_x = @x + key[0] * @window.tile_width - @scroll_x + 1
				real_y = @y + CAPTION_HEIGHT + key[1] * @window.tile_height - @scroll_y + 1
				@window.draw_rect(real_x, real_y, real_x+@window.tile_width-3, real_y+@window.tile_height-3, Gosu::Color.new(130, 255, 255, 255))
			  }
			else
			  for x in scroll_tile_x...tile_width+scroll_tile_x
				for y in scroll_tile_y...tile_height+scroll_tile_y
				  next if !@layer[layer][x] || !@layer[layer][x][y] || x < 0 || y < 0
				  real_x = @x + x * @window.tile_width - @scroll_x
				  real_y = @y + CAPTION_HEIGHT + y * @window.tile_height - @scroll_y
				  id = @layer[layer][x][y]
				  @window.tileset.image[id].draw(real_x, real_y, 0, 1, 1) if id >= 0
				end
			  end
			end
		  end
		end

		if true
		  start_x = @x - @scroll_x
		  start_y = @y+CAPTION_HEIGHT - @scroll_y
		  end_x = @map_width * @window.tile_width + start_x
		  end_y = @map_height * @window.tile_height + start_y
		  for x in scroll_tile_x...tile_width+scroll_tile_x+1
			next if x < 0 || x > @map_width
			@window.draw_line(@x+x*@window.tile_width-@scroll_x, start_y, @x+x*@window.tile_width-@scroll_x, end_y, GRID_COLOR)
		  end
		  for y in scroll_tile_y...tile_height+scroll_tile_y+1
			next if y < 0 || y > @map_height
			@window.draw_line(start_x, @y+y*@window.tile_height+CAPTION_HEIGHT-@scroll_y, end_x, @y+y*@window.tile_height+CAPTION_HEIGHT-@scroll_y, GRID_COLOR)
		  end
		end

		if @selection_drag || @selection
		  @window.draw_rect(@x + @start_sel[0]*@window.tile_width-@scroll_x, @y + @start_sel[1]*@window.tile_height - @scroll_y + CAPTION_HEIGHT,
		  @x + @end_sel[0]*@window.tile_width - @scroll_x, @y + @end_sel[1]*@window.tile_height - @scroll_y + CAPTION_HEIGHT, Gosu::Color.new(50, 0, 0, 200))
		end
	  }
  end

end
