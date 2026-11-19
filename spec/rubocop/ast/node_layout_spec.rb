# frozen_string_literal: true

RSpec.describe RuboCop::AST::NodeLayout do
  subject(:layout) { described_class.of(type) }

  let(:node) { RuboCop::AST::Node.new(:int, [1]) }

  context 'with a type whose nodes have a fixed number of children' do
    let(:type) { :def }

    it { expect(layout.arity).to eq(3..3) }
    it { expect(layout.kinds(0)).to eq [Symbol] }
    it { expect(layout.kinds(1)).to eq [:node] }
    it { expect(layout.kinds(2)).to eq [:node, NilClass] }
    it { expect(layout.kinds(3)).to eq [] }
    it { expect(layout).to be_fit([:foo, node, nil]) }
    it { expect(layout).not_to be_fit([:foo, node]) }
    it { expect(layout).not_to be_fit([node, node, nil]) }
  end

  context 'with a type whose nodes have a child that may be missing' do
    let(:type) { :lvasgn }

    it { expect(layout.arity).to eq(1..2) }
    it { expect(layout).to be_fit([:foo]) }
    it { expect(layout).to be_fit([:foo, node]) }
    it { expect(layout).not_to be_fit([:foo, nil]) }
  end

  context 'with a type whose nodes have any number of children' do
    let(:type) { :case }

    it { expect(layout.arity).to eq(3..Float::INFINITY) }
    it { expect(layout.kinds(0)).to eq [:node, NilClass] }
    it { expect(layout.kinds(1)).to eq [:node] }
    it { expect(layout.kinds(2)).to eq [:node, NilClass] }
    it { expect(layout).to be_fit([nil, node, node, nil]) }
    it { expect(layout).not_to be_fit([nil, nil]) }
    it { expect(layout).not_to be_fit([nil, node, nil, node]) }
  end

  context 'with a type that has no layout' do
    let(:type) { :procarg0 }

    it { is_expected.to be_nil }
  end

  it 'has a layout for known node types only' do
    unknown = described_class::DESCRIPTIONS.keys.reject do |type|
      RuboCop::AST::Node.method_defined?(:"#{type.to_s.delete('?')}_type?")
    end

    expect(unknown).to be_empty
  end

  describe 'the layouts', :ruby27 do
    let(:sources) do
      examples = File.read("#{__dir__}/fixtures/code_examples.rb").split("#----\n")
      files = Dir["#{__dir__}/../../../lib/**/*.rb"].reject { |file| file.include?('/vendor/') }
      examples + files.map { |file| File.read(file) }
    end

    def unfitting(source)
      ast = RuboCop::AST::ProcessedSource.new(source, ruby_version, parser_engine: parser_engine).ast
      return [] unless ast

      ast.each_node.reject do |node|
        layout = described_class.of(node.type)
        layout.nil? || layout.fit?(node.children)
      end
    end

    it 'fit the nodes that the parser builds' do
      expect(sources.flat_map { |source| unfitting(source) }).to be_empty
    end
  end
end
