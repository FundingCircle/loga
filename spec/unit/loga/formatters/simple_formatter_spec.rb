require 'spec_helper'
require 'loga/formatters/simple_formatter'

# rubocop:disable Metrics/LineLength
describe Loga::Formatters::SimpleFormatter do
  before { allow(Process).to receive(:pid).and_return(999) }

  describe '#call(severity, time, _progname, message)' do
    subject { super().call(severity, time_anchor, nil, message) }

    let(:severity) { 'INFO' }
    let(:message)  { 'Tree house magic' }
    let(:time_pid) { '[2015-12-15T09:30:05.123000+06:00 #999]' }

    context 'when the message parameter is a String' do
      specify do
        expect(subject).to eq("I, #{time_pid} Tree house magic\n")
      end
    end

    context 'when the message parameter is a nil' do
      let(:message) { nil }
      specify do
        expect(subject).to eq("I, #{time_pid} nil\n")
      end
    end

    context 'when message parameter is a Hash' do
      let(:message) { { record: 'Wooden house' } }

      specify do
        expect(subject).to eq("I, #{time_pid} {:record=>\"Wooden house\"}\n")
      end
    end

    context 'when the message parameter is a Loga::Event' do
      let(:options) { { message: 'Hello World' } }
      let(:message) { Loga::Event.new(options) }

      it 'the short_message is the Event message' do
        expect(subject).to eq("I, #{time_pid} Hello World\n")
      end

      context 'when the event has a timestamp' do
        it 'uses the event timestamp'
      end

      context 'when the Event has a type' do
        let(:options) { { message: 'Hello World', type: 'request' } }

        specify do
          expect(subject).to eq("I, #{time_pid} Hello World type=request\n")
        end
      end

      context 'when the Event has an exception' do
        let(:backtrace) { %w(a b) }
        let(:exception) do
          StandardError.new('Foo Error').tap { |e| e.set_backtrace backtrace }
        end
        let(:options)   { { exception: exception } }

        it 'outputs the exception'
      end

      context 'when the event has data' do
        let(:options) do
          {
            data: {
              admin: true,
              user: {
                email: 'hello@world.com',
              },
            },
            message: 'Hello World',
          }
        end

        specify do
          expect(subject).to eq("I, #{time_pid} Hello World data={:admin=>true, :user=>{:email=>\"hello@world.com\"}}\n")
        end
      end

      context 'when the event has data and a type' do
        let(:options) do
          {
            data: { ssl: true },
            message: 'Hello World',
            type: 'request',
          }
        end

        specify do
          expect(subject).to eq("I, #{time_pid} Hello World type=request data={:ssl=>true}\n")
        end
      end
    end

    context 'when tags are available' do
      let(:tags) { %w(USER_54321 EmailWorker) }

      before do
        allow_any_instance_of(described_class).to receive(:current_tags).and_return(tags)
      end

      specify do
        expect(subject).to eq("I, #{time_pid}[USER_54321 EmailWorker] #{message}\n")
      end
    end

    {
      'DEBUG'   => 'D',
      'INFO'    => 'I',
      'WARN'    => 'W',
      'ERROR'   => 'E',
      'FATAL'   => 'F',
      'UNKNOWN' => 'U',
    }.each do |ruby_severity, formatted_severity|
      context "with severity #{ruby_severity}" do
        let(:severity) { ruby_severity }

        specify { expect(subject).to match(/^#{formatted_severity},/) }
      end
    end
  end
end
# rubocop:enable Metrics/LineLength
