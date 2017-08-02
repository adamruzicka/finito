module Finito
  class StateMachineTest < Minitest::Test
    describe StateMachine do
      let(:template) do
        template = StateMachineTemplate.new
        template.state 'foo', :initial => true
        template.state 'baz'
        template.state 'bar', :final => true
        template.transition 'baz', 'bar'
        template.transition 'foo', 'bar'
        template
      end

      class TestHandler
        include ::Finito::Handler

        attr_reader :state_machine
        
        def initialize(machine)
          @state_machine = machine
        end
      end

      let(:machine) { StateMachine.new template }
      let(:handler) { TestHandler.new machine }

      it 'initializes in initial state' do
        handler.state_machine.current_state.name.must_equal 'foo'
      end

      it '#can_end?' do
        refute machine.can_end?
        handler.step
        assert machine.can_end?
      end
    end
  end
end
