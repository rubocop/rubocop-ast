# frozen_string_literal: true

# Note: specs for `lambda?` and `lambda_literal?` in `send_node_spec`
RSpec.describe RuboCop::AST::LambdaNode do
  subject(:lambda_node) { parse_source(source).ast }

  let(:source) { '->(a, b) { a + b }' }

  describe '#receiver' do
    it { expect(lambda_node.receiver).to eq nil }
  end

  describe '#method_name' do
    it { expect(lambda_node.method_name).to eq :lambda }
  end

  describe '#arguments' do
    it { expect(lambda_node.arguments.size).to eq 2 }
  end
end
