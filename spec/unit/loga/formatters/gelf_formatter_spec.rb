require 'spec_helper'

describe Loga::Formatters::GELFFormatter do
  let(:service_name)    { 'loga' }
  let(:service_version) { '725e032a' }
  let(:host)            { 'www.example.com' }
  let(:params) do
    {
      service_name:    service_name,
      service_version: service_version,
      host:            host,
    }
  end

  subject { described_class.new(params) }

  shared_examples 'valid GELF message' do
    it 'includes the required fields' do
      expect(json).to include('version'       => '1.1',
                              'host'          => host,
                              'short_message' => be_a(String),
                              'timestamp'     => be_a(Float),
                              'level'         => 6)
    end

    it 'includes Loga additional fields' do
      expect(json).to include('_service.name'    => service_name,
                              '_service.version' => service_version,
                              '_tags'            => '')
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

    context 'when the message parameter is a String' do
      it 'the short_message is that String' do
        expect(json['short_message']).to eq(message)
      end

      include_examples 'valid GELF message'
    end

    context 'when the message parameter is a nil' do
      let(:message) { nil }
      it 'the short_message is empty' do
        expect(json['short_message']).to eq('')
      end

      include_examples 'valid GELF message'
    end

    context 'when message parameter is a Hash' do
      let(:message) { { message: 'Wooden house' } }

      it 'the short_message is a String reprentation of that Hash' do
        expect(json['short_message']).to eq('{:message=>"Wooden house"}')
      end

      include_examples 'valid GELF message'
    end

    context 'when message parameter is an Object' do
      let(:message) { Object.new }

      it 'the short_message is a String reprentation of that Object' do
        expect(json['short_message']).to match(/#<Object:\dx\h+>/)
      end

      include_examples 'valid GELF message'
    end

    context 'when the message parameter is a Loga::Event' do
      let(:options) { { message: 'Wooden house' } }
      let(:message) { Loga::Event.new(options) }

      include_examples 'valid GELF message'

      it 'the short_message is the Event message' do
        expect(json['short_message']).to eq(message.message)
      end

      context 'when the Event has a timestamp' do
        let(:time)         { Time.new(2010, 12, 15, 9, 30, 5.323, '+02:00') }
        let(:time_in_unix) { BigDecimal.new('1292398205.323') }
        let(:options)      { { timestamp: time } }

        it 'uses the Event timestamp' do
          expect(json['timestamp']).to eq(time_in_unix)
        end
      end

      context 'when the Event has a type' do
        let(:options)    { { type: 'request' } }

        specify { expect(json['_type']).to eq(message.type) }
      end

      context 'when the Event no type' do
        specify { expect(json).to_not include('_type') }
      end

      context 'when the Event has an exception' do
        let(:backtrace) { %w[a b] }
        let(:exception) do
          StandardError.new('Foo Error').tap { |e| e.set_backtrace backtrace }
        end
        let(:options)   { { exception: exception } }

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

      context 'when the Event has no exception' do
        specify { expect(json).to_not include(/_exception.+/) }
      end

      context 'when the Event has data' do
        let(:options) do
          {
            data: {
              user_id: 1,
              user: {
                email: 'hello@world.com',
                address: {
                  postcode: 'ABCD',
                },
              },
            },
          }
        end

        specify { expect(json['_user_id']).to eq(1) }
        specify { expect(json['_user.email']).to eq('hello@world.com') }
        specify { expect(json['_user.address']).to eq('postcode' => 'ABCD') }
      end

      context 'when the Event data contains fiels identical to the formatter fields' do
        let(:options) do
          {
            data: {
              service: { name: 'Malicious Tags' },
            },
          }
        end

        include_examples 'valid GELF message'
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
