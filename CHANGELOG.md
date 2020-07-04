# Change log

## master (unreleased)

### New features

* [#50](https://github.com/rubocop-hq/rubocop-ast/pull/50): Support find pattern matching for Ruby 2.8 (3.0) parser. ([@koic][])
* [#55](https://github.com/rubocop-hq/rubocop-ast/pull/55): Add `ProcessedSource#line_with_comment?`. ([@marcandre][])

### Bug fixes

* [#55](https://github.com/rubocop-hq/rubocop-ast/pull/55): Fix `ProcessedSource#commented?` for multi-line ranges. Renamed `contains_comment?` ([@marcandre][])

## 0.1.0 (2020-06-26)

### New features

* [#36](https://github.com/rubocop-hq/rubocop-ast/pull/36): Add `post_condition_loop?` and `loop_keyword?` for `Node`. ([@fatkodima][])
* [#38](https://github.com/rubocop-hq/rubocop-ast/pull/38): Add helpers allowing to check whether the method is a nonmutating operator method or a nonmutating method of several core classes. ([@fatkodima][])
* [#37](https://github.com/rubocop-hq/rubocop-ast/pull/37): Add `enumerable_method?` for `MethodIdentifierPredicates`. ([@fatkodima][])
* [#4](https://github.com/rubocop-hq/rubocop-ast/issues/4): Add `interpolation?` for `RegexpNode`. ([@tejasbubane][])
* [#20](https://github.com/rubocop-hq/rubocop-ast/pull/20): Add option predicates for `RegexpNode`. ([@owst][])
* [#11](https://github.com/rubocop-hq/rubocop-ast/issues/11): Add `argument_type?` method to make it easy to recognize argument nodes. ([@tejasbubane][])
* [#31](https://github.com/rubocop-hq/rubocop-ast/pull/31): NodePattern now uses `param === node` to match params, which allows Regexp, Proc, Set in addition to Nodes and literals. ([@marcandre][])
* [#41](https://github.com/rubocop-hq/rubocop-ast/pull/41): Add `delimiters` and related predicates for `RegexpNode`. ([@owst][])
* [#46](https://github.com/rubocop-hq/rubocop-ast/pull/46): Basic support for [non-legacy AST output from parser](https://github.com/whitequark/parser/#usage). Note that there is no support (yet) in main RuboCop gem. Expect `emit_forward_arg` to be set to `true` in v1.0 ([@marcandre][])
* [#48](https://github.com/rubocop-hq/rubocop-ast/pull/48): Support `Parser::Ruby28` for Ruby 2.8 (3.0) parser (experimental). ([@koic][])
* [#35](https://github.com/rubocop-hq/rubocop-ast/pull/35): NodePattern now accepts `%named_param` and `%CONST`. The macros `def_node_matcher` and `def_node_search` accept default named parameters. ([@marcandre][])

## 0.0.3 (2020-05-15)

### Changes

* [#7](https://github.com/rubocop-hq/rubocop-ast/issues/7): Classes `NodePattern`, `ProcessedSource` and `Token` moved to `AST::NodePattern`, etc.
  The `rubocop` gem has aliases to ensure compatibility. ([@marcandre][])
* [#7](https://github.com/rubocop-hq/rubocop-ast/issues/7): `AST::ProcessedSource.from_file` now raises a `Errno::ENOENT` instead of a `RuboCop::Error`. ([@marcandre][])

## 0.0.2 (2020-05-12)

### Bug fixes

* [Perf #106](https://github.com/rubocop-hq/rubocop-performance#106): Fix RegexpNode#to_regexp where option is 'o' + any other. ([@marcandre][])
* Define `RuboCop::AST::Version::STRING`. ([@marcandre][])

## 0.0.1 (2020-05-11)

* Gem extracted from RuboCop. ([@marcandre][])

[@marcandre]: https://github.com/marcandre
[@tejasbubane]: https://github.com/tejasbubane
[@owst]: https://github.com/owst
[@fatkodima]: https://github.com/fatkodima
[@koic]: https://github.com/koic
