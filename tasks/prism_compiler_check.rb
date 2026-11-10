# frozen_string_literal: true

# Checks the native prism AST builder (`parser_engine: :prism`) against the
# prism translation layer (`parser_engine: :parser_prism`).
#
#   ruby tasks/prism_compiler_check.rb diff  PATH...   # compare the trees
#   ruby tasks/prism_compiler_check.rb bench PATH...   # compare the timings
#
# A PATH is a file or a directory that is searched for `*.rb` files.
# Set TARGET_RUBY to parse with a Ruby version other than 3.4.

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'rubocop-ast'
require 'benchmark'
require_relative 'tree_diff'

# Runs both engines over a set of files.
class PrismCompilerCheck
  TARGET_RUBY = Float(ENV.fetch('TARGET_RUBY', '3.4'))

  def initialize(paths)
    @files = paths.flat_map { |path| File.directory?(path) ? Dir["#{path}/**/*.rb"] : [path] }
    @files.sort!
  end

  # Prints the kinds of differences found, most common first.
  # @return [Integer] the number of files whose trees differ
  def diff
    differ = TreeDiff.new
    failures = Hash.new { |hash, key| hash[key] = [] }
    invalid = @files.count { |file| compare(file, differ, failures) == :invalid }
    failed = report(failures)
    valid = @files.size - invalid

    puts "#{valid - failed}/#{valid} files identical (#{invalid} skipped as invalid), " \
         "#{differ.nodes} nodes compared"
    failed
  end

  def bench
    sources = @files.map { |file| [File.read(file, mode: 'rb'), file] }

    puts "#{@files.size} files, prism #{Prism::VERSION}, ruby #{RUBY_VERSION}"
    measure('Prism.parse_lex only') { sources.each { |source, _path| Prism.parse_lex(source) } } # rubocop:disable Style/HashEachMethods -- an array of pairs, not a hash
    %i[parser_prism prism].each do |engine|
      measure("#{engine} (ast)") do
        sources.each { |source, path| processed_source(source, path, engine) }
      end
    end
  end

  private

  def processed_source(source, path, engine)
    RuboCop::AST::ProcessedSource.new(source, TARGET_RUBY, path, parser_engine: engine)
  end

  def report(failures)
    failures.sort_by { |_, list| -list.size }.first(25).each do |kind, list|
      puts "#{list.size}x #{kind}\n  #{list.first}"
    end
    failures.sum { |_, list| list.size }
  end

  # @return [Symbol] :invalid when the file is not valid Ruby, :compared otherwise
  def compare(file, differ, failures)
    source = File.read(file, mode: 'rb')
    expected = processed_source(source, file, :parser_prism)
    return :invalid unless expected.ast

    difference = difference(differ, expected, source, file)
    if difference
      kind = difference.sub(/\A\S+ /, '').gsub(/\d+/, 'N')
      failures[kind] << "#{file}: #{difference}"
    end
    :compared
  end

  def difference(differ, expected, source, file)
    actual = processed_source(source, file, :prism)
    raise actual.parser_error if actual.parser_error

    differ.call(expected.ast, actual.ast)
  rescue StandardError => e
    location = e.backtrace.first.sub(/.*prism_compiler/, 'prism_compiler')
    "#{e.class}: #{e.message.lines.first} (#{location})"
  end

  def measure(label, &block)
    yield
    time = Array.new(5) do
      GC.start
      Benchmark.realtime(&block)
    end.min
    allocated = allocations(&block)

    puts format('%-24<label>s %7.3<time>fs %10<allocated>d objects',
                label: label, time: time, allocated: allocated)
  end

  def allocations
    GC.start
    before = GC.stat(:total_allocated_objects)
    yield
    GC.stat(:total_allocated_objects) - before
  end
end

command, *paths = ARGV
abort 'usage: prism_compiler_check.rb diff|bench PATH...' if paths.empty?
check = PrismCompilerCheck.new(paths)

case command
when 'diff' then exit(check.diff.zero?)
when 'bench' then check.bench
else abort "unknown command #{command}"
end
