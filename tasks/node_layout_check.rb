# frozen_string_literal: true

# Checks `RuboCop::AST::NodeLayout` against the nodes of the Ruby files in the
# given paths, and lists the node types that have no layout.
#
#   ruby tasks/node_layout_check.rb PATH...

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'rubocop-ast'

ENGINES = [[3.4, :parser_prism], [2.7, :parser_whitequark]].freeze

def shape(node)
  node.children.map { |child| RuboCop::AST::NodeLayout.kind(child) }.join(' ')
end

files = ARGV.flat_map { |path| File.directory?(path) ? Dir["#{path}/**/*.{rb,txt}"] : [path] }
unfitting = Hash.new { |hash, type| hash[type] = {} }
unknown = Hash.new(0)
failed = []

files.product(ENGINES) do |file, (version, engine)|
  source = File.read(file, mode: 'rb').force_encoding(Encoding::UTF_8)
  ast = RuboCop::AST::ProcessedSource.new(source, version, file, parser_engine: engine).ast
  ast&.each_node do |node|
    layout = RuboCop::AST::NodeLayout.of(node.type)
    next unknown[node.type] += 1 unless layout

    unfitting[node.type][shape(node)] ||= "#{file}:#{node.first_line}" unless layout.fit?(node.children)
  end
rescue StandardError => e
  failed << "#{file}: #{e.class}"
end

unfitting.each do |type, shapes|
  shapes.each { |shape, location| puts "#{type}: (#{shape}) at #{location}" }
end
unknown.each { |type, count| puts "#{type}: no layout (#{count} nodes)" }
puts(failed.uniq.map { |failure| "not checked: #{failure}" })
puts "#{files.size} files, #{unfitting.sum { |_type, shapes| shapes.size }} shapes that do not fit"
