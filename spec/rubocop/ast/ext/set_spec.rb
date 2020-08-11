# frozen_string_literal: true

# rubocop:disable RSpec/DescribeClass, Style/CaseEquality
RSpec.describe 'Set#===' do
  it 'tests for inclusion' do
    expect(Set[1, 2, 3] === 2).to eq true
  end
end
# rubocop:enable RSpec/DescribeClass, Style/CaseEquality
