class Event < Window
  attr_reader :events
  attr_reader :index
  def initialize(window, x, y, width)
    super(window, x, y, width, 35+CAPTION_HEIGHT, "Event")
    button = add_widget(Button.new(window, 5, 5, "<", 20))
    button.set_action(:release, method(:previous_event))
    @text_box = add_widget(TextBox.new(window, 30, 5, width - 60, 20))
    @button = add_widget(Button.new(window, width - 25, 5, ">", 20))
    @button.set_action(:release, method(:next_event))
    @index = 0
    @events = []
  end

  def height=(value)
    return if value < 30
    super(value)
  end

  def width=(value)
    return if value < 70
    super(value)
    @text_box.width = width - 60
    @button.x = @x + width - 25
  end

  def event_name
    text = @text_box.text
    @events.push(text) if !@events.include?(text)
    @index = @events.size - 1
    return text
  end

  def index=(value)
    return if @events.size == 0
    @index = value
    @text_box.text = @events[@index]
  end
  
  def next_event
    self.index += 1
    self.index = 0 if @index >= @events.size
  end
  
  def previous_event
    self.index -= 1
    self.index = @events.size-1 if @index < 0
  end

  def add_event(name)
    @events.push(name)
  end
end
