# frozen_string_literal: true

RSpec.describe RuboCop::AST::KeywordBeginNode do
  let(:parsed_source) { parse_source(source) }
  let(:kwbegin_node) { parsed_source.ast }

  describe '.new' do
    let(:source) do
      <<~RUBY
        begin
          foo
        end
      RUBY
    end

    it { expect(kwbegin_node).to be_a(described_class) }
  end

  describe '#body' do
    subject(:body) { kwbegin_node.body }

    let(:node) { parsed_source.node }

    context 'when the `kwbegin` node is empty' do
      let(:source) do
        <<~RUBY
          begin
          end
        RUBY
      end

      it { is_expected.to be_nil }
    end

    context 'when the `kwbegin` node only contains a single line' do
      let(:source) do
        <<~RUBY
          begin
            >> foo <<
          end
        RUBY
      end

      it { is_expected.to eq(node) }
    end

    context 'when the body has multiple lines' do
      let(:source) do
        <<~RUBY
          begin
            foo
            bar
          end
        RUBY
      end

      it 'returns the entire `kwbegin` node' do
        expect(body).to eq(kwbegin_node)
      end
    end

    context 'when there is a `rescue` node' do
      let(:source) do
        <<~RUBY
          begin
            >>foo<<
          rescue
            bar
          end
        RUBY
      end

      it { is_expected.to eq(node) }
    end

    context 'when there is an `ensure` node' do
      let(:source) do
        <<~RUBY
          begin
            >>foo<<
          ensure
            bar
          end
        RUBY
      end

      it { is_expected.to eq(node) }
    end

    context 'when there is a `rescue` and `ensure` node' do
      let(:source) do
        <<~RUBY
          begin
            >>foo<<
          rescue
            bar
          ensure
            baz
          end
        RUBY
      end

      it { is_expected.to eq(node) }
    end
  end

  describe '#ensure_node' do
    subject(:ensure_node) { kwbegin_node.ensure_node }

    context 'when the `kwbegin` node is empty' do
      let(:source) do
        <<~RUBY
          begin
          end
        RUBY
      end

      it { is_expected.to be_nil }
    end

    context 'when the `kwbegin` node only contains a single line' do
      let(:source) do
        <<~RUBY
          begin
            foo
          end
        RUBY
      end

      it { is_expected.to be_nil }
    end

    context 'when the body has multiple lines' do
      let(:source) do
        <<~RUBY
          begin
            foo
            bar
          end
        RUBY
      end

      it { is_expected.to be_nil }
    end

    context 'when there is a `rescue` node without `ensure`' do
      let(:source) do
        <<~RUBY
          begin
            foo
          rescue
            bar
          end
        RUBY
      end

      it { is_expected.to be_nil }
    end

    context 'when there is an `ensure` node' do
      let(:source) do
        <<~RUBY
          begin
            foo
          ensure
            bar
          end
        RUBY
      end

      it { is_expected.to be_a(RuboCop::AST::EnsureNode) }
    end

    context 'when there is a `rescue` and `ensure` node' do
      let(:source) do
        <<~RUBY
          begin
            foo
          rescue
            bar
          ensure
            baz
          end
        RUBY
      end

      it { is_expected.to be_a(RuboCop::AST::EnsureNode) }
    end
  end

  describe '#rescue_node' do
    subject(:rescue_node) { kwbegin_node.rescue_node }

    context 'when the `kwbegin` node is empty' do
      let(:source) do
        <<~RUBY
          begin
          end
        RUBY
      end

      it { is_expected.to be_nil }
    end

    context 'when the `kwbegin` node only contains a single line' do
      let(:source) do
        <<~RUBY
          begin
            foo
          end
        RUBY
      end

      it { is_expected.to be_nil }
    end

    context 'when the body has multiple lines' do
      let(:source) do
        <<~RUBY
          begin
            foo
            bar
          end
        RUBY
      end

      it { is_expected.to be_nil }
    end

    context 'when there is a `rescue` node without `ensure`' do
      let(:source) do
        <<~RUBY
          begin
            foo
          rescue
            bar
          end
        RUBY
      end

      it { is_expected.to be_a(RuboCop::AST::RescueNode) }
    end

    context 'when there is an `ensure` node without `rescue`' do
      let(:source) do
        <<~RUBY
          begin
            foo
          ensure
            bar
          end
        RUBY
      end

      it { is_expected.to be_nil }
    end

    context 'when there is a `rescue` and `ensure` node' do
      let(:source) do
        <<~RUBY
          begin
            foo
          rescue
            bar
          ensure
            baz
          end
        RUBY
      end

      it { is_expected.to be_a(RuboCop::AST::RescueNode) }
    end
  end
end
