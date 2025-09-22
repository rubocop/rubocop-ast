# frozen_string_literal: true

RSpec.describe RuboCop::AST::RescueNode do
  subject(:ast) { parsed_source.ast }

  let(:parsed_source) { parse_source(source) }
  let(:node) { parsed_source.node }
  let(:rescue_node) { ast.children.first }

  describe '.new' do
    let(:source) { <<~RUBY }
      begin
      rescue => e
      end
    RUBY

    it { expect(rescue_node).to be_a(described_class) }
  end

  describe '#body' do
    subject(:body) { rescue_node.body }

    context 'when the body is empty' do
      let(:source) { <<~RUBY }
        begin
        rescue => e
        end
      RUBY

      it { is_expected.to be_nil }
    end

    context 'when the body is a single line' do
      let(:source) { <<~RUBY }
        begin
          >>foo<<
        rescue => e
        end
      RUBY

      it { is_expected.to eq(node) }
    end

    context 'with multiple lines in body' do
      let(:source) { <<~RUBY }
        begin
          >>foo<<
          bar
        rescue => e
          baz
        end
      RUBY

      it 'returns a begin node' do
        expect(body).to be_begin_type
        expect(body.children).to include(node)
      end
    end
  end

  describe '#resbody_branches' do
    let(:source) { <<~RUBY }
      begin
      rescue FooError then foo
      rescue BarError, BazError then bar_and_baz
      end
    RUBY

    it { expect(rescue_node.resbody_branches.size).to eq(2) }
    it { expect(rescue_node.resbody_branches).to all(be_resbody_type) }
  end

  describe '#branches' do
    context 'when there is an else' do
      let(:source) { <<~RUBY }
        begin
        rescue FooError then foo
        rescue BarError then # do nothing
        else 'bar'
        end
      RUBY

      it 'returns all the bodies' do
        expect(rescue_node.branches).to match [be_send_type, nil, be_str_type]
      end

      context 'with an empty else' do
        let(:source) { <<~RUBY }
          begin
          rescue FooError then foo
          rescue BarError then # do nothing
          else # do nothing
          end
        RUBY

        it 'returns all the bodies' do
          expect(rescue_node.branches).to match [be_send_type, nil, nil]
        end
      end
    end

    context 'when there is no else keyword' do
      let(:source) { <<~RUBY }
        begin
        rescue FooError then foo
        rescue BarError then # do nothing
        end
      RUBY

      it 'returns only then rescue bodies' do
        expect(rescue_node.branches).to match [be_send_type, nil]
      end
    end
  end

  describe '#else_branch' do
    context 'without an else statement' do
      let(:source) { <<~RUBY }
        begin
        rescue FooError then foo
        end
      RUBY

      it { expect(rescue_node.else_branch).to be_nil }
    end

    context 'with an else statement' do
      let(:source) { <<~RUBY }
        begin
        rescue FooError then foo
        else bar
        end
      RUBY

      it { expect(rescue_node.else_branch).to be_send_type }
    end
  end

  describe '#else?' do
    context 'without an else statement' do
      let(:source) { <<~RUBY }
        begin
        rescue FooError then foo
        end
      RUBY

      it { expect(rescue_node).not_to be_else }
    end

    context 'with an else statement' do
      let(:source) { <<~RUBY }
        begin
        rescue FooError then foo
        else bar
        end
      RUBY

      it { expect(rescue_node).to be_else }
    end
  end
end
