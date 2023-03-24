# frozen_string_literal: true

RSpec.describe RuboCop::AST::KeywordSplatNode do
  let(:kwsplat_node) { parse_source(source).ast.children.last }
  let(:source) { '{ a: 1, **foo }' }

  describe '.new' do
    it { expect(kwsplat_node).to be_a(described_class) }
  end

  describe '#hash_rocket?' do
    it { expect(kwsplat_node).not_to be_hash_rocket }
  end

  describe '#colon?' do
    it { expect(kwsplat_node).not_to be_colon }
  end

  describe '#key' do
    it { expect(kwsplat_node.key).to eq(kwsplat_node) }
  end

  describe '#value' do
    it { expect(kwsplat_node.value).to eq(kwsplat_node) }
  end

  describe '#operator' do
    it { expect(kwsplat_node.operator).to eq('**') }
  end

  describe '#kwsplat_type?' do
    it { expect(kwsplat_node).to be_kwsplat_type }
  end

  describe '#forwarded_kwrestarg_type?' do
    it { expect(kwsplat_node).not_to be_forwarded_kwrestarg_type }
  end

  context 'when forwarded keyword rest arguments', :ruby32 do
    let(:kwsplat_node) { parse_source(source).ast.children.last.children.last }
    let(:source) do
      <<~RUBY
        def foo(**)
          { a: 1, ** }
        end
      RUBY
    end

    describe '.new' do
      it { expect(kwsplat_node).to be_a(described_class) }
    end

    describe '#hash_rocket?' do
      it { expect(kwsplat_node).not_to be_hash_rocket }
    end

    describe '#colon?' do
      it { expect(kwsplat_node).not_to be_colon }
    end

    describe '#key' do
      it { expect(kwsplat_node.key).to eq(kwsplat_node) }
    end

    describe '#value' do
      it { expect(kwsplat_node.value).to eq(kwsplat_node) }
    end

    describe '#operator' do
      it { expect(kwsplat_node.operator).to eq('**') }
    end

    describe '#kwsplat_type?' do
      it { expect(kwsplat_node).to be_kwsplat_type }
    end

    describe '#forwarded_kwrestarg_type?' do
      it { expect(kwsplat_node).to be_forwarded_kwrestarg_type }
    end
  end

  describe '#same_line?' do
    let(:first_pair) { parse_source(source).ast.children[0] }
    let(:second_pair) { parse_source(source).ast.children[1] }

    context 'when both pairs are on the same line' do
      let(:source) do
        ['{',
         '  a: 1, **foo',
         '}'].join("\n")
      end

      it { expect(first_pair).to be_same_line(second_pair) }
    end

    context 'when a multiline pair shares the same line' do
      let(:source) do
        ['{',
         '  a: (',
         '  ), **foo',
         '}'].join("\n")
      end

      it { expect(first_pair).to be_same_line(second_pair) }
      it { expect(second_pair).to be_same_line(first_pair) }
    end

    context 'when pairs are on separate lines' do
      let(:source) do
        ['{',
         '  a: 1,',
         '  **foo',
         '}'].join("\n")
      end

      it { expect(first_pair).not_to be_same_line(second_pair) }
    end
  end

  describe '#key_delta' do
    let(:pair_node) { parse_source(source).ast.children[0] }
    let(:kwsplat_node) { parse_source(source).ast.children[1] }

    context 'with alignment set to :left' do
      context 'when using colon delimiters' do
        context 'when keyword splat is aligned' do
          let(:source) do
            ['{',
             '  a: 1,',
             '  **foo',
             '}'].join("\n")
          end

          it { expect(kwsplat_node.key_delta(pair_node)).to eq(0) }
        end

        context 'when keyword splat is ahead' do
          let(:source) do
            ['{',
             '  a: 1,',
             '    **foo',
             '}'].join("\n")
          end

          it { expect(kwsplat_node.key_delta(pair_node)).to eq(2) }
        end

        context 'when keyword splat is behind' do
          let(:source) do
            ['{',
             '    a: 1,',
             '  **foo',
             '}'].join("\n")
          end

          it { expect(kwsplat_node.key_delta(pair_node)).to eq(-2) }
        end

        context 'when keyword splat is on the same line' do
          let(:source) do
            ['{',
             '  a: 1, **foo',
             '}'].join("\n")
          end

          it { expect(kwsplat_node.key_delta(pair_node)).to eq(0) }
        end
      end

      context 'when using hash rocket delimiters' do
        context 'when keyword splat is aligned' do
          let(:source) do
            ['{',
             '  a => 1,',
             '  **foo',
             '}'].join("\n")
          end

          it { expect(kwsplat_node.key_delta(pair_node)).to eq(0) }
        end

        context 'when keyword splat is ahead' do
          let(:source) do
            ['{',
             '  a => 1,',
             '    **foo',
             '}'].join("\n")
          end

          it { expect(kwsplat_node.key_delta(pair_node)).to eq(2) }
        end

        context 'when keyword splat is behind' do
          let(:source) do
            ['{',
             '    a => 1,',
             '  **foo',
             '}'].join("\n")
          end

          it { expect(kwsplat_node.key_delta(pair_node)).to eq(-2) }
        end

        context 'when keyword splat is on the same line' do
          let(:source) do
            ['{',
             '  a => 1, **foo',
             '}'].join("\n")
          end

          it { expect(kwsplat_node.key_delta(pair_node)).to eq(0) }
        end
      end
    end

    context 'with alignment set to :right' do
      context 'when using colon delimiters' do
        context 'when keyword splat is aligned' do
          let(:source) do
            ['{',
             '  a: 1,',
             '  **foo',
             '}'].join("\n")
          end

          it { expect(kwsplat_node.key_delta(pair_node, :right)).to eq(0) }
        end

        context 'when keyword splat is ahead' do
          let(:source) do
            ['{',
             '  a: 1,',
             '    **foo',
             '}'].join("\n")
          end

          it { expect(kwsplat_node.key_delta(pair_node, :right)).to eq(0) }
        end

        context 'when keyword splat is behind' do
          let(:source) do
            ['{',
             '    a: 1,',
             '  **foo',
             '}'].join("\n")
          end

          it { expect(kwsplat_node.key_delta(pair_node, :right)).to eq(0) }
        end

        context 'when keyword splat is on the same line' do
          let(:source) do
            ['{',
             '  a: 1, **foo',
             '}'].join("\n")
          end

          it { expect(kwsplat_node.key_delta(pair_node, :right)).to eq(0) }
        end
      end

      context 'when using hash rocket delimiters' do
        context 'when keyword splat is aligned' do
          let(:source) do
            ['{',
             '  a => 1,',
             '  **foo',
             '}'].join("\n")
          end

          it { expect(kwsplat_node.key_delta(pair_node, :right)).to eq(0) }
        end

        context 'when keyword splat is ahead' do
          let(:source) do
            ['{',
             '  a => 1,',
             '    **foo',
             '}'].join("\n")
          end

          it { expect(kwsplat_node.key_delta(pair_node, :right)).to eq(0) }
        end

        context 'when keyword splat is behind' do
          let(:source) do
            ['{',
             '    a => 1,',
             '  **foo',
             '}'].join("\n")
          end

          it { expect(kwsplat_node.key_delta(pair_node, :right)).to eq(0) }
        end

        context 'when keyword splat is on the same line' do
          let(:source) do
            ['{',
             '  a => 1, **foo',
             '}'].join("\n")
          end

          it { expect(kwsplat_node.key_delta(pair_node, :right)).to eq(0) }
        end
      end
    end
  end

  describe '#value_delta' do
    let(:pair_node) { parse_source(source).ast.children[0] }
    let(:kwsplat_node) { parse_source(source).ast.children[1] }

    context 'when using colon delimiters' do
      context 'when keyword splat is left aligned' do
        let(:source) do
          ['{',
           '  a: 1,',
           '  **foo',
           '}'].join("\n")
        end

        it { expect(kwsplat_node.value_delta(pair_node)).to eq(0) }
      end

      context 'when keyword splat is ahead' do
        let(:source) do
          ['{',
           '  a: 1,',
           '       **foo',
           '}'].join("\n")
        end

        it { expect(kwsplat_node.value_delta(pair_node)).to eq(0) }
      end

      context 'when keyword splat is behind' do
        let(:source) do
          ['{',
           '  a:  1,',
           '    **foo',
           '}'].join("\n")
        end

        it { expect(kwsplat_node.value_delta(pair_node)).to eq(0) }
      end

      context 'when keyword splat is on the same line' do
        let(:source) do
          ['{',
           '  a: 1, **foo',
           '}'].join("\n")
        end

        it { expect(kwsplat_node.value_delta(pair_node)).to eq(0) }
      end
    end

    context 'when using hash rocket delimiters' do
      context 'when keyword splat is left aligned' do
        let(:source) do
          ['{',
           '  a => 1,',
           '  **foo',
           '}'].join("\n")
        end

        it { expect(kwsplat_node.value_delta(pair_node)).to eq(0) }
      end

      context 'when keyword splat is ahead' do
        let(:source) do
          ['{',
           '  a => 1,',
           '           **foo',
           '}'].join("\n")
        end

        it { expect(kwsplat_node.value_delta(pair_node)).to eq(0) }
      end

      context 'when keyword splat is behind' do
        let(:source) do
          ['{',
           '  a => 1,',
           '    **foo',
           '}'].join("\n")
        end

        it { expect(kwsplat_node.value_delta(pair_node)).to eq(0) }
      end

      context 'when keyword splat is on the same line' do
        let(:source) do
          ['{',
           '  a => 1, **foo',
           '}'].join("\n")
        end

        it { expect(kwsplat_node.value_delta(pair_node)).to eq(0) }
      end
    end
  end
end
