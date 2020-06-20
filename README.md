# RuboCop AST

[![Gem Version](https://badge.fury.io/rb/rubocop-ast.svg)](https://badge.fury.io/rb/rubocop-ast)
[![CI](https://github.com/rubocop-hq/rubocop-ast/workflows/CI/badge.svg)](https://github.com/rubocop-hq/rubocop-ast/actions?query=workflow%3ACI)
[![Test Coverage](https://api.codeclimate.com/v1/badges/a29666e6373bc41bc0a9/test_coverage)](https://codeclimate.com/github/rubocop-hq/rubocop-ast/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/a29666e6373bc41bc0a9/maintainability)](https://codeclimate.com/github/rubocop-hq/rubocop-ast/maintainability)

Contains the classes needed by [RuboCop](https://github.com/rubocop-hq/rubocop) to deal with Ruby's AST, in particular:
* `RuboCop::AST::Node`
* `RuboCop::AST::NodePattern` ([doc](docs/modules/ROOT/pages/node_pattern.adoc))

This gem may be used independently from the main RuboCop gem. It was extracted from RuboCop in version 0.84 and its only
dependency is the `parser` gem, which `rubocop-ast` extends.

## Installation

Just install the `rubocop-ast` gem

```sh
gem install rubocop-ast
```

or if you use bundler put this in your `Gemfile`

```ruby
gem 'rubocop-ast'
```

## Usage

Refer to the documentation of `RuboCop::AST::Node` and [`RuboCop::AST::NodePattern`](docs/modules/ROOT/pages/node_pattern.adoc)

### Parser compatibility switches

The main `RuboCop` gem uses [legacy AST output from parser](https://github.com/whitequark/parser/#usage).
This gem is meant to be compatible with all settings. For example, to have `-> { ... }` emitted
as `LambdaNode` instead of `SendNode`:

```ruby
RuboCop::AST::Builder.emit_lambda = true
```

## Contributing

Checkout the [contribution guidelines](CONTRIBUTING.md).

## License

`rubocop-ast` is MIT licensed. [See the accompanying file](LICENSE.txt) for
the full text.
