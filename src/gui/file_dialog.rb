class FileDialog < MessageBox
  include Action
  def initialize(window, mode, filter = "All (*.*)", default = "")
    # if !defined?(Win32API)
    @mode = mode
    caption = mode.to_s
    caption[0] = caption[0].capitalize
    super(window, caption, "", [], 250)
    if @mode == :save
      add_button("Cancel").set_action(:release, Proc.new{self.show = false})
      add_button("Save").set_action(:release, method(:ok_action))
      @text_box = TextBox.new(@window, @x+5, @y+5+CAPTION_HEIGHT, 240, 20, default)
    else
      filter = [filter] if !filter.is_a?(Array)
      ext = "*.{"
      filter.first[/.*\((.*)\)/]
      ext += ($1.include?(";") ? $1.split(";").join(",") : $1).gsub("*.", "")
      @file_list = Dir.glob(File.join(ext+"}"))
      @file_list.push("") if @file_list.empty?
      @file_index = 0
      self.text = "In : #{Dir.pwd}\nFile : #{@file_list[@file_index]}"
      add_button(" >").set_action(:release, method(:next_file))
      add_button("Cancel").set_action(:release, Proc.new{self.show = false})
      add_button("Open").set_action(:release, method(:ok_action))
      add_button("< ").set_action(:release, method(:previous_file))
    end
  end

  def next_file(b = nil)
    @file_index += 1
    @file_index = 0 if @file_index >= @file_list.size
    self.text = "In : #{Dir.pwd}\nFile : #{@file_list[@file_index]}"
  end

  def previous_file(b = nil)
    @file_index -= 1
    @file_index = @file_list.size-1 if @file_index < 0
    self.text = "In : #{Dir.pwd}\nFile : #{@file_list[@file_index]}"
  end
  
  def x=(value)
    inc =  value - @x
    super(value)
    @text_box.x += inc if @text_box
  end

  def y=(value)
    inc =  value - @y
    super(value)
    @text_box.y += inc if @text_box
  end

  def file
    return Dir.pwd+@text_box.text
  end
  
  def ok_action(button)
    call_action(@mode)
    @window.popup = nil if @window.popup == self
  end

  def show=(value)
    super(value)
    call_action(:cancel) if !value
  end
  
  def button_triggered(id)
    super(id)
    @text_box.button_triggered(id) if @text_box
  end
  
  def button_released(id)
    super(id)
    @text_box.button_released(id) if @text_box
  end
  
  def update
    super
    @text_box.update if @text_box
  end
  
  def draw
    super
    @text_box.draw if @text_box
  end
end
