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

  def perform(_name); end
end

describe 'Sidekiq client logger' do
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
    job_logger = Loga::Sidekiq::JobLogger

    expect(Sidekiq.options[:job_logger]).to eq job_logger
  end

  it 'has the proper logger Sidekiq::Logging.logger' do
    expect(Sidekiq::Logging.logger).to eq Loga.logger
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
      expect(last_element['retry']).to eq true
      expect(last_element['queue']).to eq 'default'
    end
  end

  if ENV['BUNDLE_GEMFILE'] =~ /sidekiq51/
    # https://github.com/mperham/sidekiq/blob/97363210b47a4f8a1d8c1233aaa059d6643f5040/test/test_actors.rb#L57-L79
    let(:mgr) do
      Class.new do
        attr_reader :latest_error, :mutex, :cond

        def initialize
          @mutex = ::Mutex.new
          @cond = ::ConditionVariable.new
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
            job_logger: Loga::Sidekiq::JobLogger,
          }
        end
      end
    end

    it 'logs the job processing event' do
      MySidekiqWorker.perform_async('Bob')

      require 'sidekiq/processor'
      Sidekiq::Processor.new(mgr.new).start
      sleep 0.5

      expected_attributes = {
        '_queue'=> 'default',
        '_retry'=> true,
        '_params'=> ['Bob'],
        '_class'=> 'MySidekiqWorker',
        '_type'=> 'sidekiq',
        '_service.name'=> 'hello_world_app',
        '_service.version'=> '1.0',
        '_tags'=> '',
        'level'=> 6,
        'version'=> '1.1',
      }

      json_line = read_json_log(line: 1)

      aggregate_failures do
        expect(json_line).to include(expected_attributes)

        %w[_created_at _enqueued_at _jid _duration timestamp host].each do |key|
          expect(json_line).to have_key(key)
        end

        expect(json_line['short_message']).to match(/MySidekiqWorker with jid:*/)
      end

      # This was a bug - the duration was constantly incresing based on when
      # the logger was created. https://github.com/FundingCircle/loga/pull/117
      #
      # Test that after sleeping for few seconds the duration is still under 500ms
      sleep 1

      MySidekiqWorker.perform_async('Bob')

      sleep 1

      json_line = read_json_log(line: 2)

      expect(json_line['_duration']).to be < 500
    end
  end
end
