# frozen_string_literal: true

RSpec.describe RuboCop::AST::EnsureNode do
  let(:ensure_node) { parse_source(source).ast.children.first }

  describe '.new' do
    let(:source) { 'begin; beginbody; ensure; ensurebody; end' }

    it { expect(ensure_node).to be_a(described_class) }
  end

  describe '#body' do
    let(:source) { 'begin; beginbody; ensure; :ensurebody; end' }

    it { expect(ensure_node.body).to be_sym_type }
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
