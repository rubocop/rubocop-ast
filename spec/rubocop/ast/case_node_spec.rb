# frozen_string_literal: true

RSpec.describe RuboCop::AST::CaseNode do
  let(:ast) { parse_source(source).ast }
  let(:case_node) { ast }

  describe '.new' do
    let(:source) do
      ['case',
       'when :foo then bar',
       'end'].join("\n")
    end

    it { expect(case_node.is_a?(described_class)).to be(true) }
  end

  describe '#keyword' do
    let(:source) do
      ['case',
       'when :foo then bar',
       'end'].join("\n")
    end

    it { expect(case_node.keyword).to eq('case') }
  end

  describe '#when_branches' do
    let(:source) do
      ['case',
       'when :foo then 1',
       'when :bar then 2',
       'when :baz then 3',
       'end'].join("\n")
    end

    it { expect(case_node.when_branches.size).to eq(3) }
    it { expect(case_node.when_branches).to all(be_when_type) }
  end

  describe '#each_when' do
    let(:source) do
      ['case',
       'when :foo then 1',
       'when :bar then 2',
       'when :baz then 3',
       'end'].join("\n")
    end

    context 'when not passed a block' do
      it { expect(case_node.each_when.is_a?(Enumerator)).to be(true) }
    end

    context 'when passed a block' do
      it 'yields all the conditions' do
        expect { |b| case_node.each_when(&b) }
          .to yield_successive_args(*case_node.when_branches)
      end
    end
  end

  describe '#else?' do
    context 'without an else statement' do
      let(:source) do
        ['case',
         'when :foo then :bar',
         'end'].join("\n")
      end

      it { expect(case_node.else?).to be_falsey }
    end

    context 'with an else statement' do
      let(:source) do
        ['case',
         'when :foo then :bar',
         'else :baz',
         'end'].join("\n")
      end

      it { expect(case_node.else?).to be_truthy }
    end
  end

  describe '#else_branch' do
    describe '#else?' do
      context 'without an else statement' do
        let(:source) do
          ['case',
           'when :foo then :bar',
           'end'].join("\n")
        end

        it { expect(case_node.else_branch.nil?).to be(true) }
      end

      context 'with an else statement' do
        let(:source) do
          ['case',
           'when :foo then :bar',
           'else :baz',
           'end'].join("\n")
        end

        it { expect(case_node.else_branch.sym_type?).to be(true) }
      end
    end
  end

  describe '#branches' do
    context 'when there is an else' do
      let(:source) { <<~RUBY }
        case
        when :foo then # do nothing
        when :bar then 42
        else 'hello'
        end
      RUBY

      it 'returns all the bodies' do
        expect(case_node.branches).to match [nil, be_int_type, be_str_type]
      end

      context 'with an empty else' do
        let(:source) { <<~RUBY }
          case
          when :foo then # do nothing
          when :bar then 42
          else # do nothing
          end
        RUBY

        it 'returns all the bodies' do
          expect(case_node.branches).to match [nil, be_int_type, nil]
        end
      end
    end

    context 'when there is no else keyword' do
      let(:source) { <<~RUBY }
        case
        when :foo then # do nothing
        when :bar then 42
        end
      RUBY

      it 'returns only then when bodies' do
        expect(case_node.branches).to match [nil, be_int_type]
      end
    end

    context 'when compared to an IfNode' do
      let(:source) { <<~RUBY }
        case
        when foo then 1
        when bar then 2
        else
        end

        if foo then 1
        elsif bar then 2
        else
        end
      RUBY

      let(:case_node) { ast.children.first }
      let(:if_node) { ast.children.last }

      it 'returns the same' do
        expect(case_node.branches).to eq if_node.branches
      end
    end
  end
end
