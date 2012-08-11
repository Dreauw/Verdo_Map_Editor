class Button < Widget
  include Action
  attr_reader :state
  attr_reader :label
  def initialize(window, x, y, label = "", width = nil, height = nil, font_height = nil)
    font_height = (height ? height : 20) - 4 if !font_height
    @font = Cache.font(window, font_height)
    @label = label
    @state = :normal
    label_width = @font.text_width(@label).round
    width = label_width + 6 if !width
    # Square if only one character
    height = width if label.length == 1 && !height
    height = 20 if !height
    super(window, x, y, width, height)
    update_label
  end
  
  def state=(value)
    return if @state == value
    call_action(:trigger) if @state != value && value == :pressed
    call_action(:release) if @state != value && @state == :pressed
    @state = value
    @window.need_redraw = true
  end

  def update_label
    label_width = @font.text_width(@label).round
    @margin_x = ((@width - label_width) / 2).round
    @margin_y = ((@height - @font.height) / 2).round
  end
  
  def update
    if mouse_over?
      self.state = :over if @state != :over && @state != :pressed
    else
      self.state = :normal if @state != :normal && @state != :pressed
    end
  end

  def button_triggered(id)
    self.state = :pressed if id == Gosu::MsLeft && @state == :over
  end

  def button_released(id)
    self.state = :normal if id == Gosu::MsLeft && @state == :pressed
  end

  def draw
    @window.draw_rect(@x, @y, @x+@width, @y+@height, Color::BORDER)
    color = Color::BUTTON_BACKGROUND
    color = Color::BORDER if @state == :over
    color = Color::BUTTON_PRESSED if @state == :pressed
    @window.draw_rect(@x+1, @y+1, @x+@width-1, @y+@height-1, color)
    @font.draw(@label, @x+@margin_x, @y+@margin_y, 0, 1, 1, Color::FONT) if @margin_x > 0
  end
end