class UndoEvent
  def initialize(window)
    window.add_undo_event(self)
  end

  def execute(window)
  end
end
