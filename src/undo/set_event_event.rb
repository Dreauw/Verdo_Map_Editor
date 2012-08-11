class SetEventEvent < UndoEvent
  attr_reader :events
  attr_reader :name
  attr_reader :layer
  attr_reader :width

  def initialize(window, layer, width)
    @width, @layer = width, layer
    @events = Hash.new
    super(window)
  end

  def add_event(x, y, name)
    @events[x+y*@width] = name
  end

  def execute(window)
    @events.each { |key, value|
      x = key%@width
      y = key/@width
      window.map.set_event(x, y, value, @layer)
    }
  end
end
