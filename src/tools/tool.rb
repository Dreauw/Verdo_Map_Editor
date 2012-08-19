class Tool
  def initialize(window)
    @window = window
  end
  
  # Abstract methods
  def ms_left_pressed;end
  
  def ms_right_pressed;end
  
  def ms_left_triggered;end
  
  def ms_right_triggered;end
  
  def ms_left_released;end
  
  def ms_right_released;end
  
  def button_triggered(id);end
  
end