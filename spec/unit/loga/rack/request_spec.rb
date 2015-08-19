require 'spec_helper'

describe Loga::Rack::Request do
  let(:options)   { {} }
  let(:full_path) { '/' }
  let(:env)       { Rack::MockRequest.env_for(full_path, options) }

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

  describe '#original_path' do
    let(:path)    { 'users/5/oranges' }
    let(:options) { { 'loga.request.original_path' => path } }

    it 'returns path based on loga request env' do
      expect(subject.original_path).to eq(path)
    end
  end

  describe '#filtered_full_path' do
    let(:config) { double :config, filter_parameters: [:password] }

    let(:path)         { '/hello' }
    let(:query)        { { 'password' => 123, 'color' => 'red' }  }
    let(:query_string) { Rack::Utils.build_query(query) }
    let(:full_path)    { "#{path}?#{query_string}" }

    let(:options) { { 'loga.request.original_path' => path } }

    before do
      allow(Loga).to receive(:configuration).and_return(config)
    end

    context 'request with sensitive parameters' do
      it 'returns the path with sensitive parameters filtered' do
        expect(subject.filtered_full_path).to eq('/hello?password=[FILTERED]&color=red')
      end
    end

    it 'memoizes the result' do
      expect(subject.filtered_full_path).to equal(subject.filtered_full_path)
    end
  end

  describe '#filtered_parameters' do
    pending 'returns both query and form filered parameters'

    it 'memoizes the result' do
      expect(subject.filtered_parameters).to equal(subject.filtered_parameters)
    end
  end
end
