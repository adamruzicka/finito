#!/usr/bin/env ruby

require_relative 'example_helper'
require 'finito'

require_relative 'sub_plans'

class BulkSubPlansExample < SubPlansExample
  include ::Dynflow::Action::WithBulkSubPlans

  define_transition do |builder|
    builder.from 'waiting' do |waiting|
      waiting.if { |event| event.is_a?(PlanNextBatch) && !can_spawn_next_batch? }.stay.else
      waiting.if { |event| event.is_a?(PlanNextBatch) && can_spawn_next_batch? }.goto('spawned')
    end
  end

  def total_count
    input[:count]
  end

  def batch(from, count)
    total_count.times.to_a.drop(from).take(count)
  end

  def create_sub_plans
    current_batch.map { trigger(SubPlan) }
  end
end

if $0 == __FILE__
  ExampleHelper.world.action_logger.level = Logger::DEBUG
  ExampleHelper.something_should_fail!
  ExampleHelper.world.trigger(BulkSubPlansExample, :count => 25)
  ExampleHelper.run_web_console
end
