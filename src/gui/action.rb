module Action
  def set_action(state, method)
    @actions ||= Hash.new
    @actions[state] = method
  end

  def call_action(state, *args)
    @actions ||= Hash.new
    if @actions.has_key?(state)
      if @actions[state].parameters.size > 0
        @actions[state].call(self, *args)
      else
        @actions[state].call
      end
    end
  end
end
