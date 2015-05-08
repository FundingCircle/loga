require 'spec_helper'

describe ServiceLogger::Rack::Logger do
  let(:opts)   { {} }
  let(:env)    { Rack::MockRequest.env_for('/about_us?limit=1', opts) }
  let(:app)    { double(:app) }
  let(:logger) { double(:logger) }

  subject { described_class.new(app) }

  before do
    allow(subject).to receive(:logger).and_return(logger)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
    allow(app).to receive(:call).with(env).and_return([200, {}, ''])
  end

  describe '#call(env)' do
    context 'when an exception is raised' do
      before do
        allow(app).to receive(:call).with(env).and_raise(StandardError, 'Hello Error')
      end

      it 'logs with severity ERROR' do
        expect(logger).to receive(:error).with(type:      'http_request',
                                               data:      an_instance_of(Hash),
                                               timestamp: an_instance_of(Time),
                                               short_message: 'GET /about_us?limit=1',
                                              )
        begin
          subject.call(env)
        rescue StandardError
        end
      end

      it 'logs exception data' do
        expect(logger).to receive(:error)
          .with(hash_including(data: include('_exception.klass'     => 'StandardError',
                                             '_exception.message'   => 'Hello Error',
                                             '_exception.backtrace' => be_a(String),
                                            )))
        begin
          subject.call(env)
        rescue StandardError
        end
      end

      it 'raises the rescued error' do
        expect { subject.call(env) }.to raise_error(StandardError)
      end
    end

    context 'when an exception is raised and wrapped by ActionDispatch::ShowExceptions' do
      let(:exception) do
        StandardError.new('Hello Error').tap do |e|
          e.set_backtrace []
        end
      end
      let(:opts)   { { 'action_dispatch.exception' => exception } }

      it 'logs the exception' do
        expect(logger).to receive(:error)
          .with(hash_including(data: include('_exception.klass'     => 'StandardError',
                                             '_exception.message'   => 'Hello Error',
                                             '_exception.backtrace' => be_a(String),
                                            )))
        subject.call(env)
      end
    end

    context 'when no exception is raised' do
      it 'logs with severity INFO' do
        expect(logger).to receive(:info).with(type:      'http_request',
                                              data:      an_instance_of(Hash),
                                              timestamp: an_instance_of(Time),
                                              short_message: 'GET /about_us?limit=1',
                                             )
        subject.call(env)
      end
    end
  end

  describe '#short_message(request)' do
    let(:request) { ::Rack::Request.new(env) }

    subject { super().short_message(request) }

    specify do
      expect(subject).to eq('GET /about_us?limit=1')
    end
  end
end
