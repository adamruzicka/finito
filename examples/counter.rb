require 'finito'

class Counter
  # Make instance of this class serve as a state machine handler
  include ::Finito::Handler
  # Allow using the DSL
  extend  ::Finito::DSL

  # Define the states
  state 'initial', :initial => true # The initial state where the state machine will start
  state 'final',   :final => true   # The final state where the state machine will end
  state 'counting'                  # The "not-done-yet" state

  # Define the state transitions
  define_transition do |root|
    # From 'initial' transition to 'counting' and set @counter to 0 while doing so
    root.from('initial').goto('counting').do { @counter = 0 }
    # From 'counting' transition to 'final' if done
    #   otherwise increment @counter and transition to 'counting' again
    root.from('counting').if(:done?).goto('final')
                         .else.do { @counter += 1 }.stay
  end

  # Define a callback to be executed on each state transition
  around_transition do |pass, transition|
    prefix = pass == :before ? '[START]' : '[END]'
    puts "#{prefix} In transition #{transition.from} ~> #{transition.to}"
  end

  # Define another callback to be executed on each state transition
  around_transition do |pass, *_args|
    puts "Counter is #{@counter}" if pass == :before
  end

  # Set to which number we want to count
  def initialize(target = 5)
    @done = false
    @target = target
  end

  # Instantiate the state machine from the template on demand
  def state_machine
    @state_machine ||= self.class.instantiate_state_machine_template
  end

  # Set @done when the state machine runs out of possible transitions
  #   while in a final state
  def on_finish
    @done = true
  end

  # Check if the counter reached the target
  def done?
    @counter >= @target
  end

  # Do steps until we reach the final state
  def process
    step until @done
  end
end

Counter.new.process
