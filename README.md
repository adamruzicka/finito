# Finito
A gem for modelling processes as finite state machines.

## How it works
The base for a state machine are states. States can be initial and final, a state machine needs exactly one
initial state and at least on final state. Another important thing are state transitions.
State transitions define how a state machine can change its state, from where to where it can go, under which conditions and what to do when that transition happens.

In this gem the states are not a property of a state machine but of a state machine template, which can be instantiated into a state machine, allowing many state machines to share the same template.

Another important module is the Handler. This module should be included into a class inside whose context the transition conditions and callbacks will be evaluated.

This gem also provides a DSL for defining states and transitions.

Please see the scripts in examples directory. `examples/counter.rb` provides an example on how to use state machines in a standalone fashion. `examples/action_counter.rb` and `examples/action_counter_evented.rb` explores its usage in Dynflow. Both of those do exactly the same thing as `examples/counter.rb`, but they are Dynflow actions, one runs the whole thing within one invocation of `run`, whereas the other one suspends the action after every transition.

`examples/sub_plans.rb` and `examples/bulk_sub_plans_example.rb` show how Dynflow's `Action::WithSubPlans` and `Action::WithBulkSubPlans` could be reimplemented using state machines. These two examples also demonstrate more advanced usage of the state transition builder.

## Usage
To be filled later

## Development
To be filled later

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/adamruzicka/finito.
