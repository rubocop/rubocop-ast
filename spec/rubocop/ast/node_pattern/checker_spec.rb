# frozen_string_literal: true

RSpec.describe RuboCop::AST::NodePattern::Checker do
  subject(:problems) { described_class.new.check(pattern) }

  let(:messages) { problems.map(&:message) }
  let(:sources) { problems.map { |problem| problem.range.source } }

  shared_examples 'no problems' do |pattern|
    context "with `#{pattern}`" do
      let(:pattern) { pattern }

      it { is_expected.to be_empty }
    end
  end

  shared_examples 'a problem' do |pattern, source, message|
    context "with `#{pattern}`" do
      let(:pattern) { pattern }

      it 'finds it' do
        expect(messages).to eq [message]
        expect(sources).to eq [source]
      end
    end
  end

  describe 'node types' do
    it_behaves_like 'no problems', '(send nil? :foo)'
    it_behaves_like 'no problems', '{call any_block block-pass}'
    it_behaves_like 'a problem', '(sned nil? :foo)', 'sned', 'Unknown node type `sned`.'
    it_behaves_like 'a problem', '{send blok}', 'blok', 'Unknown node type `blok`.'
  end

  describe 'the number of children' do
    it_behaves_like 'no problems', '(if _ _ _)'
    it_behaves_like 'no problems', '(send _ :foo)'
    it_behaves_like 'no problems', '(send ...)'
    it_behaves_like 'no problems', '(lvasgn _)'
    it_behaves_like 'no problems', '(lvasgn _ _)'
    it_behaves_like 'no problems', '(case _ when+ _)'
    it_behaves_like 'no problems', '(hash <(pair (sym :a) _) ...>)'
    it_behaves_like 'no problems', '(_ _ _ _ _ _)'
    it_behaves_like 'no problems', '(#foo? _)'
    it_behaves_like 'a problem', '(if _ _ _ _ _)', '(if _ _ _ _ _)',
                    '`if` nodes have 3 children, not 5.'
    it_behaves_like 'a problem', '(true _)', '(true _)', '`true` nodes have no children, not 1.'
    it_behaves_like 'a problem', '(int)', '(int)', '`int` nodes have 1 child, not 0.'
    it_behaves_like 'a problem', '(send _)', '(send _)',
                    '`send` nodes have 2 or more children, not 1.'
    it_behaves_like 'a problem', '(lvasgn _ _ _ ...)', '(lvasgn _ _ _ ...)',
                    '`lvasgn` nodes have 1 to 2 children, not 3 or more.'
    it_behaves_like 'a problem', '(pair _ <_ _>)', '(pair _ <_ _>)',
                    '`pair` nodes have 2 children, not 3.'

    context 'when the sequence is for several types' do
      it_behaves_like 'no problems', '({send csend} _ :foo)'
      it_behaves_like 'a problem', '({send def} _ _ _ _)', '({send def} _ _ _ _)',
                      '`def` nodes have 3 children, not 4.'
    end

    context 'when the sequence is for a group of types' do
      it_behaves_like 'no problems', '(any_block _ _ _)'
      it_behaves_like 'no problems', '(any_def _ _ _)'
      it_behaves_like 'no problems', '(argument _)'

      context 'with `(any_def _ _)`' do
        let(:pattern) { '(any_def _ _)' }

        it 'finds a problem for each type' do
          expect(messages).to eq ['`def` nodes have 3 children, not 2.',
                                  '`defs` nodes have 4 children, not 2.']
        end
      end
    end
  end

  describe 'what the children are' do
    it_behaves_like 'no problems', '(def :foo (args) nil?)'
    it_behaves_like 'no problems', '(send {nil? cbase} ${:foo :bar} (int 1))'
    it_behaves_like 'no problems', '(send [!nil? !self] _)'
    it_behaves_like 'no problems', '(int {1 2.0})'
    it_behaves_like 'no problems', '(str #foo?)'
    it_behaves_like 'no problems', '(sym %1)'
    it_behaves_like 'no problems', '(send _ :foo ... nil?)'
    it_behaves_like 'no problems', '(procarg0 nil?)'
    it_behaves_like 'no problems', '({arg procarg0} (arg _))'
    it_behaves_like 'no problems', '(rational 1)'
    it_behaves_like 'a problem', '(send _ to_s)', 'to_s', 'Unknown node type `to_s`.'
    it_behaves_like 'a problem', '(def (sym :foo) _ _)', '(sym :foo)',
                    'This never matches child 1 of `def` nodes, which is a symbol.'
    it_behaves_like 'a problem', '(str :foo)', ':foo',
                    'This never matches child 1 of `str` nodes, which is a string.'
    it_behaves_like 'a problem', '(nth_ref "1")', '"1"',
                    'This never matches child 1 of `nth_ref` nodes, which is an integer.'
    it_behaves_like 'a problem', '(send _ $int)', '$int',
                    'This never matches child 2 of `send` nodes, which is a symbol.'
    it_behaves_like 'a problem', '(call 1 :foo)', '1',
                    'This never matches child 1 of `send`, `csend` nodes, which is a node or nil.'
    it_behaves_like 'a problem', '(csend nil? :foo)', 'nil?',
                    'This never matches child 1 of `csend` nodes, which is a node.'
    it_behaves_like 'a problem', '(hash (pair {:a :b} _))', '{:a :b}',
                    'This never matches child 1 of `pair` nodes, which is a node.'
  end

  describe 'predicates' do
    it_behaves_like 'no problems', '(send _ :foo sym_type?)'
    it_behaves_like 'no problems', '(send _ :foo assignment_method?)'
    it_behaves_like 'no problems', '(send _ start_with?("a"))'
    it_behaves_like 'no problems', '(send _ :foo #frobnicate?)'
    it_behaves_like 'a problem', '(send _ :foo frobnicate?)', 'frobnicate?',
                    'Neither a node nor a child of one responds to `frobnicate?`.'
  end

  describe 'unions' do
    it_behaves_like 'no problems', '{send csend}'
    it_behaves_like 'no problems', '(send _ {:a :b})'
    it_behaves_like 'no problems', '({int ...})'
    it_behaves_like 'no problems', '({send $...} _)'
    it_behaves_like 'a problem', '(send _ {:a :b :a})', '{:a :b :a}',
                    '`:a` is in the union more than once.'
    it_behaves_like 'a problem', '{(send _ :a) int (send _ :a)}', '{(send _ :a) int (send _ :a)}',
                    '`(send _ :a)` is in the union more than once.'
  end

  context 'with a pattern that has several problems' do
    let(:pattern) { '(send (blok _ _) :foo (pair _))' }

    it 'finds them all' do
      expect(messages).to eq ['Unknown node type `blok`.', '`pair` nodes have 2 children, not 1.']
    end
  end

  context 'with a pattern that is not valid' do
    let(:pattern) { '(send' }

    it { expect { problems }.to raise_error(RuboCop::AST::NodePattern::Invalid) }
  end
end
