# frozen_string_literal: true

RSpec.describe RuboCop::AST::AutoConstToSet do
  let(:mod) do
    Module.new do
      extend RuboCop::AST::AutoConstToSet
    end
  end

  before do
    stub_const('Mod', mod)
    stub_const('Mod::WORDS', %w[hello world].freeze)
  end

  it 'automatically creates set variants for array constants' do
    expect(mod.constants).not_to include :WORDS_SET
    expect(mod::WORDS_SET).to eq Set['hello', 'world']
  end

  it 'raises an erreor if constant is already a set' do
    stub_const('Mod::WORDS', %w[hello world].to_set.freeze)
    expect { mod::WORDS_SET }.to raise_error(TypeError)
  end
end
