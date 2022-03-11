# frozen_string_literal: true

require 'parser/current'

RSpec.describe RuboCop::AST::NodePattern do
  include RuboCop::AST::Sexp

  def parse(code)
    buffer = Parser::Source::Buffer.new('(string)', 1, source: code)
    builder = RuboCop::AST::Builder.new
    Parser::CurrentRuby.new(builder).parse(buffer)
  end

  let(:root_node) { parse(ruby) }
  let(:node) { root_node }
  let(:params) { [] }
  let(:keyword_params) { {} }
  let(:instance) { described_class.new(pattern) }
  let(:method_name) { :match }
  let(:result) do
    if keyword_params.empty? # Avoid bug in Ruby < 2.6
      instance.match(node, *params)
    else
      instance.match(node, *params, **keyword_params)
    end
  end

  RSpec::Matchers.define :match_code do |code, *params, **keyword_params|
    match do |pattern|
      instance = pattern.is_a?(String) ? described_class.new(pattern) : pattern
      code = parse(code) if code.is_a?(String)
      if keyword_params.empty? # Avoid bug in Ruby < 2.6
        instance.public_send(method_name, code, *params)
      else
        instance.public_send(method_name, code, *params, **keyword_params)
      end
    end
  end

  RSpec::Matchers.define_negated_matcher :not_match_code, :match_code

  def match_codes(*codes)
    codes.map { |code| match_code(code) }.inject(:and)
  end

  def not_match_codes(*codes)
    codes.map { |code| not_match_code(code) }.inject(:and)
  end

  shared_examples 'nonmatching' do
    it "doesn't match" do
      expect(result).to be_nil
    end
  end

  shared_examples 'invalid' do
    it 'is invalid' do
      expect { instance }
        .to raise_error(RuboCop::AST::NodePattern::Invalid)
    end
  end

  shared_examples 'single capture' do
    it 'yields captured value(s) and returns true if there is a block' do
      expect do |probe|
        compiled = instance
        retval = compiled.match(node, *params) do |capture|
          probe.to_proc.call(capture)
          :retval_from_block
        end
        expect(retval).to be :retval_from_block
      end.to yield_with_args(captured_val)
    end

    it 'returns captured values if there is no block' do
      retval = instance.match(node, *params)
      expect(retval).to eq captured_val
    end
  end

  shared_examples 'multiple capture' do
    it 'yields captured value(s) and returns true if there is a block' do
      expect do |probe|
        compiled = instance
        retval = compiled.match(node, *params) do |*captures|
          probe.to_proc.call(captures)
          :retval_from_block
        end
        expect(retval).to be :retval_from_block
      end.to yield_with_args(captured_vals)
    end

    it 'returns captured values if there is no block' do
      retval = instance.match(node, *params)
      expect(retval).to eq captured_vals
    end
  end

  describe 'bare node type' do
    let(:pattern) { 'send' }

    context 'on a node with the same type' do
      let(:ruby) { 'obj.method' }

      it { expect(pattern).to match_code(node) }
    end

    context 'on a node with a different type' do
      let(:ruby) { '@ivar' }

      it_behaves_like 'nonmatching'
    end

    context 'on a node with a matching, hyphenated type' do
      let(:pattern) { 'op-asgn' }
      let(:ruby) { 'a += 1' }

      # this is an (op-asgn ...) node
      it { expect(pattern).to match_code(node) }
    end

    describe '#pattern' do
      it 'returns the pattern' do
        expect(instance.pattern).to eq pattern
      end
    end

    describe '#to_s' do
      it 'is instructive' do
        expect(instance.to_s).to include pattern
      end
    end

    describe 'marshal compatibility' do
      let(:instance) { Marshal.load(Marshal.dump(super())) }
      let(:ruby) { 'obj.method' }

      it { expect(pattern).to match_code(node) }
    end

    describe '#dup' do
      let(:instance) { super().dup }
      let(:ruby) { 'obj.method' }

      it { expect(pattern).to match_code(node) }
    end

    if RUBY_VERSION >= '2.6'
      describe 'yaml compatibility' do
        let(:instance) do
          YAML.safe_load(YAML.dump(super()), permitted_classes: [described_class])
        end
        let(:ruby) { 'obj.method' }

        it { expect(pattern).to match_code(node) }
      end
    end

    describe '#==' do
      let(:pattern) { "  (send  42 \n :to_s ) " }

      it 'returns true iff the patterns are similar' do
        expect(instance == instance.dup).to be true
        expect(instance == 42).to be false
        expect(instance == described_class.new('(send)')).to be false
        expect(instance == described_class.new('(send 42 :to_s)')).to be true
      end
    end
  end

  describe 'node type' do
    describe 'in seq head' do
      let(:pattern) { '(send ...)' }

      context 'on a node with the same type' do
        let(:ruby) { '@ivar + 2' }

        it { expect(pattern).to match_code(node) }
      end

      context 'on a child with a different type' do
        let(:ruby) { '@ivar += 2' }

        it_behaves_like 'nonmatching'
      end
    end

    describe 'for a child' do
      let(:pattern) { '(_ send ...)' }

      context 'on a child with the same type' do
        let(:ruby) { 'foo.bar' }

        it { expect(pattern).to match_code(node) }
      end

      context 'on a child with a different type' do
        let(:ruby) { '@ivar.bar' }

        it_behaves_like 'nonmatching'
      end

      context 'on a child litteral' do
        let(:pattern) { '(_ _ send)' }
        let(:ruby) { '42.bar' }

        it_behaves_like 'nonmatching'
      end
    end
  end

  describe 'literals' do
    context 'negative integer literals' do
      let(:pattern) { '(int -100)' }
      let(:ruby) { '-100' }

      it { expect(pattern).to match_code(node) }
    end

    context 'positive float literals' do
      let(:pattern) { '(float 1.0)' }
      let(:ruby) { '1.0' }

      it { expect(pattern).to match_code(node) }
    end

    context 'negative float literals' do
      let(:pattern) { '(float -2.5)' }
      let(:ruby) { '-2.5' }

      it { expect(pattern).to match_code(node) }
    end

    context 'single quoted string literals' do
      let(:pattern) { '(str "foo")' }
      let(:ruby) { '"foo"' }

      it { expect(pattern).to match_code(node) }
    end

    context 'double quoted string literals' do
      let(:pattern) { '(str "foo")' }
      let(:ruby) { "'foo'" }

      it { expect(pattern).to match_code(node) }
    end

    context 'symbol literals' do
      let(:pattern) { '(sym :foo)' }
      let(:ruby) { ':foo' }

      it { expect(pattern).to match_code(node) }
    end

    describe 'bare literal' do
      let(:ruby) { ':bar' }
      let(:pattern) { ':bar' }

      context 'on a node' do
        it_behaves_like 'nonmatching'
      end

      context 'on a matching literal' do
        let(:node) { root_node.children[0] }

        it { expect(pattern).to match_code(node) }
      end
    end
  end

  describe 'nil' do
    context 'nil literals' do
      let(:pattern) { '(nil)' }
      let(:ruby) { 'nil' }

      it { expect(pattern).to match_code(node) }
    end

    context 'nil value in AST' do
      let(:pattern) { '(send nil :foo)' }
      let(:ruby) { 'foo' }

      it_behaves_like 'nonmatching'
    end

    context 'nil value in AST, use nil? method' do
      let(:pattern) { '(send nil? :foo)' }
      let(:ruby) { 'foo' }

      it { expect(pattern).to match_code(node) }
    end

    context 'against a node pattern (bug #5470)' do
      let(:pattern) { '(:send (:const ...) ...)' }
      let(:ruby) { 'foo' }

      it_behaves_like 'nonmatching'
    end
  end

  describe 'simple sequence' do
    let(:pattern) { '(send int :+ int)' }

    context 'on a node with the same type and matching children' do
      let(:ruby) { '1 + 1' }

      it { expect(pattern).to match_code(node) }
    end

    context 'on a node with a different type' do
      let(:ruby) { 'a = 1' }

      it_behaves_like 'nonmatching'
    end

    context 'on a node with the same type and non-matching children' do
      context 'with non-matching selector' do
        let(:ruby) { '1 - 1' }

        it_behaves_like 'nonmatching'
      end

      context 'with non-matching receiver type' do
        let(:ruby) { '1.0 + 1' }

        it_behaves_like 'nonmatching'
      end
    end

    context 'on a node with too many children' do
      let(:pattern) { '(send int :blah int)' }
      let(:ruby) { '1.blah(1, 2)' }

      it_behaves_like 'nonmatching'
    end

    context 'with a nested sequence in head position' do
      let(:pattern) { '((send) int :blah)' }

      it_behaves_like 'invalid'
    end

    context 'with a nested sequence in non-head position' do
      let(:pattern) { '(send (send _ :a) :b)' }
      let(:ruby) { 'obj.a.b' }

      it { expect(pattern).to match_code(node) }
    end
  end

  describe 'sequence with trailing ...' do
    let(:pattern) { '(send int :blah ...)' }

    context 'on a node with the same type and exact number of children' do
      let(:ruby) { '1.blah' }

      it { expect(pattern).to match_code(node) }
    end

    context 'on a node with the same type and more children' do
      context 'with 1 child more' do
        let(:ruby) { '1.blah(1)' }

        it { expect(pattern).to match_code(node) }
      end

      context 'with 2 children more' do
        let(:ruby) { '1.blah(1, :something)' }

        it { expect(pattern).to match_code(node) }
      end
    end

    context 'on a node with the same type and fewer children' do
      let(:pattern) { '(send int :blah int int ...)' }
      let(:ruby) { '1.blah(2)' }

      it_behaves_like 'nonmatching'
    end

    context 'on a node with fewer children, with a wildcard preceding' do
      let(:pattern) { '(hash _ ...)' }
      let(:ruby) { '{}' }

      it_behaves_like 'nonmatching'
    end

    context 'on a node with a different type' do
      let(:ruby) { 'A = 1' }

      it_behaves_like 'nonmatching'
    end

    context 'on a node with non-matching children' do
      let(:ruby) { '1.foo' }

      it_behaves_like 'nonmatching'
    end
  end

  describe 'wildcards' do
    describe 'unnamed wildcards' do
      context 'at the root level' do
        let(:pattern) { '_' }
        let(:ruby) { 'class << self; def something; 1; end end.freeze' }

        it { expect(pattern).to match_code(node) }
      end

      context 'within a sequence' do
        let(:pattern) { '(const _ _)' }
        let(:ruby) { 'Const' }

        it { expect(pattern).to match_code(node) }
      end

      context 'within a sequence with other patterns intervening' do
        let(:pattern) { '(ivasgn _ (int _))' }
        let(:ruby) { '@abc = 22' }

        it { expect(pattern).to match_code(node) }
      end

      context 'in head position of a sequence' do
        let(:pattern) { '(_ int ...)' }
        let(:ruby) { '1 + a' }

        it { expect(pattern).to match_code(node) }
      end

      context 'negated' do
        let(:pattern) { '!_' }
        let(:ruby) { '123' }

        it_behaves_like 'nonmatching'
      end
    end

    describe 'named wildcards' do
      # unification is done on named wildcards!
      context 'at the root level' do
        let(:pattern) { '_node' }
        let(:ruby) { 'class << self; def something; 1; end end.freeze' }

        it { expect(pattern).to match_code(node) }
      end

      context 'within a sequence' do
        context 'with values which can be unified' do
          let(:pattern) { '(send _num :+ _num)' }
          let(:ruby) { '5 + 5' }

          it { expect(pattern).to match_code(node) }
        end

        context 'with values which cannot be unified' do
          let(:pattern) { '(send _num :+ _num)' }
          let(:ruby) { '5 + 4' }

          it_behaves_like 'nonmatching'
        end

        context 'unifying the node type with an argument' do
          let(:pattern) { '(_type _ _type)' }
          let(:ruby) { 'obj.send' }

          it { expect(pattern).to match_code(node) }
        end
      end

      context 'within a sequence with other patterns intervening' do
        let(:pattern) { '(ivasgn _ivar (int _val))' }
        let(:ruby) { '@abc = 22' }

        it { expect(pattern).to match_code(node) }
      end

      context 'in head position of a sequence' do
        let(:pattern) { '(_type int ...)' }
        let(:ruby) { '1 + a' }

        it { expect(pattern).to match_code(node) }
      end

      context 'within a union' do
        context 'confined to the union' do
          context 'without unification' do
            let(:pattern) { '{(array (int 1) _num) (array _num (int 1))}' }
            let(:ruby) { '[2, 1]' }

            it { expect(pattern).to match_code(node) }
          end

          context 'with partial unification' do
            let(:pattern) { '{(array _num _num) (array _num (int 1))}' }

            context 'matching the unified branch' do
              let(:ruby) { '[5, 5]' }

              it { expect(pattern).to match_code(node) }
            end

            context 'matching the free branch' do
              let(:ruby) { '[2, 1]' }

              it { expect(pattern).to match_code(node) }
            end

            context 'that can not be unified' do
              let(:ruby) { '[3, 2]' }

              it_behaves_like 'nonmatching'
            end
          end
        end

        context 'with a preceding unifying constraint' do
          let(:pattern) do
            '(array _num {(array (int 1) _num)
                          send
                          (array _num (int 1))})'
          end

          context 'matching a branch' do
            let(:ruby) { '[2, [2, 1]]' }

            it { expect(pattern).to match_code(node) }
          end

          context 'that can not be unified' do
            let(:ruby) { '[3, [2, 1]]' }

            it_behaves_like 'nonmatching'
          end
        end

        context 'with a succeeding unifying constraint' do
          context 'with branches without the wildcard' do
            context 'encountered first' do
              let(:pattern) do
                '(array {send
                         (array (int 1) _num)
                        } _num)'
              end

              it_behaves_like 'invalid'
            end

            context 'encountered after' do
              let(:pattern) do
                '(array {(array (int 1) _num)
                         (array _num (int 1))
                          send
                        } _num)'
              end

              it_behaves_like 'invalid'
            end
          end

          context 'with all branches with the wildcard' do
            let(:pattern) do
              '(array {(array (int 1) _num)
                       (array _num (int 1))
                      } _num)'
            end

            context 'matching the first branch' do
              let(:ruby) { '[[1, 2], 2]' }

              it { expect(pattern).to match_code(node) }
            end

            context 'matching another branch' do
              let(:ruby) { '[[2, 1], 2]' }

              it { expect(pattern).to match_code(node) }
            end

            context 'that can not be unified' do
              let(:ruby) { '[[2, 1], 1]' }

              it_behaves_like 'nonmatching'
            end
          end
        end
      end
    end
  end

  describe 'unions' do
    context 'at the top level' do
      context 'containing symbol literals' do
        context 'when the AST has a matching symbol' do
          let(:pattern) { '(send _ {:a :b})' }
          let(:ruby) { 'obj.b' }

          it { expect(pattern).to match_code(node) }
        end

        context 'when the AST does not have a matching symbol' do
          let(:pattern) { '(send _ {:a :b})' }
          let(:ruby) { 'obj.c' }

          it_behaves_like 'nonmatching'
        end
      end

      context 'containing string literals' do
        let(:pattern) { '(send (str {"a" "b"}) :upcase)' }
        let(:ruby) { '"a".upcase' }

        it { expect(pattern).to match_code(node) }
      end

      context 'containing integer literals' do
        let(:pattern) { '(send (int {1 10}) :abs)' }
        let(:ruby) { '10.abs' }

        it { expect(pattern).to match_code(node) }
      end

      context 'containing mixed node and literals' do
        let(:pattern) { '(send {int nil?} ...)' }
        let(:ruby) { 'obj' }

        it { expect(pattern).to match_code(node) }
      end

      context 'containing multiple []' do
        let(:pattern) { '{[(int odd?) int] [!nil float]}' }

        context 'on a node which meets all requirements of the first []' do
          let(:ruby) { '3' }

          it { expect(pattern).to match_code(node) }
        end

        context 'on a node which meets all requirements of the second []' do
          let(:ruby) { '2.4' }

          it { expect(pattern).to match_code(node) }
        end

        context 'on a node which meets some requirements but not all' do
          let(:ruby) { '2' }

          it_behaves_like 'nonmatching'
        end
      end
    end

    context 'nested inside a sequence' do
      let(:pattern) { '(send {const int} ...)' }
      let(:ruby) { 'Const.method' }

      it { expect(pattern).to match_code(node) }
    end

    context 'with a nested sequence' do
      let(:pattern) { '{(send int ...) (send const ...)}' }
      let(:ruby) { 'Const.method' }

      it { expect(pattern).to match_code(node) }
    end

    context 'variadic' do
      context 'with fixed terms' do
        it 'works for cases with fixed arity before and after union' do
          expect('(_ { int | sym _ str | } const)').to match_codes(
            '[X]', '[42, X]', '[:foo, //, "bar", X]'
          ).and not_match_codes(
            '[42]', '[4.2, X]', '["bar", //, :foo, X]'
          )
        end

        it 'works for cases with variadic terms after union' do
          expect('(_ { int | sym _ str | } const+)').to match_codes(
            '[X]', '[42, X, Y, Z]', '[:foo, //, "bar", X]'
          ).and not_match_codes(
            '[42]', '[4.2, X]', '["bar", //, :foo, X]'
          )
        end

        it 'works for cases with variadic terms before and after union' do
          expect('(_ const ? { int | sym _ str | } const+)').to match_codes(
            '[X]', '[FOO, 42, X, Y, Z]', '[:foo, //, "bar", X]', '[X, Y, Z]'
          ).and not_match_codes(
            '[42]', '[4.2, X]', '["bar", //, :foo, X]', '[FOO BAR, 42]'
          )
        end
      end

      context 'with variadic terms' do
        it 'works for cases with fixed arity before and after union' do
          expect('(_ { sym+ _ str | int* } const)').to match_codes(
            '[X]', '[42, 666, X]', '[:foo, :foo2, //, "bar", X]'
          ).and not_match_codes(
            '[42]', '[4.2, X]', '["bar", //, :foo, X]'
          )
        end

        it 'works for cases with variadic terms after union' do
          expect('(_ { sym+ _ str | int* } const+)').to match_codes(
            '[X]', '[42, 666, X, Y, Z]', '[:foo, :foo2, //, "bar", X]'
          ).and not_match_codes(
            '[42]', '[4.2, X]', '["bar", //, :foo, X]'
          )
        end

        it 'works for cases with variadic terms before and after union' do
          expect('(_ const ? { sym+ _ str | int* } const+)').to match_codes(
            '[X]', '[FOO, 42, 666, X, Y, Z]', '[:foo, :foo2, //, "bar", X]', '[X, Y, Z]'
          ).and not_match_codes(
            '[42]', '[4.2, X]', '["bar", //, :foo, X]', '[FOO BAR, 42]'
          )
        end
      end

      context 'multiple' do
        it 'works for complex cases' do
          expect('(_ const ? { sym+ int+ | int+ sym+ } { str+ | regexp+ } ... )').to match_codes(
            '[X, :foo, :bar, 42, "a", Y]', '[42, 666, :foo, //]'
          ).and not_match_codes(
            '[42, :almost, X]', '[X, 42, :foo, 42, //]', '[X, :foo, //, :foo, X]'
          )
        end
      end
    end
  end

  describe 'captures on a wildcard' do
    context 'at the root level' do
      let(:pattern) { '$_' }
      let(:ruby) { 'begin; raise StandardError; rescue Exception => e; end' }
      let(:captured_val) { node }

      it_behaves_like 'single capture'
    end

    context 'in head position in a sequence' do
      let(:pattern) { '($_ ...)' }
      let(:ruby) { 'A.method' }
      let(:captured_val) { :send }

      it_behaves_like 'single capture'
    end

    context 'in head position in a sequence against nil (bug #5470)' do
      let(:pattern) { '($_ ...)' }
      let(:ruby) { '' }

      it_behaves_like 'nonmatching'
    end

    context 'in head position in a sequence against literal (bug #5470)' do
      let(:pattern) { '(int ($_ ...))' }
      let(:ruby) { '42' }

      it_behaves_like 'nonmatching'
    end

    context 'in non-head position in a sequence' do
      let(:pattern) { '(send $_ ...)' }
      let(:ruby) { 'A.method' }
      let(:captured_val) { s(:const, nil, :A) }

      it_behaves_like 'single capture'
    end

    context 'in a nested sequence' do
      let(:pattern) { '(send (const nil? $_) ...)' }
      let(:ruby) { 'A.method' }
      let(:captured_val) { :A }

      it_behaves_like 'single capture'
    end

    context 'nested in any child' do
      let(:pattern) { '(send $<(const nil? $_) $...>)' }
      let(:ruby) { 'A.method' }
      let(:captured_vals) { [[s(:const, nil, :A), :method], :A, [:method]] }

      it_behaves_like 'multiple capture'
    end
  end

  describe 'captures which also perform a match' do
    context 'on a sequence' do
      let(:pattern) { '(send $(send _ :keys) :each)' }
      let(:ruby) { '{}.keys.each' }
      let(:captured_val) { s(:send, s(:hash), :keys) }

      it_behaves_like 'single capture'
    end

    context 'on a set' do
      let(:pattern) { '(send _ ${:inc :dec})' }
      let(:ruby) { '1.dec' }
      let(:captured_val) { :dec }

      it_behaves_like 'single capture'
    end

    context 'on []' do
      let(:pattern) { '(send (int $[!odd? !zero?]) :inc)' }
      let(:ruby) { '2.inc' }
      let(:captured_val) { 2 }

      it_behaves_like 'single capture'
    end

    context 'on a node type' do
      let(:pattern) { '(send $int :inc)' }
      let(:ruby) { '5.inc' }
      let(:captured_val) { s(:int, 5) }

      it_behaves_like 'single capture'
    end

    context 'on a literal' do
      let(:pattern) { '(send int $:inc)' }
      let(:ruby) { '5.inc' }
      let(:captured_val) { :inc }

      it_behaves_like 'single capture'
    end

    context 'when nested' do
      let(:pattern) { '(send $(int $_) :inc)' }
      let(:ruby) { '5.inc' }
      let(:captured_vals) { [s(:int, 5), 5] }

      it_behaves_like 'multiple capture'
    end
  end

  describe 'captures on ...' do
    context 'with no remaining pattern at the end' do
      let(:pattern) { '(send $...)' }
      let(:ruby) { '5.inc' }
      let(:captured_val) { [s(:int, 5), :inc] }

      it_behaves_like 'single capture'
    end

    context 'with a remaining node type at the end' do
      let(:pattern) { '(send $... int)' }
      let(:ruby) { '5 + 4' }
      let(:captured_val) { [s(:int, 5), :+] }

      it_behaves_like 'single capture'
    end

    context 'with remaining patterns at the end' do
      let(:pattern) { '(send $... int int)' }
      let(:ruby) { '[].push(1, 2, 3)' }
      let(:captured_val) { [s(:array), :push, s(:int, 1)] }

      it_behaves_like 'single capture'
    end

    context 'with a remaining sequence at the end' do
      let(:pattern) { '(send $... (int 4))' }
      let(:ruby) { '5 + 4' }
      let(:captured_val) { [s(:int, 5), :+] }

      it_behaves_like 'single capture'
    end

    context 'with a remaining set at the end' do
      let(:pattern) { '(send $... {int float})' }
      let(:ruby) { '5 + 4' }
      let(:captured_val) { [s(:int, 5), :+] }

      it_behaves_like 'single capture'
    end

    context 'with a remaining [] at the end' do
      let(:pattern) { '(send $... [(int even?) (int zero?)])' }
      let(:ruby) { '5 + 0' }
      let(:captured_val) { [s(:int, 5), :+] }

      it_behaves_like 'single capture'
    end

    context 'with a remaining literal at the end' do
      let(:pattern) { '(send $... :inc)' }
      let(:ruby) { '5.inc' }
      let(:captured_val) { [s(:int, 5)] }

      it_behaves_like 'single capture'
    end

    context 'with a remaining wildcard at the end' do
      let(:pattern) { '(send $... _)' }
      let(:ruby) { '5.inc' }
      let(:captured_val) { [s(:int, 5)] }

      it_behaves_like 'single capture'
    end

    context 'with a remaining capture at the end' do
      let(:pattern) { '(send $... $_)' }
      let(:ruby) { '5 + 4' }
      let(:captured_vals) { [[s(:int, 5), :+], s(:int, 4)] }

      it_behaves_like 'multiple capture'
    end

    context 'at the very beginning of a sequence' do
      let(:pattern) { '($... (int 1))' }
      let(:ruby) { '10 * 1' }
      let(:captured_val) { [s(:int, 10), :*] }

      it_behaves_like 'single capture'
    end

    context 'after a child' do
      let(:pattern) { '(send (int 10) $...)' }
      let(:ruby) { '10 * 1' }
      let(:captured_val) { [:*, s(:int, 1)] }

      it_behaves_like 'single capture'
    end
  end

  describe 'captures within union' do
    context 'on simple subpatterns' do
      let(:pattern) { '{$send $int $float}' }
      let(:ruby) { '2.0' }
      let(:captured_val) { s(:float, 2.0) }

      it_behaves_like 'single capture'
    end

    context 'within nested sequences' do
      let(:pattern) { '{(send $_ $_) (const $_ $_)}' }
      let(:ruby) { 'Namespace::CONST' }
      let(:captured_vals) { [s(:const, nil, :Namespace), :CONST] }

      it_behaves_like 'multiple capture'
    end

    context 'with complex nesting' do
      let(:pattern) do
        '{(send {$int $float} {$:inc $:dec}) ' \
          '[!nil {($_ sym $_) (send ($_ $_) :object_id)}]}'
      end
      let(:ruby) { '10.object_id' }
      let(:captured_vals) { [:int, 10] }

      it_behaves_like 'multiple capture'
    end

    context 'with a different number of captures in each branch' do
      let(:pattern) { '{(send $...) (int $...) (send $_ $_)}' }

      it_behaves_like 'invalid'
    end
  end

  describe 'negation' do
    context 'on a symbol' do
      let(:pattern) { '(send _ !:abc)' }

      context 'with a matching symbol' do
        let(:ruby) { 'obj.abc' }

        it_behaves_like 'nonmatching'
      end

      context 'with a non-matching symbol' do
        let(:ruby) { 'obj.xyz' }

        it { expect(pattern).to match_code(node) }
      end

      context 'with a non-matching symbol, but too many children' do
        let(:ruby) { 'obj.xyz(1)' }

        it_behaves_like 'nonmatching'
      end
    end

    context 'on a string' do
      let(:pattern) { '(send (str !"foo") :upcase)' }

      context 'with a matching string' do
        let(:ruby) { '"foo".upcase' }

        it_behaves_like 'nonmatching'
      end

      context 'with a non-matching symbol' do
        let(:ruby) { '"bar".upcase' }

        it { expect(pattern).to match_code(node) }
      end
    end

    context 'on a set' do
      let(:pattern) { '(ivasgn _ !(int {1 2}))' }

      context 'with a matching value' do
        let(:ruby) { '@a = 1' }

        it_behaves_like 'nonmatching'
      end

      context 'with a non-matching value' do
        let(:ruby) { '@a = 3' }

        it { expect(pattern).to match_code(node) }
      end
    end

    context 'on a sequence' do
      let(:pattern) { '!(ivasgn :@a ...)' }

      context 'with a matching node' do
        let(:ruby) { '@a = 1' }

        it_behaves_like 'nonmatching'
      end

      context 'with a node of different type' do
        let(:ruby) { '@@a = 1' }

        it { expect(pattern).to match_code(node) }
      end

      context 'with a node with non-matching children' do
        let(:ruby) { '@b = 1' }

        it { expect(pattern).to match_code(node) }
      end
    end

    context 'on square brackets' do
      let(:pattern) { '![!int !float]' }

      context 'with a node which meets all requirements of []' do
        let(:ruby) { '"abc"' }

        it_behaves_like 'nonmatching'
      end

      context 'with a node which meets only 1 requirement of []' do
        let(:ruby) { '1' }

        it { expect(pattern).to match_code(node) }
      end
    end

    context 'when nested in complex ways' do
      let(:pattern) { '!(send !{int float} !:+ !(send _ :to_i))' }

      context 'with (send str :+ (send str :to_i))' do
        let(:ruby) { '"abc" + "1".to_i' }

        it { expect(pattern).to match_code(node) }
      end

      context 'with (send int :- int)' do
        let(:ruby) { '1 - 1' }

        it { expect(pattern).to match_code(node) }
      end

      context 'with (send str :<< str)' do
        let(:ruby) { '"abc" << "xyz"' }

        it_behaves_like 'nonmatching'
      end
    end
  end

  describe 'ellipsis' do
    context 'preceding a capture' do
      let(:pattern) { '(send array :push ... $_)' }
      let(:ruby) { '[1].push(2, 3, 4)' }
      let(:captured_val) { s(:int, 4) }

      it_behaves_like 'single capture'
    end

    context 'preceding multiple captures' do
      let(:pattern) { '(send array :push ... $_ $_)' }
      let(:ruby) { '[1].push(2, 3, 4, 5)' }
      let(:captured_vals) { [s(:int, 4), s(:int, 5)] }

      it_behaves_like 'multiple capture'
    end

    context 'with a wildcard at the end, but no remaining child to match it' do
      let(:pattern) { '(send array :zip array ... _)' }
      let(:ruby) { '[1,2].zip([3,4])' }

      it_behaves_like 'nonmatching'
    end

    context 'with a nodetype at the end, but no remaining child to match it' do
      let(:pattern) { '(send array :zip array ... array)' }
      let(:ruby) { '[1,2].zip([3,4])' }

      it_behaves_like 'nonmatching'
    end

    context 'with a nested sequence at the end, but no remaining child' do
      let(:pattern) { '(send array :zip array ... (array ...))' }
      let(:ruby) { '[1,2].zip([3,4])' }

      it_behaves_like 'nonmatching'
    end

    context 'with a set at the end, but no remaining child to match it' do
      let(:pattern) { '(send array :zip array ... {array})' }
      let(:ruby) { '[1,2].zip([3,4])' }

      it_behaves_like 'nonmatching'
    end

    context 'with [] at the end, but no remaining child to match it' do
      let(:pattern) { '(send array :zip array ... [array !nil])' }
      let(:ruby) { '[1,2].zip([3,4])' }

      it_behaves_like 'nonmatching'
    end

    context 'at the very beginning of a sequence' do
      let(:pattern) { '(... (int 1))' }
      let(:ruby) { '10 * 1' }

      it { expect(pattern).to match_code(node) }
    end
  end

  describe 'predicates' do
    context 'in root position' do
      let(:pattern) { 'send_type?' }
      let(:ruby) { '1.inc' }

      it { expect(pattern).to match_code(node) }

      context 'with name containing a numeral' do
        before { RuboCop::AST::Node.def_node_matcher :custom_42?, 'send_type?' }

        let(:pattern) { 'custom_42?' }

        it { expect(pattern).to match_code(node) }
      end
    end

    context 'at head position of a sequence' do
      # called on the type symbol
      let(:pattern) { '(!nil? int ...)' }
      let(:ruby) { '1.inc' }

      it { expect(pattern).to match_code(node) }
    end

    context 'applied to an integer for which the predicate is true' do
      let(:pattern) { '(send (int odd?) :inc)' }
      let(:ruby) { '1.inc' }

      it { expect(pattern).to match_code(node) }
    end

    context 'applied to an integer for which the predicate is false' do
      let(:pattern) { '(send (int odd?) :inc)' }
      let(:ruby) { '2.inc' }

      it_behaves_like 'nonmatching'
    end

    context 'when captured' do
      let(:pattern) { '(send (int $odd?) :inc)' }
      let(:ruby) { '1.inc' }
      let(:captured_val) { 1 }

      it_behaves_like 'single capture'
    end

    context 'when negated' do
      let(:pattern) { '(send int !nil?)' }
      let(:ruby) { '1.inc' }

      it { expect(pattern).to match_code(node) }
    end

    context 'when in last-child position, but all children have already ' \
            'been matched' do
      let(:pattern) { '(send int :inc ... !nil?)' }
      let(:ruby) { '1.inc' }

      it_behaves_like 'nonmatching'
    end

    context 'with one extra argument' do
      let(:pattern) { '(send (int equal?(%1)) ...)' }
      let(:ruby) { '1 + 2' }

      context 'for which the predicate is true' do
        let(:params) { [1] }

        it { expect(pattern).to match_code(node, 1) }
      end

      context 'for which the predicate is false' do
        let(:params) { [2] }

        it_behaves_like 'nonmatching'
      end
    end

    context 'with a named argument' do
      let(:pattern) { '(send (int equal?(%param)) ...)' }
      let(:ruby) { '1 + 2' }

      context 'for which the predicate is true' do
        let(:keyword_params) { { param: 1 } }

        it { expect(pattern).to match_code(node, param: 1) }
      end

      context 'for which the predicate is false' do
        let(:keyword_params) { { param: 2 } }

        it_behaves_like 'nonmatching'
      end

      context 'when not given' do
        let(:keyword_params) { {} }

        it 'raises an error' do
          expect { result }.to raise_error(ArgumentError)
        end
      end

      context 'with extra arguments' do
        let(:keyword_params) { { param: 1, extra: 2 } }

        it 'raises an error' do
          expect { result }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with a constant argument' do
      let(:pattern) { '(send (int equal?(%CONST)) ...)' }
      let(:ruby) { '1 + 2' }

      before { stub_const 'CONST', const_value }

      context 'for which the predicate is true' do
        let(:const_value) { 1 }

        it { expect(pattern).to match_code(node) }
      end

      context 'for which the predicate is false' do
        let(:const_value) { 2 }

        it_behaves_like 'nonmatching'
      end
    end

    context 'with an expression argument' do
      before do
        def instance.some_function(node, arg)
          arg === node # rubocop:disable Style/CaseEquality
        end
      end

      let(:pattern) { '(send (int _value) :+ #some_function( {(int _value) (float _value)} ) )' }

      context 'for which the predicate is true' do
        let(:ruby) { '2 + 2.0' }

        it { expect(instance).to match_code(node) }
      end

      context 'for which the predicate is false' do
        let(:ruby) { '2 + 3.0' }

        it_behaves_like 'nonmatching'
      end
    end

    context 'with multiple arguments' do
      let(:pattern) { '(str between?(%1, %2))' }
      let(:ruby) { '"c"' }

      context 'for which the predicate is true' do
        let(:params) { %w[a d] }

        it { expect(pattern).to match_code(node, 'a', 'd') }
      end

      context 'for which the predicate is false' do
        let(:params) { %w[a b] }

        it_behaves_like 'nonmatching'
      end
    end
  end

  describe 'params' do
    context 'in root position' do
      let(:pattern) { '%1' }
      let(:params) { [s(:int, 10)] }
      let(:ruby) { '10' }

      it { expect(pattern).to match_code(node, s(:int, 10)) }

      context 'in root position' do
        let(:pattern) { '%1' }
        let(:matcher) { Object.new }
        let(:params) { [matcher] }
        let(:ruby) { '10' }

        before { expect(matcher).to receive(:===).with(s(:int, 10)).and_return true } # rubocop:todo RSpec/ExpectInHook

        it { expect(pattern).to match_code(node, matcher) }
      end
    end

    context 'as named parameters' do
      let(:pattern) { '%foo' }
      let(:matcher) { Object.new }
      let(:keyword_params) { { foo: matcher } }
      let(:ruby) { '10' }

      context 'when provided as argument to match' do
        before { expect(matcher).to receive(:===).with(s(:int, 10)).and_return true } # rubocop:todo RSpec/ExpectInHook

        it { expect(pattern).to match_code(node, foo: matcher) }
      end

      context 'when extra are provided' do
        let(:keyword_params) { { foo: matcher, bar: matcher } }

        it 'raises an ArgumentError' do
          expect { result }.to raise_error(ArgumentError)
        end
      end

      context 'when not provided' do
        let(:keyword_params) { {} }

        it 'raises an ArgumentError' do
          expect { result }.to raise_error(ArgumentError)
        end
      end
    end

    context 'in a nested sequence' do
      let(:pattern) { '(send (send _ %2) %1)' }
      let(:params) { %i[inc dec] }
      let(:ruby) { '5.dec.inc' }

      it { expect(pattern).to match_code(node, :inc, :dec) }
    end

    context 'when preceded by ...' do
      let(:pattern) { '(send ... %1)' }
      let(:params) { [s(:int, 10)] }
      let(:ruby) { '1 + 10' }

      it { expect(pattern).to match_code(node, s(:int, 10)) }
    end

    context 'when preceded by $...' do
      let(:pattern) { '(send $... %1)' }
      let(:params) { [s(:int, 10)] }
      let(:ruby) { '1 + 10' }
      let(:captured_val) { [s(:int, 1), :+] }

      it_behaves_like 'single capture'
    end

    context 'when captured' do
      let(:pattern) { '(const _ $%1)' }
      let(:params) { [:A] }
      let(:ruby) { 'Namespace::A' }
      let(:captured_val) { :A }

      it_behaves_like 'single capture'
    end

    context 'when negated, with a matching value' do
      let(:pattern) { '(const _ !%1)' }
      let(:params) { [:A] }
      let(:ruby) { 'Namespace::A' }

      it_behaves_like 'nonmatching'
    end

    context 'when negated, with a nonmatching value' do
      let(:pattern) { '(const _ !%1)' }
      let(:params) { [:A] }
      let(:ruby) { 'Namespace::B' }

      it { expect(pattern).to match_code(node, :A) }
    end

    context 'without explicit number' do
      let(:pattern) { '(const %2 %)' }
      let(:params) { [:A, s(:const, nil, :Namespace)] }
      let(:ruby) { 'Namespace::A' }

      it { expect(pattern).to match_code(node, :A, s(:const, nil, :Namespace)) }
    end

    context 'when inside a union, with a matching value' do
      let(:pattern) { '{str (int %)}' }
      let(:params) { [10] }
      let(:ruby) { '10' }

      it { expect(pattern).to match_code(node, 10) }
    end

    context 'when inside a union, with a nonmatching value' do
      let(:pattern) { '{str (int %)}' }
      let(:params) { [10] }
      let(:ruby) { '1.0' }

      it_behaves_like 'nonmatching'
    end

    context 'when inside an intersection' do
      let(:pattern) { '(int [!%1 %2 !zero?])' }
      let(:params) { [10, 20] }
      let(:ruby) { '20' }

      it { expect(pattern).to match_code(node, 10, 20) }
    end

    context 'param number zero' do
      # refers to original target node passed to #match
      let(:pattern) { '^(send %0 :+ (int 2))' }
      let(:ruby) { '1 + 2' }

      context 'in a position which matches original target node' do
        let(:node) { root_node.children[0] }

        it { expect(pattern).to match_code(node) }
      end

      context 'in a position which does not match original target node' do
        let(:node) { root_node.children[2] }

        it_behaves_like 'nonmatching'
      end
    end
  end

  describe 'caret (ascend)' do
    context 'used with a node type' do
      let(:ruby) { '1.inc' }
      let(:node) { root_node.children[0] }

      context 'which matches' do
        let(:pattern) { '^send' }

        it { expect(pattern).to match_code(node) }
      end

      context "which doesn't match" do
        let(:pattern) { '^const' }

        it_behaves_like 'nonmatching'
      end
    end

    context 'within sequence' do
      let(:ruby) { '1.inc' }

      context 'not in head' do
        let(:ruby) { '1.inc' }
        let(:pattern) { '(send ^send :inc)' }

        it { expect(pattern).to match_code(node) }

        context 'of a sequence' do
          let(:pattern) { '(send ^(send _ _) :inc)' }

          it { expect(pattern).to match_code(node) }
        end
      end

      context 'in head' do
        let(:node) { root_node.children[0] }
        let(:pattern) { '(^send 1)' }

        it { expect(pattern).to match_code(node) }

        context 'of a sequence' do
          let(:pattern) { '(^(send _ _) 1)' }

          it { expect(pattern).to match_code(node) }
        end
      end
    end

    context 'repeated twice' do
      # ascends to grandparent node
      let(:pattern) { '^^block' }
      let(:ruby) { '1.inc { something }' }
      let(:node) { root_node.children[0].children[0] }

      it { expect(pattern).to match_code(node) }
    end

    context 'inside an intersection' do
      let(:pattern) { '^[!nil send ^(block ...)]' }
      let(:ruby) { '1.inc { something }' }
      let(:node) { root_node.children[0].children[0] }

      it { expect(pattern).to match_code(node) }
    end

    context 'inside a union' do
      let(:pattern) { '{^send ^^send}' }
      let(:ruby) { '"str".concat(local += "abc")' }
      let(:node) { root_node.children[2].children[2] }

      it { expect(pattern).to match_code(node) }
    end

    # NOTE!! a pitfall of doing this is that unification is done using #==
    # This means that 'identical' AST nodes, which are not really identical
    # because they have different metadata, will still unify
    context 'using unification to match self within parent' do
      let(:pattern) { '[_self ^(send _ _ _self)]' }
      let(:ruby) { '1 + 2' }

      context 'with self in the right position' do
        let(:node) { root_node.children[2] }

        it { expect(pattern).to match_code(node) }
      end

      context 'with self in the wrong position' do
        let(:node) { root_node.children[0] }

        it_behaves_like 'nonmatching'
      end
    end
  end

  describe 'funcalls' do
    module RuboCop # rubocop:disable Lint/ConstantDefinitionInBlock
      module AST
        # Add test function calls
        class NodePattern
          def goodmatch(_foo)
            true
          end

          def badmatch(_foo)
            false
          end

          def witharg(foo, bar)
            foo == bar
          end

          def withargs(foo, bar, qux)
            foo.between?(bar, qux)
          end
        end
      end
    end

    context 'without extra arguments' do
      let(:pattern) { '(lvasgn #goodmatch ...)' }
      let(:ruby) { 'a = 1' }

      it { expect(pattern).to match_code(node) }
    end

    context 'with one argument' do
      let(:pattern) { '(str #witharg(%1))' }
      let(:ruby) { '"foo"' }
      let(:params) { %w[foo] }

      it { expect(pattern).to match_code(node, 'foo') }
    end

    context 'with multiple arguments' do
      let(:pattern) { '(str #withargs(%1, %2))' }
      let(:ruby) { '"c"' }
      let(:params) { %w[a d] }

      it { expect(pattern).to match_code(node, 'a', 'd') }
    end
  end

  describe 'commas' do
    context 'with commas randomly strewn around' do
      let(:pattern) { ',,(,send,, ,int,:+, int ), ' }

      it_behaves_like 'invalid'
    end
  end

  describe 'in any order' do
    let(:ruby) { '[:hello, "world", 1, 2, 3]' }

    context 'without ellipsis' do
      context 'with matching children' do
        let(:pattern) { '(array <(str $_) (int 1) (int 3) (int $_) $_>)' }

        let(:captured_vals) { ['world', 2, s(:sym, :hello)] }

        it_behaves_like 'multiple capture'
      end

      context 'with too many children' do
        let(:pattern) { '(array <(str $_) (int 1) (int 3) (int $_)>)' }

        it_behaves_like 'nonmatching'
      end

      context 'with too few children' do
        let(:pattern) { '(array <(str $_) (int 1) (int 3) (int $_) _ _>)' }

        it_behaves_like 'nonmatching'
      end
    end

    context 'with a captured ellipsis' do
      context 'matching non sequential children' do
        let(:pattern) { '(array <(str "world") (int 2) $...>)' }

        let(:captured_val) { [s(:sym, :hello), s(:int, 1), s(:int, 3)] }

        it_behaves_like 'single capture'
      end

      context 'matching all children' do
        let(:pattern) { '(array <(str "world") (int 2) _ _ _ $...>)' }

        let(:captured_val) { [] }

        it_behaves_like 'single capture'
      end

      context 'nested' do
        let(:ruby) { '[:x, 1, [:y, 2, 3], 42]' }
        let(:pattern) { '(array <(int $_) (array <(int $_) $...>) $...>)' }

        let(:captured_vals) do
          [1, 2, [s(:sym, :y), s(:int, 3)],
           [s(:sym, :x), s(:int, 42)]]
        end

        it_behaves_like 'multiple capture'
      end
    end

    context 'with an ellipsis' do
      let(:pattern) { '(array <(str "world") (int 2) ...> $_)' }

      let(:captured_val) { s(:int, 3) }

      it_behaves_like 'single capture'
    end

    context 'captured' do
      context 'without ellipsis' do
        let(:pattern) { '(array sym $<int int _ _>)' }
        let(:captured_val) { node.children.last(4) }

        it_behaves_like 'single capture'
      end
    end

    context 'doubled' do
      context 'separated by fixed argument' do
        let(:pattern) { '(array <(str $_) (sym $_)> $_ <(int 3) (int $_)>)' }

        let(:captured_vals) { ['world', :hello, s(:int, 1), 2] }

        it_behaves_like 'multiple capture'
      end

      context 'separated by an ellipsis' do
        let(:pattern) { '(array <(str $_) (sym $_)> $... <(int 3) (int $_)>)' }

        let(:captured_vals) { ['world', :hello, [s(:int, 1)], 2] }

        it_behaves_like 'multiple capture'
      end
    end

    describe 'invalid' do
      context 'at the beginning of a sequence' do
        let(:pattern) { '(<(str $_) (sym $_)> ...)' }

        it_behaves_like 'invalid'
      end

      context 'containing ellipsis not at the end' do
        let(:pattern) { '(array <(str $_) ... (sym $_)>)' }

        it_behaves_like 'invalid'
      end

      context 'with an ellipsis inside and outside' do
        let(:pattern) { '(array <(str $_) (sym $_) ...> ...)' }
        let(:captured_vals) { ['world', :hello] }

        it_behaves_like 'multiple capture'
      end

      context 'doubled with ellipsis' do
        let(:pattern) { '(array <(sym $_) ...> <(int $_) ...>)' }
        let(:captured_vals) { [:hello, 3] }

        it_behaves_like 'multiple capture'
      end

      context 'doubled with ellipsis in wrong order' do
        let(:pattern) { '(array <(int $_) ...> <(sym $_) ...>)' }

        it_behaves_like 'nonmatching'
      end

      context 'nested' do
        let(:pattern) { '(array <(str $_) <int sym>> ...)' }

        it_behaves_like 'invalid'
      end
    end
  end

  describe 'repeated' do
    let(:ruby) { '[:hello, 1, 2, 3]' }

    shared_examples 'repeated pattern' do
      context 'with one match' do
        let(:pattern) { "(array sym int $int #{symbol} int)" }

        let(:captured_val) { [s(:int, 2)] }

        it_behaves_like 'single capture'
      end

      context 'at beginning of sequence' do
        let(:pattern) { "(int #{symbol} int)" }

        it_behaves_like 'invalid'
      end

      context 'with an ellipsis in the same sequence' do
        let(:pattern) { "(array sym #{symbol} ...)" }

        it { expect(pattern).to match_code(ruby) }
      end
    end

    context 'using *' do
      let(:symbol) { :* }

      it_behaves_like 'repeated pattern'

      context 'without capture' do
        let(:pattern) { '(array sym int* int)' }

        it { expect(pattern).to match_code(node) }
      end

      context 'with matching children' do
        let(:pattern) { '(array sym $int* int)' }

        let(:captured_val) { [s(:int, 1), s(:int, 2)] }

        it_behaves_like 'single capture'
      end

      context 'with zero match' do
        let(:pattern) { '(array sym int int $sym* int)' }

        let(:captured_val) { [] }

        it_behaves_like 'single capture'
      end

      context 'with no match' do
        let(:pattern) { '(array sym int $sym* int)' }

        it_behaves_like 'nonmatching'
      end

      context 'with multiple subcaptures' do
        let(:pattern) { '(array ($_ $_)* int int)' }

        let(:captured_vals) { [%i[sym int], [:hello, 1]] }

        it_behaves_like 'multiple capture'
      end

      context 'nested with multiple subcaptures' do
        let(:ruby) { '[[:hello, 1, 2, 3], [:world, 3, 4]]' }
        let(:pattern) { '(array (array (sym $_) (int $_)*)*)' }

        let(:captured_vals) { [%i[hello world], [[1, 2, 3], [3, 4]]] }

        it_behaves_like 'multiple capture'
      end
    end

    context 'using +' do
      let(:symbol) { :+ }

      it_behaves_like 'repeated pattern'

      context 'with matching children' do
        let(:pattern) { '(array sym $int+ int)' }

        let(:captured_val) { [s(:int, 1), s(:int, 2)] }

        it_behaves_like 'single capture'
      end

      context 'with zero match' do
        let(:pattern) { '(array sym int int $sym+ int)' }

        it_behaves_like 'nonmatching'
      end
    end

    context 'using ?' do
      let(:symbol) { '?' }

      it_behaves_like 'repeated pattern'

      context 'with too many matching children' do
        let(:pattern) { '(array sym $int ? int)' }

        let(:captured_val) { [s(:int, 1), s(:int, 2)] }

        it_behaves_like 'nonmatching'
      end

      context 'with zero match' do
        let(:pattern) { '(array sym int int $(sym _)? int)' }

        let(:captured_val) { [] }

        it_behaves_like 'single capture'
      end
    end
  end

  describe 'descend' do
    let(:ruby) { '[1, [[2, 3, [[5]]], 4]]' }

    context 'with an immediate match' do
      let(:pattern) { '(array `$int _)' }

      let(:captured_val) { s(:int, 1) }

      it_behaves_like 'single capture'
    end

    context 'with a match multiple levels, depth first' do
      let(:pattern) { '(array (int 1) `$int)' }

      let(:captured_val) { s(:int, 2) }

      it_behaves_like 'single capture'
    end

    context 'nested' do
      let(:pattern) { '(array (int 1) `(array <`(array $int) ...>))' }

      let(:captured_val) { s(:int, 5) }

      it_behaves_like 'single capture'
    end

    context 'with a literal match' do
      let(:pattern) { '(array (int 1) `4)' }

      it { expect(pattern).to match_code(node) }
    end

    context 'without match' do
      let(:pattern) { '(array `$str ...)' }

      it_behaves_like 'nonmatching'
    end
  end

  describe 'regexp' do
    it 'matches symbols or strings' do
      expect('(_ _ $/abc|def|foo/i ...)').to match_codes(
        'Foo(42)', 'foo(42)'
      ).and not_match_codes(
        'bar(42)'
      )
    end
  end

  describe 'bad syntax' do
    context 'with empty parentheses' do
      let(:pattern) { '()' }

      it_behaves_like 'invalid'
    end

    context 'with empty union' do
      let(:pattern) { '{}' }

      it_behaves_like 'invalid'
    end

    context 'with empty union subsequence in seq head' do
      let(:pattern) { '({foo|})' }

      it_behaves_like 'invalid'
    end

    context 'with unsupported subsequence in seq head within union' do
      let(:pattern) { '({foo bar+})' }

      it_behaves_like 'invalid'
    end

    context 'with variadic unions where not supported' do
      let(:pattern) { '(_ [_ {foo | ...}])' }

      it_behaves_like 'invalid'
    end

    context 'with empty intersection' do
      let(:pattern) { '[]' }

      it_behaves_like 'invalid'
    end

    context 'with unmatched opening paren' do
      let(:pattern) { '(send (const)' }

      it_behaves_like 'invalid'
    end

    context 'with unmatched opening paren and `...`' do
      let(:pattern) { '(send ...' }

      it_behaves_like 'invalid'
    end

    context 'with unmatched closing paren' do
      let(:pattern) { '(send (const)))' }

      it_behaves_like 'invalid'
    end

    context 'with unmatched opening curly' do
      let(:pattern) { '{send const' }

      it_behaves_like 'invalid'
    end

    context 'with unmatched closing curly' do
      let(:pattern) { '{send const}}' }

      it_behaves_like 'invalid'
    end

    context 'with negated closing paren' do
      let(:pattern) { '(send (const) !)' }

      it_behaves_like 'invalid'
    end

    context 'with negated closing curly' do
      let(:pattern) { '{send const !}' }

      it_behaves_like 'invalid'
    end

    context 'with negated ellipsis' do
      let(:pattern) { '(send !...)' }

      it_behaves_like 'invalid'
    end

    context 'with doubled ellipsis' do
      let(:ruby) { 'foo' }
      let(:pattern) { '(send ... ...)' }

      it { expect(pattern).to match_code(ruby) } # yet silly
    end

    context 'with doubled comma in arg list' do
      let(:pattern) { '(send #func(:foo, ,:bar))' }

      it_behaves_like 'invalid'
    end

    context 'with leading comma in arg list' do
      let(:pattern) { '(send #func(, :foo))' }

      it_behaves_like 'invalid'
    end
  end

  describe 'comments' do
    let(:pattern) { "(int # We want an int\n$_) # Let's capture the value" }
    let(:ruby) { '42' }
    let(:captured_val) { 42 }

    it_behaves_like 'single capture'
  end

  describe '.descend' do
    let(:ruby) { '[[1, 2], 3]' }

    it 'yields all children depth first' do
      e = described_class.descend(node)
      expect(e).to be_an_instance_of(Enumerator)
      array, three = node.children
      one, two = array.children
      expect(e.to_a).to eq([node, array, one, 1, two, 2, three, 3])
    end

    it 'yields the given argument if it is not a Node' do
      expect(described_class.descend(42).to_a).to eq([42])
    end
  end

  context 'macros' do
    include RuboCop::AST::Sexp

    subject(:result) do
      if keyword_params.empty? # Avoid bug in Ruby < 2.7
        defined_class.new.send(method_name, node, *params)
      else
        defined_class.new.send(method_name, node, *params, **keyword_params)
      end
    end

    before do
      stub_const('MyClass', Class.new do
        extend RuboCop::AST::NodePattern::Macros
      end)
    end

    let(:keyword_defaults) { {} }
    let(:method_name) { :my_matcher }
    let(:line_no) { __LINE__ + 1 }
    let(:call_helper) { MyClass.public_send helper_name, method_name, pattern, **keyword_defaults }
    let(:defined_class) do
      call_helper
      MyClass
    end
    let(:ruby) { ':hello' }
    let(:instance) { defined_class.new }

    let(:raise_argument_error) do
      raise_error do |err|
        expect(err).to be_a(ArgumentError)
        expect(err.message).to include('wrong number of arguments')
        expect(err.backtrace_locations.first.lineno).to be(line_no) if RUBY_ENGINE == 'ruby'
      end
    end

    context 'with a pattern without captures' do
      let(:pattern) { '(sym _)' }

      context 'def_node_matcher' do
        let(:helper_name) { :def_node_matcher }

        it 'returns the method name' do
          expect(call_helper).to eq method_name
        end

        context 'when called on matching code' do
          it { expect(instance).to match_code(node) }
        end

        context 'when called on non-matching code' do
          let(:ruby) { '"world"' }

          it_behaves_like 'nonmatching'
        end

        context 'when it errors' do
          let(:params) { [:extra] }

          it 'raises an error with the right location' do
            expect { result }.to(raise_argument_error)
          end
        end
      end

      context 'def_node_search' do
        let(:helper_name) { :def_node_search }
        let(:ruby) { 'foo(:hello, :world)' }

        it 'returns the method name' do
          expect(call_helper).to eq method_name
        end

        context('without a predicate name') do
          context 'when called on matching code' do
            it 'returns an enumerator yielding the matches' do
              is_expected.to be_a(Enumerator)
              expect(result.to_a).to match_array [s(:sym, :hello), s(:sym, :world)]
            end
          end

          context 'when called on non-matching code' do
            let(:ruby) { 'foo("hello", "world")' }

            it 'returns an enumerator yielding nothing' do
              is_expected.to be_a(Enumerator)
              expect(result.to_a).to eq []
            end
          end

          context 'when it errors' do
            let(:params) { [:extra] }

            it 'raises an error with the right location' do
              expect { result }.to(raise_argument_error)
            end
          end
        end

        context('with a predicate name') do
          let(:method_name) { :my_matcher? }

          context 'when called on matching code' do
            it { expect(instance).to match_code(node) }
          end

          context 'when called on non-matching code' do
            let(:ruby) { '"world"' }

            it_behaves_like 'nonmatching'
          end

          context 'when it errors' do
            let(:params) { [:extra] }

            it 'raises an error with the right location' do
              expect { result }.to(raise_argument_error)
            end
          end
        end
      end
    end

    context 'with a pattern with captures' do
      let(:pattern) { '(sym $_)' }

      context 'def_node_matcher' do
        let(:helper_name) { :def_node_matcher }

        context 'when called on matching code' do
          it { is_expected.to eq :hello }
        end

        context 'when called on non-matching code' do
          let(:ruby) { '"world"' }

          it_behaves_like 'nonmatching'
        end

        context 'when it errors' do
          let(:params) { [:extra] }

          it 'raises an error with the right location' do
            expect { result }.to(raise_argument_error)
          end
        end
      end

      context 'def_node_search' do
        let(:helper_name) { :def_node_search }
        let(:ruby) { 'foo(:hello, :world)' }

        context('without a predicate name') do
          context 'when called on matching code' do
            it 'returns an enumerator yielding the captures' do
              is_expected.to be_a(Enumerator)
              expect(result.to_a).to match_array %i[hello world]
            end

            context 'when the pattern contains keyword_params' do
              let(:pattern) { '(sym $%foo)' }
              let(:keyword_params) { { foo: Set[:hello, :foo] } }

              it 'returns an enumerator yielding the captures' do
                is_expected.to be_a(Enumerator)
                expect(result.to_a).to match_array %i[hello]
              end

              # rubocop:disable RSpec/NestedGroups
              context 'when helper is called with default keyword_params' do
                let(:keyword_defaults) { { foo: :world } }

                it 'is overridden when calling the matcher' do
                  is_expected.to be_a(Enumerator)
                  expect(result.to_a).to match_array %i[hello]
                end

                context 'and no value is given to the matcher' do
                  let(:keyword_params) { {} }

                  it 'uses the defaults' do
                    is_expected.to be_a(Enumerator)
                    expect(result.to_a).to match_array %i[world]
                  end
                end

                context 'some defaults are not params' do
                  let(:keyword_defaults) { { bar: :world } }

                  it 'raises an error' do
                    expect { result }.to raise_error(ArgumentError)
                  end
                end
              end
              # rubocop:enable RSpec/NestedGroups
            end
          end

          context 'when called on non-matching code' do
            let(:ruby) { 'foo("hello", "world")' }

            it 'returns an enumerator yielding nothing' do
              is_expected.to be_a(Enumerator)
              expect(result.to_a).to eq []
            end
          end

          context 'when it errors' do
            let(:params) { [:extra] }

            it 'raises an error with the right location' do
              expect { result }.to(raise_argument_error)
            end
          end
        end

        context('with a predicate name') do
          let(:method_name) { :my_matcher? }

          context 'when called on matching code' do
            it { expect(instance).to match_code(node) }
          end

          context 'when called on non-matching code' do
            let(:ruby) { '"world"' }

            it_behaves_like 'nonmatching'
          end

          context 'when it errors' do
            let(:params) { [:extra] }

            it 'raises an error with the right location' do
              expect { result }.to(raise_argument_error)
            end
          end
        end
      end
    end

    context 'with a pattern with a constant' do
      let(:pattern) { '(sym %TEST)' }
      let(:helper_name) { :def_node_matcher }

      before { defined_class::TEST = Set[:hello, :foo] }

      it { expect(instance).to match_code(node) }

      context 'when the value is not in the set' do
        let(:ruby) { ':world' }

        it_behaves_like 'nonmatching'
      end
    end

    context 'with a pattern with a namespaced call' do
      let(:pattern) { '(sym #MyMod.foo)' }
      let(:helper_name) { :def_node_matcher }

      before do
        mod = Module.new
        mod::MyMod = Module.new
        mod::MyMod.module_eval do
          def self.foo(val)
            val == :hello
          end
        end
        defined_class.include mod
      end

      it { expect(instance).to match_code(node) }

      context 'when the value is not in the set' do
        let(:ruby) { ':world' }

        it_behaves_like 'nonmatching'
      end
    end
  end
end
