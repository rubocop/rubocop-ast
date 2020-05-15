# Change log

## master (unreleased)

## 0.0.3 (2020-05-15)

### Changes

* Classes `NodePattern`, `ProcessedSource` and `Token` moved to `AST::NodePattern`, etc.
  The `rubocop` gem has aliases to ensure compatibility. [#7]

* `AST::ProcessedSource.from_file` now raises a `Errno::ENOENT` instead of a `RuboCop::Error` [#7]

## 0.0.2 (2020-05-12)

### Bug fixes

* [Perf #106](https://github.com/rubocop-hq/rubocop-performance#106): Fix RegexpNode#to_regexp where option is 'o' + any other ([@marcandre][])

* Define `RuboCop::AST::Version::STRING`

## 0.0.1 (2020-05-11)

* Gem extracted from RuboCop. ([@marcandre][])

[@marcandre]: https://github.com/marcandre
