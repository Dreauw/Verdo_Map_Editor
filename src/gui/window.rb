class Window < Widget
  CAPTION_HEIGHT = 21

  attr_reader :caption, :resizable, :visible_rect
  
  def initialize(window, x, y, width, height, caption = "", resizable = true)
    height -= CAPTION_HEIGHT
    super(window, x, y, width, height)
    @resizable = resizable
    @font = Cache.font(window, CAPTION_HEIGHT-5)
    self.caption = caption
    @cross_width = @font.text_width("X")
    @drag_resize = @drag = false
    @shortcut = -1
    @visible_rect = [width, height]
    @caption_widget = Array.new
    @widget = Array.new
    @min_width = 0
  end

  def mouse_over?
    return @window.mouse_x.between?(@x, @x+@width) && @window.mouse_y.between?(@y+CAPTION_HEIGHT, @y+CAPTION_HEIGHT+@height)
  end

  def x=(value)
    inc =  value - @x
    super(value)
    @caption_widget.each {|b| b.x += inc}
    @widget.each {|b| b.x += inc}
  end

  def y=(value)
    inc =  value - @y
    super(value)
    @caption_widget.each {|b| b.y += inc}
    @widget.each {|b| b.y += inc}
  end

  def add_caption_widget(widget)
    @min_width = @caption_width if @min_width < @caption_width
    widget.x = @x + @min_width + 6#@width - @cross_width - widget.width - 10
    widget.y = @y + ((CAPTION_HEIGHT - widget.height)/2)
    @min_width += widget.width + 8
    @caption_widget << widget
    return widget
  end

  def add_widget(widget)
    widget.x += @x
    widget.y += @y + CAPTION_HEIGHT
    @widget << widget
    return widget
  end

  def width=(value)
    super(value) if value > @min_width+@cross_width+6
    @visible_rect[0] = @width
  end

  def height=(value)
    super(value) if value > 11
    @visible_rect[1] = @height
  end

  def button_triggered(id)
    @caption_widget.each{|b|b.button_triggered(id)}
    @widget.each{|b|b.button_triggered(id)}
    if id == Gosu::MsLeft
      if @window.mouse_x.between?(@x, @x+@width) &&
          @window.mouse_y.between?(@y, @y+CAPTION_HEIGHT-3)
        return true if @window.mouse_x.between?(@x+3+@caption_width, @x+@min_width)
        if @window.mouse_x > @x+@width-@cross_width-3
          self.show = false
          return false
        end
        @drag = true
        @start_drag_pos = [@window.mouse_x - @x, @window.mouse_y - @y]
        return false
      end
      if @resizable && @window.mouse_x.between?(@x+@width-8, @x+@width) &&
          @window.mouse_y.between?(@y+CAPTION_HEIGHT+@height-8, @y+CAPTION_HEIGHT+@height)
        @drag_resize = true
        @start_drag_pos = [@window.mouse_x-@x-(@width-11), @window.mouse_y-@y-(CAPTION_HEIGHT+@height-11)]
        return false
      end
    end
    return true
  end

  def button_released(id)
    @caption_widget.each{|b|b.button_released(id)}
    @widget.each{|b|b.button_released(id)}
    @drag_resize = @drag = false if id == Gosu::MsLeft
    return true
  end

  def update
    @caption_widget.each{|b|b.update}
    @widget.each{|b|b.update}
    if @drag
      self.x = @window.mouse_x - @start_drag_pos[0]
      self.y = @window.mouse_y - @start_drag_pos[1]
    elsif @drag_resize
      self.width = ((@window.mouse_x - @x + 11) - @start_drag_pos[0])
      self.height = ((@window.mouse_y - (@y + 10)) - @start_drag_pos[1])
    end
  end

  def resizable=(value)
    return until @resizable != value
    @resizable = value
    @window.need_redraw = true
  end

  def caption=(value)
    return until @caption != value
    @caption = value
    @caption_width = @font.text_width(@caption)
    @window.need_redraw = true
  end

  def draw
    @window.draw_rect(@x, @y, @x + @width, @y + @height + CAPTION_HEIGHT, Color::BORDER)
    @window.draw_rect(@x+1, @y+CAPTION_HEIGHT-1, @x+@width-1, @y+@height+CAPTION_HEIGHT-1, Color::WINDOW_BACKGROUND1, Color::WINDOW_BACKGROUND2)
    @window.draw_rect(@x+1, @y+1, @x+@width-1, @y+CAPTION_HEIGHT-2, Color::CAPTION1, Color::CAPTION2)
    @font.draw(@caption, @x+3, @y+3, 0, 1, 1, Color::FONT) if @caption_width+10+@cross_width < @width
    @font.draw("X", @x+@width-@cross_width-3, @y+3, 0, 1, 1, Color::FONT)
    @caption_widget.each{|b|b.draw if b.show}
    @window.clip_to(@x, @y + CAPTION_HEIGHT, @visible_rect[0], @visible_rect[1]) {draw_content}
    return until @resizable
    @window.draw_triangle(@x+@width-11, @y+@height+CAPTION_HEIGHT, @x+@width,
      @y+@height+CAPTION_HEIGHT, @x+@width, @y+@height+CAPTION_HEIGHT-11, Color::BORDER)
  end
  
  def draw_content
  @widget.each{|b|b.draw if b.show}
  end
end