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

  context 'when a template is rendered' do
    let(:action_view_notifications) do
      json_entries.select { |e| e.to_json =~ /Rendered/ }
    end

    before { put '/users/5' }

    specify { expect(last_response.status).to eq(200) }

    it 'silences ActionView::LogSubscriber' do
      expect(action_view_notifications).to be_empty
    end
  end
end
