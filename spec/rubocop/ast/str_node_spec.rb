# frozen_string_literal: true

RSpec.describe RuboCop::AST::StrNode do
  subject(:str_node) { parsed_source.ast }

  let(:parsed_source) { parse_source(source) }

  describe '.new' do
    context 'with a normal string' do
      let(:source) { "'foo'" }

      it { is_expected.to be_a(described_class) }
    end

    context 'with a string with interpolation' do
      let(:source) { '"#{foo}"' }

      it { is_expected.to be_a(described_class) }
    end

    context 'with a heredoc' do
      let(:source) do
        <<~RUBY
          <<-CODE
            foo
            bar
          CODE
        RUBY
      end

      it { is_expected.to be_a(described_class) }
    end
  end

  describe '#single_quoted?' do
    context 'with a single-quoted string' do
      let(:source) { "'foo'" }

      it { is_expected.to be_single_quoted }
    end

    context 'with a double-quoted string' do
      let(:source) { '"foo"' }

      it { is_expected.not_to be_single_quoted }
    end

    context 'with a %() delimited string' do
      let(:source) { '%(foo)' }

      it { is_expected.not_to be_single_quoted }
    end

    context 'with a %q() delimited string' do
      let(:source) { '%q(foo)' }

      it { is_expected.not_to be_single_quoted }
    end

    context 'with a %Q() delimited string' do
      let(:source) { '%Q(foo)' }

      it { is_expected.not_to be_single_quoted }
    end

    context 'with a character literal' do
      let(:source) { '?x' }

      it { is_expected.not_to be_single_quoted }
    end

    context 'with an undelimited string within another node' do
      subject(:str_node) { parsed_source.ast.child_nodes.first }

      let(:source) { '/string/' }

      it { is_expected.not_to be_single_quoted }
    end
  end

  describe '#double_quoted?' do
    context 'with a single-quoted string' do
      let(:source) { "'foo'" }

      it { is_expected.not_to be_double_quoted }
    end

    context 'with a double-quoted string' do
      let(:source) { '"foo"' }

      it { is_expected.to be_double_quoted }
    end

    context 'with a %() delimited string' do
      let(:source) { '%(foo)' }

      it { is_expected.not_to be_double_quoted }
    end

    context 'with a %q() delimited string' do
      let(:source) { '%q(foo)' }

      it { is_expected.not_to be_double_quoted }
    end

    context 'with a %Q() delimited string' do
      let(:source) { '%Q(foo)' }

      it { is_expected.not_to be_double_quoted }
    end

    context 'with a character literal' do
      let(:source) { '?x' }

      it { is_expected.not_to be_double_quoted }
    end

    context 'with an undelimited string within another node' do
      subject(:str_node) { parsed_source.ast.child_nodes.first }

      let(:source) { '/string/' }

      it { is_expected.not_to be_single_quoted }
    end
  end

  describe '#character_literal?' do
    context 'with a character literal' do
      let(:source) { '?\n' }

      it { is_expected.to be_character_literal }
    end

    context 'with a normal string literal' do
      let(:source) { '"\n"' }

      it { is_expected.not_to be_character_literal }
    end

    context 'with a heredoc' do
      let(:source) do
        <<~RUBY
          <<-CODE
            foo
            bar
          CODE
        RUBY
      end

      it { is_expected.not_to be_character_literal }
    end
  end

  describe '#heredoc?' do
    context 'with a normal string' do
      let(:source) { "'foo'" }

      it { is_expected.not_to be_heredoc }
    end

    context 'with a string with interpolation' do
      let(:source) { '"#{foo}"' }

      it { is_expected.not_to be_heredoc }
    end

    context 'with a heredoc' do
      let(:source) do
        <<~RUBY
          <<-CODE
            foo
            bar
          CODE
        RUBY
      end

      it { is_expected.to be_heredoc }
    end
  end

  describe '#percent_literal?' do
    context 'with a single-quoted string' do
      let(:source) { "'foo'" }

      it { is_expected.not_to be_percent_literal }
      it { is_expected.not_to be_percent_literal(:%) }
      it { is_expected.not_to be_percent_literal(:q) }
      it { is_expected.not_to be_percent_literal(:Q) }
    end

    context 'with a double-quoted string' do
      let(:source) { '"foo"' }

      it { is_expected.not_to be_percent_literal }
      it { is_expected.not_to be_percent_literal(:%) }
      it { is_expected.not_to be_percent_literal(:q) }
      it { is_expected.not_to be_percent_literal(:Q) }
    end

    context 'with a %() delimited string' do
      let(:source) { '%(foo)' }

      it { is_expected.to be_percent_literal }
      it { is_expected.to be_percent_literal(:%) }
      it { is_expected.not_to be_percent_literal(:q) }
      it { is_expected.not_to be_percent_literal(:Q) }
    end

    context 'with a %q() delimited string' do
      let(:source) { '%q(foo)' }

      it { is_expected.to be_percent_literal }
      it { is_expected.not_to be_percent_literal(:%) }
      it { is_expected.to be_percent_literal(:q) }
      it { is_expected.not_to be_percent_literal(:Q) }
    end

    context 'with a %Q() delimited string' do
      let(:source) { '%Q(foo)' }

      it { is_expected.to be_percent_literal }
      it { is_expected.not_to be_percent_literal(:%) }
      it { is_expected.not_to be_percent_literal(:q) }
      it { is_expected.to be_percent_literal(:Q) }
    end

    context 'with a character literal?' do
      let(:source) { '?x' }

      it { is_expected.not_to be_percent_literal }
      it { is_expected.not_to be_percent_literal(:%) }
      it { is_expected.not_to be_percent_literal(:q) }
      it { is_expected.not_to be_percent_literal(:Q) }
    end

    context 'with an undelimited string within another node' do
      subject(:str_node) { parsed_source.ast.child_nodes.first }

      let(:source) { '/string/' }

      it { is_expected.not_to be_percent_literal }
      it { is_expected.not_to be_percent_literal(:%) }
      it { is_expected.not_to be_percent_literal(:q) }
      it { is_expected.not_to be_percent_literal(:Q) }
    end

    context 'when given an invalid type' do
      subject { str_node.percent_literal?(:x) }

      let(:source) { '%q(foo)' }

      it 'raises a KeyError' do
        expect { str_node.percent_literal?(:x) }.to raise_error(KeyError, 'key not found: :x')
      end
    end
  end
end
