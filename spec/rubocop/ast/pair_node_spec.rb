# frozen_string_literal: true

RSpec.describe RuboCop::AST::PairNode do
  let(:pair_node) { parse_source(source).ast.children.first }

  describe '.new' do
    let(:source) { '{ a: 1 }' }

    it { expect(pair_node).to be_a(described_class) }
  end

  describe '#hash_rocket?' do
    context 'when using a hash rocket delimiter' do
      let(:source) { '{ a => 1 }' }

      it { expect(pair_node).to be_hash_rocket }
    end

    context 'when using a colon delimiter' do
      let(:source) { '{ a: 1 }' }

      it { expect(pair_node).not_to be_hash_rocket }
    end
  end

  describe '#colon?' do
    context 'when using a hash rocket delimiter' do
      let(:source) { '{ a => 1 }' }

      it { expect(pair_node).not_to be_colon }
    end

    context 'when using a colon delimiter' do
      let(:source) { '{ a: 1 }' }

      it { expect(pair_node).to be_colon }
    end
  end

  describe '#delimiter' do
    context 'when using a hash rocket delimiter' do
      let(:source) { '{ a => 1 }' }

      it { expect(pair_node.delimiter).to eq('=>') }
      it { expect(pair_node.delimiter(true)).to eq(' => ') }
    end

    context 'when using a colon delimiter' do
      let(:source) { '{ a: 1 }' }

      it { expect(pair_node.delimiter).to eq(':') }
      it { expect(pair_node.delimiter(true)).to eq(': ') }
    end
  end

  describe '#inverse_delimiter' do
    context 'when using a hash rocket delimiter' do
      let(:source) { '{ a => 1 }' }

      it { expect(pair_node.inverse_delimiter).to eq(':') }
      it { expect(pair_node.inverse_delimiter(true)).to eq(': ') }
    end

    context 'when using a colon delimiter' do
      let(:source) { '{ a: 1 }' }

      it { expect(pair_node.inverse_delimiter).to eq('=>') }
      it { expect(pair_node.inverse_delimiter(true)).to eq(' => ') }
    end
  end

  describe '#key' do
    context 'when using a symbol key' do
      let(:source) { '{ a: 1 }' }

      it { expect(pair_node.key).to be_sym_type }
    end

    context 'when using a string key' do
      let(:source) { "{ 'a' => 1 }" }

      it { expect(pair_node.key).to be_str_type }
    end
  end

  describe '#value' do
    let(:source) { '{ a: 1 }' }

    it { expect(pair_node.value).to be_int_type }
  end

  describe '#value_on_new_line?' do
    let(:pair) { parse_source(source).ast.children[0] }

    context 'when value starts on a new line' do
      let(:source) do
        ['{',
         '  a:',
         '    1',
         '}'].join("\n")
      end

      it { expect(pair).to be_value_on_new_line }
    end

    context 'when value spans multiple lines' do
      let(:source) do
        ['{',
         '  a: (',
         '  )',
         '}'].join("\n")
      end

      it { expect(pair).not_to be_value_on_new_line }
    end

    context 'when pair is on a single line' do
      let(:source) { "{ 'a' => 1 }" }

      it { expect(pair).not_to be_value_on_new_line }
    end
  end

  describe '#same_line?' do
    let(:first_pair) { parse_source(source).ast.children[0] }
    let(:second_pair) { parse_source(source).ast.children[1] }

    context 'when both pairs are on the same line' do
      context 'when both pairs are explicit pairs' do
        let(:source) do
          ['{',
           '  a: 1, b: 2',
           '}'].join("\n")
        end

        it { expect(first_pair).to be_same_line(second_pair) }
      end

      context 'when both pair is a keyword splat' do
        let(:source) do
          ['{',
           '  a: 1, **foo',
           '}'].join("\n")
        end

        it { expect(first_pair).to be_same_line(second_pair) }
      end
    end

    context 'when a multiline pair shares the same line' do
      context 'when both pairs are explicit pairs' do
        let(:source) do
          ['{',
           '  a: (',
           '  ), b: 2',
           '}'].join("\n")
        end

        it { expect(first_pair).to be_same_line(second_pair) }
        it { expect(second_pair).to be_same_line(first_pair) }
      end

      context 'when last pair is a keyword splat' do
        let(:source) do
          ['{',
           '  a: (',
           '  ), **foo',
           '}'].join("\n")
        end

        it { expect(first_pair).to be_same_line(second_pair) }
        it { expect(second_pair).to be_same_line(first_pair) }
      end
    end

    context 'when pairs are on separate lines' do
      context 'when both pairs are explicit pairs' do
        let(:source) do
          ['{',
           '  a: 1,',
           '  b: 2',
           '}'].join("\n")
        end

        it { expect(first_pair).not_to be_same_line(second_pair) }
      end

      context 'when last pair is a keyword splat' do
        let(:source) do
          ['{',
           '  a: 1,',
           '  **foo',
           '}'].join("\n")
        end

        it { expect(first_pair).not_to be_same_line(second_pair) }
      end
    end
  end

  describe '#key_delta' do
    let(:first_pair) { parse_source(source).ast.children[0] }
    let(:second_pair) { parse_source(source).ast.children[1] }

    context 'with alignment set to :left' do
      context 'when using colon delimiters' do
        context 'when keys are aligned' do
          context 'when both pairs are explicit pairs' do
            let(:source) do
              ['{',
               '  a: 1,',
               '  b: 2',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair)).to eq(0) }
          end

          context 'when second pair is a keyword splat' do
            let(:source) do
              ['{',
               '  a: 1,',
               '  **foo',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair)).to eq(0) }
          end
        end

        context 'when receiver key is behind' do
          context 'when both pairs are reail pairs' do
            let(:source) do
              ['{',
               '  a: 1,',
               '    b: 2',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair)).to eq(-2) }
          end

          context 'when second pair is a keyword splat' do
            let(:source) do
              ['{',
               '  a: 1,',
               '    **foo',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair)).to eq(-2) }
          end
        end

        context 'when receiver key is ahead' do
          context 'when both pairs are explicit pairs' do
            let(:source) do
              ['{',
               '    a: 1,',
               '  b: 2',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair)).to eq(2) }
          end

          context 'when second pair is a keyword splat' do
            let(:source) do
              ['{',
               '    a: 1,',
               '  **foo',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair)).to eq(2) }
          end
        end

        context 'when both keys are on the same line' do
          context 'when both pairs are explicit pairs' do
            let(:source) do
              ['{',
               '  a: 1, b: 2',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair)).to eq(0) }
          end

          context 'when second pair is a keyword splat' do
            let(:source) do
              ['{',
               '  a: 1, **foo',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair)).to eq(0) }
          end
        end
      end

      context 'when using hash rocket delimiters' do
        context 'when keys are aligned' do
          context 'when both keys are explicit keys' do
            let(:source) do
              ['{',
               '  a => 1,',
               '  b => 2',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair)).to eq(0) }
          end

          context 'when second key is a keyword splat' do
            let(:source) do
              ['{',
               '  a => 1,',
               '  **foo',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair)).to eq(0) }
          end
        end

        context 'when receiver key is behind' do
          context 'when both pairs are explicit pairs' do
            let(:source) do
              ['{',
               '  a => 1,',
               '    b => 2',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair)).to eq(-2) }
          end

          context 'when second pair is a keyword splat' do
            let(:source) do
              ['{',
               '  a => 1,',
               '    **foo',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair)).to eq(-2) }
          end
        end

        context 'when receiver key is ahead' do
          context 'when both pairs are explicit pairs' do
            let(:source) do
              ['{',
               '    a => 1,',
               '  b => 2',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair)).to eq(2) }
          end

          context 'when second pair is a keyword splat' do
            let(:source) do
              ['{',
               '    a => 1,',
               '  **foo',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair)).to eq(2) }
          end
        end

        context 'when both keys are on the same line' do
          context 'when both pairs are explicit pairs' do
            let(:source) do
              ['{',
               '  a => 1, b => 2',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair)).to eq(0) }
          end

          context 'when second pair is a keyword splat' do
            let(:source) do
              ['{',
               '  a => 1, **foo',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair)).to eq(0) }
          end
        end
      end
    end

    context 'with alignment set to :right' do
      context 'when using colon delimiters' do
        context 'when keys are aligned' do
          context 'when both pairs are explicit pairs' do
            let(:source) do
              ['{',
               '  a: 1,',
               '  b: 2',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair, :right)).to eq(0) }
          end

          context 'when second pair is a keyword splat' do
            let(:source) do
              ['{',
               '  a: 1,',
               '  **foo',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair, :right)).to eq(0) }
          end
        end

        context 'when receiver key is behind' do
          context 'when both pairs are reail pairs' do
            let(:source) do
              ['{',
               '  a: 1,',
               '    b: 2',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair, :right)).to eq(-2) }
          end

          context 'when second pair is a keyword splat' do
            let(:source) do
              ['{',
               '  a: 1,',
               '    **foo',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair, :right)).to eq(0) }
          end
        end

        context 'when receiver key is ahead' do
          context 'when both pairs are explicit pairs' do
            let(:source) do
              ['{',
               '    a: 1,',
               '  b: 2',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair, :right)).to eq(2) }
          end

          context 'when second pair is a keyword splat' do
            let(:source) do
              ['{',
               '    a: 1,',
               '  **foo',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair, :right)).to eq(0) }
          end
        end

        context 'when both keys are on the same line' do
          context 'when both pairs are explicit pairs' do
            let(:source) do
              ['{',
               '  a: 1, b: 2',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair, :right)).to eq(0) }
          end

          context 'when second pair is a keyword splat' do
            let(:source) do
              ['{',
               '  a: 1, **foo',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair, :right)).to eq(0) }
          end
        end
      end

      context 'when using hash rocket delimiters' do
        context 'when keys are aligned' do
          context 'when both keys are explicit keys' do
            let(:source) do
              ['{',
               '  a => 1,',
               '  b => 2',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair, :right)).to eq(0) }
          end

          context 'when second key is a keyword splat' do
            let(:source) do
              ['{',
               '  a => 1,',
               '  **foo',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair, :right)).to eq(0) }
          end
        end

        context 'when receiver key is behind' do
          context 'when both pairs are explicit pairs' do
            let(:source) do
              ['{',
               '  a => 1,',
               '    b => 2',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair, :right)).to eq(-2) }
          end

          context 'when second pair is a keyword splat' do
            let(:source) do
              ['{',
               '  a => 1,',
               '    **foo',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair, :right)).to eq(0) }
          end
        end

        context 'when receiver key is ahead' do
          context 'when both pairs are explicit pairs' do
            let(:source) do
              ['{',
               '    a => 1,',
               '  b => 2',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair, :right)).to eq(2) }
          end

          context 'when second pair is a keyword splat' do
            let(:source) do
              ['{',
               '    a => 1,',
               '  **foo',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair, :right)).to eq(0) }
          end
        end

        context 'when both keys are on the same line' do
          context 'when both pairs are explicit pairs' do
            let(:source) do
              ['{',
               '  a => 1, b => 2',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair, :right)).to eq(0) }
          end

          context 'when second pair is a keyword splat' do
            let(:source) do
              ['{',
               '  a => 1, **foo',
               '}'].join("\n")
            end

            it { expect(first_pair.key_delta(second_pair, :right)).to eq(0) }
          end
        end
      end
    end
  end

  describe '#value_delta' do
    let(:first_pair) { parse_source(source).ast.children[0] }
    let(:second_pair) { parse_source(source).ast.children[1] }

    context 'when using colon delimiters' do
      context 'when values are aligned' do
        context 'when both pairs are explicit pairs' do
          let(:source) do
            ['{',
             '  a: 1,',
             '  b: 2',
             '}'].join("\n")
          end

          it { expect(first_pair.value_delta(second_pair)).to eq(0) }
        end

        context 'when second pair is a keyword splat' do
          let(:source) do
            ['{',
             '  a: 1,',
             '  **foo',
             '}'].join("\n")
          end

          it { expect(first_pair.value_delta(second_pair)).to eq(0) }
        end
      end

      context 'when receiver value is behind' do
        let(:source) do
          ['{',
           '  a: 1,',
           '  b:   2',
           '}'].join("\n")
        end

        it { expect(first_pair.value_delta(second_pair)).to eq(-2) }
      end

      context 'when receiver value is ahead' do
        let(:source) do
          ['{',
           '  a:   1,',
           '  b: 2',
           '}'].join("\n")
        end

        it { expect(first_pair.value_delta(second_pair)).to eq(2) }
      end

      context 'when both pairs are on the same line' do
        let(:source) do
          ['{',
           '  a: 1, b: 2',
           '}'].join("\n")
        end

        it { expect(first_pair.value_delta(second_pair)).to eq(0) }
      end
    end

    context 'when using hash rocket delimiters' do
      context 'when values are aligned' do
        context 'when both pairs are explicit pairs' do
          let(:source) do
            ['{',
             '  a => 1,',
             '  b => 2',
             '}'].join("\n")
          end

          it { expect(first_pair.value_delta(second_pair)).to eq(0) }
        end

        context 'when second pair is a keyword splat' do
          let(:source) do
            ['{',
             '  a => 1,',
             '  **foo',
             '}'].join("\n")
          end

          it { expect(first_pair.value_delta(second_pair)).to eq(0) }
        end
      end

      context 'when receiver value is behind' do
        let(:source) do
          ['{',
           '  a => 1,',
           '  b =>   2',
           '}'].join("\n")
        end

        it { expect(first_pair.value_delta(second_pair)).to eq(-2) }
      end

      context 'when receiver value is ahead' do
        let(:source) do
          ['{',
           '  a =>   1,',
           '  b => 2',
           '}'].join("\n")
        end

        it { expect(first_pair.value_delta(second_pair)).to eq(2) }
      end

      context 'when both pairs are on the same line' do
        let(:source) do
          ['{',
           '  a => 1, b => 2',
           '}'].join("\n")
        end

        it { expect(first_pair.value_delta(second_pair)).to eq(0) }
      end
    end
  end

  describe '#value_omission?' do
    context 'when using hash value omission', :ruby31 do
      let(:source) { '{ x: }' }

      it { expect(pair_node).to be_value_omission }
    end

    context 'when not using hash value omission' do
      let(:source) { '{ x: x }' }

      it { expect(pair_node).not_to be_value_omission }
    end
  end
end
