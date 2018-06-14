require 'spec_helper'

RSpec.describe Loga::ParameterFilter do
  let(:filters) { [:password, /token/] }

  shared_examples 'compiled filter' do
    let(:compiled_filters) { described_class::CompiledFilter }

    before do
      allow(compiled_filters).to receive(:compile).and_call_original
    end

    it 'compiles filters only once' do
      2.times { subject.filter(params) }
      expect(compiled_filters).to have_received(:compile).once
    end
  end

  describe '#filter(params)' do
    subject { described_class.new(filters) }

    let(:params) do
      {
        password: 'password123',
        email: 'hello@world.com',
        token: 'ABC',
      }
    end

    let(:result) do
      {
        password: '[FILTERED]',
        email: 'hello@world.com',
        token: '[FILTERED]',
      }
    end

    context 'when no filters are applied' do
      let(:filters) { [] }

      it 'returns params' do
        expect(subject.filter(params)).to match(params)
      end

      include_examples 'compiled filter'
    end

    context 'when params is shallow' do
      it 'returns filtered params' do
        expect(subject.filter(params)).to match(result)
      end

      include_examples 'compiled filter'
    end

    context 'when params has a nested Hash' do
      let(:params) { { user: super() } }

      it 'returns filtered params' do
        expect(subject.filter(params)).to match(user: result)
      end

      include_examples 'compiled filter'
    end

    context 'when params has a nested Array' do
      let(:params) { { users: [super(), super()] } }

      it 'returns filtered params' do
        expect(subject.filter(params)).to match(users: [result, result])
      end

      include_examples 'compiled filter'
    end
  end
end
