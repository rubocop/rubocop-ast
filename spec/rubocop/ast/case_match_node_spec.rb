# frozen_string_literal: true

RSpec.describe RuboCop::AST::CaseMatchNode do
  subject(:case_match_node) { parse_source(source).ast }

  context 'when using Ruby 2.7 or newer', :ruby27 do
    describe '.new' do
      let(:source) do
        <<~RUBY
          case expr
          in pattern
          end
        RUBY
      end

      it { is_expected.to be_a(described_class) }
    end

    describe '#keyword' do
      let(:source) do
        <<~RUBY
          case expr
          in pattern
          end
        RUBY
      end

      it { expect(case_match_node.keyword).to eq('case') }
    end

    describe '#in_pattern_branches' do
      let(:source) do
        <<~RUBY
          case expr
          in pattern
          in pattern
          in pattern
          end
        RUBY
      end

      it { expect(case_match_node.in_pattern_branches.size).to eq(3) }

      it {
        expect(case_match_node.in_pattern_branches).to all(be_in_pattern_type)
      }
    end

    describe '#each_in_pattern' do
      let(:source) do
        <<~RUBY
          case expr
          in pattern
          in pattern
          in pattern
          end
        RUBY
      end

      context 'when not passed a block' do
        it {
          expect(case_match_node.each_in_pattern).to be_a(Enumerator)
        }
      end

      context 'when passed a block' do
        it 'yields all the conditions' do
          expect { |b| case_match_node.each_in_pattern(&b) }
            .to yield_successive_args(*case_match_node.in_pattern_branches)
        end
      end
    end

    describe '#else?' do
      context 'without an else statement' do
        let(:source) do
          <<~RUBY
            case expr
            in pattern
            end
          RUBY
        end

        it { is_expected.not_to be_else }
      end

      context 'with an else statement' do
        let(:source) do
          <<~RUBY
            case expr
            in pattern
            else
            end
          RUBY
        end

        it { is_expected.to be_else }
      end
    end

    describe '#else_branch' do
      describe '#else?' do
        context 'without an else statement' do
          let(:source) do
            <<~RUBY
              case expr
              in pattern
              end
            RUBY
          end

          it { expect(case_match_node.else_branch).to be_nil }
        end

        context 'with an else statement' do
          let(:source) do
            <<~RUBY
              case expr
              in pattern
              else
                :foo
              end
            RUBY
          end

          it { expect(case_match_node.else_branch).to be_sym_type }
        end
      end
    end

    describe '#branches' do
      context 'when there is an else' do
        context 'with else body' do
          let(:source) { <<~RUBY }
            case pattern
            in :foo then # do nothing
            in :bar then 42
            else 'hello'
            end
          RUBY

          it 'returns all the bodies' do
            expect(case_match_node.branches).to match [nil, be_int_type, be_str_type]
          end
        end

        context 'with empty else' do
          let(:source) { <<~RUBY }
            case pattern
            in :foo then # do nothing
            in :bar then 42
            else # do nothing
            end
          RUBY

          it 'returns all the bodies' do
            expect(case_match_node.branches).to match [nil, be_int_type, nil]
          end
        end
      end

      context 'when there is no else keyword' do
        let(:source) { <<~RUBY }
          case pattern
          in :foo then # do nothing
          in :bar then 42
          end
        RUBY

        it 'returns only then when bodies' do
          expect(case_match_node.branches).to match [nil, be_int_type]
        end
      end
    end
  end
end
