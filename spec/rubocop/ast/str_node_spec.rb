# frozen_string_literal: true

RSpec.describe RuboCop::AST::StrNode do
  let(:str_node) { parse_source(source).ast }

  describe '.new' do
    context 'with a normal string' do
      let(:source) { "'foo'" }

      it { expect(str_node).to be_a(described_class) }
    end

    context 'with a string with interpolation' do
      let(:source) { '"#{foo}"' }

      it { expect(str_node).to be_a(described_class) }
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

      it { expect(str_node).to be_a(described_class) }
    end
  end

  describe '#heredoc?' do
    context 'with a normal string' do
      let(:source) { "'foo'" }

      it { expect(str_node).not_to be_heredoc }
    end

    context 'with a string with interpolation' do
      let(:source) { '"#{foo}"' }

      it { expect(str_node).not_to be_heredoc }
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

      it { expect(str_node).to be_heredoc }
    end
  end
end
