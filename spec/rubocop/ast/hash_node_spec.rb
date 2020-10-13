# frozen_string_literal: true

RSpec.describe RuboCop::AST::HashNode do
  subject(:hash_node) { parse_source(source).ast }

  describe '.new' do
    let(:source) { '{}' }

    it { expect(hash_node).to be_a(described_class) }
  end

  describe '#pairs' do
    context 'with an empty hash' do
      let(:source) { '{}' }

      it { expect(hash_node.pairs).to be_empty }
    end

    context 'with a hash of literals' do
      let(:source) { '{ a: 1, b: 2, c: 3 }' }

      it { expect(hash_node.pairs.size).to eq(3) }
      it { expect(hash_node.pairs).to all(be_pair_type) }
    end

    context 'with a hash of variables' do
      let(:source) { '{ a: foo, b: bar }' }

      it { expect(hash_node.pairs.size).to eq(2) }
      it { expect(hash_node.pairs).to all(be_pair_type) }
    end
  end

  describe '#empty?' do
    context 'with an empty hash' do
      let(:source) { '{}' }

      it { expect(hash_node).to be_empty }
    end

    context 'with a hash containing pairs' do
      let(:source) { '{ a: 1, b: 2 }' }

      it { expect(hash_node).not_to be_empty }
    end

    context 'with a hash containing a keyword splat' do
      let(:source) { '{ **foo }' }

      it { expect(hash_node).not_to be_empty }
    end
  end

  describe '#keys' do
    context 'with an empty hash' do
      let(:source) { '{}' }

      it { expect(hash_node.keys).to be_empty }
    end

    context 'with a hash with symbol keys' do
      let(:source) { '{ a: 1, b: 2, c: 3 }' }

      it { expect(hash_node.keys.size).to eq(3) }
      it { expect(hash_node.keys).to all(be_sym_type) }
    end

    context 'with a hash with string keys' do
      let(:source) { "{ 'a' => foo,'b' => bar }" }

      it { expect(hash_node.keys.size).to eq(2) }
      it { expect(hash_node.keys).to all(be_str_type) }
    end
  end

  describe '#each_key' do
    let(:source) { '{ a: 1, b: 2, c: 3 }' }

    context 'when not passed a block' do
      it { expect(hash_node.each_key).to be_a(Enumerator) }
    end

    context 'when passed a block' do
      let(:expected) do
        [
          hash_node.pairs[0].key,
          hash_node.pairs[1].key,
          hash_node.pairs[2].key
        ]
      end

      it 'yields all the pairs' do
        expect { |b| hash_node.each_key(&b) }
          .to yield_successive_args(*expected)
      end
    end
  end

  describe '#values' do
    context 'with an empty hash' do
      let(:source) { '{}' }

      it { expect(hash_node.values).to be_empty }
    end

    context 'with a hash with literal values' do
      let(:source) { '{ a: 1, b: 2, c: 3 }' }

      it { expect(hash_node.values.size).to eq(3) }
      it { expect(hash_node.values).to all(be_literal) }
    end

    context 'with a hash with string keys' do
      let(:source) { '{ a: foo, b: bar }' }

      it { expect(hash_node.values.size).to eq(2) }
      it { expect(hash_node.values).to all(be_send_type) }
    end
  end

  describe '#each_value' do
    let(:source) { '{ a: 1, b: 2, c: 3 }' }

    context 'when not passed a block' do
      it { expect(hash_node.each_value).to be_a(Enumerator) }
    end

    context 'when passed a block' do
      let(:expected) do
        [
          hash_node.pairs[0].value,
          hash_node.pairs[1].value,
          hash_node.pairs[2].value
        ]
      end

      it 'yields all the pairs' do
        expect { |b| hash_node.each_value(&b) }
          .to yield_successive_args(*expected)
      end
    end
  end

  describe '#each_pair' do
    let(:source) { '{ a: 1, b: 2, c: 3 }' }

    context 'when not passed a block' do
      it { expect(hash_node.each_pair).to be_a(Enumerator) }
    end

    context 'when passed a block' do
      let(:expected) do
        hash_node.pairs.map(&:to_a)
      end

      it 'yields all the pairs' do
        expect { |b| hash_node.each_pair(&b) }
          .to yield_successive_args(*expected)
      end
    end
  end

  describe '#pairs_on_same_line?' do
    context 'with all pairs on the same line' do
      let(:source) { '{ a: 1, b: 2 }' }

      it { expect(hash_node).to be_pairs_on_same_line }
    end

    context 'with no pairs on the same line' do
      let(:source) do
        ['{ a: 1,',
         ' b: 2 }'].join("\n")
      end

      it { expect(hash_node).not_to be_pairs_on_same_line }
    end

    context 'with some pairs on the same line' do
      let(:source) do
        ['{ a: 1,',
         ' b: 2, c: 3 }'].join("\n")
      end

      it { expect(hash_node).to be_pairs_on_same_line }
    end
  end

  describe '#mixed_delimiters?' do
    context 'when all pairs are using a colon delimiter' do
      let(:source) { '{ a: 1, b: 2 }' }

      it { expect(hash_node).not_to be_mixed_delimiters }
    end

    context 'when all pairs are using a hash rocket delimiter' do
      let(:source) { '{ :a => 1, :b => 2 }' }

      it { expect(hash_node).not_to be_mixed_delimiters }
    end

    context 'when pairs are using different delimiters' do
      let(:source) { '{ :a => 1, b: 2 }' }

      it { expect(hash_node).to be_mixed_delimiters }
    end
  end

  describe '#braces?' do
    context 'with braces' do
      let(:source) { '{ a: 1, b: 2 }' }

      it { expect(hash_node).to be_braces }
    end

    context 'as an argument with no braces' do
      let(:source) { 'foo(:bar, a: 1, b: 2)' }

      let(:hash_argument) { hash_node.children.last }

      it { expect(hash_argument).not_to be_braces }
    end

    context 'as an argument with braces' do
      let(:source) { 'foo(:bar, { a: 1, b: 2 })' }

      let(:hash_argument) { hash_node.children.last }

      it { expect(hash_argument).to be_braces }
    end
  end
end
