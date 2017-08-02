require 'test_helper'

module Finito
  class StateMachineTemplateTest < ::Minitest::Test
    describe StateMachineTemplate do

      let(:empty_template) { StateMachineTemplate.new }
      let(:template) do
        template = StateMachineTemplate.new
        template.state 'foo', :initial => true
        %w(bar baz).each { |name| template.state name }
        template.transition 'baz', 'bar'
        template.transition 'foo', 'bar'
        template
      end

      it 'initializes empty' do
        empty_template.states.must_be :empty?
        empty_template.state_transitions.must_be :empty?
        empty_template.around_transitions.must_be :empty?
      end

      it 'can have states' do
        empty_template.state('foo')
        empty_template.state('bar')
        empty_template.states.keys.must_equal %w(foo bar)
      end

      it 'can have transitions' do
        empty_template.state 'foo'
        empty_template.state 'bar'
        empty_template.transition 'foo', 'bar'
        arr = empty_template.state_transitions['foo']['bar']
        arr.count.must_equal 1
        arr.first.must_be_instance_of StateTransition
        arr.first.from.must_equal 'foo'
        arr.first.to.must_equal 'bar'
      end

      it 'can have all states transient' do
        empty_template.all_states_transient!
        empty_template.state('foo')
        assert empty_template.states['foo'].transient
      end

      it 'can instantiate state machine' do
        template.instantiate.must_be_instance_of StateMachine
      end

      it 'raises when adding transition with unknown states' do
        exception = ::Finito::Exception::UnknownStateTransition
        empty_template.state('known')
        proc { empty_template.transition('known', 'unknown') }.must_raise exception
        proc { empty_template.transition('unknown', 'another_unknown') }.must_raise exception
      end

      it 'returns possible transitions' do
        template.possible_transitions('bar').must_be :empty?
        transitions = template.possible_transitions('foo')
        transitions.count.must_equal 1
        transitions.first.from.must_equal 'foo'
        transitions.first.to.must_equal 'bar'
      end
    end
  end
end
