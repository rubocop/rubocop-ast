# frozen_string_literal: true

RSpec.describe RuboCop::AST::AliasNode do
  subject(:alias_node) { parse_source(source).ast }

  describe '.new' do
    let(:source) do
      'alias foo bar'
    end

    it { is_expected.to be_a(described_class) }
  end

  describe '#new_identifier' do
    let(:source) do
      'alias foo bar'
    end

    it { expect(alias_node.new_identifier).to be_sym_type }
    it { expect(alias_node.new_identifier.children.first).to eq(:foo) }
  end

  describe '#old_identifier' do
    let(:source) do
      'alias foo bar'
    end

    it { expect(alias_node.old_identifier).to be_sym_type }
    it { expect(alias_node.old_identifier.children.first).to eq(:bar) }
  end
end
