class Spinner < TextBox
  def initialize(window, x, y, width, height, number = 0)
    super(window, x, y, width-20, height, number.to_s)
    font_height = 11 if height/2 < 12
    @more_button = Button.new(window, x+width-20, y, "/\\",  20, height/2, font_height)
    @more_button.set_action(:release, method(:increment))
    @less_button = Button.new(window, @more_button.x, y+@more_button.height, "\\/", 20, height/2, font_height)
    @less_button.set_action(:release, method(:decrement))
    set_filter {|text| text[/[0-9]/]}
  end

  def x=(value)
    inc = value - @x
    super(value)
    @more_button.x += inc
    @less_button.x += inc
  end

  def y=(value)
    inc = value - @y
    super(value)
    @more_button.y += inc
    @less_button.y += inc
  end

  def button_triggered(id)
    @more_button.button_triggered(id)
    @less_button.button_triggered(id)
    return super(id)
  end
  
  def button_released(id)
    @more_button.button_released(id)
    @less_button.button_released(id)
    return super(id)
  end
  
  def update
    @more_button.update
    @less_button.update
    super
  end

  def draw
    super
    @more_button.draw
    @less_button.draw
  end

  def number
    return text.to_i
  end

  def number=(value)
    self.text = value.to_s
  end

  def increment
    self.text = (text.to_i+1).to_s
  end

  def decrement
    self.text = (text.to_i-1).to_s
  end
end
