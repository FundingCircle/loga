# frozen_string_literal: true

require 'spec_helper'
require 'loga/sidekiq7/job_logger'
require 'loga/sidekiq8/job_logger'

logger_klass =
  if Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new('8.0.0')
    Loga::Sidekiq8::JobLogger
  elsif Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new('7.0.0')
    Loga::Sidekiq7::JobLogger
  else
    raise 'No suitable Sidekiq JobLogger implementation found'
  end

RSpec.describe logger_klass, 'unified (latest) Sidekiq JobLogger spec' do
  # Sidekiq < 7.3: initializer expects a raw logger
  # Sidekiq >= 7.3: initializer expects a config object responding to #logger and #[] (Sidekiq 8 keeps this)
  subject(:job_logger) do
    if Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new('7.3.0')
      described_class.new(sidekiq_config)
    else
      described_class.new(logger)
    end
  end

  let(:target) { StringIO.new }

  let(:json_line) do
    target.rewind
    raw = target.read
    line = raw.split("\n").last
    JSON.parse(line) if line
  end

  let(:logger) { Loga.logger }
  let(:sidekiq_config) { instance_double(Sidekiq::Config, logger: logger, :[] => nil) }

  before do
    Loga.reset
    Loga.configure(
      service_name: 'hello_world_app',
      service_version: '1.0',
      device: target,
      format: :gelf,
    )
  end

  it 'inherits from ::Sidekiq::JobLogger' do
    expect(job_logger).to be_a(Sidekiq::JobLogger)
  end

  describe '#call' do
    let(:item_data) do
      {
        'class' => 'HardWorker',
        'args' => ['asd'],
        'retry' => true,
        'queue' => 'default',
        'jid' => '591f6f66ee0d218fb451dfb6',
        'created_at' => 1_528_799_582.904939,
        'enqueued_at' => 1_528_799_582.9049861,
      }
    end

    context 'when the job passes successfully' do
      it 'logs the expected structured event' do
        job_logger.call(item_data, 'default') do
          # simulate job body
        end

        expected = {
          'version' => '1.1',
          'level' => 6, # INFO -> 6 (syslog mapping)
          '_type' => 'sidekiq',
          '_created_at' => item_data['created_at'],
          '_enqueued_at' => item_data['enqueued_at'],
          '_jid' => item_data['jid'],
          '_retry' => true,
          '_queue' => 'default',
          '_service.name' => 'hello_world_app',
          '_service.version' => '1.0',
          '_class' => 'HardWorker',
          '_params' => ['asd'],
          '_tags' => '',
        }

        aggregate_failures do
          expect(json_line).to include(expected)
          expect(json_line['_duration']).to be_a(Float).or be_a(Integer)
          expect(json_line['timestamp']).to be_a(Float)
          expect(json_line['host']).to be_a(String)
          expect(json_line['short_message'])
            .to match(/HardWorker with jid: '591f6f66ee0d218fb451dfb6' (done|executed)/)
        end
      end
    end

    context 'when the job fails' do
      it 'logs the expected structured event with exception info' do
        failing = lambda do
          job_logger.call(item_data, 'default') do
            raise StandardError, 'Boom'
          end
        end

        expect(&failing).to raise_error(StandardError, 'Boom')

        expected = {
          'version' => '1.1',
          # WARN -> syslog 4 (sidekiq job failure logged at warn)
          'level' => 4,
          '_type' => 'sidekiq',
          '_created_at' => item_data['created_at'],
          '_enqueued_at' => item_data['enqueued_at'],
          '_jid' => item_data['jid'],
          '_retry' => true,
          '_queue' => 'default',
          '_service.name' => 'hello_world_app',
          '_service.version' => '1.0',
          '_class' => 'HardWorker',
          '_params' => ['asd'],
          '_tags' => '',
          '_exception' => 'Boom',
        }

        aggregate_failures do
          expect(json_line).to include(expected)
          expect(json_line['_duration']).to be_a(Float).or be_a(Integer)
          expect(json_line['timestamp']).to be_a(Float)
          expect(json_line['host']).to be_a(String)
          expect(json_line['short_message'])
            .to match(/HardWorker with jid: '591f6f66ee0d218fb451dfb6' fail/)
        end
      end
    end
  end
end
