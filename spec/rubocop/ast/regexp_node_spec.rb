# frozen_string_literal: true

RSpec.describe RuboCop::AST::RegexpNode do
  let(:regexp_node) { parse_source(source).ast }

  describe '.new' do
    let(:source) { '/re/' }

    it { expect(regexp_node.is_a?(described_class)).to be(true) }
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
  end

  describe '#regopt' do
    let(:regopt) { regexp_node.regopt }

    context 'with an empty regexp' do
      let(:source) { '//' }

      it { expect(regopt.regopt_type?).to be(true) }
      it { expect(regopt.children.empty?).to be(true) }
    end

    context 'with a regexp without option' do
      let(:source) { '/.+/' }

      it { expect(regopt.regopt_type?).to be(true) }
      it { expect(regopt.children.empty?).to be(true) }
    end

    context 'with a multi-line regexp without option' do
      let(:source) { "/\n.+\n/" }

      it { expect(regopt.regopt_type?).to be(true) }
      it { expect(regopt.children.empty?).to be(true) }
    end

    context 'with an empty regexp with option' do
      let(:source) { '//ix' }

      it { expect(regopt.regopt_type?).to be(true) }
      it { expect(regopt.children).to eq(%i[i x]) }
    end

    context 'with a regexp with option' do
      let(:source) { '/.+/imx' }

      it { expect(regopt.regopt_type?).to be(true) }
      it { expect(regopt.children).to eq(%i[i m x]) }
    end

    context 'with a multi-line regexp with option' do
      let(:source) { "/\n.+\n/imx" }

      it { expect(regopt.regopt_type?).to be(true) }
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

      it { expect(regexp_node.slash_literal?).to eq(true) }
    end

    context 'with %r/-delimiters' do
      let(:source) { '%r/abc/' }

      it { expect(regexp_node.slash_literal?).to eq(false) }
    end

    context 'with %r{-delimiters' do
      let(:source) { '%r{abc}' }

      it { expect(regexp_node.slash_literal?).to eq(false) }
    end

    context 'with multi-line %r{-delimiters' do
      let(:source) do
        <<~SRC
          %r{
            abc
          }x
        SRC
      end

      it { expect(regexp_node.slash_literal?).to eq(false) }
    end

    context 'with %r<-delimiters' do
      let(:source) { '%r<abc>x' }

      it { expect(regexp_node.slash_literal?).to eq(false) }
    end
  end

  describe '#percent_r_literal?' do
    context 'with /-delimiters' do
      let(:source) { '/abc/' }

      it { expect(regexp_node.percent_r_literal?).to eq(false) }
    end

    context 'with %r/-delimiters' do
      let(:source) { '%r/abc/' }

      it { expect(regexp_node.percent_r_literal?).to eq(true) }
    end

    context 'with %r{-delimiters' do
      let(:source) { '%r{abc}' }

      it { expect(regexp_node.percent_r_literal?).to eq(true) }
    end

    context 'with multi-line %r{-delimiters' do
      let(:source) do
        <<~SRC
          %r{
            abc
          }x
        SRC
      end

      it { expect(regexp_node.percent_r_literal?).to eq(true) }
    end

    context 'with %r<-delimiters' do
      let(:source) { '%r<abc>x' }

      it { expect(regexp_node.percent_r_literal?).to eq(true) }
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

      it { expect(regexp_node.delimiter?('/')).to eq(true) }

      it { expect(regexp_node.delimiter?('{')).to eq(false) }
    end

    context 'with %r/-delimiters' do
      let(:source) { '%r/abc/' }

      it { expect(regexp_node.delimiter?('/')).to eq(true) }

      it { expect(regexp_node.delimiter?('{')).to eq(false) }
      it { expect(regexp_node.delimiter?('}')).to eq(false) }
      it { expect(regexp_node.delimiter?('%')).to eq(false) }
      it { expect(regexp_node.delimiter?('r')).to eq(false) }
      it { expect(regexp_node.delimiter?('%r')).to eq(false) }
      it { expect(regexp_node.delimiter?('%r/')).to eq(false) }
    end

    context 'with %r{-delimiters' do
      let(:source) { '%r{abc}' }

      it { expect(regexp_node.delimiter?('{')).to eq(true) }
      it { expect(regexp_node.delimiter?('}')).to eq(true) }

      it { expect(regexp_node.delimiter?('/')).to eq(false) }
      it { expect(regexp_node.delimiter?('%')).to eq(false) }
      it { expect(regexp_node.delimiter?('r')).to eq(false) }
      it { expect(regexp_node.delimiter?('%r')).to eq(false) }
      it { expect(regexp_node.delimiter?('%r/')).to eq(false) }
      it { expect(regexp_node.delimiter?('%r{')).to eq(false) }
    end

    context 'with multi-line %r{-delimiters' do
      let(:source) do
        <<~SRC
          %r{
            abc
          }x
        SRC
      end

      it { expect(regexp_node.delimiter?('{')).to eq(true) }
      it { expect(regexp_node.delimiter?('}')).to eq(true) }

      it { expect(regexp_node.delimiter?('/')).to eq(false) }
      it { expect(regexp_node.delimiter?('%')).to eq(false) }
      it { expect(regexp_node.delimiter?('r')).to eq(false) }
      it { expect(regexp_node.delimiter?('%r')).to eq(false) }
      it { expect(regexp_node.delimiter?('%r/')).to eq(false) }
      it { expect(regexp_node.delimiter?('%r{')).to eq(false) }
    end

    context 'with %r<-delimiters' do
      let(:source) { '%r<abc>x' }

      it { expect(regexp_node.delimiter?('<')).to eq(true) }
      it { expect(regexp_node.delimiter?('>')).to eq(true) }

      it { expect(regexp_node.delimiter?('{')).to eq(false) }
      it { expect(regexp_node.delimiter?('}')).to eq(false) }
      it { expect(regexp_node.delimiter?('/')).to eq(false) }
      it { expect(regexp_node.delimiter?('%')).to eq(false) }
      it { expect(regexp_node.delimiter?('r')).to eq(false) }
      it { expect(regexp_node.delimiter?('%r')).to eq(false) }
      it { expect(regexp_node.delimiter?('%r/')).to eq(false) }
      it { expect(regexp_node.delimiter?('%r{')).to eq(false) }
      it { expect(regexp_node.delimiter?('%r<')).to eq(false) }
    end
  end

  describe '#interpolation?' do
    context 'with direct variable interpoation' do
      let(:source) { '/\n\n#{foo}(abc)+/' }

      it { expect(regexp_node.interpolation?).to eq(true) }
    end

    context 'with regexp quote' do
      let(:source) { '/\n\n#{Regexp.quote(foo)}(abc)+/' }

      it { expect(regexp_node.interpolation?).to eq(true) }
    end

    context 'with no interpolation returns false' do
      let(:source) { '/a{3,6}/' }

      it { expect(regexp_node.interpolation?).to eq(false) }
    end
  end

  describe '#multiline_mode?' do
    context 'with no options' do
      let(:source) { '/x/' }

      it { expect(regexp_node.multiline_mode?).to be(false) }
    end

    context 'with other options' do
      let(:source) { '/x/ix' }

      it { expect(regexp_node.multiline_mode?).to be(false) }
    end

    context 'with only m option' do
      let(:source) { '/x/m' }

      it { expect(regexp_node.multiline_mode?).to be(true) }
    end

    context 'with m and other options' do
      let(:source) { '/x/imx' }

      it { expect(regexp_node.multiline_mode?).to be(true) }
    end
  end

  describe '#extended?' do
    context 'with no options' do
      let(:source) { '/x/' }

      it { expect(regexp_node.extended?).to be(false) }
    end

    context 'with other options' do
      let(:source) { '/x/im' }

      it { expect(regexp_node.extended?).to be(false) }
    end

    context 'with only x option' do
      let(:source) { '/x/x' }

      it { expect(regexp_node.extended?).to be(true) }
    end

    context 'with x and other options' do
      let(:source) { '/x/ixm' }

      it { expect(regexp_node.extended?).to be(true) }
    end
  end

  describe '#ignore_case?' do
    context 'with no options' do
      let(:source) { '/x/' }

      it { expect(regexp_node.ignore_case?).to be(false) }
    end

    context 'with other options' do
      let(:source) { '/x/xm' }

      it { expect(regexp_node.ignore_case?).to be(false) }
    end

    context 'with only i option' do
      let(:source) { '/x/i' }

      it { expect(regexp_node.ignore_case?).to be(true) }
    end

    context 'with i and other options' do
      let(:source) { '/x/xim' }

      it { expect(regexp_node.ignore_case?).to be(true) }
    end
  end

  describe '#no_encoding?' do
    context 'with no options' do
      let(:source) { '/x/' }

      it { expect(regexp_node.no_encoding?).to be(false) }
    end

    context 'with other options' do
      let(:source) { '/x/xm' }

      it { expect(regexp_node.no_encoding?).to be(false) }
    end

    context 'with only n option' do
      let(:source) { '/x/n' }

      it { expect(regexp_node.no_encoding?).to be(true) }
    end

    context 'with n and other options' do
      let(:source) { '/x/xnm' }

      it { expect(regexp_node.no_encoding?).to be(true) }
    end
  end

  describe '#single_interpolation?' do
    context 'with no options' do
      let(:source) { '/x/' }

      it { expect(regexp_node.single_interpolation?).to be(false) }
    end

    context 'with other options' do
      let(:source) { '/x/xm' }

      it { expect(regexp_node.single_interpolation?).to be(false) }
    end

    context 'with only o option' do
      let(:source) { '/x/o' }

      it { expect(regexp_node.single_interpolation?).to be(true) }
    end

    context 'with o and other options' do
      let(:source) { '/x/xom' }

      it { expect(regexp_node.single_interpolation?).to be(true) }
    end
  end
end
