# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      class Compiler
        # The global state used when compiling a node pattern.
        class Context < Binding
          attr_reader :captures, :named_parameters, :positional_parameters

          def initialize
            @temp_depth = 0 # avoid name clashes between temp variables
            @captures = 0 # number of captures seen
            @positional_parameters = 0 # highest % (param) number seen
            @named_parameters = Set[] # keyword parameters

            super
          end

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
            AtomCompiler
          end

          def node_pattern
            NodePatternCompiler
          end

          def sequence
            SequenceCompiler
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
end
