#!/usr/bin/env ruby

require_relative 'example_helper'
require 'dynflow'
require 'finito'

class SubPlan < ::Dynflow::Action
  def run
  end
end

class SubPlansExample < ::Dynflow::Action
  include ::Dynflow::Action::Cancellable
  include ::Dynflow::Action::WithSubPlans
  include ::Finito::Dynflow::Action::WithStateMachine
  extend  ::Finito::DSL
  include ::ExampleHelper::TransitionLogging

  state 'initial', :initial => true
  state 'waiting'
  state 'done',    :final => true
  state 'error',   :final => true

  # Transient states
  state 'sub_plan_finished', :transient => true
  state 'spawned', :transient => true

  define_transition do |transition|
    transition.from('initial').do { initiate }.goto('spawned')

    transition.from('spawned') do |spawned|
      spawned.if(:done?).goto('done')
             .else.goto('waiting')
    end
    
    transition.from('sub_plan_finished') do |finished|
      finished.unless(:done?).goto('waiting')
      finished.if { done? && success? }.goto('done')
              .elsif { done? && !success? }
              .do { fail 'A sub task failed' }.goto('error')
    end
    
    transition.from 'waiting' do |waiting|
      waiting.if { |event| event.is_a?(SubPlanFinished) }
             .do { |event| mark_as_done(event.execution_plan_id, event.success) }
             .goto('sub_plan_finished')
      waiting.if { |event| event.is_a?(Cancel) }
             .do(:cancel!)
             .goto('error')
    end
  end

  def done?(*args)
    super(*[])
  end

  def cancel!
    @world.throttle_limiter.cancel!(execution_plan_id)
    sub_plans('state' => 'running').each(&:cancel)
  end

  def success?
    output[:failed_count] == 0
  end

  def create_sub_plans
    input[:count].times.map { trigger(SubPlan) }
  end

  def notify_on_finish(plans)
    plans.each do |plan|
      plan.finished.on_completion! do |success, value|
        suspended_action << SubPlanFinished[plan.id, success && (value.result == :success)]
      end
    end
  end
end

if $0 == __FILE__
  ExampleHelper.world.action_logger.level = Logger::DEBUG
  ExampleHelper.something_should_fail!
  ExampleHelper.world.trigger(SubPlansExample, :count => 5)
  ExampleHelper.run_web_console
end
