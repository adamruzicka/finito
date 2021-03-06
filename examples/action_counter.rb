#!/usr/bin/env ruby

require_relative 'example_helper'
require 'finito'

class ActionCounter < ::Dynflow::Action
  include ::Finito::Dynflow::Action::WithStateMachine
  extend  ::Finito::DSL
  include ::ExampleHelper::TransitionLogging

  all_states_transient!
  
  state 'start', :initial => true
  state 'counting'
  state 'final', :final   => true

  define_transition do |root|
    root.from('start').do { output[:counter] = 0 }.goto('counting')
    root.from('counting').if(:stopping_condition).goto('final')
                         .else.do { output[:counter] += 1 }.goto('counting')
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

  def stopping_condition(_event = nil)
    output[:counter] >= input[:target]
  end
end

if $0 == __FILE__
  ExampleHelper.world.action_logger.level = Logger::DEBUG
  ExampleHelper.something_should_fail!
  ExampleHelper.world.trigger(ActionCounter, :target => 5)
  ExampleHelper.run_web_console
end
