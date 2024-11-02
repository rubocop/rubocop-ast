# Change log

## master (unreleased)

## 1.33.1 (2024-11-02)

### Bug fixes

* [#325](https://github.com/rubocop-hq/rubocop-ast/pull/325): Allow `non_bare_access_modifier_declaration?` to handle modifiers with multiple arguments. ([@dvandersluis][])

## 1.33.0 (2024-10-29)

### New features

* [#203](https://github.com/rubocop-hq/rubocop-ast/pull/203): Add classes for `masgn` and `mlhs` nodes. ([@dvandersluis][])
* [#204](https://github.com/rubocop-hq/rubocop-ast/pull/204): Add `VarNode` class for `lvar`, `ivar`, `cvar` and `gvar` node types. ([@dvandersluis][])

## 1.32.3 (2024-09-05)

### Bug fixes

* [#310](https://github.com/rubocop/rubocop-ast/pull/310): Fix `RuboCop::AST::DefNode#void_context?` to handle class methods called `initialize`. ([@vlad-pisanov][])

## 1.32.2 (2024-09-02)

## 1.32.1 (2024-08-17)

### Changes

* [#309](https://github.com/rubocop/rubocop-ast/pull/309): Mark `RuboCop::AST::EnsureNode` as being in a void context. ([@earlopain][])

## 1.32.0 (2024-08-05)

### New features

* [#304](https://github.com/rubocop/rubocop-ast/pull/304): Add `RuboCop::AST::RationalNode`. ([@koic][])

## 1.31.3 (2024-04-29)

### Bug fixes

* [#289](https://github.com/rubocop/rubocop-ast/pull/289): Fix an error during parsing when encountering unknown encodings in the encoding magic comment. ([@Earlopain][])

## 1.31.2 (2024-03-08)

### Bug fixes

* [#286](https://github.com/rubocop/rubocop-ast/pull/286): Improve error message for invalid `parser_engine` value. ([@Earlopain][])

## 1.31.1 (2024-03-01)

### Changes

* [#282](https://github.com/rubocop/rubocop-ast/issues/282): Remove Prism from runtime dependency. ([@koic][])

## 1.31.0 (2024-02-29)

### New features

* [#277](https://github.com/rubocop/rubocop-ast/pull/277): Support Prism as a Ruby parser (experimental). ([@koic][])
* [#276](https://github.com/rubocop/rubocop-ast/pull/276): Support `Parser::Ruby34` for Ruby 3.4 parser (experimental). ([@koic][])

### Changes

* [#279](https://github.com/rubocop/rubocop-ast/pull/279): **(Compatibility)** Drop Ruby 2.6 runtime support. ([@koic][])
* [#272](https://github.com/rubocop/rubocop-ast/pull/272): Make `Node#left_curly_brace?` aware of lambda brace. ([@koic][])

## 1.30.0 (2023-10-26)

### New features

- [#270](https://github.com/rubocop/rubocop-ast/pull/270): Add `BlockNode#{first,last}_argument` helpers. ([@sambostock][])

## 1.29.0 (2023-06-01)

* [#262](https://github.com/rubocop/rubocop-ast/pull/267): Introduce RuboCop::Ast::MethodDispatchNode#selector. ([@gsamokovarov][])

## 1.28.1 (2023-05-01)

### Bug fixes

* [#262](https://github.com/rubocop/rubocop-ast/pull/262): Fix an error when parsing non UTF-8 frozen string. ([@koic][])

## 1.28.0 (2023-03-24)

### New features

* [#259](https://github.com/rubocop/rubocop-ast/pull/259): Add `forwarded_kwrestarg` node to `AST::Builder`. ([@koic][])

## 1.27.0 (2023-02-27)

### New features

* [#229](https://github.com/rubocop/rubocop-ast/pull/229): Add `source_range` method to `NodePattern`. ([@koic][])

## 1.26.0 (2023-02-11)

### New features

* [#255](https://github.com/rubocop/rubocop-ast/pull/255): Make `Node#class_constructor?` aware of Ruby 3.2's `Data.define`. ([@koic][])
* [#255](https://github.com/rubocop/rubocop-ast/pull/255): Make `Node#class_construcor?` aware of Ruby 2.7's numbered parameters. ([@koic][])

## 1.25.0 (2023-02-11)

### New features

* [#256](https://github.com/rubocop/rubocop-ast/pull/256): Support `Parser::Ruby33` for Ruby 3.3 parser (experimental). ([@koic][])

## 1.24.1 (2022-12-29)

## 1.24.0 (2022-11-30)

### New features

* [#245](https://github.com/rubocop/rubocop-ast/pull/245): Add node types `forwarded_restarg` and `forwarded_kwrestarg`. ([@ydah][])

## 1.23.0 (2022-10-21)

### New features

* [#242](https://github.com/rubocop/rubocop-ast/pull/242): Add `character_literal?` to `StrNode`. ([@koic][])

## 1.22.0 (2022-10-17)

### New features

* [#240](https://github.com/rubocop/rubocop-ast/pull/240): Add a type predicate `new_line?` to Token. ([@tdeo][])

## 1.21.0 (2022-08-08)

### New features

* [#231](https://github.com/rubocop/rubocop-ast/pull/231): Add a type predicate `dot?` to Token. ([@nobuyo][])

## 1.20.1 (2022-08-07)

### New features

* [#237](https://github.com/rubocop/rubocop-ast/pull/237) Fix `#macro?` for numblock nodes ([@gsamokovarov][])

## 1.20.0 (2022-08-07)

### Bug fixes

* [#230](https://github.com/rubocop/rubocop-ast/pull/230): Make `RegexpNode` aware of fixed-encoding regopt. ([@koic][])

## 1.19.1 (2022-07-10)

### New features

* [#235](https://github.com/rubocop/rubocop-ast/pull/235): Add `regexp_dots?` method to `RuboCop::AST::Token` (erroneously released in 1.19.0 as `regexp_dot?`). ([@koic][])

## 1.18.0 (2022-05-13)

### New features

* [#233](https://github.com/rubocop/rubocop-ast/pull/233): Make parse from Ruby 1.9 to 2.3 available. ([@koic][])

### Changes

* [#232](https://github.com/rubocop/rubocop-ast/pull/232): **(Compatibility)** Drop support for Ruby 2.5. ([@koic][])

## 1.17.0 (2022-04-09)

### New features

* [#227](https://github.com/rubocop/rubocop-ast/pull/227):  Make `Node#condition?` aware of `case-match` node. ([@koic][])

## 1.16.0 (2022-02-21)

### New features

* [#223](https://github.com/rubocop/rubocop-ast/pull/223): Support `Parser::Ruby32` for Ruby 3.2 parser (experimental). ([@koic][])

## 1.15.2 (2022-02-12)

### Bug fixes

* Fix `:&` parsing ([@zverok][])

## 1.15.1 (2021-12-27)

### Bug fixes

* [#10220](https://github.com/rubocop/rubocop/pull/10220): Make `AST::Node#receiver` aware of `csend` block method calls. ([@koic][])

## 1.15.0 (2021-12-12)

### New features

* [#10219](https://github.com/rubocop/rubocop/pull/10219): Add `value_omission` method to `AST::PairNode` for Ruby 3.1's hash value omission. ([@koic][])

## 1.14.0 (2021-12-02)

### New features

* [#218](https://github.com/rubocop/rubocop-ast/pull/218): Support Ruby 3.1's anonymous block forwarding syntax. ([@koic][])

## 1.13.0 (2021-11-07)

### New features

* [#213](https://github.com/rubocop/rubocop-ast/pull/213): Make `Node#numeric_type?` aware of rational and complex literals. ([@koic][])

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
[@zverok]: https://github.com/zverok
[@gsamokovarov]: https://github.com/gsamokovarov
[@nobuyo]: https://github.com/nobuyo
[@tdeo]: https://github.com/tdeo
[@ydah]: https://github.com/ydah
[@sambostock]: https://github.com/sambostock

[@Earlopain]: https://github.com/Earlopain
[@earlopain]: https://github.com/earlopain