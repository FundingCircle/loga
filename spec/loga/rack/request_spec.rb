require 'spec_helper'

describe Loga::Rack::Request do
  let(:options) { {} }
  let(:env)     { Rack::MockRequest.env_for('/', options) }

  subject { described_class.new(env) }

  describe '#uuid' do
    let(:http_x_request_id)          { 'A-B-C-D' }
    let(:action_dispatch_request_id) { 'ABCD' }

    context 'when HTTP_X_REQUEST_ID header is present' do
      context 'with ActionDispatch::RequestId middleware' do
        let(:options) do
          { 'HTTP_X_REQUEST_ID' => http_x_request_id,
            'action_dispatch.request_id' => action_dispatch_request_id }
        end

        it 'returns the middleware value' do
          expect(subject.uuid).to eq(action_dispatch_request_id)
        end
      end

      context 'without ActionDispatch::RequestId middleware' do
        let(:options) { { 'HTTP_X_REQUEST_ID' => http_x_request_id } }

        it 'returns the header value' do
          expect(subject.uuid).to eq(http_x_request_id)
        end
      end
    end

    context 'when HTTP_X_REQUEST_ID header is blank' do
      context 'with ActionDispatch::RequestId middleware' do
        let(:options) { { 'action_dispatch.request_id' => action_dispatch_request_id } }
        it 'returns the middleware value' do
          expect(subject.uuid).to eq(action_dispatch_request_id)
        end
      end

      context 'without ActionDispatch::RequestId middleware' do
        it 'returns nil' do
          expect(subject.uuid).to be_nil
        end
      end
    end
  end
end
