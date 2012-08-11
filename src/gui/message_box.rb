class MessageBox < Window
  include Action
  def initialize(window, title="", text="", button = ["OK"], width = nil)
    width = 200 if !width
    height = 86
    x = (window.width - width)/2
    y = (window.height - height)/2
    super(window, x, y, width, height, title, false)
    @buttons = Array.new
    self.text = text if !text.empty?
    window.popup = self
    button.reverse.each {|b|add_button(b)}
  end

  def x=(value)
    inc =  value - @x
    super(value)
    @buttons.each {|b| b.x += inc}
  end

  def y=(value)
    inc =  value - @y
    super(value)
    @buttons.each {|b| b.y += inc}
  end

  def height=(value)
    inc =  value - @height
    super(value)
    @buttons.each {|b| b.y += inc}
  end

  def width=(value)
    inc =  value - @width
    super(value)
    @buttons.each {|b| b.x += inc}
  end

  def text=(value)
    (return @text_image = nil) if value.empty?
    @text_image = Gosu::Image.from_text(@window, value, Gosu.default_font_name, 16)
    width = @text_image.width+10
    height = @text_image? @text_image.height + 70 : 86
    if height > @height
      self.height = height - CAPTION_HEIGHT
      self.y = (@window.height - @height)/2
    end
    if width > @width
      self.width = width
      self.x = (@window.width - @width)/2
    end
    @window.need_redraw = true
  end
  
  def add_button(button_name)
    button = Button.new(@window, 0, 0, button_name, nil, 20)
    button.x =  @buttons.empty? ? @x+@width-button.width-5 : @buttons.last.x-button.width-5
    button.y = @y+CAPTION_HEIGHT+@height-button.height-5
    @buttons.push(button)
    button.set_action(:release, method(:on_button_released))
    return button
  end
  
  def on_button_released(button)
    call_action(button.label)
    self.show = false
  end
  
  def button_triggered(id)
    @buttons.each{|b|b.button_triggered(id)}
    return super(id)
  end
  
  def button_released(id)
    @buttons.each{|b|b.button_released(id)}
    return super(id)
  end

  def update
    super
    @buttons.each{|b|b.update}
  end

  def show=(value)
    super(value)
    if !value
      @window.popup = nil if @window.popup == self
    end
  end

  def draw
    super
    @window.draw_rect(@x+1, @y+@height+CAPTION_HEIGHT-41, @x+@width-1, @y+CAPTION_HEIGHT+@height-1, Color::MESSAGEBOX_BOT1, Color::MESSAGEBOX_BOT2)
    @text_image.draw(@x+5, @y+5+CAPTION_HEIGHT, 0, 1, 1, Color::FONT) if @text_image
    @buttons.each{|b|b.draw}
  end
end
