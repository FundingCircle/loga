require 'spec_helper'
require 'rack/test'

# rubocop:disable RSpec/SubjectStub, RSpec/MessageSpies, RSpec/VerifiedDoubles
describe Loga::Rack::Logger do
  subject { described_class.new(app) }

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

  before { Loga.instance_variable_set(:@configuration, configuration) }

  shared_examples 'logs the event' do |details|
    let(:level) { details[:level] }

    before do
      allow(subject).to receive(:started_at).and_return(:timestamp)
      allow(subject).to receive(:duration_in_ms).with(any_args).and_return(5)
    end

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
            'duration'   => 5,
          },
        },
        exception: logged_exception,
        message:   %r{^GET \/about_us\?limit=1 #{response_status} in \d+ms$},
        timestamp: :timestamp,
        type:      'request',
      )

      subject.call(env)
    end

    it "logs the Loga::Event with severity #{details[:level]}" do
      allow(logger).to receive(level)
      subject.call(env)
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
        expect { subject.call(env) }.to raise_error(exception_class)
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
      let(:logger) { double(:logger, tagged: true) }

      before do
        allow(subject).to receive(:call_app).with(any_args).and_return(:response)
        allow(subject).to receive(:compute_tags).with(any_args).and_return(:tag)
        allow(logger).to receive(:tagged).with('hello') do |&block|
          block.call
        end
      end

      context 'when tags are present' do
        let(:tags) { [:foo] }

        it 'yields the app with tags' do
          allow(logger).to receive(:tagged)
          subject.call(env)
          expect(logger).to have_received(:tagged).with(:tag) do |&block|
            expect(block.call).to eq(:response)
          end
        end
      end
    end
  end
end
# rubocop:enable RSpec/SubjectStub, RSpec/MessageSpies, RSpec/VerifiedDoubles
