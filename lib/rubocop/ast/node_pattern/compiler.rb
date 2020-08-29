# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      # The top-level compiler holding the global state
      # Defers work to its subcompilers
      class Compiler
        extend Forwardable
        attr_reader :captures, :named_parameters, :positional_parameters, :binding

        def initialize
          @temp_depth = 0 # avoid name clashes between temp variables
          @captures = 0 # number of captures seen
          @positional_parameters = 0 # highest % (param) number seen
          @named_parameters = Set[] # keyword parameters
          @binding = Binding.new # bound variables

          super
        end

        def_delegators :binding, :bind, :union_bind

        def positional_parameter(number)
          @positional_parameters = number if number > @positional_parameters
          "param#{number}"
        end

        def named_parameter(name)
          @named_parameters << name
          name
        end

        def enforce_same_captures(enum)
          return to_enum __method__, enum unless block_given?

          captures_before = captures_after = nil
          enum.each do |node|
            captures_before ||= @captures
            @captures = captures_before
            yield node
            captures_after ||= @captures
            raise Invalid, 'each branch must have same # of captures' if captures_after != @captures
          end
        end

        def atom
          self.class::AtomSubcompiler
        end

        def node_pattern
          self.class::NodePatternSubcompiler
        end

        def sequence
          self.class::SequenceSubcompiler
        end

        def parser
          self.class::Parser
        end

        # Utilities

        def with_temp_variables(*names, &block)
          @temp_depth += 1
          suffix = @temp_depth if @temp_depth > 1
          names = block.parameters.map(&:last) if names.empty?
          names.map! { |name| "#{name}#{suffix}" }
          yield(*names)
        ensure
          @temp_depth -= 1
        end

        def next_capture
          "captures[#{new_capture}]"
        end

        def freeze
          @named_parameters.freeze
          super
        end

        private

        def new_capture
          @captures
        ensure
          @captures += 1
        end
      end
    end
  end
end
