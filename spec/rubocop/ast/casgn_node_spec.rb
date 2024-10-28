# frozen_string_literal: true

RSpec.describe RuboCop::AST::CasgnNode do
  let(:casgn_node) { parse_source(source).ast }

  describe '.new' do
    context 'with a `casgn` node' do
      let(:source) { 'VAR = value' }

      it { expect(casgn_node).to be_a(described_class) }
    end
  end

  describe '#namespace' do
    include AST::Sexp

    subject { casgn_node.namespace }

    context 'when there is no parent' do
      let(:source) { 'VAR = value' }

      it { is_expected.to be_nil }
    end

    context 'when the parent is a `cbase`' do
      let(:source) { '::VAR = value' }

      it { is_expected.to eq(s(:cbase)) }
    end

    context 'when the parent is a `const`' do
      let(:source) { 'FOO::VAR = value' }

      it { is_expected.to eq(s(:const, nil, :FOO)) }
    end
  end

  describe '#name' do
    subject { casgn_node.name }

    let(:source) { 'VAR = value' }

    it { is_expected.to eq(:VAR) }
  end

  describe '#short_name' do
    subject { casgn_node.short_name }

    let(:source) { 'VAR = value' }

    it { is_expected.to eq(:VAR) }
  end

  describe '#expression' do
    include AST::Sexp

    subject { casgn_node.expression }

    let(:source) { 'VAR = value' }

    it { is_expected.to eq(s(:send, nil, :value)) }
  end

  describe '#module_name?' do
    context 'with a constant with only uppercase letters' do
      let(:source) { 'VAR = value' }

      it { expect(casgn_node).not_to be_module_name }
    end

    context 'with a constant with a lowercase letter' do
      let(:source) { '::Foo::Bar = value' }

      it { expect(casgn_node).to be_module_name }
    end
  end

  describe '#absolute?' do
    context 'with a constant starting with ::' do
      let(:source) { '::VAR' }

      it { expect(casgn_node).to be_absolute }
    end

    context 'with a constant not starting with ::' do
      let(:source) { 'Foo::Bar::BAZ' }

      it { expect(casgn_node).not_to be_absolute }
    end

    context 'with a non-namespaced constant' do
      let(:source) { 'Foo' }

      it { expect(casgn_node).not_to be_absolute }
    end
  end

  describe '#relative?' do
    context 'with a constant starting with ::' do
      let(:source) { '::VAR' }

      it { expect(casgn_node).not_to be_relative }
    end

    context 'with a constant not starting with ::' do
      let(:source) { 'Foo::Bar::BAZ' }

      it { expect(casgn_node).to be_relative }
    end

    context 'with a non-namespaced constant' do
      let(:source) { 'Foo' }

      it { expect(casgn_node).to be_relative }
    end
  end

  describe '#each_path' do
    let(:source) { '::Foo::Bar::BAZ = value' }

    it 'yields all parts of the namespace' do
      expect(casgn_node.each_path.map(&:type)).to eq %i[cbase const const]
      expect(casgn_node.each_path.to_a.last(2).map(&:short_name)).to eq %i[Foo Bar]
    end
  end
end
