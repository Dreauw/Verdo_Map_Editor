module Cache
  def self.font(window, font_height)
    @fonts ||= Hash.new
    @fonts[font_height] ||= Gosu::Font.new(window, Gosu.default_font_name, font_height)
    return @fonts[font_height]
  end
end