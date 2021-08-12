# frozen_string_literal: true

RSpec.describe RuboCop::AST::MlhsNode do
  let(:mlhs_node) { parse_source(source).ast.node_parts[0] }

  describe '.new' do
    context 'with a `masgn` node' do
      let(:source) { 'x, y = z' }

      it { expect(mlhs_node).to be_a(described_class) }
    end
  end

  describe '#assignments' do
    include AST::Sexp

    subject { mlhs_node.assignments }

    context 'with variables' do
      let(:source) { 'x, y = z' }

      it { is_expected.to eq([s(:lvasgn, :x), s(:lvasgn, :y)]) }
    end

    context 'with a splat' do
      let(:source) { 'x, *y = z' }

      it { is_expected.to eq([s(:lvasgn, :x), s(:lvasgn, :y)]) }
    end

    context 'with nested `mlhs` nodes' do
      let(:source) { 'a, (b, c) = z' }

      it { is_expected.to eq([s(:lvasgn, :a), s(:lvasgn, :b), s(:lvasgn, :c)]) }
    end

    context 'with different variable types' do
      let(:source) { 'a, @b, @@c, $d, E, *f = z' }
      let(:expected_nodes) do
        [
          s(:lvasgn, :a),
          s(:ivasgn, :@b),
          s(:cvasgn, :@@c),
          s(:gvasgn, :$d),
          s(:casgn, nil, :E),
          s(:lvasgn, :f)
        ]
      end

      it { is_expected.to eq(expected_nodes) }
    end

    context 'with assignment on RHS' do
      let(:source) { 'x, y = 1, z += 2' }

      it { is_expected.to eq([s(:lvasgn, :x), s(:lvasgn, :y)]) }
    end

    context 'with nested assignment on LHS' do
      let(:source) { 'a, b[c+=1] = z' }

      if RuboCop::AST::Builder.emit_index
        let(:expected_nodes) do
          [
            s(:lvasgn, :a),
            s(:indexasgn,
              s(:send, nil, :b),
              s(:op_asgn,
                s(:lvasgn, :c), :+, s(:int, 1)))
          ]
        end
      else
        let(:expected_nodes) do
          [
            s(:lvasgn, :a),
            s(:send,
              s(:send, nil, :b), :[]=,
              s(:op_asgn,
                s(:lvasgn, :c), :+, s(:int, 1)))
          ]
        end
      end

      it { is_expected.to eq(expected_nodes) }
    end
  end
end
