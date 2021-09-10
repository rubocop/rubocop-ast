# frozen_string_literal: true

return unless RUBY_VERSION >= '2.6'

require_relative '../../tasks/changelog'

# rubocop:disable RSpec/ExampleLength
RSpec.describe Changelog do
  subject(:changelog) do
    list = entries.to_h { |e| [e.path, e.content] }
    described_class.new(content: <<~CHANGELOG, entries: list)
      # Change log

      ## master (unreleased)

      ### New features

      * [#bogus] Bogus feature
      * [#bogus] Other bogus feature

      ## 0.7.1 (2020-09-28)

      ### Bug fixes

      * [#127](https://github.com/rubocop/rubocop-ast/pull/127): Fix dependency issue for JRuby. ([@marcandre][])

      ## 0.7.0 (2020-09-27)

      ### New features

      * [#105](https://github.com/rubocop/rubocop-ast/pull/105): `NodePattern` stuff...
      * [#109](https://github.com/rubocop/rubocop-ast/pull/109): Add `NodePattern` debugging rake tasks: `test_pattern`, `compile`, `parse`. See also [this app](https://nodepattern.herokuapp.com) ([@marcandre][])
      * [#110](https://github.com/rubocop/rubocop-ast/pull/110): Add `NodePattern` support for multiple terms unions. ([@marcandre][])
      * [#111](https://github.com/rubocop/rubocop-ast/pull/111): Optimize some `NodePattern`s by using `Set`s. ([@marcandre][])
      * [#112](https://github.com/rubocop/rubocop-ast/pull/112): Add `NodePattern` support for Regexp literals. ([@marcandre][])

      more stuf....

      [@marcandre]: https://github.com/marcandre
      [@johndoexx]: https://github.com/johndoexx
    CHANGELOG
  end

  let(:entries) do
    %i[fix new fix].map.with_index do |type, i|
      Changelog::Entry.new(type: type, body: "Do something cool#{'x' * i}", user: "johndoe#{'x' * i}")
    end
  end
  let(:entry) { entries.first }

  describe Changelog::Entry do
    it 'generates correct content' do
      expect(entry.content).to eq <<~MD
        * [#x](https://github.com/rubocop/rubocop-ast/pull/x): Do something cool. ([@johndoe][])
      MD
    end
  end

  it 'parses correctly' do
    expect(changelog.rest).to start_with('## 0.7.1 (2020-09-28)')
  end

  it 'merges correctly' do
    expect(changelog.unreleased_content).to eq(<<~CHANGELOG)
      ### New features

      * [#bogus] Bogus feature
      * [#bogus] Other bogus feature
      * [#x](https://github.com/rubocop/rubocop-ast/pull/x): Do something coolx. ([@johndoex][])

      ### Bug fixes

      * [#x](https://github.com/rubocop/rubocop-ast/pull/x): Do something cool. ([@johndoe][])
      * [#x](https://github.com/rubocop/rubocop-ast/pull/x): Do something coolxx. ([@johndoexx][])
    CHANGELOG

    expect(changelog.new_contributor_lines).to eq(
      [
        '[@johndoe]: https://github.com/johndoe',
        '[@johndoex]: https://github.com/johndoex'
      ]
    )
  end
end
# rubocop:enable RSpec/ExampleLength
