class SetTilesEvent < UndoEvent
  attr_reader :tiles
  attr_reader :id
  attr_reader :layer
  attr_reader :width

  def initialize(window, layer, width)
    @width, @layer = width, layer
    @tiles = Hash.new
    super(window)
  end
  
  def add_tile(x, y, id)
    @tiles[x+y*@width] = id
  end
  
  def has_tile?(x, y)
    return @tiles[x+y*@width] != nil
  end

  def execute(window)
    @tiles.each { |key, value|
      x = key%@width
      y = key/@width
      window.map.set_tile(x, y, value, @layer)
    }
  end
end
