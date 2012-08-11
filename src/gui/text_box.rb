# For add a way to use the filter system
class TextInput < Gosu::TextInput
  def set_filter(&block)
    @block = block
  end

  def filter(text_in)
    return @block ? @block.call(text_in) : super(text_in)
  end
end

class TextBox < Widget
  attr_reader :window
  TIME = 800
  def initialize(window, x, y, width, height, text = "")
    super(window, x, y, width, height)
    @text_input = TextInput.new
    @text_input.text = text
    @font = Cache.font(window, height-4)
    @counter = 0
    @show_caret = true
  end

  def text=(value)
    @text_input.text = value
  end

  def text
    return @text_input.text
  end
  
  def check_width
    ret = true
    while @font.text_width(@text_input.text)+3 >= @width
      @text_input.text = @text_input.text[0...-1]
      ret = false
    end
    return ret
  end
  
  def update
    if @last_text != @text_input.text || @last_caret_pos != @text_input.caret_pos
      return if !check_width
      @last_caret_pos = @text_input.caret_pos
      @last_text = @text_input.text
      @window.need_redraw = true 
    end
    if Gosu.milliseconds >= @counter+TIME
      @show_caret = !@show_caret
      @window.need_redraw = true
      @counter = Gosu.milliseconds
    end
  end

  def set_filter(&block)
    @text_input.set_filter(&block)
  end

  def button_triggered(id)
    if id == Gosu::MsLeft
      if mouse_over?
        @window.text_input = @text_input
        @window.need_redraw = true
      elsif @window.text_input == @text_input
        @window.text_input = nil
        @window.need_redraw = true
      end
      return false
    end
    return true
  end

  def draw
    @window.draw_rect(@x, @y, @x+@width, @y+@height, Color::BORDER)
    color = @window.text_input == @text_input ? Color::TEXTBOX_BACKGROUND_FOCUS : Color::TEXTBOX_BACKGROUND
    @window.draw_rect(@x+1, @y+1, @x+@width-1, @y+@height-1, color)
    caret_x = @x + 3 + @font.text_width(text[0...@text_input.caret_pos])
    @font.draw("</b>|", caret_x, @y + 1, 0, 1, 1, Color::TEXTBOX_FONT) if @window.text_input == @text_input && @show_caret
    sel_x = @x + 3 + @font.text_width(text[0...@text_input.selection_start])
    @window.draw_rect(sel_x, @y+3, caret_x, @y - 3 + @height, Color::BORDER)
    @font.draw(@text_input.text, @x + 3, @y + 3, 0, 1, 1, Color::TEXTBOX_FONT)
  end
end
