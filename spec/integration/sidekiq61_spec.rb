# frozen_string_literal: true

require 'spec_helper'
require 'timecop'
require 'fakeredis'

dummy_redis_config = ConnectionPool.new(size: 5) { Redis.new }

Sidekiq.configure_client do |config|
  config.redis = dummy_redis_config
end

Sidekiq.configure_server do |config|
  config.redis = dummy_redis_config
end

class MySidekiqWorker
  include Sidekiq::Worker

  def perform(_name)
    logger.info('Hello from MySidekiqWorker')
  end
end

describe 'Sidekiq client logger' do
  let(:mgr) do
    # https://github.com/mperham/sidekiq/blob/v6.1.2/test/test_actors.rb#L58-L82
    Class.new do
      attr_reader :latest_error, :mutex, :cond

      def initialize
        @mutex = Mutex.new
        @cond = ConditionVariable.new
      end

      def processor_died(_inst, err)
        @latest_error = err

        @mutex.synchronize { @cond.signal }
      end

      def processor_stopped(_inst)
        @mutex.synchronize { @cond.signal }
      end

      def options
        {
          concurrency: 3,
          queues: ['default'],
          job_logger: Loga::Sidekiq6::JobLogger,
        }.tap { |opts| opts[:fetch] = Sidekiq::BasicFetch.new(opts) }
      end
    end
  end

  let(:target) { StringIO.new }

  def read_json_log(line:)
    target.rewind
    JSON.parse(target.each_line.drop(line - 1).first)
  end

  before do
    Redis.current.flushall

    Loga.reset

    Loga.configure(
      service_name: 'hello_world_app',
      service_version: '1.0',
      device: target,
      format: :gelf,
    )
  end

  it 'has the proper job logger' do
    expect(Sidekiq.options[:job_logger]).to eq Loga::Sidekiq6::JobLogger
  end

  it 'has the proper logger for Sidekiq.logger' do
    expect(Sidekiq.logger).to eq Loga.logger
  end

  it 'pushes a new element in the default queue' do
    MySidekiqWorker.perform_async('Bob')

    last_element = JSON.parse(Redis.current.lpop('queue:default'))

    aggregate_failures do
      expect(last_element['class']).to eq 'MySidekiqWorker'
      expect(last_element['args']).to eq ['Bob']
      expect(last_element['retry']).to be true
      expect(last_element['queue']).to eq 'default'
    end
  end

  def test_log_from_worker(json_line)
    aggregate_failures do
      expect(json_line).to include(
        '_class' => 'MySidekiqWorker',
        '_service.name' => 'hello_world_app',
        '_service.version' => '1.0',
        '_tags' => '',
        'level' => 6,
        'version' => '1.1',
        'short_message' => 'Hello from MySidekiqWorker',
      )

      %w[_jid timestamp host].each do |key|
        expect(json_line).to have_key(key)
      end

      expect(json_line).not_to include('_duration')
    end
  end

  def test_job_end_log(json_line) # rubocop:disable Metrics/MethodLength
    aggregate_failures do
      expect(json_line).to include(
        '_queue' => 'default',
        '_retry' => true,
        '_params' => ['Bob'],
        '_class' => 'MySidekiqWorker',
        '_type' => 'sidekiq',
        '_service.name' => 'hello_world_app',
        '_service.version' => '1.0',
        '_tags' => '',
        'level' => 6,
        'version' => '1.1',
      )

      %w[_created_at _enqueued_at _jid _duration timestamp host].each do |key|
        expect(json_line).to have_key(key)
      end

      expect(json_line['_duration']).to be < 500
      expect(json_line['short_message']).to match(/MySidekiqWorker with jid:*/)
    end
  end

  it 'logs the job processing event' do
    MySidekiqWorker.perform_async('Bob')

    require 'sidekiq/processor'

    sidekiq_manager = mgr.new
    Sidekiq::Processor.new(sidekiq_manager, sidekiq_manager.options).start
    sleep 0.5

    test_log_from_worker(read_json_log(line: 1))
    test_job_end_log(read_json_log(line: 2))

    # This was a bug - the duration was constantly incresing based on when
    # the logger was created. https://github.com/FundingCircle/loga/pull/117
    #
    # Test that after sleeping for few seconds the duration is still under 500ms
    sleep 1

    MySidekiqWorker.perform_async('Bob')

    sleep 1

    test_log_from_worker(read_json_log(line: 3))
    test_job_end_log(read_json_log(line: 4))
  end
end
