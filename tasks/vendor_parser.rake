# frozen_string_literal: true

desc 'Refresh the copy of the source layer of `parser` from the installed gem'
task :vendor_parser do
  require 'fileutils'
  require_relative '../lib/rubocop/ast/parser_source'

  gem_dir = Gem.loaded_specs.fetch('parser').full_gem_path
  vendor_dir = RuboCop::AST::ParserSource::VENDOR_DIR

  FileUtils.rm_rf(vendor_dir)
  RuboCop::AST::ParserSource::FILES.each do |file|
    target = File.join(vendor_dir, "#{file}.rb")
    FileUtils.mkdir_p(File.dirname(target))
    FileUtils.cp(File.join(gem_dir, 'lib', 'parser', "#{file}.rb"), target)
  end
  FileUtils.cp(File.join(gem_dir, 'LICENSE.txt'), vendor_dir)
end
