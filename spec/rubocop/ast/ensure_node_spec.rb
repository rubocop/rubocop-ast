# frozen_string_literal: true

RSpec.describe RuboCop::AST::EnsureNode do
  let(:parsed_source) { parse_source(source) }
  let(:ensure_node) { parsed_source.ast.children.first }
  let(:node) { parsed_source.node }

  describe '.new' do
    let(:source) { 'begin; beginbody; ensure; ensurebody; end' }

    it { expect(ensure_node).to be_a(described_class) }
  end

  describe '#branch' do
    let(:source) { 'begin; beginbody; ensure; >>ensurebody<<; end' }

    it { expect(ensure_node.branch).to eq(node) }
  end

  describe '#rescue_node' do
    subject(:rescue_node) { ensure_node.rescue_node }

    context 'when there is no `rescue` node' do
      let(:source) do
        <<~RUBY
          begin
            beginbody
          ensure
            ensurebody
          end
        RUBY
      end

      it { is_expected.to be_nil }
    end

    context 'when there is a `rescue` node' do
      let(:source) do
        <<~RUBY
          begin
            beginbody
          rescue
            rescuebody
          ensure
            ensurebody
          end
        RUBY
      end

      it { is_expected.to be_a(RuboCop::AST::RescueNode) }
    end
  end

  describe '#void_context?' do
    let(:source) { 'begin; beginbody; ensure; ensurebody; end' }

    it { expect(ensure_node).to be_void_context }
  end
end
