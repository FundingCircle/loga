require 'spec_helper'

describe Loga::Rack::Request do
  let(:options) { {} }
  let(:env)     { Rack::MockRequest.env_for('/', options) }

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
end
