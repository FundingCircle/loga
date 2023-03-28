# frozen_string_literal: true

require 'spec_helper'

describe 'Sidekiq client logger' do
  let(:target) { StringIO.new }
  let(:config) { Sidekiq.instance_variable_get :@config }

  before do
    Sidekiq.configure_server do |config|
      config.redis = { pool_name: :default }
    end

    Loga.reset

    Loga.configure(
      service_name: 'hello_world_app',
      service_version: '1.0',
      device: target,
      format: :gelf,
    )
  end

  it 'has the proper job logger' do
    expect(config[:job_logger]).to eq Loga::Sidekiq7::JobLogger
  end

  it 'has the proper logger for Sidekiq.logger' do
    expect(Sidekiq.logger).to eq Loga.logger
  end

  context 'with processor' do
    require 'sidekiq/processor'

    let(:mutex) { Mutex.new }
    let(:cond) { ConditionVariable.new }
    let(:processor) do
      Sidekiq::Processor.new(config.default_capsule) { |pr, ex| result(pr, ex) }
    end

    before do
      @exception = nil
    end

    context 'with a successful job' do
      before do
        MySidekiqWorker.perform_async('Bob')

        await { processor.start }

        processor.terminate(true)
      end

      it 'logs the job processing event' do
        test_log_from_worker(read_json_log(line: -2))
      end

      it 'logs the "done" event' do
        test_job_end_log(read_json_log(line: -1))
      end
    end

    context 'with an error' do
      before do
        MySidekiqWorker.perform_async('Boom')

        await { processor.start }

        processor.terminate(true)
      end

      it 'logs the "error" event' do
        test_job_fail_log(read_json_log(line: 0))
      end

      it 're-throws the error' do
        # rubocop:disable RSpec/InstanceVariable
        expect(@exception.message).to eq('Boom')
        # rubocop:enable RSpec/InstanceVariable
      end
    end

    def result(_processor, exception)
      @exception = exception
      mutex.synchronize { cond.signal }
    end

    def await(timeout: 0.1)
      mutex.synchronize do
        yield
        cond.wait(mutex, timeout)
      end
    end

    def common_log_fields
      {
        '_class' => 'MySidekiqWorker',
        '_service.name' => 'hello_world_app',
        '_service.version' => '1.0',
        '_tags' => '',
        'version' => '1.1',
      }.freeze
    end

    def job_logger_common_fields
      common_log_fields.merge(
        '_queue' => 'default',
        '_retry' => true,
        '_type' => 'sidekiq',
      )
    end

    def test_log_from_worker(json_line)
      aggregate_failures do
        expect(json_line).to include(
          common_log_fields.merge(
            'level' => 6,
            'short_message' => 'Hello from MySidekiqWorker',
          ),
        )

        %w[_jid timestamp host].each do |key|
          expect(json_line).to have_key(key)
        end

        expect(json_line).not_to include('_duration')
      end
    end

    def test_job_end_log(json_line)
      aggregate_failures do
        expect(json_line).to include(
          job_logger_common_fields.merge(
            '_params' => ['Bob'],
            'level' => 6,
          ),
        )

        %w[_created_at _enqueued_at _jid _duration timestamp host].each do |key|
          expect(json_line).to have_key(key)
        end

        expect(json_line['_duration']).to be < 500
        expect(json_line['short_message'])
          .to match(/MySidekiqWorker with jid: '\w+' done/)
      end
    end

    def test_job_fail_log(json_line)
      aggregate_failures do
        expect(json_line).to include(
          job_logger_common_fields.merge(
            '_params' => ['Boom'],
            'level' => 4,
          ),
        )

        %w[_created_at _enqueued_at _jid _duration timestamp host].each do |key|
          expect(json_line).to have_key(key)
        end

        expect(json_line['_duration']).to be < 500
        expect(json_line['short_message'])
          .to match(/MySidekiqWorker with jid: '\w+' fail/)
      end
    end
  end

  def dump_log
    offset = target.pos

    target.rewind
    target.each_line { puts _1 }

    target.pos = offset
  end

  def read_json_log(line:)
    target.rewind

    JSON.parse(target.readlines[line])
  end
end

class MySidekiqWorker
  include Sidekiq::Job

  def perform(name)
    raise name if name == 'Boom'

    logger.info('Hello from MySidekiqWorker')
  end
end
