require 'spec_helper'

RSpec.describe 'Structured logging with Rails', timecop: true,
                                                if: Rails.env.production? do
  let(:app) { Rails.application }

  let(:log_entries) do
    entries = []
    STREAM.tap do |s|
      s.rewind
      entries = s.read.split("\n").map { |line| JSON.parse(line) }
      s.close
      s.reopen
    end
    entries
  end

  let(:last_log_entry) { log_entries.last }
  let(:json_response)  { JSON.parse(last_response.body) }

  include_examples 'request logger'

  it 'preserves rails parameters' do
    get '/show'
    expect(json_response).to eq('action' => 'show', 'controller' => 'application')
  end

  it 'includes the controller name and action' do
    get '/ok'
    expect(last_log_entry).to include('_request.controller' => 'ApplicationController#ok')
  end

  describe 'LogSubscriber' do
    describe 'ActionController' do
      let(:action_controller_notifications) do
        log_entries.select { |e| e.to_json =~ /Processing by|Completed/ }
      end

      it 'silences ActionController::LogSubscriber' do
        get '/show'
        expect(action_controller_notifications).to be_empty
      end
    end

    describe 'ActionView' do
      let(:action_view_notifications) do
        log_entries.select { |e| e.to_json =~ /Rendered/ }
      end

      it 'silences ActionView::LogSubscriber' do
        put '/users/5'
        expect(action_view_notifications).to be_empty
      end
    end
  end

  describe 'when request causes ActionDispatch 404' do
    it 'does not log ActionDispatch::DebugExceptions' do
      get '/not_found', {}, 'HTTP_X_REQUEST_ID' => '471a34dc'
      expect(log_entries.count).to eq(1)
      expect(last_log_entry['short_message']).to eq('GET /not_found 404 in 0ms')
    end
  end
end
