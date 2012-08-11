class Layer < Window
  attr_reader :index
  attr_reader :layers_name
  def initialize(window, x, y, width, height)
    super(window, x, y, width, height, "Layers")
    @index = 0
    @layers_name = Array.new
    button = Button.new(window, 0, 0, "T", 16)
    button.set_action(:release, Proc.new{add_layer(0)})
    add_caption_widget(button)
    button = Button.new(window, 0, 0, "E", 16)
    button.set_action(:release, Proc.new{add_layer(1)})
    add_caption_widget(button)
    add_caption_widget(Button.new(window, 0, 0, "/\\", 16, 16)).set_action(:release, method(:move_up_current_layer))
    add_caption_widget(Button.new(window, 0, 0, "\\/", 16, 16)).set_action(:release, method(:move_down_current_layer))
    @font = Cache.font(window, 16)
    add_layer(0)
  end

  def marshal_dump
    return [@layer_name, @index]
  end

  def marshal_load(array)
    remove_all
    @layer_name, @index = array
    @window.map.layer.size.times{|i|
      add_layer(event_layer?(i) ? 1 : 0, false)
    }
  end

  def move_down_current_layer
    layer1 = @index
    layer2 = @index + 1
    return if layer2 >= @window.map.layer.size
    tmp = @layers_name[layer2]
    @layers_name[layer2] = @layers_name[layer1]
    @layers_name[layer1] = tmp
    @window.map.invert_layer(layer1, layer2)
    @index = layer2
  end

  def move_up_current_layer
    layer1 = @index
    layer2 = @index - 1
    return if layer2 < 0
    tmp = @layers_name[layer2]
    @layers_name[layer2] = @layers_name[layer1]
    @layers_name[layer1] = tmp
    @window.map.invert_layer(layer1, layer2)
    @index = layer2
  end

  def event_layer?(layer_id)
    return (@window.map.layer[layer_id].is_a?(Hash))
  end

  def add_layer(type = 0, map_layer = true)
    @window.map.layer.push(type == 1 ? Hash.new : Array.new) if @window.map && map_layer
    @layers_name.push("Layer #{@layers_name.size} - " + (type == 1 ? "Events" : "Tiles"))
    y = @widget.empty? ? -2 : @widget.last.y-@y-2
    check_box = CheckBox.new(@window, 0, y, 20, 20)
    check_box.checked = true
    add_widget(check_box)
    @window.need_redraw = true
  end

  def remove_all
    @widget = Array.new
    @layers_name = Array.new
    @index = 0
  end

  def show_layer?(id)
    return @widget[id].checked
  end

  def button_triggered(id)
    if @over && id == Gosu::MsLeft && @over != @index
      @index = @over
      @window.need_redraw = true
      return false
    end
    return super(id)
  end

  def update
    super
    if mouse_over? && @window.mouse_x - @x > 20
      y = @window.mouse_y - @y - CAPTION_HEIGHT - 7
      over = (y/20).round
      if @over != over
        @over = over
        @window.need_redraw = true
      end
    else
      @window.need_redraw = true if @over
      @over = nil
    end
  end

  def draw
    @window.clip_to(@x, @y, @visible_rect[0]+1, @visible_rect[1] + CAPTION_HEIGHT + 1) {
      super
      @window.map.layer.each_with_index{|l, i|
        @window.draw_rect(@x+19, @y-2+i*19+CAPTION_HEIGHT, @x+@width, @y-2+i*19+CAPTION_HEIGHT+20, Color::BORDER)
        if i != @over || i == @index
          @window.draw_rect(@x+20, @y-1+i*19+CAPTION_HEIGHT, @x+@width-1, @y-1+i*19+CAPTION_HEIGHT+18, i == @index ? Color::BUTTON_PRESSED : Color::BUTTON_BACKGROUND)
        end
        @font.draw(@layers_name[i], @x + 22, @y+i*19+CAPTION_HEIGHT, 0, 1, 1, Color::FONT)
      }}
  end
end
