module Finito
  module Dynflow
    module Action
      # A module ipmlementing important bits and pieces to allow using a state machine
      # in Dynflow actions
      module WithStateMachine

        include ::Finito::Handler
        extend  ::Finito::DSL

        # Run phase of an action which saves and loads state machine's state
        # to and from action's output and controls the state machine
        def run(event = nil)
          loop do
            with_keeping_state { step(event) }
            raise @exception if @exception
            break unless state_machine.current_state.transient && !state_machine.current_state.final
          end
          suspend unless state_machine.current_state.final
        end

        # Helper for raising exceptions in actions. The exception is stored and raised later
        # when the transition completed.
        #
        # @param message[Exception,String] the exception or message to be raised
        def fail(message)
          @exception = message
        end

        # Keeps the state machine's state by saving it a loading it to/from action's output
        # 
        # @yield calls the given block in between loading and saving the state
        def with_keeping_state
          if control.key? :saved
            state_machine.load_current_state(control[:saved])
          else
            state_machine.set_initial_state
          end
          yield
          control[:saved] = state_machine.save_current_state          
        end

        # Helper to store all of the state machine's data in one place
        #
        # @return [Hash] state machine's persistent data
        def control
          output[:control] ||= {}
        end

        # The state machine of this action's instance
        #
        # @return [StateMachine] state machine for this action's instance.
        def state_machine
          @state_machine ||= self.class.instantiate_state_machine_template
        end
      end
    end
  end
end
