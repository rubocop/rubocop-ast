# frozen_string_literal: true

RSpec.describe RuboCop::AST::StrNode do
  subject(:str_node) { parse_source(source).ast }

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
end
