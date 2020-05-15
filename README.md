# RuboCop AST

[![Gem Version](https://badge.fury.io/rb/rubocop-ast.svg)](https://badge.fury.io/rb/rubocop-ast)
[![CI](https://github.com/rubocop-hq/rubocop-ast/workflows/CI/badge.svg)](https://github.com/rubocop-hq/rubocop-ast/actions?query=workflow%3ACI)

Contains the classes needed by [RuboCop](https://github.com/rubocop-hq/rubocop) to deal with Ruby's AST, in particular:
* `RuboCop::AST::Node`
* `RuboCop::AST::NodePattern` ([doc](manual/node_pattern.md))

This gem may be used independently from the main RuboCop gem.

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

Refer to the documentation of `RuboCop::AST::Node` and [`RuboCop::AST::NodePattern`](manual/node_pattern.md)

## Contributing

Checkout the [contribution guidelines](CONTRIBUTING.md).

## License

`rubocop-ast` is MIT licensed. [See the accompanying file](LICENSE.txt) for
the full text.
