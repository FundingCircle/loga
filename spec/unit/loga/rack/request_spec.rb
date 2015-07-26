require 'spec_helper'

describe Loga::Rack::Request do
  let(:options) { {} }
  let(:path)    { '/' }
  let(:env)     { Rack::MockRequest.env_for(path, options) }

  subject { described_class.new(env) }

  describe '#uuid' do
    let(:action_dispatch_request_id) { 'ABCD' }

    context 'when ACTION_DISPATCH_REQUEST_ID present' do
      let(:options) do
        { 'action_dispatch.request_id' => action_dispatch_request_id }
      end
      it 'returns the middleware value' do
        expect(subject.uuid).to eq(action_dispatch_request_id)
      end
    end

    context 'when ACTION_DISPATCH_REQUEST_ID blank' do
      it 'returns nil' do
        expect(subject.uuid).to be_nil
      end
    end
  end

  describe '#filtered_path' do
    let(:config) { double :config, filter_parameters: [:password] }

    before do
      allow(Loga).to receive(:configuration).and_return(config)
    end

    context 'request with sensitive parameters' do
      let(:path) { '/hello?password=123&color=red' }

      it 'returns the path with sensitive parameters filtered' do
        expect(subject.filtered_path).to eq('/hello?password=[FILTERED]&color=red')
      end
    end

    context 'request with no parameters' do
      let(:path) { '/hello' }

      it 'returns the path as is' do
        expect(subject.filtered_path).to eq('/hello')
      end
    end

    it 'memoizes the result' do
      expect(subject.filtered_path).to equal(subject.filtered_path)
    end
  end

  describe '#filtered_parameters' do
    it 'memoizes the result' do
      expect(subject.filtered_parameters).to equal(subject.filtered_parameters)
    end
  end
end
