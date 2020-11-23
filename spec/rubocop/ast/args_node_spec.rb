# frozen_string_literal: true

RSpec.describe RuboCop::AST::ArgsNode do
  let(:args_node) { parse_source(source).ast.arguments }

  describe '.new' do
    context 'with a method definition' do
      let(:source) { 'def foo(x) end' }

      it { expect(args_node).to be_a(described_class) }
    end

    context 'with a block' do
      let(:source) { 'foo { |x| bar }' }

      it { expect(args_node).to be_a(described_class) }
    end

    context 'with a lambda literal' do
      let(:source) { '-> (x) { bar }' }

      it { expect(args_node).to be_a(described_class) }
    end
  end

  describe '#empty_and_without_delimiters?' do
    subject { args_node.empty_and_without_delimiters? }

    context 'with empty arguments' do
      context 'with a method definition' do
        let(:source) { 'def x; end' }

        it { is_expected.to be(true) }
      end

      context 'with a block' do
        let(:source) { 'x { }' }

        it { is_expected.to be(true) }
      end

      context 'with a lambda literal' do
        let(:source) { '-> { }' }

        it { is_expected.to be(true) }
      end
    end

    context 'with delimiters' do
      context 'with a method definition' do
        let(:source) { 'def x(); end' }

        it { is_expected.to be(false) }
      end

      context 'with a block' do
        let(:source) { 'x { || }' }

        it { is_expected.to be(false) }
      end

      context 'with a lambda literal' do
        let(:source) { '-> () { }' }

        it { is_expected.to be(false) }
      end
    end

    context 'with arguments' do
      context 'with a method definition' do
        let(:source) { 'def x a; end' }

        it { is_expected.to be(false) }
      end

      context 'with a lambda literal' do
        let(:source) { '-> a { }' }

        it { is_expected.to be(false) }
      end
    end
  end

  describe '#argument_list' do
    include AST::Sexp

    subject { args_node.argument_list }

    let(:source) { 'foo { |a, b = 42, (c, *d), e:, f: 42, **g, &h; i| nil }' }
    let(:arguments) do
      [
        s(:arg, :a),
        s(:optarg, :b, s(:int, 42)),
        s(:arg, :c),
        s(:restarg, :d),
        s(:kwarg, :e),
        s(:kwoptarg, :f, s(:int, 42)),
        s(:kwrestarg, :g),
        s(:blockarg, :h),
        s(:shadowarg, :i)
      ]
    end

    it { is_expected.to eq(arguments) }

    context 'when using Ruby 2.7 or newer', :ruby27 do
      context 'with argument forwarding' do
        let(:source) { 'def foo(...); end' }
        let(:arguments) { [s(:forward_arg)] }

        it { is_expected.to eq(arguments) } if RuboCop::AST::Builder.emit_forward_arg
      end
    end
  end
end
