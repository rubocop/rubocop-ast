# frozen_string_literal: true

RSpec.describe RuboCop::AST::ForwardArgsNode do
  let(:args_node) { parse_source(source).ast.arguments }
  let(:source) { 'def foo(...); end' }

  context 'when using Ruby 2.7 or newer', :ruby27 do
    if RuboCop::AST::Builder.emit_forward_arg
      describe '#to_a' do
        it { expect(args_node.to_a).to contain_exactly(be_forward_arg_type) }
      end
    else
      describe '.new' do
        it { expect(args_node.is_a?(described_class)).to be(true) }
      end

      describe '#to_a' do
        it { expect(args_node.to_a).to contain_exactly(args_node) }
      end
    end
  end
end
