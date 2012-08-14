class Tileset < Window
  attr_reader :image
  attr_reader :scale
  attr_reader :start_sel
  attr_reader :end_sel
  attr_accessor :file
  
  def initialize(window, x, y, width, height)
    super(window, x, y, width, height, "Tileset - 100%")
    @file = ""
    @scale = 1.0
    @start_sel, @end_sel = [0, 0], [1, 1]
    @tile_width = (@width / (@window.tile_width*@scale)).round
    button = Button.new(window, 0, 0, "R", 16)
    button.set_action(:release, method(:refresh))
    add_caption_widget(button)
    button = Button.new(window, 0, 0, "O", 16)
    button.set_action(:release, method(:select_tileset))
    add_caption_widget(button)
  end

  def select_tileset
    dialog = FileDialog.new(@window, :open, ["All Images Files (*.bmp;*.png)", "Window Bitmap (*.bmp)", "PNG Bitmap (*.png)"])
    dialog.set_action(:open, Proc.new {|d|@file = d.file;refresh})
  end

  def width=(value)
    super(value)
    @tile_width = (@width / (@window.tile_width*@scale)).round
  end
  
  # - Scale the content
  def scale=(value)
    return unless @scale != value
    @scale = value
    @window.need_redraw = true
  end
  
  # - Position of the mouse in tile relative to the window
  def get_mouse_tile_x
    return ((@window.mouse_x - @x)/(@window.tile_width*@scale)).floor
  end
  
  def get_mouse_tile_y
    return ((@window.mouse_y - @y - CAPTION_HEIGHT)/(@window.tile_height*@scale)).floor
  end

  def get_tile_id(x, y)
    id = (x + y * @tile_width).round
    id = -1 if !@image || id >= @image.size
    return id
  end
  
  # - Handle button input
  
  def button_triggered(id)
    super_bool = !super(id)
    mouse_over = mouse_over?
    @ms_left_pressed = true if id == Gosu::MsLeft && mouse_over
    @ms_right_pressed = true if id == Gosu::MsRight && mouse_over
    if id == Gosu::MsWheelUp && mouse_over
      return if (@scale * 100).floor>= 980
      self.scale = (@scale + 0.2).round(2)
      self.caption = "Tileset - #{(@scale*100).floor}%"
    elsif id == Gosu::MsWheelDown && mouse_over
      return if (@scale * 100).floor <= 20
      self.scale = (@scale - 0.2).round(2)
      self.caption = "Tileset - #{(@scale*100).floor}%"
    elsif @ms_left_pressed
      self.start_sel = [get_mouse_tile_x, get_mouse_tile_y]
      @selection = true
    end
    return (@ms_left_pressed || @ms_right_pressed || super_bool ? false : true)
  end
  
  def button_released(id)
    @ms_left_pressed = false if id == Gosu::MsLeft
    @ms_right_pressed = false if id == Gosu::MsRight
    @scroll_drag = false if @scroll_drag && id == Gosu::MsLeft
    return super(id)
  end

  # - Update (each frame)
  
  def update
    super
    if @ms_left_pressed && @selection && !@drag_resize
      self.end_sel = [get_mouse_tile_x, get_mouse_tile_y]
      return
    end
  end
  
  # - Refresh the tileset file
  def refresh
    return if @file.empty?
    @image = Gosu::Image.load_tiles(@window, @file, @window.tile_width, @window.tile_height, true)
    GC.start
    @window.need_redraw = true
  end
  
  # - Selection methods
  
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
  
  # - Draw tiles & selection
  
  def draw_content
    super
    x, y = @x, @y+CAPTION_HEIGHT
      @window.scale(@scale, @scale, x, y+30) {
        if @image
          for i in @image
            i.draw(x, y, 0)
            x += @window.tile_width
            x, y = @x, y+@window.tile_height if x*@scale-@x+(@window.tile_width*scale)/2 > @width
          end
        end

        if @selection
          @window.draw_rect(@x + @start_sel[0]*@window.tile_width, @y + @start_sel[1]*@window.tile_height + CAPTION_HEIGHT,
          @x + @end_sel[0]*@window.tile_width, @y + @end_sel[1]*@window.tile_height + CAPTION_HEIGHT, Gosu::Color.new(50, 0, 0, 200))
        end
      }
  end
end