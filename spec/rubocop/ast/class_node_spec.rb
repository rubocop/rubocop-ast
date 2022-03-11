# frozen_string_literal: true

RSpec.describe RuboCop::AST::ClassNode do
  subject(:class_node) { parse_source(source).ast }

  describe '.new' do
    let(:source) do
      'class Foo; end'
    end

    it { is_expected.to be_a(described_class) }
  end

  describe '#identifier' do
    let(:source) do
      'class Foo; end'
    end

    it { expect(class_node.identifier).to be_const_type }
  end

  describe '#parent_class' do
    context 'when a parent class is specified' do
      let(:source) do
        'class Foo < Bar; end'
      end

      it { expect(class_node.parent_class).to be_const_type }
    end

    context 'when no parent class is specified' do
      let(:source) do
        'class Foo; end'
      end

      it { expect(class_node.parent_class).to be_nil }
    end
  end

  describe '#body' do
    context 'with a single expression body' do
      let(:source) do
        'class Foo; bar; end'
      end

      it { expect(class_node.body).to be_send_type }
    end

    context 'with a multi-expression body' do
      let(:source) do
        'class Foo; bar; baz; end'
      end

      it { expect(class_node.body).to be_begin_type }
    end

    context 'with an empty body' do
      let(:source) do
        'class Foo; end'
      end

      it { expect(class_node.body).to be_nil }
    end
  end
end
