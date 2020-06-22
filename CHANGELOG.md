# Change log

## master (unreleased)

### New features

* [#38](https://github.com/rubocop-hq/rubocop-ast/pull/38): Add helpers allowing to check whether the method is a nonmutating operator method or a nonmutating method of several core classes. ([@fatkodima][])
* [#37](https://github.com/rubocop-hq/rubocop-ast/pull/37): Add `enumerable_method?` for `MethodIdentifierPredicates`. ([@fatkodima][])
* [#4](https://github.com/rubocop-hq/rubocop-ast/issues/4): Add `interpolation?` for `RegexpNode`. ([@tejasbubane][])
* [#20](https://github.com/rubocop-hq/rubocop-ast/pull/20): Add option predicates for `RegexpNode`. ([@owst][])
* [#11](https://github.com/rubocop-hq/rubocop-ast/issues/11): Add `argument_type?` method to make it easy to recognize argument nodes. ([@tejasbubane][])
* [#31](https://github.com/rubocop-hq/rubocop-ast/pull/31): NodePattern now uses `param === node` to match params, which allows Regexp, Proc, Set in addition to Nodes and literals. ([@marcandre][])
* [#41](https://github.com/rubocop-hq/rubocop-ast/pull/41): Add `delimiters` and related predicates for `RegexpNode`. ([@owst][])
* [#46](https://github.com/rubocop-hq/rubocop-ast/pull/46): Basic support for [non-legacy AST output from parser](https://github.com/whitequark/parser/#usage). Note that there is no support (yet) in main RuboCop gem. ([@marcandre][])

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
[@tejasbubane]: https://github.com/tejasbubane
[@owst]: https://github.com/owst
[@fatkodima]: https://github.com/fatkodima
