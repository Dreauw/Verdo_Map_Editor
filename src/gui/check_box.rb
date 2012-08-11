class CheckBox < Widget
  attr_reader :checked
  attr_reader :over
  def initialize(window, x, y, width = 20, height = 20)
    super(window, x, y, width, height)
    @state = :normal
  end
  
  def checked=(value)
    return if value == @checked
    @checked = value
    @window.need_redraw = true
  end

  def over=(value)
    return if value == @over
    @over = value
    @window.need_redraw = true
  end
  
  def update
    super
    self.over = mouse_over?
  end
  
  def button_triggered(id)
    self.checked = !@checked if @over && id == Gosu::MsLeft
    return super(id)
  end
  
  def draw
    super
    @window.draw_rect(@x, @y, @x+@width, @y+@height, Color::BORDER)
    if !@over
      @window.draw_rect(@x+1, @y+1, @x+@width-1, @y+@height-1, Color::CHECKBOX_BACKGROUND)
    end
    if @checked
      @window.draw_rect(@x+4, @y+4, @x+@width-4, @y+@height-4, Color::CHECKBOX_MARK)
    end
  end
end
