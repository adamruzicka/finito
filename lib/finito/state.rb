module Finito
  # Class representing a state.
  class State
    include Drawable

    attr_reader :name, :initial, :final, :transient

    # @param name [String] the name of the state
    # @param [Hash] options the options to create the state with
    # @option options [Boolean] :initial (false) The state is initial
    # @option options [Boolean] :transient (false) The state is transient
    # @option options [Boolean] :final (false) The state is final
    def initialize(name, options = {})
      @name = name
      @initial = options.fetch(:initial, false)
      @final = options.fetch(:final, false)
      @transient = options.fetch(:transient, false)
    end

    # @return [String] textual representation of the state in graphviz language
    def draw
      properties = ["<B>#{name}</B>"]
      properties << font_color('initial', 'blue')      if initial
      properties << font_color('transient', 'dimgray') if transient
      properties << font_color('final', 'darkgreen')   if final
      "#{name} [label=<#{properties.join('<BR/>')}>];"
    end
  end
end
