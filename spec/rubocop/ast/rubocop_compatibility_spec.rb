# frozen_string_literal: true

RSpec.describe RuboCop::AST::RuboCopCompatibility do # rubocop:disable RSpec/FilePath
  subject(:callback) { RuboCop::AST.rubocop_loaded }

  before do
    stub_const '::RuboCop::Version::STRING', rubocop_version
  end

  context 'when ran from an incompatible version of Rubocop' do
    let(:rubocop_version) { '0.42.0' }

    it 'issues a warning' do
      expect { callback }.to output(/LineLength/).to_stderr
    end
  end

  context 'when ran from a compatible version of Rubocop' do
    let(:rubocop_version) { '0.92.0' }

    it 'issues a warning' do
      expect { callback }.not_to output.to_stderr
    end
  end
end
