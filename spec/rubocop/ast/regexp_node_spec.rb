# frozen_string_literal: true

RSpec.describe RuboCop::AST::RegexpNode do
  subject(:regexp_node) { parse_source(source).ast }

  describe '.new' do
    let(:source) { '/re/' }

    it { is_expected.to be_a(described_class) }
  end

  describe '#to_regexp' do
    # rubocop:disable Security/Eval
    context 'with an empty regexp' do
      let(:source) { '//' }

      it { expect(regexp_node.to_regexp).to eq(eval(source)) }
    end

    context 'with a regexp without option' do
      let(:source) { '/.+/' }

      it { expect(regexp_node.to_regexp).to eq(eval(source)) }
    end

    context 'with a multi-line regexp without option' do
      let(:source) { "/\n.+\n/" }

      it { expect(regexp_node.to_regexp).to eq(eval(source)) }
    end

    context 'with an empty regexp with option' do
      let(:source) { '//ix' }

      it { expect(regexp_node.to_regexp).to eq(eval(source)) }
    end

    context 'with a regexp with option' do
      let(:source) { '/.+/imx' }

      it { expect(regexp_node.to_regexp).to eq(eval(source)) }
    end

    context 'with a multi-line regexp with option' do
      let(:source) { "/\n.+\n/ix" }

      it { expect(regexp_node.to_regexp).to eq(eval(source)) }
    end
    # rubocop:enable Security/Eval

    context 'with a regexp with an "o" option' do
      let(:source) { '/abc/io' }

      it { expect(regexp_node.to_regexp.inspect).to eq('/abc/i') }
    end

    context 'with a regexp with an "n" option' do
      let(:source) { '/abc/n' }

      it { expect(regexp_node.to_regexp.inspect).to eq('/abc/n') }
    end

    context 'with a regexp with an "u" option' do
      let(:source) { '/abc/u' }

      it { expect(regexp_node.to_regexp.inspect).to eq('/abc/') }
    end
  end

  describe '#regopt' do
    let(:regopt) { regexp_node.regopt }

    context 'with an empty regexp' do
      let(:source) { '//' }

      it { expect(regopt).to be_regopt_type }
      it { expect(regopt.children).to be_empty }
    end

    context 'with a regexp without option' do
      let(:source) { '/.+/' }

      it { expect(regopt).to be_regopt_type }
      it { expect(regopt.children).to be_empty }
    end

    context 'with a multi-line regexp without option' do
      let(:source) { "/\n.+\n/" }

      it { expect(regopt).to be_regopt_type }
      it { expect(regopt.children).to be_empty }
    end

    context 'with an empty regexp with option' do
      let(:source) { '//ix' }

      it { expect(regopt).to be_regopt_type }
      it { expect(regopt.children).to eq(%i[i x]) }
    end

    context 'with a regexp with option' do
      let(:source) { '/.+/imx' }

      it { expect(regopt).to be_regopt_type }
      it { expect(regopt.children).to eq(%i[i m x]) }
    end

    context 'with a multi-line regexp with option' do
      let(:source) { "/\n.+\n/imx" }

      it { expect(regopt).to be_regopt_type }
      it { expect(regopt.children).to eq(%i[i m x]) }
    end
  end

  describe '#options' do
    let(:actual_options) { regexp_node.options }
    # rubocop:disable Security/Eval
    let(:expected_options) { eval(source).options }
    # rubocop:enable Security/Eval

    context 'with an empty regexp' do
      let(:source) { '//' }

      it { expect(actual_options).to eq(expected_options) }
    end

    context 'with a regexp without option' do
      let(:source) { '/.+/' }

      it { expect(actual_options).to eq(expected_options) }
    end

    context 'with a regexp with single option' do
      let(:source) { '/.+/i' }

      it { expect(actual_options).to eq(expected_options) }
    end

    context 'with a regexp with multiple options' do
      let(:source) { '/.+/ix' }

      it { expect(actual_options).to eq(expected_options) }
    end

    context 'with a regexp with "o" option' do
      let(:source) { '/.+/o' }

      it { expect(actual_options).to eq(expected_options) }
    end
  end

  describe '#content' do
    let(:content) { regexp_node.content }

    context 'with an empty regexp' do
      let(:source) { '//' }

      it { expect(content).to eq('') }
    end

    context 'with a regexp without option' do
      let(:source) { '/.+/' }

      it { expect(content).to eq('.+') }
    end

    context 'with a multi-line regexp without option' do
      let(:source) { "/\n.+\n/" }

      it { expect(content).to eq("\n.+\n") }
    end

    context 'with an empty regexp with option' do
      let(:source) { '//ix' }

      it { expect(content).to eq('') }
    end

    context 'with a regexp with option' do
      let(:source) { '/.+/imx' }

      it { expect(content).to eq('.+') }
    end

    context 'with a multi-line regexp with option' do
      let(:source) { "/\n.+\n/imx" }

      it { expect(content).to eq("\n.+\n") }
    end
  end

  describe '#slash_literal?' do
    context 'with /-delimiters' do
      let(:source) { '/abc/' }

      it { is_expected.to be_slash_literal }
    end

    context 'with %r/-delimiters' do
      let(:source) { '%r/abc/' }

      it { is_expected.not_to be_slash_literal }
    end

    context 'with %r{-delimiters' do
      let(:source) { '%r{abc}' }

      it { is_expected.not_to be_slash_literal }
    end

    context 'with multi-line %r{-delimiters' do
      let(:source) do
        <<~SRC
          %r{
            abc
          }x
        SRC
      end

      it { is_expected.not_to be_slash_literal }
    end

    context 'with %r<-delimiters' do
      let(:source) { '%r<abc>x' }

      it { is_expected.not_to be_slash_literal }
    end
  end

  describe '#percent_r_literal?' do
    context 'with /-delimiters' do
      let(:source) { '/abc/' }

      it { is_expected.not_to be_percent_r_literal }
    end

    context 'with %r/-delimiters' do
      let(:source) { '%r/abc/' }

      it { is_expected.to be_percent_r_literal }
    end

    context 'with %r{-delimiters' do
      let(:source) { '%r{abc}' }

      it { is_expected.to be_percent_r_literal }
    end

    context 'with multi-line %r{-delimiters' do
      let(:source) do
        <<~SRC
          %r{
            abc
          }x
        SRC
      end

      it { is_expected.to be_percent_r_literal }
    end

    context 'with %r<-delimiters' do
      let(:source) { '%r<abc>x' }

      it { is_expected.to be_percent_r_literal }
    end
  end

  describe '#delimiters' do
    context 'with /-delimiters' do
      let(:source) { '/abc/' }

      it { expect(regexp_node.delimiters).to eq(['/', '/']) }
    end

    context 'with %r/-delimiters' do
      let(:source) { '%r/abc/' }

      it { expect(regexp_node.delimiters).to eq(['/', '/']) }
    end

    context 'with %r{-delimiters' do
      let(:source) { '%r{abc}' }

      it { expect(regexp_node.delimiters).to eq(['{', '}']) }
    end

    context 'with multi-line %r{-delimiters' do
      let(:source) do
        <<~SRC
          %r{
            abc
          }x
        SRC
      end

      it { expect(regexp_node.delimiters).to eq(['{', '}']) }
    end

    context 'with %r<-delimiters' do
      let(:source) { '%r<abc>x' }

      it { expect(regexp_node.delimiters).to eq(['<', '>']) }
    end
  end

  describe '#delimiter?' do
    context 'with /-delimiters' do
      let(:source) { '/abc/' }

      it { is_expected.to be_delimiter('/') }

      it { is_expected.not_to be_delimiter('{') }
    end

    context 'with %r/-delimiters' do
      let(:source) { '%r/abc/' }

      it { is_expected.to be_delimiter('/') }

      it { is_expected.not_to be_delimiter('{') }
      it { is_expected.not_to be_delimiter('}') }
      it { is_expected.not_to be_delimiter('%') }
      it { is_expected.not_to be_delimiter('r') }
      it { is_expected.not_to be_delimiter('%r') }
      it { is_expected.not_to be_delimiter('%r/') }
    end

    context 'with %r{-delimiters' do
      let(:source) { '%r{abc}' }

      it { is_expected.to be_delimiter('{') }
      it { is_expected.to be_delimiter('}') }

      it { is_expected.not_to be_delimiter('/') }
      it { is_expected.not_to be_delimiter('%') }
      it { is_expected.not_to be_delimiter('r') }
      it { is_expected.not_to be_delimiter('%r') }
      it { is_expected.not_to be_delimiter('%r/') }
      it { is_expected.not_to be_delimiter('%r{') }
    end

    context 'with multi-line %r{-delimiters' do
      let(:source) do
        <<~SRC
          %r{
            abc
          }x
        SRC
      end

      it { is_expected.to be_delimiter('{') }
      it { is_expected.to be_delimiter('}') }

      it { is_expected.not_to be_delimiter('/') }
      it { is_expected.not_to be_delimiter('%') }
      it { is_expected.not_to be_delimiter('r') }
      it { is_expected.not_to be_delimiter('%r') }
      it { is_expected.not_to be_delimiter('%r/') }
      it { is_expected.not_to be_delimiter('%r{') }
    end

    context 'with %r<-delimiters' do
      let(:source) { '%r<abc>x' }

      it { is_expected.to be_delimiter('<') }
      it { is_expected.to be_delimiter('>') }

      it { is_expected.not_to be_delimiter('{') }
      it { is_expected.not_to be_delimiter('}') }
      it { is_expected.not_to be_delimiter('/') }
      it { is_expected.not_to be_delimiter('%') }
      it { is_expected.not_to be_delimiter('r') }
      it { is_expected.not_to be_delimiter('%r') }
      it { is_expected.not_to be_delimiter('%r/') }
      it { is_expected.not_to be_delimiter('%r{') }
      it { is_expected.not_to be_delimiter('%r<') }
    end
  end

  describe '#interpolation?' do
    context 'with direct variable interpoation' do
      let(:source) { '/\n\n#{foo}(abc)+/' }

      it { is_expected.to be_interpolation }
    end

    context 'with regexp quote' do
      let(:source) { '/\n\n#{Regexp.quote(foo)}(abc)+/' }

      it { is_expected.to be_interpolation }
    end

    context 'with no interpolation returns false' do
      let(:source) { '/a{3,6}/' }

      it { is_expected.not_to be_interpolation }
    end
  end

  describe '#multiline_mode?' do
    context 'with no options' do
      let(:source) { '/x/' }

      it { is_expected.not_to be_multiline_mode }
    end

    context 'with other options' do
      let(:source) { '/x/ix' }

      it { is_expected.not_to be_multiline_mode }
    end

    context 'with only m option' do
      let(:source) { '/x/m' }

      it { is_expected.to be_multiline_mode }
    end

    context 'with m and other options' do
      let(:source) { '/x/imx' }

      it { is_expected.to be_multiline_mode }
    end
  end

  describe '#extended?' do
    context 'with no options' do
      let(:source) { '/x/' }

      it { is_expected.not_to be_extended }
    end

    context 'with other options' do
      let(:source) { '/x/im' }

      it { is_expected.not_to be_extended }
    end

    context 'with only x option' do
      let(:source) { '/x/x' }

      it { is_expected.to be_extended }
    end

    context 'with x and other options' do
      let(:source) { '/x/ixm' }

      it { is_expected.to be_extended }
    end
  end

  describe '#ignore_case?' do
    context 'with no options' do
      let(:source) { '/x/' }

      it { is_expected.not_to be_ignore_case }
    end

    context 'with other options' do
      let(:source) { '/x/xm' }

      it { is_expected.not_to be_ignore_case }
    end

    context 'with only i option' do
      let(:source) { '/x/i' }

      it { is_expected.to be_ignore_case }
    end

    context 'with i and other options' do
      let(:source) { '/x/xim' }

      it { is_expected.to be_ignore_case }
    end
  end

  describe '#no_encoding?' do
    context 'with no options' do
      let(:source) { '/x/' }

      it { is_expected.not_to be_no_encoding }
    end

    context 'with other options' do
      let(:source) { '/x/xm' }

      it { is_expected.not_to be_no_encoding }
    end

    context 'with only n option' do
      let(:source) { '/x/n' }

      it { is_expected.to be_no_encoding }
    end

    context 'with n and other options' do
      let(:source) { '/x/xnm' }

      it { is_expected.to be_no_encoding }
    end
  end

  describe '#fixed_encoding?' do
    context 'with no options' do
      let(:source) { '/x/' }

      it { is_expected.not_to be_fixed_encoding }
    end

    context 'with other options' do
      let(:source) { '/x/xm' }

      it { is_expected.not_to be_fixed_encoding }
    end

    context 'with only u option' do
      let(:source) { '/x/u' }

      it { is_expected.to be_fixed_encoding }
    end

    context 'with u and other options' do
      let(:source) { '/x/unm' }

      it { is_expected.to be_fixed_encoding }
    end
  end

  describe '#single_interpolation?' do
    context 'with no options' do
      let(:source) { '/x/' }

      it { is_expected.not_to be_single_interpolation }
    end

    context 'with other options' do
      let(:source) { '/x/xm' }

      it { is_expected.not_to be_single_interpolation }
    end

    context 'with only o option' do
      let(:source) { '/x/o' }

      it { is_expected.to be_single_interpolation }
    end

    context 'with o and other options' do
      let(:source) { '/x/xom' }

      it { is_expected.to be_single_interpolation }
    end
  end
end
