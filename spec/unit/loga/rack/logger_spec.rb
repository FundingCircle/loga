require 'spec_helper'
require 'rack/test'

describe Loga::Rack::Logger do
  subject(:middleware) { described_class.new(app) }

  let(:env)     { Rack::MockRequest.env_for('/about_us?limit=1', options) }
  let(:options) { {} }
  let(:app)     {  ->(_env) { [response_status, {}, ''] } }
  let(:logger)  { instance_double(Logger, info: nil, error: nil) }
  let(:tags)    { [] }

  let(:configuration) do
    instance_double(
      Loga::Configuration,
      filter_exceptions: %w[ActionController::RoutingError],
      filter_parameters: [],
      logger: logger,
      tags: tags,
    )
  end

  let(:started_at) { Time.new(2021, 1, 2, 9, 30, 4.500, '+00:00') }

  around do |example|
    Timecop.freeze(Time.new(2021, 1, 2, 9, 30, 5.000, '+00:00'), &example)
  end

  before do
    allow(Loga).to receive(:configuration).and_return(configuration)
  end

  shared_examples 'logs the event' do |details|
    let(:level) { details[:level] }

    it 'instantiates a Loga::Event' do
      expect(Loga::Event).to receive(:new).with(
        data:      {
          request: {
            'status'     => response_status,
            'method'     => 'GET',
            'path'       => '/about_us',
            'params'     => { 'limit' => '1' },
            'request_id' => nil,
            'request_ip' => nil,
            'user_agent' => nil,
            'duration'   => 500,
          },
        },
        exception: logged_exception,
        message:   %r{^GET \/about_us\?limit=1 #{response_status} in \d+ms$},
        timestamp: started_at,
        type:      'request',
      )

      middleware.call(env, started_at)
    end

    it "logs the Loga::Event with severity #{details[:level]}" do
      allow(logger).to receive(level)
      middleware.call(env, started_at)
      expect(logger).to have_received(level).with(an_instance_of(Loga::Event))
    end
  end

  describe '#call(env)' do
    let(:exception)        { StandardError.new }
    let(:logged_exception) { nil }
    let(:response_status)  { 200 }
    let(:exception_class)  { Class.new(StandardError) }

    context 'when an exception is raised' do
      let(:app) {  ->(_env) { raise exception_class } }

      it 'does not rescue the exception' do
        expect { middleware.call(env) }.to raise_error(exception_class)
      end
    end

    context 'when an exception wrapped by ActionDispatch' do
      let(:response_status)  { 500 }
      let(:logged_exception) { exception }
      let(:options)          { { 'action_dispatch.exception' => exception } }

      include_examples 'logs the event', level: :error
    end

    context 'when an exception wrapped by Sinatra' do
      let(:response_status)  { 500 }
      let(:logged_exception) { exception }
      let(:options)          { { 'sinatra.error' => exception } }

      include_examples 'logs the event', level: :error
    end

    context 'when the exception is ActionController::RoutingError' do
      let(:response_status) { 404 }
      let(:exception)       { double(class: 'ActionController::RoutingError') }
      let(:options)         { { 'action_dispatch.exception' => exception } }

      include_examples 'logs the event', level: :info
    end

    context 'when the exception is on rack.exception' do
      let(:response_status)  { 500 }
      let(:exception)        { StandardError }
      let(:logged_exception) { exception }
      let(:options)          { { 'rack.exception' => exception } }

      include_examples 'logs the event', level: :error
    end

    context 'when no exception is raised' do
      include_examples 'logs the event', level: :info
    end

    context 'when the logger is tagged' do
      let(:logger) { Loga::TaggedLogging.new(Logger.new('/dev/null')) }
      let(:fake_tag_proc) { double(:proc, call: true) }

      let(:tags) { [->(request) { fake_tag_proc.call(request) }] }

      include_examples 'logs the event', level: :info

      it 'calls the tags and computes them' do
        middleware.call(env)

        expect(fake_tag_proc).to have_received(:call).with(instance_of(Loga::Rack::Request))
      end
    end
  end
end
