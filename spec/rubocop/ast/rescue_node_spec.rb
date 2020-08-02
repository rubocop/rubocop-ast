# frozen_string_literal: true

RSpec.describe RuboCop::AST::RescueNode do
  let(:ast) { parse_source(source).ast }
  let(:rescue_node) { ast.children.first }

  describe '.new' do
    let(:source) { <<~RUBY }
      begin
      rescue => e
      end
    RUBY

    it { expect(rescue_node.is_a?(described_class)).to be(true) }
  end

  describe '#body' do
    let(:source) { <<~RUBY }
      begin
        foo
      rescue => e
      end
    RUBY

    it { expect(rescue_node.body.send_type?).to be(true) }
  end

  describe '#resbody_branches' do
    let(:source) { <<~RUBY }
      begin
      rescue FooError then foo
      rescue BarError, BazError then bar_and_baz
      end
    RUBY

    it { expect(rescue_node.resbody_branches.size).to eq(2) }
    it { expect(rescue_node.resbody_branches).to all(be_resbody_type) }
  end

  describe '#branches' do
    context 'when there is an else' do
      let(:source) { <<~RUBY }
        begin
        rescue FooError then foo
        rescue BarError then # do nothing
        else 'bar'
        end
      RUBY

      it 'returns all the bodies' do
        expect(rescue_node.branches).to match [be_send_type, nil, be_str_type]
      end

      context 'with an empty else' do
        let(:source) { <<~RUBY }
          begin
          rescue FooError then foo
          rescue BarError then # do nothing
          else # do nothing
          end
        RUBY

        it 'returns all the bodies' do
          expect(rescue_node.branches).to match [be_send_type, nil, nil]
        end
      end
    end

    context 'when there is no else keyword' do
      let(:source) { <<~RUBY }
        begin
        rescue FooError then foo
        rescue BarError then # do nothing
        end
      RUBY

      it 'returns only then rescue bodies' do
        expect(rescue_node.branches).to match [be_send_type, nil]
      end
    end
  end

  describe '#else_branch' do
    context 'without an else statement' do
      let(:source) { <<~RUBY }
        begin
        rescue FooError then foo
        end
      RUBY

      it { expect(rescue_node.else_branch.nil?).to be(true) }
    end

    context 'with an else statement' do
      let(:source) { <<~RUBY }
        begin
        rescue FooError then foo
        else bar
        end
      RUBY

      it { expect(rescue_node.else_branch.send_type?).to be(true) }
    end
  end

  describe '#else?' do
    context 'without an else statement' do
      let(:source) { <<~RUBY }
        begin
        rescue FooError then foo
        end
      RUBY

      it { expect(rescue_node.else?).to be_falsey }
    end

    context 'with an else statement' do
      let(:source) { <<~RUBY }
        begin
        rescue FooError then foo
        else bar
        end
      RUBY

      it { expect(rescue_node.else?).to be_truthy }
    end
  end
end
