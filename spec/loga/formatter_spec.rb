require 'spec_helper'

describe Loga::Formatter do
  let(:service_name)    { 'loga' }
  let(:service_version) { '725e032a' }
  let(:host)            { 'www.example.com' }
  let(:options) do
    {
      service_name:    service_name,
      service_version: service_version,
      host:            host,
    }
  end

  subject { described_class.new(options) }

  shared_examples 'default fields' do
    it 'includes default fields' do
      expect(json).to include('@version'   => '1',
                              'host'       => host,
                              'severity'   => severity,
                              'service'    => {
                                'name'     => service_name,
                                'version'  => service_version,
                              },
                             )
    end

    it 'outputs the timestamp in UTC' do
      expect(json).to include('@timestamp' => '2015-12-15T03:30:05.123Z')
    end
  end

  describe '#call(severity, time, _progname, message)' do
    subject { super().call('INFO', time_anchor, nil, message) }

    let(:severity) { 'INFO' }
    let(:message)  { 'Tree house magic' }
    let(:json)   { JSON.parse(subject) }

    context 'when message is a String' do
      it 'uses the message as the message' do
        expect(json['message']).to eq(message)
      end

      include_examples 'default fields'
    end

    context 'when message is a Hash' do
      let(:message) { { message: 'Wooden house' } }

      context 'when message includes a key :message' do
        it 'uses the key :message as the message' do
          expect(json['message']).to eq(message[:message])
        end
      end
      include_examples 'default fields'

      context 'when message includes a key :timestamp' do
        let(:time)  { Time.new(2010, 12, 15, 9, 30, 5.323) }
        let(:message) { super().merge(timestamp: time) }

        it 'uses the key :timestamp as the @timestamp' do
          expect(json['@timestamp']).to eq('2010-12-15T09:30:05.323Z')
        end
      end

      describe ':type' do
        context 'when present' do
          let(:type)  { 'request' }
          let(:message) { super().merge(type: type) }

          specify { expect(json['type']).to eq(type) }
        end
        context 'when absent' do
          specify { expect(json['type']).to eq('default') }
        end
      end

      describe ':exception' do
        context 'when present' do
          let(:backtrace) { %w(a b) }
          let(:exception) do
            StandardError.new('Foo Error').tap { |e| e.set_backtrace backtrace }
          end
          let(:message) do
            super().merge(exception: exception)
          end

          specify do
            expect(json['exception']).to match('klass'     => 'StandardError',
                                               'message'   => 'Foo Error',
                                               'backtrace' => backtrace,
                                              )
          end
        end
        context 'when absent' do
          specify { expect(json).to_not include('exception') }
        end
      end

      describe ':event' do
        context 'when present' do
          let(:event) { { user_id: 1 } }
          let(:message) { super().merge(event: event) }

          specify { expect(json['event']).to match('user_id' => 1) }
        end
        context 'when absent' do
          specify { expect(json['event']).to eq({}) }
        end
      end
    end
  end
end
