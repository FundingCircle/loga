require 'spec_helper'

describe Loga::Rack::Request do
  let(:options)   { {} }
  let(:full_path) { '/' }
  let(:env)       { Rack::MockRequest.env_for(full_path, options) }

  let(:action_controller_class) do
    ApplicationController = Class.new do
      def action_name
        'index'
      end
    end
  end

  let(:config) { instance_double Loga::Configuration, filter_parameters: [:password] }

  before do
    allow(Loga).to receive(:configuration).and_return(config)
  end

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

  describe '#action_controller_instance' do
    let(:action_controller_instance) { action_controller_class.new }

    context 'when ACTION_CONTROLLER_INSTANCE is present' do
      let(:options) do
        { 'action_controller.instance' => action_controller_instance }
      end
      it 'returns the instance' do
        expect(subject.action_controller_instance).to eq(action_controller_instance)
      end
    end

    context 'when ACTION_DISPATCH_REQUEST_ID blank' do
      it 'returns nil' do
        expect(subject.action_controller_instance).to be_nil
      end
    end
  end

  describe '#action_controller' do
    let(:options) do
      { 'action_controller.instance' => action_controller_class.new }
    end

    it 'returns the controller with the action_name' do
      expect(subject.action_controller).to eq('ApplicationController#index')
    end
  end

  describe '#request_id' do
    let(:action_dispatch_request_id) { 'ABCD' }
    let(:options) do
      { 'action_dispatch.request_id' => action_dispatch_request_id }
    end

    it 'aliases to uuid' do
      expect(subject.request_id).to eq(subject.uuid)
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
    let(:path)         { '/hello' }
    let(:query)        { { 'password' => 123, 'color' => 'red' }  }
    let(:query_string) { Rack::Utils.build_query(query) }
    let(:full_path)    { "#{path}?#{query_string}" }

    let(:options) { { 'loga.request.original_path' => path } }

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
