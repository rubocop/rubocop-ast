# frozen_string_literal: true

RSpec.describe RuboCop::AST::SelfClassNode do
  subject(:self_class_node) { parse_source(source).ast }

  describe '.new' do
    let(:source) do
      'class << self; end'
    end

    it { is_expected.to be_a(described_class) }
  end

  describe '#identifier' do
    let(:source) do
      'class << self; end'
    end

    it { expect(self_class_node.identifier).to be_self_type }
  end

  describe '#body' do
    context 'with a single expression body' do
      let(:source) do
        'class << self; bar; end'
      end

      it { expect(self_class_node.body).to be_send_type }
    end

    context 'with a multi-expression body' do
      let(:source) do
        'class << self; bar; baz; end'
      end

      it { expect(self_class_node.body).to be_begin_type }
    end

    context 'with an empty body' do
      let(:source) do
        'class << self; end'
      end

      it { expect(self_class_node.body).to be_nil }
    end
  end
end
