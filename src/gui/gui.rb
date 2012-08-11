require 'rbconfig'
require 'gosu'

if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
  require 'Win32API'
end

require_relative 'color.rb'
require_relative 'cache.rb'
require_relative 'action.rb'
require_relative 'undo_event.rb'
require_relative 'main_window.rb'
require_relative 'win32/main_window.rb' if defined?(Win32API)
require_relative 'widget.rb'
require_relative 'button.rb'
require_relative 'text_box.rb'
require_relative 'check_box.rb'
require_relative 'spinner.rb'
require_relative 'toggle_buttons.rb'
require_relative 'window.rb'
require_relative 'message_box.rb'
require_relative 'file_dialog.rb' if !defined?(Win32API)
require_relative 'win32/file_dialog.rb' if defined?(Win32API)