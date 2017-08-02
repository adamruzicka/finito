module Finito
  # Purpose of this module is to allow "handling" the state machine. This mostly means it allows the state machine
  # to execute its on_transition callbacks inside the context of the handler's instance.

  module Handler
    # Callback called when the state machine reaches a final state.
    # @abstract Include and override {#on_finish} to implement
    #   custom behavior.
    def on_finish; end

    # Perform one transition of the state machine, if possible.
    # @param args [Array] array of arguments to be passed to the condition callbacks
    #   and on_transition callback
    # @raise [NoMoreTransitions] if the state machine
    #   cannot transition to another state
    # @raise [AccountBalanceError] if the state machine
    #   has several options to which state to transition
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def step(*args)
      all_transitions = state_machine.possible_transitions
      transitions = evaluate_transitions(all_transitions, *args)

      if transitions.empty?
        raise Finito::Exception::NoMoreTransitions, state_machine.current_state.name if state_machine.current_state.transient || !state_machine.can_end?
        on_finish
      elsif transitions.count > 1
        raise Finito::Exception::NoDeterministicTransition.new state_machine.current_state.name,
          transitions.map(&:to)
      else
        perform_transition transitions.first, *args
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # Defines a way for the handler to access the instance of the
    # state machine it is handling.
    # @abstract Include and override {#state_machine} to implement
    #   the access.
    def state_machine
      raise NotImplementedError
    end

    private

    # Do the transition and execute all the associated callbacks.
    #
    # @param transition [StateTransition] the transition to perform
    # @param args [Array] arguments to be passed to the callbacks
    def perform_transition(transition, *args)
      state_machine.perform_transition(transition) do |callback, around_transition|
        around_args = [around_transition, transition, *args]
        evaluate_around_transition(:before, *around_args)
        evaluate(callback, *args)
        evaluate_around_transition(:after, *around_args)
      end
    end

    # Run the block/symbol in the context of the current class.
    #
    # @param block [Proc, Symbol] callback to be executed
    # @param args [Array] arguments to be passed to the callback
    def evaluate(block, *args)
      return if block.nil?
      if block.is_a? Symbol
        instance_exec(self, *args, &block)
      else
        instance_exec(*args, &block)
      end
    end

    # Run the around_transition callbacks.
    #
    # @param kind [Symbol] kind of the transitions, either :before or :after
    # @param around_transition [Array<Proc,Symbol>] callbacks to be executed
    # @param transition [StateTransition] transition the callbacks are wrapping
    # @param args [Array] arguments to be passed to the callbacks
    def evaluate_around_transition(kind, around_transition, transition, *args)
      around_transition.each do |callback|
        evaluate(callback, kind, transition, *args)
      end
    end

    # Run the condition callbacks on transitions, select those which succeed.
    #
    # @param transitions [Array<StateTransition>] transitions to be filtered
    # @param args [Array] arguments to be passed to the condition callback
    def evaluate_transitions(transitions, *args)
      transitions.select do |transition|
        transition.can_transition? { |condition| evaluate(condition, *args) }
      end
    end
  end
end
