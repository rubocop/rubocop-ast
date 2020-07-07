# frozen_string_literal: true

module RuboCop
  module AST
    # If a module extends this, then `SOME_CONSTANT_SET` will be a set created
    # automatically from `SOME_CONSTANT`
    #
    #     class Foo
    #       extend AutoConstToSet
    #
    #       WORDS = %w[hello world].freeze
    #     end
    #
    #     Foo::WORDS_SET # => Set['hello', 'world'].freeze
    module AutoConstToSet
      def const_missing(name)
        return super unless name =~ /(?<array_name>.*)_SET/

        array = const_get(Regexp.last_match(:array_name))
        raise TypeError, 'Already a set!' if array.is_a?(Set)

        const_set(name, array.to_set.freeze)
      end
    end
  end
end
