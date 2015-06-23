require 'spec_helper'
require 'timecop'
require 'sidekiq'
require 'sidekiq/testing'

Sidekiq::Testing.fake!

class MySidekiqWorker
  include Sidekiq::Worker
  def perform(_name)
  end
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add Loga::Sidekiq::ClientLogger
  end
end

describe 'Sidekiq client logger' do
  include_context 'loga initialize'

  context 'when the job is successful' do
    it 'logs the job enqueue' do
      MySidekiqWorker.perform_async('Bob')
      expect(json).to match(
        '@version'   => '1',
        'host'       => 'bird.example.com',
        'message'    => 'MySidekiqWorker Enqueued',
        '@timestamp' => '2015-12-15T09:30:05.123+00:00',
        'severity'   => 'INFO',
        'type'       => 'job',
        'service'    => {
          'name' => 'hello_world_app',
          'version' => '1.0',
        },
        'event' => {
          'retry' => true,
          'queue' => 'default',
          'params' => ['Bob'],
          'jid' => be_a(String),
          'enqueued_at' => 1_450_171_805.1230001,
          'klass' => 'MySidekiqWorker',
          'duration' => 0,
        },
      )
    end
  end
end
