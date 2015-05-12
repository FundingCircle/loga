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
    subject { super().call('INFO', time_anchor, nil, message) }

    let(:result) { JSON.parse(subject) }

    context 'when message is a String' do
      let(:message) { 'Tree house magic' }

      it 'uses the message as the short_message' do
        expect(result['short_message']).to eq(message)
      end
    end

    context 'when message is a Hash' do
      let(:message) do
        {
          short_message: 'Hello World',
          event:    'http_request',
          data:          {},
        }
      end

      specify do
        expect(result).to include('version'       => '1.1',
                                  'host'          => host,
                                  'short_message' => 'Hello World',
                                  'full_message'  => '',
                                 )
      end

      it 'formats the severity as standard syslog level' do
        expect(result).to include('level' => 6)
      end

      it 'formats the time as unix timestamp with milliseconds' do
        expect(result).to include('timestamp' => '1450171805.123')
      end

      context 'when the message does not includes short_message key' do
        let(:message) { {} }
        it 'raises a KeyError' do
          expect { subject }.to raise_error(KeyError)
        end
      end

      context 'when the message includes a data key' do
        let(:message) do
          super().merge(data: { 'user_uuid' => 'abcd' })
        end
        it 'merges the data key values with the message' do
          expect(result).to include('_user_uuid' => 'abcd')
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
          expect(result).to include('_exception.klass'     => 'StandardError',
                                    '_exception.message'   => 'Corn Error',
                                    '_exception.backtrace' => backtrace,
                                   )
        end

        it 'does not include the original exception key' do
          expect(result).to_not include(:exception)
        end
      end
    end
  end

  describe '#extract_data(data)' do
    let(:data) { {} }

    subject { super().extract_data(data) }

    context 'when data is nil' do
      let(:data) { nil }

      it 'returns an empty hash' do
        expect(subject).to eq({})
      end
    end

    context 'when data is present' do
      let(:data) do
        {
          'request' => {
            'method' => 'GET',
            'params' => {
              'name' => 'bob',
            },
          },
          'job' => {
            'duration' => 123,
          },
          'thread' => 0,
        }
      end

      it 'extracts hash into GELF additional fiels' do
        expect(subject).to match(
          '_request.method' => 'GET',
          '_request.params' => { 'name' => 'bob' },
          '_job.duration'   => 123,
          '_thread'         => 0,
        )
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
