# frozen_string_literal: true

RSpec.describe RuboCop::AST::EnsureNode do
  let(:parsed_source) { parse_source(source) }
  let(:ensure_node) { parsed_source.ast.children.first }
  let(:node) { parsed_source.node }

  describe '.new' do
    let(:source) { 'begin; beginbody; ensure; ensurebody; end' }

    it { expect(ensure_node).to be_a(described_class) }
  end

  describe '#body' do
    subject(:body) { ensure_node.body }

    context 'when there is no body' do
      let(:source) { 'begin; ensure; ensurebody; end' }

      it { is_expected.to be_nil }
    end

    context 'when the body is a single line' do
      let(:source) { 'begin; >>beginbody<<; ensure; ensurebody; end' }

      it { is_expected.to eq(node) }
    end

    context 'when the body is multiple lines' do
      let(:source) { 'begin; >>foo<<; bar; ensure; ensurebody; end' }

      it 'returns a begin node' do
        expect(body).to be_begin_type
        expect(body.children).to include(node)
      end
    end

    context 'with `rescue`' do
      context 'when there is no body' do
        let(:source) { 'begin; rescue; rescuebody; ensure; ensurebody; end' }

        it { is_expected.to be_nil }
      end

      context 'when the body is a single line' do
        let(:source) { 'begin; >>beginbody<<; rescue; rescuebody; ensure; ensurebody; end' }

        it { is_expected.to eq(node) }
      end

      context 'when the body is multiple lines' do
        let(:source) { 'begin; >>foo<<; bar; rescue; rescuebody; ensure; ensurebody; end' }

        it 'returns a begin node' do
          expect(body).to be_begin_type
          expect(body.children).to include(node)
        end
      end
    end
  end

  describe '#branch' do
    let(:source) { 'begin; beginbody; ensure; >>ensurebody<<; end' }

    it { expect(ensure_node.branch).to eq(node) }
  end

  describe '#rescue_node' do
    subject(:rescue_node) { ensure_node.rescue_node }

    context 'when there is no `rescue` node' do
      let(:source) do
        <<~RUBY
          begin
            beginbody
          ensure
            ensurebody
          end
        RUBY
      end

      it { is_expected.to be_nil }
    end

    context 'when there is a `rescue` node' do
      let(:source) do
        <<~RUBY
          begin
            beginbody
          rescue
            rescuebody
          ensure
            ensurebody
          end
        RUBY
      end

      it { is_expected.to be_a(RuboCop::AST::RescueNode) }
    end
  end

  describe '#void_context?' do
    let(:source) { 'begin; beginbody; ensure; ensurebody; end' }

    it { expect(ensure_node).to be_void_context }
  end
end
