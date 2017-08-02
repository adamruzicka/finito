module Finito
  # Builder interface for defining state transitions
  class StateTransitionBuilder
    attr_accessor :to

    # Create new StateTransitionBuilder
    #
    # @param from [String] name of the source state
    # @param to [String] name of the target state
    # @param [Hash] options options to create the builder with
    # @return [StateTransitionBuilder] new builder
    def initialize(from = nil, to = nil, options = {})
      @children = []
      @from = from
      @to = to
      @options = options
      @callback = options[:callback]
    end

    # Sets the source state for the current builder
    #
    # @param name [String] name of the source state
    # @yield [builder] new builder with source state set if block given
    # @return [StateTransitionBuilder] self if block given
    # @return [StateTransitionBuilder] new builder with source state set
    #   unless block given
    # @raise [RuntimeError] if source state already set
    def from(name)
      raise "Source state already set to #{@from}" unless @from.nil?
      child = self.class.new(name)
      @children << child
      if block_given?
        yield child
        self
      else
        child
      end
    end

    # Branches a new state builder
    #
    # @param condition [Proc,Symbol] callback to be executed to determine
    #   if the transition is possible
    # @param negate [Boolean] if the result of the condition should be negated
    # @param block [Proc,Symbol] callback to be executed when the transition happens
    # @return [StateTransitionBuilder] new transition builder with from and to
    #   inherited from the current one
    def if(condition = nil, negate = false, &block)
      child = self.class.new(@from, @to,
                             :condition => block_given? ? block : condition,
                             :negate => negate)
      @children << child
      child
    end

    # Branches a new state builder with the last condition negated
    #
    # @return [StateTransitionBuilder] new builder with last condition negated
    def else
      condition = @options[:condition]
      raise 'Cannot create else branch without condition' if condition.nil?
      child = self.class.new(@from, nil,
                             :condition => condition,
                             :negate => !@options.fetch(:negate, false))
      @children << child
      child
    end

    # Branches a new state builder with a condition
    #
    # @param condition [Proc,Symbol] callback to be executed to determine
    #   if the transition is possible
    # @param block [Proc,Symbol] callback to be executed when the transition happens
    # @return [StateTransitionBuilder] new builder with source and destination states
    #   inherited and condition set
    def elsif(condition = nil, &block)
      child = self.if(condition, &block)
      child.to = nil
      child
    end

    # The same as #{if} but the condition is negated
    #
    # @param condition [Proc,Symbol] callback to be executed to determine
    #   if the transition is possible (the callback is negated after execution)
    # @param block [Proc,Symbol] callback to be executed when the transition happens
    # @return [StateTransitionBuilder] new transition builder with from and to
    #   inherited from the current one
    def unless(condition = nil, &block)
      self.if(condition, true, &block)
    end

    # Sets the target state
    #
    # @raise [RuntimeError] if the target state is already set
    # @param name [String] name of the target state
    # @return [StateTransitionBuilder] returns self
    def goto(name)
      raise "Target state already set to #{@to}" unless @to.nil?
      @to = name
      self
    end

    # Sets the callback to be performed
    #
    # @param symbol [Symbol] the symbol to be executed
    # @param block [Proc] the block to be executed
    # @return [StateTransitionBuilder] returns self
    def do(symbol = nil, &block)
      @callback = block_given? ? block : symbol
      self
    end

    # Creates a transition from the source state to the source state
    #
    # @return [StateTransitionBuilder] returns self
    def stay
      goto(@from)
    end

    # Set human readable description for the transition
    #
    # @note not used anywhere yet
    def description(desc)
      @options[:description] = desc
    end

    # Collect the child builders and create an array of state transitions
    #
    # @return [Array<StateTransition>] the create state transitions
    def build
      children = @children.map(&:build).flatten
      if complete?
        this = StateTransition.new(@from, @to, @options, @callback)
        children = [this] + children
      end
      children
    end

    private

    # Check if the transition has both source and target states set
    #
    # @return [Boolean] whether the transition is completely defined
    def complete?
      @from && @to
    end
  end

  # Class representing StateTransition
  class StateTransition
    include Drawable

    attr_reader :from, :to, :condition, :callback, :negate

    # @param from [String] name of the source state
    # @param to [String] name of the destination state
    # @param [Hash] options options to create the transition with
    # @option options [Proc,Symbol,nil] :if condition to evaluate
    # @option options [Proc,Symbol,nil] :condition condition to evaluate
    # @param callback [Proc,Symbol,nil] callback to execute when performing
    #   this transition
    def initialize(from, to, options = {}, callback = nil)
      @from      = from
      @to        = to
      options[:condition] = options[:if] if options.key? :if
      @condition = options[:condition]
      @negate    = options[:negate]
      @callback  = callback
    end

    # Check if the transition can be done
    #
    # @param block [Proc, nil] block to yield the condition to for evaluation
    def can_transition?(&block)
      @condition.nil? || yield_condition(&block)
    end

    # @return [String] textual representation of the StateTransition
    def draw
      base = "#{from} -> #{to}"
      return base if @condition.nil?
      negate = @negate ? '!' : ''
      %(#{base} [label="#{negate}#{proc_to_text(@condition)}"])
    end

    private

    # Evaluates the condition either locally or by passing it to a given block,
    # negating the result if desired.
    #
    # @yield [condition] Yields the condition to be evaluated if a block was given.
    def yield_condition
      result = if block_given?
                 yield condition
               else
                 condition.call
               end
      @negate ? !result : result
    end
  end
end
