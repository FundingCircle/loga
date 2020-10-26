require 'spec_helper'
require 'loga/sidekiq6/job_logger'

RSpec.describe Loga::Sidekiq6::JobLogger do
  subject(:job_logger) { described_class.new }

  let(:target) { StringIO.new }

  let(:json_line) do
    target.rewind
    JSON.parse(target.read.split("\n").last)
  end

  before do
    Loga.reset

    Loga.configure(
      service_name: 'hello_world_app',
      service_version: '1.0',
      device: target,
      format: :gelf,
    )
  end

  # https://github.com/mperham/sidekiq/blob/v6.1.2/lib/sidekiq/job_logger.rb
  it 'inherits from ::Sidekiq::JobLogger' do
    expect(subject).to be_a(::Sidekiq::JobLogger)
  end

  describe '#call' do
    context 'when the job passess successfully' do
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

      it 'has the the required attributes on call' do
        job_logger.call(item_data, 'queue') do
          # something
        end

        expected_body = {
          'version' => '1.1',
          'level' => 6,
          '_type' => 'sidekiq',
          '_created_at' => 1_528_799_582.904939,
          '_enqueued_at' => 1_528_799_582.9049861,
          '_jid' => '591f6f66ee0d218fb451dfb6',
          '_retry' => true,
          '_queue' => 'default',
          '_service.name' => 'hello_world_app',
          '_class' => 'HardWorker',
          '_service.version' => '1.0',
          '_tags' => '',
          '_params' => ['asd'],
        }

        aggregate_failures do
          expect(json_line).to include(expected_body)
          expect(json_line['timestamp']).to be_a(Float)
          expect(json_line['host']).to be_a(String)
          expect(json_line['short_message']).to match(/HardWorker with jid:*/)
        end
      end
    end

    context 'when the job fails' do
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

      it 'has the the required attributes on call' do
        failed_job = lambda do
          job_logger.call(item_data, 'queue') do
            raise StandardError
          end
        end

        expected_body = {
          'version' => '1.1',
          'level' => 4,
          '_type' => 'sidekiq',
          '_created_at' => 1_528_799_582.904939,
          '_enqueued_at' => 1_528_799_582.9049861,
          '_jid' => '591f6f66ee0d218fb451dfb6',
          '_retry' => true,
          '_queue' => 'default',
          '_service.name' => 'hello_world_app',
          '_class' => 'HardWorker',
          '_service.version' => '1.0',
          '_tags' => '',
          '_params' => ['asd'],
          '_exception' => 'StandardError',
        }

        aggregate_failures do
          expect(&failed_job).to raise_error(StandardError)
          expect(json_line).to include(expected_body)
          expect(json_line['timestamp']).to be_a(Float)
          expect(json_line['host']).to be_a(String)
          expect(json_line['short_message']).to match(/HardWorker with jid:*/)
        end
      end
    end
  end
end
