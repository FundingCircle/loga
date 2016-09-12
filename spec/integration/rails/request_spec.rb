require 'spec_helper'

describe 'Integration with Rails', timecop: true do
  let(:app) { Rails.application }

  let(:json_entries) do
    [].tap do |entries|
      STREAM.tap do |s|
        s.rewind
        s.read.split("\n").each do |line|
          entries << JSON.parse(line)
        end
        s.close
        s.reopen
      end
    end
  end

  let(:json) { json_entries.last }
  let(:json_response) { JSON.parse(last_response.body) }

  include_examples 'request logger'

  it 'preserves rails parameters' do
    get '/show'
    expect(json_response).to eq('action' => 'show', 'controller' => 'application')
  end

  describe 'LogSubscriber' do
    context 'ActionController' do
      let(:action_controller_notifications) do
        json_entries.select { |e| e.to_json =~ /Processing by|Completed/ }
      end

      it 'silences ActionController::LogSubscriber' do
        get '/show'
        expect(action_controller_notifications).to be_empty
      end
    end

    context 'ActionView' do
      let(:action_view_notifications) do
        json_entries.select { |e| e.to_json =~ /Rendered/ }
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
      expect(json_entries.count).to eq(1)
      expect(json['short_message']).to eq('GET /not_found 404 in 0ms')
    end
  end
end
