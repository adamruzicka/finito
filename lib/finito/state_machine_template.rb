require 'sourcify'

module Finito
  # Template for a state machine, holds information about states and transitions.
  class StateMachineTemplate
    include Finito::Drawable

    attr_reader :state_transitions, :states, :around_transitions

    def initialize(states = {},
                   state_transitions = {},
                   around_transitions = [],
                   all_transient = false)
      @states = states
      @state_transitions = state_transitions
      @around_transitions = around_transitions
      @all_states_transient = all_transient
    end

    # Adds a new state
    #
    # @param name [String] name of the state
    # @param [Hash] options options to create the state with
    def state(name, options = {})
      options[:transient] = true if @all_states_transient
      @states[name] = State.new(name, options)
    end

    # Add a new transition
    # @param from [String] name of the source state
    # @param to [String] name of the target state
    # @param [Hash] options options to create the transition with
    # @param block [Proc,Symbol] callback to execute when the transition happens
    def transition(from, to, options = {}, &block)
      raise Exception::UnknownStateTransition.new('from', from) unless @states[from]
      raise Exception::UnknownStateTransition.new('to', to) unless @states.key? to
      @state_transitions[from] ||= {}
      @state_transitions[from][to] ||= []
      if options.fetch(:disable, false)
        @state_transitions[from][to] = []
      else
        transition = StateTransition.new(from, to, options, block)
        @state_transitions[from][to] << transition
      end
    end

    # Add created state transitions to the internal registry
    #
    # @param transitions [Array<StateTransition>]
    def add_transitions(transitions)
      transitions.each do |transition|
        @state_transitions[transition.from] ||= {}
        @state_transitions[transition.from][transition.to] ||= []
        @state_transitions[transition.from][transition.to] << transition
      end
    end

    # Register a callback to be executed before and after each transition
    #
    # @param block [Proc,Symbol] the callback to be executed before and after each transition.
    def around_transition(&block)
      raise 'This method requires a block' unless block_given?
      @around_transitions << block
    end

    # @param from [String] name of the source state
    # @return [Array<StateTransition>] possible transitions from given state
    def possible_transitions(from)
      @state_transitions.fetch(from, {}).values.flatten
    end

    # @return [StateMachine] state machine instantiated from the template
    def instantiate
      instance_class.new(self).tap(&:set_initial_state)
    end

    # Marks all states defined in the future as transient
    def all_states_transient!
      @all_states_transient = true
    end

    # Performs a deep copy of the template
    #
    # @return StateMachineTemplate clone of the template
    def clone
      self.class.new(@states.dup,
                     deep_clone_hash(@state_transitions),
                     @around_transitions.dup,
                     @all_states_transient)
    end

    # Class of the state machine to be instantiated
    def instance_class
      StateMachine
    end

    # @return [String] textual representation of the template in graphviz language
    def draw
      lines = ['digraph {']
      lines.concat(@states.values.map(&:draw))
      lines.concat(@state_transitions.values.map(&:values).flatten.map(&:draw))
      lines << '}'
      lines.join("\n")
    end

    private

    # rubocop:disable Metrics/MethodLength
    # Does a deep clone of a hash
    #
    # @param hash [Hash] the hash to be cloned
    # @return [Hash] deeply cloned hash
    def deep_clone_hash(hash)
      new = {}
      hash.each do |key, value|
        new[key] = if value.is_a?(Hash)
                     deep_clone_hash(value)
                   elsif value.is_a?(Array)
                     value.dup
                   else
                     value
                   end
      end
      new
    end
    # rubocop:enable Metrics/MethodLength
  end
end
