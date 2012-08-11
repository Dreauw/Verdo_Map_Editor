class FillTilesEvent < UndoEvent
  attr_reader :tiles
  attr_reader :id
  attr_reader :layer
  attr_reader :width

  def initialize(window, layer, width, id)
    @width, @layer, @id = width, layer, id
    @tiles = Array.new
    super(window)
  end

  def add_tile(x, y)
    @tiles.push(x+y*@width)
  end

  def execute(window)
    @tiles.each { |i|
      x = i%@width
      y = i/@width
      window.map.set_tile(x, y, @id, @layer)
    }
  end
end