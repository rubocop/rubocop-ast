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

  describe '#void_context?' do
    let(:source) { 'begin; beginbody; ensure; ensurebody; end' }

    it { expect(ensure_node).to be_void_context }
  end
end
