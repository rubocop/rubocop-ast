# frozen_string_literal: true

RSpec.describe RuboCop::AST::ResbodyNode do
  let(:resbody_node) do
    begin_node = parse_source(source).ast
    rescue_node, = *begin_node
    rescue_node.children[1]
  end

  describe '.new' do
    let(:source) { 'begin; beginbody; rescue; rescuebody; end' }

    it { expect(resbody_node.is_a?(described_class)).to be(true) }
  end

  describe '#exceptions' do
    context 'without exception' do
      let(:source) { <<~RUBY }
        begin
        rescue
        end
      RUBY

      it { expect(resbody_node.exceptions.size).to eq(0) }
    end

    context 'with a single exception' do
      let(:source) { <<~RUBY }
        begin
        rescue FooError
        end
      RUBY

      it { expect(resbody_node.exceptions.size).to eq(1) }
      it { expect(resbody_node.exceptions).to all(be_const_type) }
    end

    context 'with multiple exceptions' do
      let(:source) { <<~RUBY }
        begin
        rescue FooError, BarError
        end
      RUBY

      it { expect(resbody_node.exceptions.size).to eq(2) }
      it { expect(resbody_node.exceptions).to all(be_const_type) }
    end
  end

  describe '#exception_variable' do
    context 'for an explicit rescue' do
      let(:source) { 'begin; beginbody; rescue Error => ex; rescuebody; end' }

      it { expect(resbody_node.exception_variable.source).to eq('ex') }
    end

    context 'for an implicit rescue' do
      let(:source) { 'begin; beginbody; rescue => ex; rescuebody; end' }

      it { expect(resbody_node.exception_variable.source).to eq('ex') }
    end

    context 'when an exception variable is not given' do
      let(:source) { 'begin; beginbody; rescue; rescuebody; end' }

      it { expect(resbody_node.exception_variable).to be(nil) }
    end
  end

  describe '#body' do
    let(:source) { 'begin; beginbody; rescue Error => ex; :rescuebody; end' }

    it { expect(resbody_node.body.sym_type?).to be(true) }
  end

  describe '#branch_index' do
    let(:source) { <<~RUBY }
      begin
      rescue FooError then foo
      rescue BarError, BazError then bar_and_baz
      rescue QuuxError => e then quux
      end
    RUBY

    let(:resbodies) { parse_source(source).ast.children.first.resbody_branches }

    it { expect(resbodies[0].branch_index).to eq(0) }
    it { expect(resbodies[1].branch_index).to eq(1) }
    it { expect(resbodies[2].branch_index).to eq(2) }
  end
end
