# frozen_string_literal: true

# FIXME: `broken_on: :prism` can be removed when Prism > 0.24.0 will be released.
RSpec.describe RuboCop::AST::IfNode, broken_on: :prism do
  subject(:if_node) { parse_source(source).ast }

  describe '.new' do
    context 'with a regular if statement' do
      let(:source) { 'if foo?; :bar; end' }

      it { is_expected.to be_a(described_class) }
    end

    context 'with a ternary operator' do
      let(:source) { 'foo? ? :bar : :baz' }

      it { is_expected.to be_a(described_class) }
    end

    context 'with a modifier statement' do
      let(:source) { ':foo if bar?' }

      it { is_expected.to be_a(described_class) }
    end
  end

  describe '#keyword' do
    context 'with an if statement' do
      let(:source) { 'if foo?; :bar; end' }

      it { expect(if_node.keyword).to eq('if') }
    end

    context 'with an unless statement' do
      let(:source) { 'unless foo?; :bar; end' }

      it { expect(if_node.keyword).to eq('unless') }
    end

    context 'with a ternary operator' do
      let(:source) { 'foo? ? :bar : :baz' }

      it { expect(if_node.keyword).to eq('') }
    end
  end

  describe '#inverse_keyword?' do
    context 'with an if statement' do
      let(:source) { 'if foo?; :bar; end' }

      it { expect(if_node.inverse_keyword).to eq('unless') }
    end

    context 'with an unless statement' do
      let(:source) { 'unless foo?; :bar; end' }

      it { expect(if_node.inverse_keyword).to eq('if') }
    end

    context 'with a ternary operator' do
      let(:source) { 'foo? ? :bar : :baz' }

      it { expect(if_node.inverse_keyword).to eq('') }
    end
  end

  describe '#if?' do
    context 'with an if statement' do
      let(:source) { 'if foo?; :bar; end' }

      it { is_expected.to be_if }
    end

    context 'with an unless statement' do
      let(:source) { 'unless foo?; :bar; end' }

      it { is_expected.not_to be_if }
    end

    context 'with a ternary operator' do
      let(:source) { 'foo? ? :bar : :baz' }

      it { is_expected.not_to be_if }
    end
  end

  describe '#unless?' do
    context 'with an if statement' do
      let(:source) { 'if foo?; :bar; end' }

      it { is_expected.not_to be_unless }
    end

    context 'with an unless statement' do
      let(:source) { 'unless foo?; :bar; end' }

      it { is_expected.to be_unless }
    end

    context 'with a ternary operator' do
      let(:source) { 'foo? ? :bar : :baz' }

      it { is_expected.not_to be_unless }
    end
  end

  describe '#ternary?' do
    context 'with an if statement' do
      let(:source) { 'if foo?; :bar; end' }

      it { is_expected.not_to be_ternary }
    end

    context 'with an unless statement' do
      let(:source) { 'unless foo?; :bar; end' }

      it { is_expected.not_to be_ternary }
    end

    context 'with a ternary operator' do
      let(:source) { 'foo? ? :bar : :baz' }

      it { is_expected.to be_ternary }
    end
  end

  describe '#elsif?' do
    context 'with an elsif statement' do
      let(:source) do
        ['if foo?',
         '  1',
         'elsif bar?',
         '  2',
         'end'].join("\n")
      end

      let(:elsif_node) { if_node.else_branch }

      it { expect(elsif_node).to be_elsif }
    end

    context 'with an if statement containing an elsif' do
      let(:source) do
        ['if foo?',
         '  1',
         'elsif bar?',
         '  2',
         'end'].join("\n")
      end

      it { is_expected.not_to be_elsif }
    end

    context 'without an elsif statement' do
      let(:source) do
        ['if foo?',
         '  1',
         'end'].join("\n")
      end

      it { is_expected.not_to be_elsif }
    end
  end

  describe '#else?' do
    context 'with an elsif statement' do
      let(:source) do
        ['if foo?',
         '  1',
         'elsif bar?',
         '  2',
         'end'].join("\n")
      end

      # NOTE: This is a legacy behavior.
      it { is_expected.to be_else }
    end

    context 'without an else statement' do
      let(:source) do
        ['if foo?',
         '  1',
         'else',
         '  2',
         'end'].join("\n")
      end

      it { is_expected.not_to be_elsif }
    end
  end

  describe '#modifier_form?' do
    context 'with a non-modifier if statement' do
      let(:source) { 'if foo?; :bar; end' }

      it { is_expected.not_to be_modifier_form }
    end

    context 'with a non-modifier unless statement' do
      let(:source) { 'unless foo?; :bar; end' }

      it { is_expected.not_to be_modifier_form }
    end

    context 'with a ternary operator' do
      let(:source) { 'foo? ? :bar : :baz' }

      it { is_expected.not_to be_modifier_form }
    end

    context 'with a modifier if statement' do
      let(:source) { ':bar if foo?' }

      it { is_expected.to be_modifier_form }
    end

    context 'with a modifier unless statement' do
      let(:source) { ':bar unless foo?' }

      it { is_expected.to be_modifier_form }
    end
  end

  describe '#nested_conditional?' do
    context 'with no nested conditionals' do
      let(:source) do
        ['if foo?',
         '  1',
         'elsif bar?',
         '  2',
         'else',
         '  3',
         'end'].join("\n")
      end

      it { is_expected.not_to be_nested_conditional }
    end

    context 'with nested conditionals in if clause' do
      let(:source) do
        ['if foo?',
         '  if baz; 4; end',
         'elsif bar?',
         '  2',
         'else',
         '  3',
         'end'].join("\n")
      end

      it { is_expected.to be_nested_conditional }
    end

    context 'with nested conditionals in elsif clause' do
      let(:source) do
        ['if foo?',
         '  1',
         'elsif bar?',
         '  if baz; 4; end',
         'else',
         '  3',
         'end'].join("\n")
      end

      it { is_expected.to be_nested_conditional }
    end

    context 'with nested conditionals in else clause' do
      let(:source) do
        ['if foo?',
         '  1',
         'elsif bar?',
         '  2',
         'else',
         '  if baz; 4; end',
         'end'].join("\n")
      end

      it { is_expected.to be_nested_conditional }
    end

    context 'with nested ternary operators' do
      context 'when nested in the truthy branch' do
        let(:source) { 'foo? ? bar? ? 1 : 2 : 3' }

        it { is_expected.to be_nested_conditional }
      end

      context 'when nested in the falsey branch' do
        let(:source) { 'foo? ? 3 : bar? ? 1 : 2' }

        it { is_expected.to be_nested_conditional }
      end
    end
  end

  describe '#elsif_conditional?' do
    context 'with one elsif conditional' do
      let(:source) do
        ['if foo?',
         '  1',
         'elsif bar?',
         '  2',
         'else',
         '  3',
         'end'].join("\n")
      end

      it { is_expected.to be_elsif_conditional }
    end

    context 'with multiple elsif conditionals' do
      let(:source) do
        ['if foo?',
         '  1',
         'elsif bar?',
         '  2',
         'elsif baz?',
         '  3',
         'else',
         '  4',
         'end'].join("\n")
      end

      it { is_expected.to be_elsif_conditional }
    end

    context 'with nested conditionals in if clause' do
      let(:source) do
        ['if foo?',
         '  if baz; 1; end',
         'else',
         '  2',
         'end'].join("\n")
      end

      it { is_expected.not_to be_elsif_conditional }
    end

    context 'with nested conditionals in else clause' do
      let(:source) do
        ['if foo?',
         '  1',
         'else',
         '  if baz; 2; end',
         'end'].join("\n")
      end

      it { is_expected.not_to be_elsif_conditional }
    end

    context 'with nested ternary operators' do
      context 'when nested in the truthy branch' do
        let(:source) { 'foo? ? bar? ? 1 : 2 : 3' }

        it { is_expected.not_to be_elsif_conditional }
      end

      context 'when nested in the falsey branch' do
        let(:source) { 'foo? ? 3 : bar? ? 1 : 2' }

        it { is_expected.not_to be_elsif_conditional }
      end
    end
  end

  describe '#if_branch' do
    context 'with an if statement' do
      let(:source) do
        ['if foo?',
         '  :foo',
         'else',
         '  42',
         'end'].join("\n")
      end

      it { expect(if_node.if_branch).to be_sym_type }
    end

    context 'with an unless statement' do
      let(:source) do
        ['unless foo?',
         '  :foo',
         'else',
         '  42',
         'end'].join("\n")
      end

      it { expect(if_node.if_branch).to be_sym_type }
    end

    context 'with a ternary operator' do
      let(:source) { 'foo? ? :foo : 42' }

      it { expect(if_node.if_branch).to be_sym_type }
    end
  end

  describe '#else_branch' do
    context 'with an if statement' do
      let(:source) do
        ['if foo?',
         '  :foo',
         'else',
         '  42',
         'end'].join("\n")
      end

      it { expect(if_node.else_branch).to be_int_type }
    end

    context 'with an unless statement' do
      let(:source) do
        ['unless foo?',
         '  :foo',
         'else',
         '  42',
         'end'].join("\n")
      end

      it { expect(if_node.else_branch).to be_int_type }
    end

    context 'with a ternary operator' do
      let(:source) { 'foo? ? :foo : 42' }

      it { expect(if_node.else_branch).to be_int_type }
    end
  end

  describe '#branches' do
    context 'with an if statement' do
      let(:source) { 'if foo?; :bar; end' }

      it { expect(if_node.branches.size).to eq(1) }
      it { expect(if_node.branches).to all(be_literal) }
    end

    context 'with a ternary operator' do
      let(:source) { 'foo? ? :foo : 42' }

      it { expect(if_node.branches.size).to eq(2) }
      it { expect(if_node.branches).to all(be_literal) }
    end

    context 'with an unless statement' do
      let(:source) { 'unless foo?; :bar; end' }

      it { expect(if_node.branches.size).to eq(1) }
      it { expect(if_node.branches).to all(be_literal) }
    end

    context 'with an else statement' do
      let(:source) do
        ['if foo?',
         '  1',
         'else',
         '  2',
         'end'].join("\n")
      end

      it { expect(if_node.branches.size).to eq(2) }
      it { expect(if_node.branches).to all(be_literal) }
    end

    context 'with an elsif statement' do
      let(:source) do
        ['if foo?',
         '  1',
         'elsif bar?',
         '  2',
         'else',
         '  3',
         'end'].join("\n")
      end

      it { expect(if_node.branches.size).to eq(3) }
      it { expect(if_node.branches).to all(be_literal) }
    end
  end

  describe '#each_branch' do
    let(:source) do
      ['if foo?',
       '  1',
       'elsif bar?',
       '  2',
       'else',
       '  3',
       'end'].join("\n")
    end

    context 'when not passed a block' do
      it { expect(if_node.each_branch).to be_a(Enumerator) }
    end

    context 'when passed a block' do
      it 'yields all the branches' do
        expect { |b| if_node.each_branch(&b) }
          .to yield_successive_args(*if_node.branches)
      end
    end
  end
end
