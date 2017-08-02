module Finito
  class StateTransitionTest < Minitest::Test

    describe StateTransition do
      it 'considers :condition and :if equivalent in options' do
        transition  = StateTransition.new('from', 'to', { :condition => :a_symbol })
        transition2 = StateTransition.new('from', 'to', { :if => :a_symbol })
        transition.condition.must_equal :a_symbol
        transition2.condition.must_equal :a_symbol
      end

      it 'can transition when condition is nil' do
        transition = StateTransition.new('from', 'to')
        assert transition.can_transition?
      end

      it 'yields the condition for evaluation' do
        transition = StateTransition.new('from', 'to', :condition => proc { true })
        assert transition.can_transition?
      end

      it 'can negate the condition' do
        transition = StateTransition.new('from', 'to', :condition => proc { true }, :negate => true)
        refute transition.can_transition?
      end
    end

    describe StateTransitionBuilder do
      let(:builder) { StateTransitionBuilder.new }
      let(:transitions) { builder.build }

      it 'can create simple transitions' do
        builder.from('start').goto('end')
        transitions.count.must_equal 1
        transition = transitions.first
        transition.from.must_equal 'start'
        transition.to.must_equal 'end'
        transition.condition.must_be_nil
        transition.callback.must_be_nil
      end

      it 'can take callbacks' do
        result = 15
        builder.from('start').do { result }.goto('end')
        transition = transitions.first
        transition.from.must_equal('start')
        transition.to.must_equal('end')
        transition.condition.must_be_nil
        transition.callback.call().must_equal result
      end

      it 'can take conditions' do
        builder.from('start').if { true }.goto('end')
        transition = transitions.first
        transition.from.must_equal('start')
        transition.to.must_equal('end')
        transition.callback.must_be_nil
        assert transition.condition.call()
      end

      it 'can negate conditions' do
        builder.from('start').unless { false }.goto('end')
        transition = transitions.first
        transition.from.must_equal('start')
        transition.to.must_equal('end')
        transition.callback.must_be_nil
        assert transition.can_transition?
      end

      it 'can branch' do
        builder.from('start') do |start|
          start.if { false }.goto('false-end')
          .else.goto('true-end')
        end
        transitions.count.must_equal 2
        refute transitions.first.can_transition?
        transitions.first.to.must_equal 'false-end'
        assert transitions.last.can_transition?
        transitions.last.to.must_equal 'true-end'
      end

      it 'can stay' do
        builder.from('start').stay
        transitions.first.to.must_equal 'start'
      end

      it 'can take callback' do
        result = 15
        builder.from('start').do { result }.goto('end')
        transitions.first.callback.call().must_equal result
      end

      it 'doesn\'t allow to redefine destination' do
        proc { builder.from('start').goto('end').goto('another_end') }.must_raise RuntimeError
      end

      it 'ignores non-complete transitions when building' do
        builder.from('foo')
        builder.from('bar')
        builder.from('baz').if(:something)
        builder.goto('end').do { 'Never evaluated' }
        builder.from('start').goto('end')
        transitions.count.must_equal 1
        transitions.first.from.must_equal 'start'
        transitions.first.to.must_equal 'end'
      end
    end
    
  end
end
