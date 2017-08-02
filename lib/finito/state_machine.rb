module Finito
  # The state machine representing the current state
  # of a StateMachineTemplate
  class StateMachine
    include Drawable

    attr_reader :current_state, :current_transition

    # @param template [StateMachineTemplate] the template to base the StateMachine on
    def initialize(template)
      @template = template
      @current_transition = nil
      set_initial_state
    end

    # Sets the state machine to its initial state
    #
    # @raise [Exception::NoInitialState] if the state machine has no initial state
    # @raise [Exception::NoDeterministicInitialState] if the state machine has more than
    #   one initial state
    def set_initial_state
      initial_states = @template.states.values.select(&:initial)
      if initial_states.count == 1
        @current_state = initial_states.first
      elsif initial_states.count.zero?
        raise Finito::Exception::NoInitialState
      else
        raise Finito::Exception::NoDeterministicInitialState, initial_states
      end
    end

    # @param transition [StateTransition] the transition to perform
    def perform_transition(transition)
      with_transition_tracking(transition) do
        yield transition.callback, @template.around_transitions
      end
    end

    # Gets the list of possible transitions from the current state
    #
    # @return [Array<StateTransition>] the state transitions which can be done
    #   from the current state
    def possible_transitions
      @template.possible_transitions @current_state.name
    end

    # Serializes the state machine
    # @return [Hash] serialized representation of the state machine's state
    def save_current_state
      { :current_state => @current_state.name }
    end

    # Sets the current state to previously saved one
    #
    # @param [Hash] hash the serialized state of the state machine
    # @option hash [String] :current_state the saved state of the state machine
    def load_current_state(hash)
      @current_state = @template.states[hash[:current_state]]
      @current_transition = nil
    end

    # @return [Boolean] whether the state machine can successfully end
    #   in its current state
    def can_end?
      @current_state.final
    end

    # @return [String] textual representation of the state machine
    def draw
      @template.draw
    end

    private

    # Keeps track of the current transition and changes the current state
    # after the transition.
    #
    # @param transition [StateTransition] the transition being done
    def with_transition_tracking(transition)
      @current_transition = transition
      yield
    ensure
      @current_state = @template.states[transition.to]
    end
  end
end
