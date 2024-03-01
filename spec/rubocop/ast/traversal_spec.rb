# frozen_string_literal: true

RSpec.describe RuboCop::AST::Traversal do
  subject(:traverse) do
    instance.walk(node)
    instance
  end

  let(:ast) { parse_source(source).ast }
  let(:instance) { klass.new }
  let(:node) { ast }

  context 'when a class defines on_arg', :ruby30 do
    let(:klass) do
      Class.new do
        attr_reader :calls

        include RuboCop::AST::Traversal
        def on_arg(node)
          (@calls ||= []) << node.children.first
          super
        end
      end
    end

    let(:source) { <<~RUBY }
      class Foo
        def example
          42.times { |x| p x }
        end
      end
    RUBY

    it 'calls it for all arguments', :ruby30 do
      expect(traverse.calls).to eq %i[x]
    end
  end

  context 'when a class defines `on_block_pass`', :ruby31 do
    let(:klass) do
      Class.new do
        attr_reader :calls

        include RuboCop::AST::Traversal
        def on_block_pass(node)
          (@calls ||= []) << node.children.first&.type
          super
        end
      end
    end

    let(:source) { <<~RUBY }
      def foo(&) # Anonymous block forwarding.
        bar(&)
      end

      def baz(&block)
        qux(&block)
      end
    RUBY

    it 'calls it for all block-pass arguments' do
      expect(traverse.calls).to eq [nil, :lvar]
    end
  end

  File.read("#{__dir__}/fixtures/code_examples.rb")
      .split("#----\n")
      .each_with_index do |example, _i|
    context "with example #{example}", :ruby27 do
      let(:klass) do
        Struct.new(:hits) do
          include RuboCop::AST::Traversal
          def initialize
            super(0)
          end

          instance_methods.grep(/^on_/).each do |m|
            define_method(m) do |node|
              self.hits += 1
              super(node)
            end
          end
        end
      end

      let(:source) { "foo=bar=baz=nil; #{example}" }

      # FIXME: `broken_on: :prism` can be removed when Prism > 0.24.0 will be released.
      it 'traverses all nodes', broken_on: :prism do
        actual = node.each_node.count
        expect(traverse.hits).to eql(actual)
      end
    end
  end

  it 'knows all current node types' do
    expect(described_class::MISSING).to eq []
  end

  # Sanity checking the debugging checks
  context 'when given an unexpected AST' do
    include RuboCop::AST::Sexp
    let(:klass) { Class.new { include RuboCop::AST::Traversal } }

    context 'with too few children' do
      let(:node) { s(:int) }

      it 'raises debugging error' do
        expect { traverse }.to raise_error(described_class::DebugError)
      end
    end

    context 'with too many children' do
      let(:node) { s(:int, 1, 2) }

      it 'raises debugging error' do
        expect { traverse }.to raise_error(described_class::DebugError)
      end
    end
  end
end
