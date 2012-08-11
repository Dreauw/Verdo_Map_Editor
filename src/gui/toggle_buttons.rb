class ToggleButtons < Widget
  attr_reader :index
  def initialize(window, x, y, buttons, width = nil)
    @buttons = [Button.new(window, x, y, buttons.first, width)]
    buttons.each_with_index{|b, i| 
      @buttons << Button.new(window, @buttons.last.x + @buttons.last.width + 1, y, b, width) if i > 0}
    @index = height = width = 0
    @buttons.first.state = :pressed
    @buttons.each {|b|
      width += b.width
      height = b.height if b.height > height
      b.set_action(:trigger, method(:on_button_pressed))}
    super(window, x, y, width, height)
  end

  def x=(value)
    return if @x == value
    inc = value - @x
    super(value)
    @buttons.each{|b|b.x += inc}
  end

  def y=(value)
    return if @y == value
    super(value)
    @buttons.each{|b|b.y = @y}
  end

  def on_button_pressed(button)
    button_index = @buttons.index(button)
    if button_index != @index
      @buttons[@index].state = :normal
      @index = button_index
    end
  end

  def update
    @buttons.each{|b|b.update}
  end

  def button_triggered(id)
    @buttons.each{|b|b.button_triggered(id)}
  end

  def draw
    @buttons.each{|b|b.draw}
  end
end
