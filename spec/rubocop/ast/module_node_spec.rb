# frozen_string_literal: true

RSpec.describe RuboCop::AST::ModuleNode do
  subject(:module_node) { parse_source(source).ast }

  describe '.new' do
    let(:source) do
      'module Foo; end'
    end

    it { is_expected.to be_a(described_class) }
  end

  describe '#identifier' do
    let(:source) do
      'module Foo; end'
    end

    it { expect(module_node.identifier).to be_const_type }
  end

  describe '#body' do
    context 'with a single expression body' do
      let(:source) do
        'module Foo; bar; end'
      end

      it { expect(module_node.body).to be_send_type }
    end

    context 'with a multi-expression body' do
      let(:source) do
        'module Foo; bar; baz; end'
      end

      it { expect(module_node.body).to be_begin_type }
    end

    context 'with an empty body' do
      let(:source) do
        'module Foo; end'
      end

      it { expect(module_node.body).to be_nil }
    end
  end
end
