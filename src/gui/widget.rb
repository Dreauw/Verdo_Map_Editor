class Widget
  attr_reader :x, :y, :width, :height, :show

  def initialize(window, x, y, width, height)
    @window, @x, @y, @width, @height = window, x, y, width, height
    @show = true
  end

  # - Abstract methods

  def update;end

  def button_triggered(id);true;end

  def button_released(id);true;end

  def draw;end

  # Simple function for detect if the mouse is over the widget or not
  def mouse_over?
    return @window.mouse_x.between?(@x, @x+@width) && @window.mouse_y.between?(@y, @y+@height)
  end

  # - For property who need redraw

  def x=(value)
    return until @x != value
    @x = value
    @window.need_redraw = true
  end

  def y=(value)
    return until @y != value
    @y = value
    @window.need_redraw = true
  end

  def width=(value)
    return until @width != value
    @width = value
    @window.need_redraw = true
  end

  def height=(value)
    return until @height != value
    @height = value
    @window.need_redraw = true
  end

  def show=(value)
    return until @show != value
    @show = value
    @window.need_redraw = true
  end
end
