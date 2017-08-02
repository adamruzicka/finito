module Finito
  # Module providing the DSL for defining states and state transitions.
  module DSL

    # Registers a new state in the class.
    #
    # @param name [String] name of the state
    # @param [Hash] options the options to define the state with
    def state(name, options = {})
      state_machine_template.state(name, options)
    end

    # Registers a new state transition in the class.
    #
    # @param from [String] name of the source state
    # @param to [String] name of the target state
    # @param [Hash] options the options to define the transition with
    # @param block [Proc] the callback to execute when the transition happens
    def transition(from, to, options = {}, &block)
      state_machine_template.transition(from, to, options, &block)
    end

    # Registers a new callback to be executed before and after each transition.
    #
    # @param block [Proc] the callback to execute before and after
    #   every transition
    def around_transition(&block)
      state_machine_template.around_transition(&block)
    end

    # Mark all states define after calling this method as transient
    def all_states_transient!
      state_machine_template.all_states_transient!
    end

    # Method used to inherit the state machine template from another class having DSL.
    #
    # @param template [StateMachineTemplate] the original state machine template to be inherited
    def inherit_state_machine_template(template)
      @state_machine_template = template.clone
    end

    # Callback called when a class with the DSL module is subclassed.
    #
    # @param subclass [Class] the new class being created
    def inherited(subclass)
      subclass.inherit_state_machine_template(state_machine_template)
    end

    # Accessor to the instance of the state machine template for this class.
    # @return [StateMachineTemplate] 
    def state_machine_template
      @state_machine_template ||= state_machine_template_class.new
    end

    # Method to define state transitions using the builder interface.
    #
    # @yield [builder] Gives a StateTransitionBuilder to the given block
    def define_transition
      return unless block_given?
      builder = StateTransitionBuilder.new
      yield builder
      state_machine_template.add_transitions builder.build
    end

    # Creates a new state machine from the template
    #
    # @return [StateMachine] new state machine instance using this class'
    #   StateMachineTemplate
    def instantiate_state_machine_template
      state_machine_template.instantiate
    end

    # Determines the class of the state machine template to be used
    #
    # @return [Class] the class of the state machine to be instantiated
    def state_machine_template_class
      StateMachineTemplate
    end
  end
end
