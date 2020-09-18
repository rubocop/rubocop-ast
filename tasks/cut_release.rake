# frozen_string_literal: true

require 'bump'

def update_file(path)
  content = File.read(path)
  File.write(path, yield(content))
end

namespace :cut_release do
  %w[major minor patch pre].each do |release_type|
    desc "Cut a new #{release_type} release, create release notes " \
         'and update documents.'
    task release_type do
      run(release_type)
    end
  end

  def version_sans_patch(version)
    version.split('.').take(2).join('.')
  end

  def update_antora(version)
    update_file('docs/antora.yml') do |yaml|
      yaml.gsub(/version: .*/, "version: '#{version_sans_patch(version)}'")
    end
  end

  def add_header_to_changelog(version)
    update_file('CHANGELOG.md') do |changelog|
      head, tail = changelog.split("## master (unreleased)\n\n", 2)
      [
        head,
        "## master (unreleased)\n\n",
        "## #{version} (#{Time.now.strftime('%F')})\n\n",
        tail
      ].join
    end
  end

  def run(release_type)
    old_version = Bump::Bump.current
    Bump::Bump.run(release_type, commit: false, bundle: false, tag: false)
    new_version = Bump::Bump.current

    add_header_to_changelog(new_version)
    update_antora(new_version)

    puts "Changed version from #{old_version} to #{new_version}."
    cmd = "git commit -am 'Cut #{new_version}'"
    puts cmd
    system cmd
  end
end

desc 'and restore docs/antora'
task :release do
  update_file 'docs/antora.yml' do |s|
    s.gsub!(/version: .*/, 'version: master')
  end
  cmd = "git commit -am 'Restore docs/antora.yml'"
  puts cmd
  system cmd
end
