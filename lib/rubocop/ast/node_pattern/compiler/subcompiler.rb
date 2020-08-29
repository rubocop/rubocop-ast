# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      class Compiler
        # Base class for subcompilers
        # Implements visitor pattern
        class Subcompiler
          def initialize(compiler)
            @compiler = compiler
            @node = nil
          end

          def compile(node)
            prev = @node
            @node = node
            do_compile
          ensure
            @node = prev
          end

          # @api private
          def do_compile
            callback(self.class.registry.fetch(node.type, :visit_other_type))
          end

          protected

          attr_reader :compiler, :node

          private

          def callback(method)
            send(method)
          end

          @registry = {}
          class << self
            attr_reader :registry

            def method_added(method)
              @registry[Regexp.last_match(1).to_sym] = method if method =~ /^visit_(.*)/
              super
            end

            def inherited(base)
              us = self
              base.class_eval { @registry = us.registry.dup }
              super
            end
          end
        end
      end
    end
  end
end
