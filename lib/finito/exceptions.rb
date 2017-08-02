module Finito
  # Class to group all exceptions specific to the project.
  class Exception < ::RuntimeError
    # Exception raised when there are no possible transitions from current state.
    class NoMoreTransitions < Finito::Exception
      def initialize(state)
        super("Cannot transition anywhere from #{state}")
      end
    end

    # Exception raised when there are more than one possible transitions from current state.
    class NoDeterministicTransition < Finito::Exception
      def initialize(state, destinations)
        message = "Cannot deterministically transition anywhere from #{state}." \
          "Possibilities are #{destinations.join(', ')}"
        super(message)
      end
    end

    # Exception raised when the state machine has no initial state.
    class NoInitialState < Finito::Exception
      def initialize
        super('There is no initial state')
      end
    end

    # Exception raised when the state machine has more than one possible inital states.
    class NoDeterministicInitialState < Finito::Exception
      def initialize(states)
        message = 'Cannot determine initial state.' \
          "Possibilities are #{states.join(', ')}"
        super message
      end
    end

    # Exception raised when trying to define a state transition from and/or to unknown state.
    class UnknownStateTransition < Finito::Exception
      def initialize(direction, state)
        super("Cannot transition #{direction} unknown state #{state}")
      end
    end
  end
end
