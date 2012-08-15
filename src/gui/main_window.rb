class MainWindow < Gosu::Window
  UNDO_SIZE = 20
  
  attr_reader :background
  attr_accessor :need_redraw
  attr_reader :popup
  attr_accessor :undo_stack
  attr_reader :shortcut

  def initialize(width, height, fullscreen = false)
    super(width, height, fullscreen)
  @shortcut = Hash.new
    @widgets = Array.new
    @need_redraw = true
    @undo_stack = Array.new
  end

  def add_undo_event(event)
    @undo_stack.push(event)
    @undo_stack.pop if @undo_stack.size > UNDO_SIZE
  end

  def add_widget(widget, shortcut = nil)
    @widgets.push(widget)
	@shortcut[shortcut] = widget if shortcut
    return widget
  end

  def remove_widget(widget)
    @widgets.remove(widget)
  end

  def popup=(value)
    @popup = value
    GC.start if !value
  end
    
  def draw_rect(x1, y1, x2, y2, color1, color2 = nil, z = 0)
    color2 ||= color1
    draw_quad(x1, y1, color1, x2, y1, color1, x1, y2, color2, x2, y2, color2, z)
  end

  def draw_line(x1, y1, x2, y2, color1, color2 = nil, z = 0)
    color2 ||= color1
    super(x1, y1, color1, x2, y2, color2, z)
  end

  def draw_triangle(x1, y1, x2, y2, x3, y3, color1, color2 = nil, color3 = nil, z = 0)
    color2 ||= color1
    color3 ||= color1
    super(x1, y1, color1, x2, y2, color2, x3, y3, color3, z)
  end

  def needs_redraw?
    return @need_redraw
  end

  def needs_cursor?
    return true
  end
  
  def button_down(id)
    return if text_input && id != Gosu::MsLeft
	char = button_id_to_char(id)
    if (button_down?(Gosu::KbRightControl) || button_down?(Gosu::KbLeftControl)) && char == "z"
      @undo_stack.pop.execute(self) if !@undo_stack.empty?
    end
	widget = @shortcut[char]
	(return widget.show = !widget.show) if widget
    return @popup.button_triggered(id) if @popup
    @widgets.reverse.each{|w|break unless w.button_triggered(id)}
  end

  def button_up(id)
    return @popup.button_released(id) if @popup
    @widgets.reverse.each{|w|break unless w.button_released(id)}
  end

  def update
    return @popup.update if @popup
    @widgets.reverse.each{|w|w.update if w.show}
  end
  
  def background=(value)
    @background = value
    @need_redraw = true
  end
  
  def draw
    draw_rect(0, 0, width, height, Color::MAIN_BACKGROUND)
    @widgets.each{|w|w.draw if w.show}
    @popup.draw if @popup
    @need_redraw = false
  end
end