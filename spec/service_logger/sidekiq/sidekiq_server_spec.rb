require 'spec_helper'

describe ServiceLogger::Sidekiq::ServerLogger do
  let(:item)   { { 'class' => 'ExampleWorker' } }
  let(:logger) { double(:logger) }

  subject { described_class.new }

  before do
    allow(subject).to receive(:logger).and_return(logger)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
  end

  describe '#call(worker, item, queue)' do
    let(:exception) { StandardError.new }

    context 'when an exception is raised' do
      it 'logs with severity ERROR' do
        expect(logger).to receive(:error).with(type:      'job_processed',
                                               data:      an_instance_of(Hash),
                                               timestamp: an_instance_of(Time),
                                               short_message: 'ExampleWorker Processed',
                                               exception: exception,
                                              )
        begin
          subject.call(nil, item, nil) do
            fail exception
          end
        rescue StandardError
        end
      end

      it 'raises the rescued error' do
        expect { subject.call(env) }.to raise_error(StandardError)
      end
    end

    context 'when no exception is raised' do
      it 'logs with severity INFO' do
        expect(logger).to receive(:info).with(type:      'job_processed',
                                              data:      an_instance_of(Hash),
                                              timestamp: an_instance_of(Time),
                                              short_message: 'ExampleWorker Processed',
                                              exception: nil,
                                             )
        subject.call(nil, item, nil) {}
      end
    end
  end
end
