class Map < Window
  attr_reader :scale
  attr_accessor :map_width
  attr_accessor :map_height
  attr_accessor :layer
  attr_reader :scroll_x
  attr_reader :scroll_y
  attr_reader :start_sel
  attr_reader :end_sel
  attr_reader :show_grid

  GRID_COLOR = Gosu::Color.new(100, 191, 191, 191)

  def initialize(window, x, y, width, height)
    super(window, x, y, width, height, "Map - 100%")
	  @show_grid = true
    @layer = [[[]]]
    @map_width, @map_height = 30, 25
    @tools = add_caption_widget(ToggleButtons.new(window, 0, 0, ["P", "F", "S"], 16))
    @tool = [Pen.new(@window), Fill.new(@window), Selection.new(@window)]
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
      file << "tile_width=#{@window.tile_width}\n"
      file << "tile_height=#{@window.tile_height}\n"
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
              id = get_tile(x, y, i)
              id = id == -1 ? " " : id.to_s
              file << id
              file << ", " if x < @map_width-1
            end
            file << "|"
          end
        end
      }
    }
  end
  
  def load(file)
    @layer = []
    @window.layer.remove_all
    File.readlines(file).each{|line|
      split = line.split("=")
      if split[0].include?("tile_layer")
        @window.layer.add_layer(0)
        split[1].split("|").each_with_index {|tl, y|
          tl.split(", ").each_with_index {|tc, x|
            set_tile(x, y, (tc.empty? || tc == " ") ? -1 : tc.to_i, @layer.size-1)
          }
        }
      elsif split[0] == "tile_width"
        @window.tile_width = split[1].to_i
      elsif split[0] == "tile_height"
        @window.tile_height = split[1].to_i
      elsif split[0] == "width"
        @map_width = split[1].to_i
      elsif split[0] == "height"
        @map_height = split[1].to_i
      elsif split[0].include?("event_layer")
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
    if @window.button_id_to_char(id) == "g"
      @show_grid = !@show_grid
      return !(@window.need_redraw = true)
    end
    super_bool = !super(id)
    mouse_over = mouse_over?
    @ms_left_pressed = true if id == Gosu::MsLeft && mouse_over
    @ms_right_pressed = true if id == Gosu::MsRight && mouse_over
    if @ms_left_pressed && @window.button_down?(Gosu::KbSpace)
      @scroll_drag = true
      @scroll_drag_start = [@window.mouse_x, @window.mouse_y]
      @initial_scroll = [@scroll_x, @scroll_y]
    elsif mouse_over
      if id == Gosu::MsWheelUp && !((@scale * 100).floor >= 980)
        self.scale = (@scale + 0.2).round(2)
        self.caption = "Map - #{(@scale*100).floor}%"
      elsif id == Gosu::MsWheelDown && !((@scale * 100).floor <= 20)
        self.scale = (@scale - 0.2).round(2)
        self.caption = "Map - #{(@scale*100).floor}%"
      elsif @ms_left_pressed
        @tool[@tools.index].ms_left_triggered
      elsif @ms_right_pressed
        @tool[@tools.index].ms_right_triggered
      else
        @tool[@tools.index].button_triggered(id)
      end
    end
    return (@ms_left_pressed || @ms_right_pressed || super_bool ? false : true)
  end
  
  def button_released(id)
    @ms_left_pressed = false if id == Gosu::MsLeft
    @ms_right_pressed = false if id == Gosu::MsRight
    @scroll_drag = false if @scroll_drag && !@ms_left_pressed
    @tool[@tools.index].ms_left_released if id == Gosu::MsLeft
    @tool[@tools.index].ms_right_released if id == Gosu::MsRight
    (@window.need_redraw = !@tool[2].selection = false) if @tools.index != 2 && @tool[2].selection
    return super(id)
  end

  # - Update (each frame)
  
  def update
    super
    if @scroll_drag
      self.scroll_x = (@window.mouse_x - @scroll_drag_start[0] - @initial_scroll[0]*@scale)
      self.scroll_y = (@window.mouse_y - @scroll_drag_start[1] - @initial_scroll[1]*@scale)
      return
    end
    @tool[@tools.index].ms_left_pressed if @ms_left_pressed && !@drag_resize
    @tool[@tools.index].ms_right_pressed if @ms_right_pressed && !@drag_resize
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
    event.add_tile(x, y, previous_id) if event && !event.has_tile?(x, y)
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
  
  # - Autotile methods
  def set_autotile(x, y, layer = @window.layer.index, update_neighbour = true, event = nil)
    autotile = @window.tileset.get_selection
    return autotile[0][0] if autotile.size <= 2
    left, right, up, down = get_autotile_neighbour(x, y, layer)
    xx = 1 
    xx = 0 if !left && right
    xx = autotile.size - 1 if !right && left
    xx = 1 if up && down && right && left
    yy = 0
    yy = autotile[xx].size - 1 if up
    yy = 2 if up && down if autotile[xx].size > 2
    tmp_event = (event.has_tile?(x, y) ? nil : event)
    set_tile(x, y, autotile[xx][yy], layer, tmp_event)
    if update_neighbour
      update_autotile_neighbour(x, y, layer, event, left, right, up, down)
    end
  end
  
  def get_autotile_neighbour(x, y, layer = @window.layer.index)
    tiles_id = @window.tileset.get_selection.join(" ")
    left = tiles_id.include?(get_tile(x - 1, y).to_s)
    right = tiles_id.include?(get_tile(x + 1, y).to_s)
    up = tiles_id.include?(get_tile(x, y - 1).to_s)
    down = tiles_id.include?(get_tile(x, y + 1).to_s)
    return left, right, up, down
  end
  
  def update_autotile_neighbour(x, y, layer = @window.layer.index, event = nil, left = true, right = true, up = true, down = true)
    set_autotile(x + 1, y, layer, false, event) if right
    set_autotile(x - 1, y, layer, false, event) if left
    set_autotile(x, y + 1, layer, false, event) if down
    set_autotile(x, y - 1, layer, false, event) if up
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

		if @show_grid
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

		if @tool[2].selection_drag || @tool[2].selection
		  @window.draw_rect(@x + @tool[2].start_sel[0]*@window.tile_width-@scroll_x, @y + @tool[2].start_sel[1]*@window.tile_height - @scroll_y + CAPTION_HEIGHT,
		  @x + @tool[2].end_sel[0]*@window.tile_width - @scroll_x, @y + @tool[2].end_sel[1]*@window.tile_height - @scroll_y + CAPTION_HEIGHT, Gosu::Color.new(50, 0, 0, 200))
		end
	  }
  end

end
