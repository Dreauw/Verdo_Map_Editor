class FileDialog
  attr_reader :file
  def initialize(window, mode, filter = "All Files (*.*)", default = "")
    @mode, @res = mode, 0
    filter = [filter] if !filter.is_a?(Array)
    str_filter = ""
    filter.each_with_index{|f, i|
      f[/.*\((.*)\)/]
      str_filter += f+"\0"+$1+"\0"
    }
    buffer = default+"\0"*1024+"\0\0"
    struct = Array.new(20, 0)
    struct[0] = 76
    struct[1] = window.handle
    struct[3] = str_filter
    struct[7] = buffer
    struct[8] = buffer.size
    struct[13] = 0x00000004|0x00080000
    struct[13] |= 0x00001000 if @mode == :open
    struct[13] |= 0x00000002 if @mode == :save
    @res = Win32API.new('comdlg32', 'Get'+(mode==:save ?'Save':'Open')+'FileName', 'P', 'I').call(struct.pack("I3PI3PI*"))
    @file = buffer.gsub!("\0", "").gsub!("\\", "/")
  end

  def set_action(action, method)
    if (action == :cancel && @res == 0) || (action == @mode && @res != 0)
      method.parameters.size > 0 ? method.call(self) : method.call
    end
  end
end