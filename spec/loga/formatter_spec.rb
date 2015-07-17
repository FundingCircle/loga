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
      expect(json).to include('version'          => '1.1',
                              'host'             => host,
                              'level'         => 6,
                              '_service.name'    => service_name,
                              '_service.version' => service_version,
                              '_tags'            => [],
                             )
    end

    it 'outputs the timestamp in seconds since UNIX epoch' do
      expect(json).to include('timestamp' => time_anchor_unix)
    end
  end

  describe '#call(severity, time, _progname, message)' do
    subject { super().call(severity, time_anchor, nil, message) }

    let(:severity) { 'INFO' }
    let(:message)  { 'Tree house magic' }
    let(:json)     { JSON.parse(subject) }

    context 'when message is a String' do
      it 'uses the message as the short_message' do
        expect(json['short_message']).to eq(message)
      end

      include_examples 'default fields'
    end

    context 'when message is a nil' do
      let(:message) { nil }
      it 'uses the message as the short_message' do
        expect(json['short_message']).to eq('')
      end

      include_examples 'default fields'
    end

    context 'when message is a Hash' do
      let(:message) { { message: 'Wooden house' } }

      context 'when message includes a key :message' do
        it 'uses the key :message as the short_message' do
          expect(json['short_message']).to eq(message[:message])
        end
      end
      include_examples 'default fields'

      context 'when message includes a key :timestamp' do
        let(:time) { Time.new(2010, 12, 15, 9, 30, 5.323, '+02:00') }
        let(:time_unix) { BigDecimal.new('1292398205.323') }
        let(:message) { super().merge(timestamp: time) }

        it 'uses the key :timestamp as the timestamp' do
          expect(json['timestamp']).to eq(time_unix)
        end
      end

      describe ':type' do
        context 'when present' do
          let(:type)  { 'request' }
          let(:message) { super().merge(type: type) }

          specify { expect(json['_type']).to eq(type) }
        end
        context 'when absent' do
          specify { expect(json['_type']).to eq('default') }
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

          specify { expect(json['_exception.klass']).to eq('StandardError') }
          specify { expect(json['_exception.message']).to eq('Foo Error') }
          specify { expect(json['_exception.backtrace']).to eq("a\nb") }

          context 'when the backtrace is larger than 10 lines' do
            let(:backtrace) { ('a'..'z').to_a }
            it 'truncates the backtrace' do
              expect(json['_exception.backtrace']).to eq("a\nb\nc\nd\ne\nf\ng\nh\ni\nj")
            end
          end
        end
        context 'when absent' do
          specify { expect(json).to_not include(/_exception.+/) }
        end
      end

      describe ':event' do
        context 'when present' do
          let(:event) { { user_id: 1 } }
          let(:message) { super().merge(event: event) }

          specify { expect(json['_user_id']).to eq(1) }
        end
        context 'when absent' do
          specify { expect(json).to_not include('_event') }
        end
      end
    end

    {
      'DEBUG'   => 7,
      'INFO'    => 6,
      'WARN'    => 4,
      'ERROR'   => 3,
      'FATAL'   => 2,
      'UNKNOWN' => 1,
    }.each do |ruby_severity, syslog_level|
      context "with severity #{ruby_severity}" do
        let(:severity) { ruby_severity }

        it "maps to level #{syslog_level}" do
          expect(json['level']).to eq(syslog_level)
        end
      end
    end
  end
end
