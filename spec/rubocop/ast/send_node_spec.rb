# frozen_string_literal: true

RSpec.describe RuboCop::AST::SendNode do
  let(:send_node) { parse_source(source).node }

  describe '.new' do
    context 'with a regular method send' do
      let(:source) { 'foo.bar(:baz)' }

      it { expect(send_node).to be_a(described_class) }
    end

    context 'with a safe navigation method send' do
      let(:source) { 'foo&.bar(:baz)' }

      it { expect(send_node).to be_a(described_class) }
    end
  end

  describe '#receiver' do
    context 'with no receiver' do
      let(:source) { 'bar(:baz)' }

      it { expect(send_node.receiver).to be_nil }
    end

    context 'with a literal receiver' do
      let(:source) { "'foo'.bar(:baz)" }

      it { expect(send_node.receiver).to be_str_type }
    end

    context 'with a variable receiver' do
      let(:source) { 'foo.bar(:baz)' }

      it { expect(send_node.receiver).to be_send_type }
    end
  end

  describe '#method_name' do
    context 'with a plain method' do
      let(:source) { 'bar(:baz)' }

      it { expect(send_node.method_name).to eq(:bar) }
    end

    context 'with a setter method' do
      let(:source) { 'foo.bar = :baz' }

      it { expect(send_node.method_name).to eq(:bar=) }
    end

    context 'with an operator method' do
      let(:source) { 'foo == bar' }

      it { expect(send_node.method_name).to eq(:==) }
    end

    context 'with an implicit call method' do
      let(:source) { 'foo.(:baz)' }

      it { expect(send_node.method_name).to eq(:call) }
    end
  end

  describe '#method?' do
    context 'when message matches' do
      context 'when argument is a symbol' do
        let(:source) { 'bar(:baz)' }

        it { expect(send_node).to be_method(:bar) }
      end

      context 'when argument is a string' do
        let(:source) { 'bar(:baz)' }

        it { expect(send_node).to be_method('bar') }
      end
    end

    context 'when message does not match' do
      context 'when argument is a symbol' do
        let(:source) { 'bar(:baz)' }

        it { expect(send_node).not_to be_method(:foo) }
      end

      context 'when argument is a string' do
        let(:source) { 'bar(:baz)' }

        it { expect(send_node).not_to be_method('foo') }
      end
    end
  end

  describe '#access_modifier?' do
    context 'when node is a bare `module_function`' do
      let(:source) do
        <<~RUBY
          module Foo
          >> module_function <<
          end
        RUBY
      end

      it { expect(send_node).to be_access_modifier }
    end

    context 'when node is a non-bare `module_function`' do
      let(:source) do
        <<~RUBY
          module Foo
          >> module_function :foo <<
          end
        RUBY
      end

      it { expect(send_node).to be_access_modifier }
    end

    context 'when node is a non-bare `module_function` with multiple arguments' do
      let(:source) do
        <<~RUBY
          module Foo
          >> module_function :foo, :bar <<
          end
        RUBY
      end

      it { expect(send_node).to be_access_modifier }
    end

    context 'when node is not an access modifier' do
      let(:source) do
        <<~RUBY
          module Foo
            >> some_command <<
          end
        RUBY
      end

      it { expect(send_node).not_to be_bare_access_modifier }
    end
  end

  describe '#bare_access_modifier?' do
    context 'when node is a bare `module_function`' do
      let(:source) do
        <<~RUBY
          module Foo
          >> module_function <<
          end
        RUBY
      end

      it { expect(send_node).to be_bare_access_modifier }
    end

    context 'when node has an argument' do
      let(:source) do
        <<~RUBY
          module Foo
          >> private :foo <<
          end
        RUBY
      end

      it { expect(send_node).not_to be_bare_access_modifier }
    end

    context 'when node is not an access modifier' do
      let(:source) do
        <<~RUBY
          module Foo
          >> some_command <<
          end
        RUBY
      end

      it { expect(send_node).not_to be_bare_access_modifier }
    end

    context 'with Ruby >= 2.7', :ruby27 do
      context 'when node is access modifier in block' do
        let(:source) do
          <<~RUBY
            included do
            >> module_function <<
            end
          RUBY
        end

        it { expect(send_node).to be_bare_access_modifier }
      end

      context 'when node is access modifier in numblock' do
        let(:source) do
          <<~RUBY
            included do
            _1
            >> module_function <<
            end
          RUBY
        end

        it { expect(send_node).to be_bare_access_modifier }
      end
    end
  end

  describe '#non_bare_access_modifier?' do
    context 'when node is a non-bare `module_function`' do
      let(:source) do
        <<~RUBY
          module Foo
          >> module_function :foo <<
          end
        RUBY
      end

      it { expect(send_node).to be_non_bare_access_modifier }
    end

    context 'when node is a non-bare `module_function` with multiple arguments' do
      let(:source) do
        <<~RUBY
          module Foo
          >> module_function :foo, :bar <<
          end
        RUBY
      end

      it { expect(send_node).to be_non_bare_access_modifier }
    end

    context 'when node does not have an argument' do
      let(:source) do
        <<~RUBY
          module Foo
          >> private <<
          end
        RUBY
      end

      it { expect(send_node).not_to be_non_bare_access_modifier }
    end

    context 'when node is not an access modifier' do
      let(:source) do
        <<~RUBY
          module Foo
          >> some_command <<
          end
        RUBY
      end

      it { expect(send_node).not_to be_non_bare_access_modifier }
    end
  end

  describe '#macro?' do
    context 'without a receiver' do
      context 'when parent is a class' do
        let(:source) do
          ['class Foo',
           '>>bar :baz<<',
           '  bar :qux',
           'end'].join("\n")
        end

        it { expect(send_node).to be_macro }
      end

      context 'when parent is a module' do
        let(:source) do
          ['module Foo',
           '>>bar :baz<<',
           '  bar :qux',
           'end'].join("\n")
        end

        it { expect(send_node).to be_macro }
      end

      context 'when parent is a class constructor' do
        let(:source) do
          ['Module.new do',
           '>>bar :baz<<',
           '  bar :qux',
           'end'].join("\n")
        end

        it { expect(send_node).to be_macro }
      end

      context 'when parent is a struct constructor' do
        let(:source) do
          ['Foo = Struct.new do',
           '>>bar :baz<<',
           '  bar :qux',
           'end'].join("\n")
        end

        it { expect(send_node).to be_macro }
      end

      context 'when parent is a singleton class' do
        let(:source) do
          ['class << self',
           '>>bar :baz<<',
           '  bar :qux',
           'end'].join("\n")
        end

        it { expect(send_node).to be_macro }
      end

      context 'when parent is a block in a macro scope' do
        let(:source) do
          ['concern :Auth do',
           '>>bar :baz<<',
           '  bar :qux',
           'end'].join("\n")
        end

        it { expect(send_node).to be_macro }
      end

      context 'with Ruby >= 2.7', :ruby27 do
        context 'when parent is a numblock in a macro scope' do
          let(:source) do
            ['concern :Auth do',
             '>>bar :baz<<',
             '  bar _1',
             'end'].join("\n")
          end

          it { expect(send_node).to be_macro }
        end
      end

      context 'when parent is a block not in a macro scope' do
        let(:source) { <<~RUBY }
          class Foo
            def bar
              3.times do
                >>something :baz<<
                other
              end
            end
          end
        RUBY

        it { expect(send_node).not_to be_macro }
      end

      context 'when in the global scope' do
        let(:source) { <<~RUBY }
          >>something :baz<<
          other
        RUBY

        it { expect(send_node).to be_macro }
      end

      context 'when parent is a keyword begin inside of an class' do
        let(:source) do
          ['class Foo',
           '  begin',
           '>>  bar :qux <<',
           '  end',
           'end'].join("\n")
        end

        it { expect(send_node).to be_macro }
      end

      context 'without a parent' do
        let(:source) { 'bar :baz' }

        it { expect(send_node).to be_macro }
      end

      context 'when parent is a begin without a parent' do
        let(:source) do
          ['begin',
           '>>bar :qux<<',
           'end'].join("\n")
        end

        it { expect(send_node).to be_macro }
      end

      context 'when parent is a method definition' do
        let(:source) do
          ['def foo',
           '>>bar :baz<<',
           'end'].join("\n")
        end

        it { expect(send_node).not_to be_macro }
      end

      context 'when in an if' do
        let(:source) { <<~RUBY }
          >>bar :baz<< if qux
          other
        RUBY

        it { expect(send_node).to be_macro }
      end

      context 'when the condition of an if' do
        let(:source) { <<~RUBY }
          qux if >>bar :baz<<
          other
        RUBY

        it { expect(send_node).not_to be_macro }
      end
    end

    context 'with a receiver' do
      context 'when parent is a class' do
        let(:source) do
          ['class Foo',
           '  >> qux.bar :baz <<',
           'end'].join("\n")
        end

        it { expect(send_node).not_to be_macro }
      end

      context 'when parent is a module' do
        let(:source) do
          ['module Foo',
           '  >> qux.bar :baz << ',
           'end'].join("\n")
        end

        it { expect(send_node).not_to be_macro }
      end
    end
  end

  describe '#command?' do
    context 'when argument is a symbol' do
      context 'with an explicit receiver' do
        let(:source) { 'foo.bar(:baz)' }

        it { expect(send_node).not_to be_command(:bar) }
      end

      context 'with an implicit receiver' do
        let(:source) { 'bar(:baz)' }

        it { expect(send_node).to be_command(:bar) }
      end
    end

    context 'when argument is a string' do
      context 'with an explicit receiver' do
        let(:source) { 'foo.bar(:baz)' }

        it { expect(send_node).not_to be_command('bar') }
      end

      context 'with an implicit receiver' do
        let(:source) { 'bar(:baz)' }

        it { expect(send_node).to be_command('bar') }
      end
    end
  end

  describe '#arguments' do
    context 'with no arguments' do
      let(:source) { 'foo.bar' }

      it { expect(send_node.arguments).to be_empty }
    end

    context 'with a single literal argument' do
      let(:source) { 'foo.bar(:baz)' }

      it { expect(send_node.arguments.size).to eq(1) }
    end

    context 'with a single splat argument' do
      let(:source) { 'foo.bar(*baz)' }

      it { expect(send_node.arguments.size).to eq(1) }
    end

    context 'with multiple literal arguments' do
      let(:source) { 'foo.bar(:baz, :qux)' }

      it { expect(send_node.arguments.size).to eq(2) }
    end

    context 'with multiple mixed arguments' do
      let(:source) { 'foo.bar(:baz, *qux)' }

      it { expect(send_node.arguments.size).to eq(2) }
    end
  end

  describe '#first_argument' do
    context 'with no arguments' do
      let(:source) { 'foo.bar' }

      it { expect(send_node.first_argument).to be_nil }
    end

    context 'with a single literal argument' do
      let(:source) { 'foo.bar(:baz)' }

      it { expect(send_node.first_argument).to be_sym_type }
    end

    context 'with a single splat argument' do
      let(:source) { 'foo.bar(*baz)' }

      it { expect(send_node.first_argument).to be_splat_type }
    end

    context 'with multiple literal arguments' do
      let(:source) { 'foo.bar(:baz, :qux)' }

      it { expect(send_node.first_argument).to be_sym_type }
    end

    context 'with multiple mixed arguments' do
      let(:source) { 'foo.bar(:baz, *qux)' }

      it { expect(send_node.first_argument).to be_sym_type }
    end
  end

  describe '#last_argument' do
    context 'with no arguments' do
      let(:source) { 'foo.bar' }

      it { expect(send_node.last_argument).to be_nil }
    end

    context 'with a single literal argument' do
      let(:source) { 'foo.bar(:baz)' }

      it { expect(send_node.last_argument).to be_sym_type }
    end

    context 'with a single splat argument' do
      let(:source) { 'foo.bar(*baz)' }

      it { expect(send_node.last_argument).to be_splat_type }
    end

    context 'with multiple literal arguments' do
      let(:source) { 'foo.bar(:baz, :qux)' }

      it { expect(send_node.last_argument).to be_sym_type }
    end

    context 'with multiple mixed arguments' do
      let(:source) { 'foo.bar(:baz, *qux)' }

      it { expect(send_node.last_argument).to be_splat_type }
    end
  end

  describe '#arguments?' do
    context 'with no arguments' do
      let(:source) { 'foo.bar' }

      it { expect(send_node).not_to be_arguments }
    end

    context 'with a single literal argument' do
      let(:source) { 'foo.bar(:baz)' }

      it { expect(send_node).to be_arguments }
    end

    context 'with a single splat argument' do
      let(:source) { 'foo.bar(*baz)' }

      it { expect(send_node).to be_arguments }
    end

    context 'with multiple literal arguments' do
      let(:source) { 'foo.bar(:baz, :qux)' }

      it { expect(send_node).to be_arguments }
    end

    context 'with multiple mixed arguments' do
      let(:source) { 'foo.bar(:baz, *qux)' }

      it { expect(send_node).to be_arguments }
    end
  end

  describe '#parenthesized?' do
    context 'with no arguments' do
      context 'when not using parentheses' do
        let(:source) { 'foo.bar' }

        it { expect(send_node).not_to be_parenthesized }
      end

      context 'when using parentheses' do
        let(:source) { 'foo.bar()' }

        it { expect(send_node).to be_parenthesized }
      end
    end

    context 'with arguments' do
      context 'when not using parentheses' do
        let(:source) { 'foo.bar :baz' }

        it { expect(send_node).not_to be_parenthesized }
      end

      context 'when using parentheses' do
        let(:source) { 'foo.bar(:baz)' }

        it { expect(send_node).to be_parenthesized }
      end
    end
  end

  describe '#setter_method?' do
    context 'with a setter method' do
      let(:source) { 'foo.bar = :baz' }

      it { expect(send_node).to be_setter_method }
    end

    context 'with an indexed setter method' do
      let(:source) { 'foo.bar[:baz] = :qux' }

      it { expect(send_node).to be_setter_method }
    end

    context 'with an operator method' do
      let(:source) { 'foo.bar + 1' }

      it { expect(send_node).not_to be_setter_method }
    end

    context 'with a regular method' do
      let(:source) { 'foo.bar(:baz)' }

      it { expect(send_node).not_to be_setter_method }
    end
  end

  describe '#operator_method?' do
    context 'with a binary operator method' do
      let(:source) { 'foo.bar + :baz' }

      it { expect(send_node).to be_operator_method }
    end

    context 'with a unary operator method' do
      let(:source) { '!foo.bar' }

      it { expect(send_node).to be_operator_method }
    end

    context 'with a setter method' do
      let(:source) { 'foo.bar = :baz' }

      it { expect(send_node).not_to be_operator_method }
    end

    context 'with a regular method' do
      let(:source) { 'foo.bar(:baz)' }

      it { expect(send_node).not_to be_operator_method }
    end
  end

  describe '#nonmutating_binary_operator_method?' do
    context 'with a nonmutating binary operator method' do
      let(:source) { 'foo + bar' }

      it { expect(send_node).to be_nonmutating_binary_operator_method }
    end

    context 'with a mutating binary operator method' do
      let(:source) { 'foo << bar' }

      it { expect(send_node).not_to be_nonmutating_binary_operator_method }
    end

    context 'with a regular method' do
      let(:source) { 'foo.bar(:baz)' }

      it { expect(send_node).not_to be_nonmutating_binary_operator_method }
    end
  end

  describe '#nonmutating_unary_operator_method?' do
    context 'with a nonmutating unary operator method' do
      let(:source) { '!foo' }

      it { expect(send_node).to be_nonmutating_unary_operator_method }
    end

    context 'with a regular method' do
      let(:source) { 'foo.bar(:baz)' }

      it { expect(send_node).not_to be_nonmutating_unary_operator_method }
    end
  end

  describe '#nonmutating_operator_method?' do
    context 'with a nonmutating binary operator method' do
      let(:source) { 'foo + bar' }

      it { expect(send_node).to be_nonmutating_operator_method }
    end

    context 'with a nonmutating unary operator method' do
      let(:source) { '!foo' }

      it { expect(send_node).to be_nonmutating_operator_method }
    end

    context 'with a mutating binary operator method' do
      let(:source) { 'foo << bar' }

      it { expect(send_node).not_to be_nonmutating_operator_method }
    end

    context 'with a regular method' do
      let(:source) { 'foo.bar(:baz)' }

      it { expect(send_node).not_to be_nonmutating_operator_method }
    end
  end

  describe '#nonmutating_array_method?' do
    context 'with a nonmutating Array method' do
      let(:source) { 'array.reverse' }

      it { expect(send_node).to be_nonmutating_array_method }
    end

    context 'with a mutating Array method' do
      let(:source) { 'array.push(foo)' }

      it { expect(send_node).not_to be_nonmutating_array_method }
    end

    context 'with a regular method' do
      let(:source) { 'foo.bar(:baz)' }

      it { expect(send_node).not_to be_nonmutating_array_method }
    end
  end

  describe '#nonmutating_hash_method?' do
    context 'with a nonmutating Hash method' do
      let(:source) { 'hash.slice(:foo, :bar)' }

      it { expect(send_node).to be_nonmutating_hash_method }
    end

    context 'with a mutating Hash method' do
      let(:source) { 'hash.delete(:foo)' }

      it { expect(send_node).not_to be_nonmutating_hash_method }
    end

    context 'with a regular method' do
      let(:source) { 'foo.bar(:baz)' }

      it { expect(send_node).not_to be_nonmutating_hash_method }
    end
  end

  describe '#nonmutating_string_method?' do
    context 'with a nonmutating String method' do
      let(:source) { 'string.squeeze' }

      it { expect(send_node).to be_nonmutating_string_method }
    end

    context 'with a mutating String method' do
      let(:source) { 'string.lstrip!' }

      it { expect(send_node).not_to be_nonmutating_string_method }
    end

    context 'with a regular method' do
      let(:source) { 'foo.bar(:baz)' }

      it { expect(send_node).not_to be_nonmutating_string_method }
    end
  end

  describe '#comparison_method?' do
    context 'with a comparison method' do
      let(:source) { 'foo.bar >= :baz' }

      it { expect(send_node).to be_comparison_method }
    end

    context 'with a regular method' do
      let(:source) { 'foo.bar(:baz)' }

      it { expect(send_node).not_to be_comparison_method }
    end

    context 'with a negation method' do
      let(:source) { '!foo' }

      it { expect(send_node).not_to be_comparison_method }
    end
  end

  describe '#assignment_method?' do
    context 'with an assignment method' do
      let(:source) { 'foo.bar = :baz' }

      it { expect(send_node).to be_assignment_method }
    end

    context 'with a bracket assignment method' do
      let(:source) { 'foo.bar[:baz] = :qux' }

      it { expect(send_node).to be_assignment_method }
    end

    context 'with a comparison method' do
      let(:source) { 'foo.bar == :qux' }

      it { expect(send_node).not_to be_assignment_method }
    end

    context 'with a regular method' do
      let(:source) { 'foo.bar(:baz)' }

      it { expect(send_node).not_to be_assignment_method }
    end
  end

  describe '#enumerable_method?' do
    context 'with an enumerable method' do
      let(:source) { '>> foo.all? << { |e| bar?(e) }' }

      it { expect(send_node).to be_enumerable_method }
    end

    context 'with a regular method' do
      let(:source) { 'foo.bar(:baz)' }

      it { expect(send_node).not_to be_enumerable_method }
    end
  end

  describe '#attribute_accessor?' do
    context 'with an accessor' do
      let(:source) { 'attr_reader :foo, bar, *baz' }

      it 'returns the accessor method and Array<accessors>]' do
        expect(send_node.attribute_accessor?).to contain_exactly(
          :attr_reader,
          contain_exactly(
            be_sym_type,
            be_send_type,
            be_splat_type
          )
        )
      end

      context 'with a call without arguments' do
        let(:source) { 'attr_reader' }

        it do
          expect(send_node.attribute_accessor?).to be_nil
        end
      end
    end
  end

  describe '#dot?' do
    context 'with a dot' do
      let(:source) { 'foo.+ 1' }

      it { expect(send_node).to be_dot }
    end

    context 'without a dot' do
      let(:source) { 'foo + 1' }

      it { expect(send_node).not_to be_dot }
    end

    context 'with a double colon' do
      let(:source) { 'Foo::bar' }

      it { expect(send_node).not_to be_dot }
    end

    context 'with a unary method' do
      let(:source) { '!foo.bar' }

      it { expect(send_node).not_to be_dot }
    end
  end

  describe '#double_colon?' do
    context 'with a double colon' do
      let(:source) { 'Foo::bar' }

      it { expect(send_node).to be_double_colon }
    end

    context 'with a dot' do
      let(:source) { 'foo.+ 1' }

      it { expect(send_node).not_to be_double_colon }
    end

    context 'without a dot' do
      let(:source) { 'foo + 1' }

      it { expect(send_node).not_to be_double_colon }
    end

    context 'with a unary method' do
      let(:source) { '!foo.bar' }

      it { expect(send_node).not_to be_double_colon }
    end
  end

  describe '#self_receiver?' do
    context 'with a self receiver' do
      let(:source) { 'self.bar' }

      it { expect(send_node).to be_self_receiver }
    end

    context 'with a non-self receiver' do
      let(:source) { 'foo.bar' }

      it { expect(send_node).not_to be_self_receiver }
    end

    context 'with an implicit receiver' do
      let(:source) { 'bar' }

      it { expect(send_node).not_to be_self_receiver }
    end
  end

  describe '#const_receiver?' do
    context 'with a self receiver' do
      let(:source) { 'self.bar' }

      it { expect(send_node).not_to be_const_receiver }
    end

    context 'with a non-constant receiver' do
      let(:source) { 'foo.bar' }

      it { expect(send_node).not_to be_const_receiver }
    end

    context 'with a constant receiver' do
      let(:source) { 'Foo.bar' }

      it { expect(send_node).to be_const_receiver }
    end
  end

  describe '#implicit_call?' do
    context 'with an implicit call method' do
      let(:source) { 'foo.(:bar)' }

      it { expect(send_node).to be_implicit_call }
    end

    context 'with an explicit call method' do
      let(:source) { 'foo.call(:bar)' }

      it { expect(send_node).not_to be_implicit_call }
    end

    context 'with a regular method' do
      let(:source) { 'foo.bar' }

      it { expect(send_node).not_to be_implicit_call }
    end
  end

  describe '#predicate_method?' do
    context 'with a predicate method' do
      let(:source) { 'foo.bar?' }

      it { expect(send_node).to be_predicate_method }
    end

    context 'with a bang method' do
      let(:source) { 'foo.bar!' }

      it { expect(send_node).not_to be_predicate_method }
    end

    context 'with a regular method' do
      let(:source) { 'foo.bar' }

      it { expect(send_node).not_to be_predicate_method }
    end
  end

  describe '#bang_method?' do
    context 'with a bang method' do
      let(:source) { 'foo.bar!' }

      it { expect(send_node).to be_bang_method }
    end

    context 'with a predicate method' do
      let(:source) { 'foo.bar?' }

      it { expect(send_node).not_to be_bang_method }
    end

    context 'with a regular method' do
      let(:source) { 'foo.bar' }

      it { expect(send_node).not_to be_bang_method }
    end
  end

  describe '#camel_case_method?' do
    context 'with a camel case method' do
      let(:source) { 'Integer(1.0)' }

      it { expect(send_node).to be_camel_case_method }
    end

    context 'with a regular method' do
      let(:source) { 'integer(1.0)' }

      it { expect(send_node).not_to be_camel_case_method }
    end
  end

  describe '#block_argument?' do
    context 'with a block argument' do
      let(:source) { 'foo.bar(&baz)' }

      it { expect(send_node).to be_block_argument }
    end

    context 'with no arguments' do
      let(:source) { 'foo.bar' }

      it { expect(send_node).not_to be_block_argument }
    end

    context 'with regular arguments' do
      let(:source) { 'foo.bar(:baz)' }

      it { expect(send_node).not_to be_block_argument }
    end

    context 'with mixed arguments' do
      let(:source) { 'foo.bar(:baz, &qux)' }

      it { expect(send_node).to be_block_argument }
    end
  end

  describe '#block_literal?' do
    context 'with a block literal' do
      let(:source) { '>> foo.bar << { |q| baz(q) }' }

      it { expect(send_node).to be_block_literal }
    end

    context 'with a block argument' do
      let(:source) { 'foo.bar(&baz)' }

      it { expect(send_node).not_to be_block_literal }
    end

    context 'with no block' do
      let(:source) { 'foo.bar' }

      it { expect(send_node).not_to be_block_literal }
    end

    context 'with Ruby >= 2.7', :ruby27 do
      context 'with a numblock literal' do
        let(:source) { '>> foo.bar << { baz(_1) }' }

        it { expect(send_node).to be_block_literal }
      end
    end
  end

  describe '#arithmetic_operation?' do
    context 'with a binary arithmetic operation' do
      let(:source) { 'foo + bar' }

      it { expect(send_node).to be_arithmetic_operation }
    end

    context 'with a unary numeric operation' do
      let(:source) { '+foo' }

      it { expect(send_node).not_to be_arithmetic_operation }
    end

    context 'with a regular method call' do
      let(:source) { 'foo.bar' }

      it { expect(send_node).not_to be_arithmetic_operation }
    end
  end

  describe '#block_node' do
    context 'with a block literal' do
      let(:source) { '>>foo.bar<< { |q| baz(q) }' }

      it { expect(send_node.block_node).to be_block_type }
    end

    context 'with a block argument' do
      let(:source) { 'foo.bar(&baz)' }

      it { expect(send_node.block_node).to be_nil }
    end

    context 'with no block' do
      let(:source) { 'foo.bar' }

      it { expect(send_node.block_node).to be_nil }
    end

    context 'with Ruby >= 2.7', :ruby27 do
      context 'with a numblock literal' do
        let(:source) { '>>foo.bar<< { baz(_1) }' }

        it { expect(send_node.block_node).to be_numblock_type }
      end
    end
  end

  describe '#splat_argument?' do
    context 'with a splat argument' do
      let(:source) { 'foo.bar(*baz)' }

      it { expect(send_node).to be_splat_argument }
    end

    context 'with no arguments' do
      let(:source) { 'foo.bar' }

      it { expect(send_node).not_to be_splat_argument }
    end

    context 'with regular arguments' do
      let(:source) { 'foo.bar(:baz)' }

      it { expect(send_node).not_to be_splat_argument }
    end

    context 'with mixed arguments' do
      let(:source) { 'foo.bar(:baz, *qux)' }

      it { expect(send_node).to be_splat_argument }
    end
  end

  describe '#def_modifier?' do
    context 'with a prefixed def modifier' do
      let(:source) { 'foo def bar; end' }

      it { expect(send_node).to be_def_modifier }
    end

    context 'with several prefixed def modifiers' do
      let(:source) { 'foo bar baz def qux; end' }

      it { expect(send_node).to be_def_modifier }
    end

    context 'with a block containing a method definition' do
      let(:source) { 'foo bar { baz def qux; end }' }

      it { expect(send_node).not_to be_def_modifier }
    end
  end

  describe '#def_modifier' do
    context 'with a prefixed def modifier' do
      let(:source) { 'foo def bar; end' }

      it { expect(send_node.def_modifier.method_name).to eq(:bar) }
    end

    context 'with several prefixed def modifiers' do
      let(:source) { 'foo bar baz def qux; end' }

      it { expect(send_node.def_modifier.method_name).to eq(:qux) }
    end

    context 'with a block containing a method definition' do
      let(:source) { 'foo bar { baz def qux; end }' }

      it { expect(send_node.def_modifier).to be_nil }
    end

    context 'with call with no argument' do
      let(:source) { 'foo' }

      it { expect(send_node.def_modifier).to be_nil }
    end
  end

  describe '#negation_method?' do
    context 'with prefix `not`' do
      let(:source) { 'not foo' }

      it { expect(send_node).to be_negation_method }
    end

    context 'with suffix `not`' do
      let(:source) { 'foo.not' }

      it { expect(send_node).not_to be_negation_method }
    end

    context 'with prefix bang' do
      let(:source) { '!foo' }

      it { expect(send_node).to be_negation_method }
    end

    context 'with a non-negated method' do
      let(:source) { 'foo.bar' }

      it { expect(send_node).not_to be_negation_method }
    end
  end

  describe '#prefix_not?' do
    context 'with keyword `not`' do
      let(:source) { 'not foo' }

      it { expect(send_node).to be_prefix_not }
    end

    context 'with a bang method' do
      let(:source) { '!foo' }

      it { expect(send_node).not_to be_prefix_not }
    end

    context 'with a non-negated method' do
      let(:source) { 'foo.bar' }

      it { expect(send_node).not_to be_prefix_not }
    end
  end

  describe '#prefix_bang?' do
    context 'with keyword `not`' do
      let(:source) { 'not foo' }

      it { expect(send_node).not_to be_prefix_bang }
    end

    context 'with a bang method' do
      let(:source) { '!foo' }

      it { expect(send_node).to be_prefix_bang }
    end

    context 'with a non-negated method' do
      let(:source) { 'foo.bar' }

      it { expect(send_node).not_to be_prefix_bang }
    end
  end

  describe '#lambda?' do
    context 'with a lambda method' do
      let(:source) { '>> lambda << { |foo| bar(foo) }' }

      it { expect(send_node).to be_lambda }
    end

    context 'with a method named lambda in a class' do
      let(:source) { '>> foo.lambda << { |bar| baz }' }

      it { expect(send_node).not_to be_lambda }
    end

    context 'with a stabby lambda method' do
      let(:source) { '>> -> << (foo) { do_something(foo) }' }

      it { expect(send_node).to be_lambda }
    end

    context 'with a non-lambda method' do
      let(:source) { 'foo.bar' }

      it { expect(send_node).not_to be_lambda }
    end
  end

  describe '#lambda_literal?' do
    context 'with a stabby lambda' do
      let(:source) { '>> -> << (foo) { do_something(foo) }' }

      it { expect(send_node).to be_lambda_literal }
    end

    context 'with a lambda method' do
      let(:source) { '>> lambda << { |foo| bar(foo) }' }

      it { expect(send_node).not_to be_lambda_literal }
    end

    context 'with a non-lambda method' do
      let(:source) { 'foo.bar' }

      it { expect(send_node).not_to be_lambda }
    end

    # Regression test https://github.com/rubocop/rubocop/pull/5194
    context 'with `a.() {}` style method' do
      let(:source) { '>>a.()<< {}' }

      it { expect(send_node).not_to be_lambda }
    end
  end

  describe '#unary_operation?' do
    context 'with a unary operation' do
      let(:source) { '-foo' }

      it { expect(send_node).to be_unary_operation }
    end

    context 'with a binary operation' do
      let(:source) { 'foo + bar' }

      it { expect(send_node).not_to be_unary_operation }
    end

    context 'with a regular method call' do
      let(:source) { 'foo(bar)' }

      it { expect(send_node).not_to be_unary_operation }
    end

    context 'with an implicit call method' do
      let(:source) { 'foo.(:baz)' }

      it { expect(send_node).not_to be_unary_operation }
    end
  end

  describe '#binary_operation??' do
    context 'with a unary operation' do
      let(:source) { '-foo' }

      it { expect(send_node).not_to be_binary_operation }
    end

    context 'with a binary operation' do
      let(:source) { 'foo + bar' }

      it { expect(send_node).to be_binary_operation }
    end

    context 'with a regular method call' do
      let(:source) { 'foo(bar)' }

      it { expect(send_node).not_to be_binary_operation }
    end

    context 'with an implicit call method' do
      let(:source) { 'foo.(:baz)' }

      it { expect(send_node).not_to be_binary_operation }
    end
  end

  describe '#post_condition_loop?' do
    let(:source) { 'foo(bar)' }

    it { expect(send_node).not_to be_post_condition_loop }
  end

  describe '#loop_keyword?' do
    let(:source) { 'foo(bar)' }

    it { expect(send_node).not_to be_loop_keyword }
  end
end
