# frozen_string_literal: true

RSpec.describe RuboCop::SimpleForwardable do
  let(:delegator) do
    Class.new do
      attr_reader :target

      def initialize
        @target = Struct.new(:foo).new
      end

      extend RuboCop::SimpleForwardable

      def_delegators :target, :foo=, :foo
    end
  end

  it 'correctly delegates to writer methods' do
    d = delegator.new
    d.foo = 123
    expect(d.foo).to eq(123)
  end
end
