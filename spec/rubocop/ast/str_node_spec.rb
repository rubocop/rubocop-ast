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

  describe '#first_line' do
    context 'with a normal string' do
      let(:source) { "'foo'" }

      it { expect(str_node.first_line).to eq(1) }
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

      it { expect(str_node.first_line).to eq(1) }
    end
  end

  describe '#last_line' do
    context 'with a normal string' do
      let(:source) do
        ['"foo"\\',
         '"bar"'].join("\n")
      end

      it { expect(str_node.last_line).to eq(2) }
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

      it { expect(str_node.last_line).to eq(4) }
    end
  end

  describe '#line_count' do
    context 'with a normal string' do
      let(:source) do
        ['"foo"\\',
         '"bar"'].join("\n")
      end

      it { expect(str_node.line_count).to eq(2) }
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

      it { expect(str_node.line_count).to eq(4) }
    end
  end
end
