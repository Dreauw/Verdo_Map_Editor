require 'logger'
require_relative 'gui/gui.rb'


require_relative 'layer.rb'
require_relative 'tileset.rb'
require_relative 'event.rb'
require_relative 'map_properties.rb'
require_relative 'map.rb'
require_relative 'undo/set_tiles_event.rb'
require_relative 'undo/set_event_event.rb'
require_relative 'undo/fill_tiles_event.rb'

class ApplicationWindow < MainWindow
  attr_reader :map
  attr_reader :tileset
  attr_reader :event
  attr_reader :layer
  attr_accessor :tile_width
  attr_accessor :tile_height
  def initialize
    super((Gosu.screen_width * 0.9).round, (Gosu.screen_height * 0.8).round, false)
    self.caption = "Verdo Editor v0.1"
    @tile_width = @tile_height = 16
    @tileset = Tileset.new(self, 5, 5, width * 0.2 - 10, height * 0.4 - 10)
    @event = Event.new(self, 5, height * 0.4, width * 0.2 - 10)
    layer_x = @event.y + @event.height + Window::CAPTION_HEIGHT + 5
    @layer = Layer.new(self, 5, layer_x, width * 0.2 - 10, height - layer_x - 5)
    @map = Map.new(self, width * 0.2, 5, width * 0.8 - 5, height-10)
    @tileset.show = @event.show = @layer.show = @map.show = false
    Gosu.enable_undocumented_retrofication
    add_widget(@map, "m")
    add_widget(@layer, "l")
    add_widget(@event, "e")
    add_widget(@tileset, "t")
    File.exist?("map_backup.bak") ? on_start_backup : on_start_map_properties
  end
  
  def on_start_map_properties
    MapProperties.new(self).set_action(:ok, Proc.new {
        @tileset.show = @event.show = @layer.show = @map.show = true
      })
  end

  def on_start_backup
    m = MessageBox.new(self, "Backup", "A backup is present.
It's probably because of an error.\nSee verdo_error.log\n
Do you want to load the backup ?
(If not, the backup will be removed)", ["Yes", "No"])
    m.set_action("Yes", Proc.new{
        File.open("map_backup.bak", "rb") {|file|
          @map.marshal_load(Marshal.load(file))
          @layer.marshal_load(Marshal.load(file))
          @tileset.file = Marshal.load(file)
          @tileset.refresh
        }
        File.delete("map_backup.bak")
        @tileset.show = @event.show = @layer.show = @map.show = true})
    m.set_action("No", Proc.new {
        File.delete("map_backup.bak")
        on_start_map_properties})
  end
end


begin
(window = ApplicationWindow.new).show
rescue
  Logger.new('verdo_error.log').error($!)
  File.open("map_backup.bak", "wb") {|file|
    Marshal.dump(window.map.marshal_dump, file)
    Marshal.dump(window.layer.marshal_dump, file)
    Marshal.dump(window.tileset.file, file)
  }
end