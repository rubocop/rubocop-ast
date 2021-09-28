# Change log

## master (unreleased)

## 1.12.0 (2021-09-27)

### Bug fixes

* [#208](https://github.com/rubocop/rubocop-ast/issues/208): Update `MethodDispatchNode#block_literal?` to return true for `numblock`s. ([@dvandersluis][])

## 1.11.0 (2021-08-24)

### New features

* [#205](https://github.com/rubocop/rubocop-ast/pull/205): Make class, module, and struct definitions aware of numblock. ([@koic][])

## 1.10.0 (2021-08-12)

### New features

* [#201](https://github.com/rubocop/rubocop-ast/pull/201): Add discrete node classes for assignments. ([@dvandersluis][])

## 1.9.1 (2021-08-10)

### Bug fixes

* [#197](https://github.com/rubocop/rubocop-ast/pull/197): [Fix #184] Fix `Node#parent_module_name` for `sclass` nodes. ([@dvandersluis][])

## 1.9.0 (2021-08-06)

### New features

* [#195](https://github.com/rubocop/rubocop-ast/pull/195): Move `ProcessedSource#sorted_tokens` to be a public method. ([@dvandersluis][])

## 1.8.0 (2021-07-14)

### New features

* [#192](https://github.com/rubocop/rubocop-ast/pull/192): Add `branches` method for `AST::CaseMatchNode`. ([@koic][])

### Changes

* Escape References in Documentation, partially addressing https://github.com/rubocop/rubocop/issues/9150. ([@wcmonty][])

## 1.7.0 (2021-05-28)

### New features

* [#171](https://github.com/rubocop/rubocop-ast/pull/171): Add `SendNode#def_modifier` that returns the `def` node it modifies, or `nil`. ([@marcandre][])
* [#186](https://github.com/rubocop/rubocop-ast/pull/186): Add `pattern` method for `AST::InPatternNode` node. ([@koic][])

## 1.6.0 (2021-05-26)

### New features

* [#183](https://github.com/rubocop/rubocop-ast/pull/183): Add `AST::InPatternNode` node. ([@koic][])

## 1.5.0 (2021-05-02)

### New features

* [#182](https://github.com/rubocop/rubocop-ast/pull/182): Support `Parser::Ruby31` for Ruby 3.1 parser (experimental). ([@koic][])

## 1.4.2 (2021-05-02)

### Bug fixes

* [#179](https://github.com/rubocop/rubocop-ast/pull/179): Have `ast_with_comments` distinguish nodes with same content. ([@marcandre][])

## 1.4.1 (2021-01-23)

### Changes

* [#167](https://github.com/rubocop/rubocop-ast/pull/167): Fix `#value` for `dstr` nodes to return the actual string value. ([@dvandersluis][])

## 1.4.0 (2021-01-01)

### Changes

* [#162](https://github.com/rubocop/rubocop-ast/pull/162): Improve compatibility with `parser` 3.0. Turn on `emit_match_pattern` switch. ([@marcandre][])

## 1.3.0 (2020-11-30)

### Changes

* [#156](https://github.com/rubocop/rubocop-ast/issues/156): NodePattern now considers constant names to refer to constants (instead of predicate `#Example_type?`). ([@marcandre][])

## 1.2.0 (2020-11-24)

### New features

* [#154](https://github.com/rubocop/rubocop-ast/pull/154): Add `ArgNode` and `Procarg0Node` ("modern" mode), and add `ArgsNode#argument_list` to get only argument type nodes. ([@dvandersluis][])

### Changes

* [#155](https://github.com/rubocop/rubocop-ast/pull/155): Enable `BlockNode#argument_list` for `numblock`s. ([@dvandersluis][])
* [#154](https://github.com/rubocop/rubocop-ast/pull/154): Add `BlockNode#argument_list` and `BlockNode#argument_names`. ([@dvandersluis][])
* [#147](https://github.com/rubocop/rubocop-ast/pull/147): `def_node_pattern` and `def_node_search` now return the method name. ([@marcandre][])

## 1.1.1 (2020-11-04)

### Bug fixes

* [#146](https://github.com/rubocop/rubocop-ast/pull/146): Fix `IfNode#branches` to return both branches when called on ternary conditional. ([@fatkodima][])

## 1.1.0 (2020-10-26)

### New features

* [#144](https://github.com/rubocop/rubocop-ast/pull/144): NodePattern: allow method calls on constants. ([@marcandre][])

## 1.0.1 (2020-10-23)

### Bug fixes

* [#141](https://github.com/rubocop/rubocop-ast/pull/141): Make `SendNode#macro?` and `RuboCop::AST::Node#class_constructor?` aware of struct constructor and `RuboCop::AST::Node#struct_constructor?` is deprecated. ([@koic][])
* [#142](https://github.com/rubocop/rubocop-ast/pull/142): Only traverse send nodes in `MethodDispatchNode#def_modifier?`. ([@eugeneius][])

## 1.0.0 (2020-10-21)

### Changes

* None since 0.8; official 1.0 release coinciding with RuboCop 1.0 and API considered stable. ([@marcandre][])

## 0.8.0 (2020-10-12)

### New features

* [#49](https://github.com/rubocop/rubocop-ast/pull/49): Add `DefNode#endless?` (Ruby 3.0). ([@marcandre][])
* [#117](https://github.com/rubocop/rubocop-ast/pull/117): Future-proof `AST::Traversal` by detecting unknown `Node` types. ([@marcandre][])
* [#131](https://github.com/rubocop/rubocop-ast/pull/131): Add rake tasks to merge and create Changelog entries. ([@marcandre][])

### Bug fixes

* [#117](https://github.com/rubocop/rubocop-ast/pull/117): All nodes of `break` and `next` are now traversed. ([@marcandre][])

## 0.7.1 (2020-09-28)

### Bug fixes

* [#127](https://github.com/rubocop/rubocop-ast/pull/127): Fix dependency issue for JRuby. ([@marcandre][])

## 0.7.0 (2020-09-27)

### New features

* [#105](https://github.com/rubocop/rubocop-ast/pull/105): `NodePattern` compiler [complete rewrite](https://docs.rubocop.org/rubocop-ast/node_pattern_compiler.html). Add support for multiple variadic terms. ([@marcandre][])
* [#109](https://github.com/rubocop/rubocop-ast/pull/109): Add `NodePattern` debugging rake tasks: `test_pattern`, `compile`, `parse`. See also [this app](https://nodepattern.herokuapp.com) ([@marcandre][])
* [#110](https://github.com/rubocop/rubocop-ast/pull/110): Add `NodePattern` support for multiple terms unions. ([@marcandre][])
* [#111](https://github.com/rubocop/rubocop-ast/pull/111): Optimize some `NodePattern`s by using `Set`s. ([@marcandre][])
* [#112](https://github.com/rubocop/rubocop-ast/pull/112): Add `NodePattern` support for Regexp literals. ([@marcandre][])

### Changes

* [#22](https://github.com/rubocop/rubocop-ast/issues/22): **(Potentially breaking)** Most constants are now private, the rest are converted to Sets and meant to be private. ([@marcandre][])

## 0.6.0 (2020-09-26)

### New features

* [#124](https://github.com/rubocop/rubocop-ast/pull/124): Add `RegexpNode#options`. ([@owst][])

## 0.5.1 (2020-09-25)

### Bug fixes

* [#120](https://github.com/rubocop/rubocop-ast/pull/120): **(Potentially breaking)** Fix false positives and negatives for `SendNode#macro?`. This impacts `{non_}bare_access_modifier?` and `special_access_modifier?`. ([@marcandre][])

## 0.5.0 (2020-09-24)

### New features

* [#122](https://github.com/rubocop/rubocop-ast/pull/122): Add `Node#parent?` and `Node#root?`. ([@marcandre][])

### Changes

* [#121](https://github.com/rubocop/rubocop-ast/pull/121): Update from `Parser::Ruby28` to `Parser::Ruby30` for Ruby 3.0 parser (experimental). ([@koic][])

## 0.4.2 (2020-09-18)

### Bug fixes
* [#116](https://github.com/rubocop/rubocop-ast/pull/116): Fix issues with tokens being sometimes misordered. ([@fatkodima][])

## 0.4.1 (2020-09-16)

### Bug fixes
* [#115](https://github.com/rubocop/rubocop-ast/pull/115): Fix `ConstNode#absolute?` when the constant is not namespaced. ([@dvandersluis][])

## 0.4.0 (2020-09-11)

### New features

* [#92](https://github.com/rubocop/rubocop-ast/pull/92): Add `ProcessedSource#tokens_within`, `ProcessedSource#first_token_of` and `ProcessedSource#last_token_of`. ([@fatkodima][])
* [#88](https://github.com/rubocop/rubocop-ast/pull/88): Add `RescueNode`. Add `ResbodyNode#exceptions` and `ResbodyNode#branch_index`. ([@fatkodima][])
* [#89](https://github.com/rubocop/rubocop-ast/pull/89): Support right hand assignment for Ruby 2.8 (3.0) parser. ([@koic][])
* [#93](https://github.com/rubocop/rubocop-ast/pull/93): Add `Node#{left|right}_sibling{s}` ([@marcandre][])
* [#99](https://github.com/rubocop/rubocop-ast/pull/99): Add `ConstNode` and some helper methods. ([@marcandre][])

### Changes

* [#94](https://github.com/rubocop/rubocop-ast/pull/94): In Ruby 2.4, `Set#===` is harmonized with Ruby 2.5+ to call `include?`. ([@marcandre][])
* [#91](https://github.com/rubocop/rubocop-ast/pull/91): **(Potentially breaking)** `Node#arguments` always returns a frozen array ([@marcandre][])

## 0.3.0 (2020-08-01)

### New features

* [#70](https://github.com/rubocop/rubocop-ast/pull/70): Add `NextNode` ([@marcandre][])
* [#85](https://github.com/rubocop/rubocop-ast/pull/85): Add `IntNode#value` and `FloatNode#value`. ([@fatkodima][])
* [#82](https://github.com/rubocop/rubocop-ast/pull/82): `NodePattern`: Allow comments ([@marcandre][])
* [#83](https://github.com/rubocop/rubocop-ast/pull/83): Add `ProcessedSource#comment_at_line` ([@marcandre][])
* [#83](https://github.com/rubocop/rubocop-ast/pull/83): Add `ProcessedSource#each_comment_in_lines` ([@marcandre][])
* [#84](https://github.com/rubocop/rubocop-ast/pull/84): Add `Source::Range#line_span` ([@marcandre][])
* [#87](https://github.com/rubocop/rubocop-ast/pull/87): Add `CaseNode#branches` ([@marcandre][])

### Bug fixes

* [#70](https://github.com/rubocop/rubocop-ast/pull/70): Fix arguments processing for `BreakNode` ([@marcandre][])
* [#70](https://github.com/rubocop/rubocop-ast/pull/70): **(Potentially breaking)** `BreakNode` and `ReturnNode` no longer include `MethodDispatchNode`. These methods were severely broken ([@marcandre][])

### Changes

* [#44](https://github.com/rubocop/rubocop-ast/issue/44): **(Breaking)** Use `parser` flag `self.emit_forward_arg = true` by default. ([@marcandre][])
* [#86](https://github.com/rubocop/rubocop-ast/pull/86): `PairNode#delimiter` and `inverse_delimiter` now accept their argument as a named argument. ([@marcandre][])
* [#87](https://github.com/rubocop/rubocop-ast/pull/87): **(Potentially breaking)** Have `IfNode#branches` return a `nil` value if source has `else; end` ([@marcandre][])
* [#72](https://github.com/rubocop/rubocop-ast/pull/72): **(Potentially breaking)** `SuperNode/DefinedNode/YieldNode#arguments` now return a frozen array. ([@marcandre][])


## 0.2.0 (2020-07-19)

### New features

* [#50](https://github.com/rubocop/rubocop-ast/pull/50): Support find pattern matching for Ruby 2.8 (3.0) parser. ([@koic][])
* [#55](https://github.com/rubocop/rubocop-ast/pull/55): Add `ProcessedSource#line_with_comment?`. ([@marcandre][])
* [#63](https://github.com/rubocop/rubocop-ast/pull/63): NodePattern now supports patterns as arguments to predicate and functions. ([@marcandre][])
* [#64](https://github.com/rubocop/rubocop-ast/pull/64): Add `Node#global_const?`. ([@marcandre][])
* [#28](https://github.com/rubocop/rubocop-ast/issues/28): Add `struct_constructor?`, `class_definition?` and `module_definition?` matchers. ([@tejasbubane][])

### Bug fixes

* [#55](https://github.com/rubocop/rubocop-ast/pull/55): Fix `ProcessedSource#commented?` for multi-line ranges. Renamed `contains_comment?` ([@marcandre][])
* [#69](https://github.com/rubocop/rubocop-ast/pull/69): **(Potentially breaking)** `RetryNode` has many errors. It is now a `Node`. ([@marcandre][])

## 0.1.0 (2020-06-26)

### New features

* [#36](https://github.com/rubocop/rubocop-ast/pull/36): Add `post_condition_loop?` and `loop_keyword?` for `Node`. ([@fatkodima][])
* [#38](https://github.com/rubocop/rubocop-ast/pull/38): Add helpers allowing to check whether the method is a nonmutating operator method or a nonmutating method of several core classes. ([@fatkodima][])
* [#37](https://github.com/rubocop/rubocop-ast/pull/37): Add `enumerable_method?` for `MethodIdentifierPredicates`. ([@fatkodima][])
* [#4](https://github.com/rubocop/rubocop-ast/issues/4): Add `interpolation?` for `RegexpNode`. ([@tejasbubane][])
* [#20](https://github.com/rubocop/rubocop-ast/pull/20): Add option predicates for `RegexpNode`. ([@owst][])
* [#11](https://github.com/rubocop/rubocop-ast/issues/11): Add `argument_type?` method to make it easy to recognize argument nodes. ([@tejasbubane][])
* [#31](https://github.com/rubocop/rubocop-ast/pull/31): NodePattern now uses `param === node` to match params, which allows Regexp, Proc, Set in addition to Nodes and literals. ([@marcandre][])
* [#41](https://github.com/rubocop/rubocop-ast/pull/41): Add `delimiters` and related predicates for `RegexpNode`. ([@owst][])
* [#46](https://github.com/rubocop/rubocop-ast/pull/46): Basic support for [non-legacy AST output from parser](https://github.com/whitequark/parser/#usage). Note that there is no support (yet) in main RuboCop gem. Expect `emit_forward_arg` to be set to `true` in v1.0 ([@marcandre][])
* [#48](https://github.com/rubocop/rubocop-ast/pull/48): Support `Parser::Ruby28` for Ruby 2.8 (3.0) parser (experimental). ([@koic][])
* [#35](https://github.com/rubocop/rubocop-ast/pull/35): NodePattern now accepts `%named_param` and `%CONST`. The macros `def_node_matcher` and `def_node_search` accept default named parameters. ([@marcandre][])

## 0.0.3 (2020-05-15)

### Changes

* [#7](https://github.com/rubocop/rubocop-ast/issues/7): Classes `NodePattern`, `ProcessedSource` and `Token` moved to `AST::NodePattern`, etc.
  The `rubocop` gem has aliases to ensure compatibility. ([@marcandre][])
* [#7](https://github.com/rubocop/rubocop-ast/issues/7): `AST::ProcessedSource.from_file` now raises a `Errno::ENOENT` instead of a `RuboCop::Error`. ([@marcandre][])

## 0.0.2 (2020-05-12)

### Bug fixes

* [Perf #106](https://github.com/rubocop/rubocop-performance#106): Fix RegexpNode#to_regexp where option is 'o' + any other. ([@marcandre][])
* Define `RuboCop::AST::Version::STRING`. ([@marcandre][])

## 0.0.1 (2020-05-11)

* Gem extracted from RuboCop. ([@marcandre][])

[@marcandre]: https://github.com/marcandre
[@tejasbubane]: https://github.com/tejasbubane
[@owst]: https://github.com/owst
[@fatkodima]: https://github.com/fatkodima
[@koic]: https://github.com/koic
[@dvandersluis]: https://github.com/dvandersluis
[@eugeneius]: https://github.com/eugeneius
[@wcmonty]: https://github.com/wcmonty
