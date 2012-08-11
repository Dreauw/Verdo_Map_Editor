class MainWindow
  def handle
    @handle ||= Win32API.new('user32', 'FindWindow', 'PP', 'I').call("Gosu::Window", @caption)
    return @handle
  end
end
