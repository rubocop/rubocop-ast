# frozen_string_literal: true

# Makes the `parser` gem look like it is not installed, to run the specs
# against the copy of its source layer that ships with this gem:
#
#   RUBYOPT="-r./spec/support/hide_parser" PARSER_ENGINE=prism bundle exec rspec
module HideParser
  def require(path)
    name = path.to_s
    if name == 'parser' || name.start_with?('parser/') || name.include?('prism/translation')
      raise LoadError, "cannot load such file -- #{name}"
    end

    super
  end
end

# `Object` and not `Kernel`: Ruby 2.7 does not see a module that is prepended
# to a module that a class has already included.
Object.prepend(HideParser)
