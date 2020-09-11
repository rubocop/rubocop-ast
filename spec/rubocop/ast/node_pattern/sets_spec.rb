# frozen_string_literal: true

RSpec.describe RuboCop::AST::NodePattern::Sets do
  subject(:name) { described_class[set] }

  let(:set) { Set[1, 2, 3, 4, 5, 6] }

  it { is_expected.to eq '::RuboCop::AST::NodePattern::Sets::SET_1_2_3_ETC' }

  it { is_expected.to eq described_class[Set[6, 5, 4, 3, 2, 1]] }

  it { is_expected.not_to eq described_class[Set[1, 2, 3, 4, 5, 6, 7]] }

  it 'creates a constant with the right value' do
    expect(eval(name)).to eq set # rubocop:disable Security/Eval
  end
end
