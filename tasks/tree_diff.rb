# frozen_string_literal: true

# Compares two ASTs node by node, including node classes and source maps.
class TreeDiff
  attr_reader :nodes

  def initialize
    @nodes = 0
  end

  # @return [String, nil] a description of the first difference
  def call(expected, actual, path = 'root')
    return if expected.nil? && actual.nil?

    @nodes += 1
    return "#{path}: #{expected.inspect} != #{actual.inspect}" unless node?(expected, actual)

    difference = type_difference(expected, actual) || map_difference(expected.loc, actual.loc)
    return "#{path} (#{expected.type}): #{difference}" if difference

    children_difference(expected, actual, "#{path}/#{expected.type}")
  end

  private

  def node?(*values)
    values.all?(Parser::AST::Node)
  end

  def type_difference(expected, actual)
    [
      ['type', expected.type, actual.type],
      ['class', expected.class, actual.class],
      ['children', expected.children.size, actual.children.size]
    ].each do |name, left, right|
      return "#{name} #{left} != #{right}" if left != right
    end
    nil
  end

  def map_difference(expected, actual)
    return "map #{expected.class} != #{actual.class}" unless expected.instance_of?(actual.class)
    return if expected.nil?

    expected.instance_variables.each do |ivar|
      next if ivar == :@node

      left = describe(expected.instance_variable_get(ivar))
      right = describe(actual.instance_variable_get(ivar))
      return "loc.#{ivar.to_s.delete('@')} #{left} != #{right}" if left != right
    end
    nil
  end

  def describe(value)
    value.is_a?(Parser::Source::Range) ? "#{value.begin_pos}...#{value.end_pos}" : value.inspect
  end

  def children_difference(expected, actual, path)
    expected.children.each_with_index do |child, index|
      difference = child_difference(child, actual.children[index], "#{path}[#{index}]")
      return difference if difference
    end
    nil
  end

  def child_difference(expected, actual, path)
    return call(expected, actual, path) if node?(expected) || node?(actual)

    same = expected == actual && expected.instance_of?(actual.class)
    same &&= expected.encoding == actual.encoding if expected.is_a?(String)
    "#{path}: #{expected.inspect} != #{actual.inspect}" unless same
  end
end
