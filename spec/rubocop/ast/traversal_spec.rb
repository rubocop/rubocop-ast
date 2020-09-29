# frozen_string_literal: true

RSpec.describe RuboCop::AST::Traversal do
  subject(:traverse) do
    instance.walk(node)
    instance
  end

  let(:ast) { parse_source(source).ast }
  let(:instance) { klass.new }
  let(:node) { ast }

  context 'when a class defines on_arg', :ruby30 do
    let(:klass) do
      Class.new do
        attr_reader :calls

        include RuboCop::AST::Traversal
        def on_arg(_node)
          (@calls ||= []) << :on_arg
          super
        end
      end
    end

    let(:source) { <<~RUBY }
      42.times.map { _1 + _3 }
    RUBY

    it 'calls it for all arguments', :ruby30 do
      expect(traverse.calls).to eq %i[on_arg on_arg on_arg]
    end
  end
end
