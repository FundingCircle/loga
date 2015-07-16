require 'spec_helper'

describe Loga::Rack::Logger do
  let(:env)    { Rack::MockRequest.env_for('/about_us?limit=1') }
  let(:app)    { double(:app) }
  let(:logger) { double(:logger) }

  subject { described_class.new(app) }

  before do
    allow(subject).to receive(:logger).and_return(logger)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
  end

  describe '#call(env)' do
    let(:exception) { StandardError.new }

    context 'when an exception is raised' do
      before do
        allow(app).to receive(:call).with(env).and_raise(exception)
      end

      it 'does not rescue the exception' do
        expect { subject.call(env) }.to raise_error(StandardError)
      end
    end

    context 'when an exception wrapped by ActionDispatch' do
      let(:app) do
        lambda do |env|
          env['action_dispatch.exception'] = exception
          [500, {}, '']
        end
      end

      it 'logs the exception' do
        expect(logger).to receive(:error).with(type:      'request',
                                               event:     an_instance_of(Hash),
                                               timestamp: an_instance_of(Time),
                                               message:   'GET /about_us?limit=1',
                                               exception: exception,
                                              )
        subject.call(env)
      end
    end

    context 'when an exception wrapped by Sinatra' do
      let(:app) do
        lambda do |env|
          env['sinatra.error'] = exception
          [500, {}, '']
        end
      end

      it 'logs the exception' do
        expect(logger).to receive(:error).with(type:      'request',
                                               event:     an_instance_of(Hash),
                                               timestamp: an_instance_of(Time),
                                               message:   'GET /about_us?limit=1',
                                               exception: exception,
                                              )
        subject.call(env)
      end
    end

    context 'when no exception is raised' do
      before do
        allow(app).to receive(:call).with(env).and_return([200, {}, ''])
      end

      it 'logs with severity INFO' do
        expect(logger).to receive(:info).with(type:      'request',
                                              event:     an_instance_of(Hash),
                                              timestamp: an_instance_of(Time),
                                              message:   'GET /about_us?limit=1',
                                              exception: nil,
                                             )
        subject.call(env)
      end
    end

    context 'when filter parameter are present' do
      let(:env) { Rack::MockRequest.env_for('/about_us?limit=1&password=hello') }

      before do
        allow(app).to receive(:call).with(env).and_return([200, {}, ''])
        allow(subject).to receive(:filter_parameters).and_return(%w(password username))
      end

      it 'filters the parameters' do
        expect(logger).to receive(:info)
          .with(
            hash_including(
              event: hash_including(
                request: hash_including('params' => { 'limit' => '1',
                                                      'password' => '[FILTERED]' },
                                       ),
              ),
            ),
          )
        subject.call(env)
      end
    end

    context 'when the logger is tagged' do
      let(:logger) { double(:logger, tagged: true) }

      before do
        allow(subject).to receive(:call_app).with(any_args).and_return(:response)
        allow(subject).to receive(:compute_tags).with(any_args).and_return(:tag)
        allow(logger).to receive(:tagged).with('hello') do |&block|
          block.call
        end
      end

      it 'yields the app with tags' do
        expect(logger).to receive(:tagged).with(:tag) do |&block|
          expect(block.call).to eq(:response)
        end
        subject.call(env)
      end
    end
  end
end
