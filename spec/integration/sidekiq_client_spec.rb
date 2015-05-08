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
    chain.add ServiceLogger::Sidekiq::ClientLogger
  end
end

describe 'Sidekiq client logger' do
  before(:all) { Timecop.freeze(time_anchor) }
  after(:all)  { Timecop.return }

  before do
    ServiceLogger.configure do |config|
      config.service_name    = 'hello_world_app'
      config.service_version = '1.0'
      config.log_target      = target
    end

    ServiceLogger::Logging.reset
  end

  let(:target) { StringIO.new }

  context 'when the job is successful' do
    let(:json_line) do
      target.rewind
      JSON.parse(target.read)
    end

    it 'logs the job enqueue' do
      MySidekiqWorker.perform_async('Bob')
      expect(json_line).to match(
        'version'           => '1.1',
        'host'              => be_a(String),
        'short_message'     => 'MySidekiqWorker Enqueued',
        'full_message'      => '',
        'timestamp'         => '1450171805.123',
        'level'             => 6,
        '_event_type'       => 'job.enqueued',
        '_service.name'     => 'hello_world_app',
        '_service.version'  => '1.0',
        '_job.enqueued_at'  => '1450171805.123',
        '_job.jid'          => be_a(String),
        '_job.params'       => ['Bob'],
        '_job.klass'        => 'MySidekiqWorker',
        '_job.queue'        => 'default',
        '_job.retry'        => true,
        '_job.duration'     => 0,
      )
    end
  end
end
