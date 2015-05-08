require 'spec_helper'

describe ServiceLogger::GELFFormatter do
  let(:service_name)    { 'demo_service' }
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

  describe '#call(severity, time, _progname, message)' do
    let(:message) do
      {
        short_message: 'Hello World',
        event_type:    'http_request',
        data:          {},
      }
    end

    subject { JSON.parse(super().call('INFO', time_anchor, nil, message)) }

    specify do
      expect(subject).to include('version'       => '1.1',
                                 'host'          => host,
                                 'short_message' => 'Hello World',
                                 'full_message'  => '',
                                )
    end

    it 'formats the severity as standard syslog level' do
      expect(subject).to include('level' => 6)
    end

    it 'formats the time as unix timestamp with milliseconds' do
      expect(subject).to include('timestamp' => '1450171805.123')
    end

    context 'when the message does not includes short_message key' do
      let(:message) { {} }
      it 'raises a KeyError' do
        expect { subject }.to raise_error(KeyError)
      end
    end

    context 'when the message includes a data key' do
      let(:message) do
        super().merge(data: { '_user_uuid' => 'abcd' })
      end
      it 'merges the data key values with the message' do
        expect(subject).to include('_user_uuid' => 'abcd')
      end
    end

    context 'when the message includes an exception key' do
      let(:backtrace) { '/home/corn.rb:5' }
      let(:exception) do
        StandardError.new('Corn Error').tap { |e| e.set_backtrace [backtrace] }
      end
      let(:message) do
        super().merge(exception: exception)
      end

      it 'formats the exception' do
        expect(subject).to include('_exception.klass'     => 'StandardError',
                                   '_exception.message'   => 'Corn Error',
                                   '_exception.backtrace' => backtrace,
                                  )
      end

      it 'does not include the original exception key' do
        expect(subject).to_not include(:exception)
      end
    end
  end

  describe '#severity_to_syslog_level(severity)' do
    let(:severity) { 'INFO' }

    subject { super().severity_to_syslog_level(severity) }

    specify { expect(subject).to eq(6) }
    pending 'test all other mappings'
  end
end
