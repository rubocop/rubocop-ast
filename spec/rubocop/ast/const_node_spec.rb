# frozen_string_literal: true

RSpec.describe RuboCop::AST::ConstNode do
  let(:ast) { parse_source(source).ast }
  let(:const_node) { ast }
  let(:source) { '::Foo::Bar::BAZ' }

  describe '#namespace' do
    it { expect(const_node.namespace.source).to eq '::Foo::Bar' }
  end

  describe '#short_name' do
    it { expect(const_node.short_name).to eq :BAZ }
  end

  describe '#module_name?' do
    it { expect(const_node.module_name?).to eq false }

    context 'with a constant with a lowercase letter' do
      let(:source) { '::Foo::Bar' }

      it { expect(const_node.module_name?).to eq true }
    end
  end

  describe '#absolute?' do
    it { expect(const_node.absolute?).to eq true }

    context 'with a constant not starting with ::' do
      let(:source) { 'Foo::Bar::BAZ' }

      it { expect(const_node.absolute?).to eq false }
    end

    context 'with a non-namespaced constant' do
      let(:source) { 'Foo' }

      it { expect(const_node.absolute?).to eq false }
    end
  end

  describe '#relative?' do
    context 'with a non-namespaced constant' do
      let(:source) { 'Foo' }

      it { expect(const_node.relative?).to eq true }
    end
  end

  describe '#each_path' do
    let(:source) { 'var = ::Foo::Bar::BAZ' }
    let(:const_node) { ast.children.last }

    it 'yields all parts of the namespace' do
      expect(const_node.each_path.map(&:type)).to eq %i[cbase const const]
      expect(const_node.each_path.to_a.last(2).map(&:short_name)).to eq %i[Foo Bar]
    end
  end
end
