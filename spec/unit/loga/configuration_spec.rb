require 'spec_helper'

describe Loga::Configuration do
  let(:options) do
    { service_name: 'hello_world_app' }
  end

  subject { described_class.new(options) }

  describe 'initialize' do
    context 'defaults' do
      specify { expect(subject.device).to eq(STDOUT) }
      specify { expect(subject.filter_parameters).to eq([]) }
      specify { expect(subject.format).to eq(:simple) }
      specify { expect(subject.host).to eq(hostname_anchor) }
      specify { expect(subject.level).to eq(:info) }
      specify { expect(subject.service_name).to eq('hello_world_app') }
      specify { expect(subject.service_version).to eq('') }
      specify { expect(subject.sync).to eq(true) }
      specify { expect(subject.tags).to eq([]) }
    end

    describe 'device' do
      context 'when initialized with nil' do
        let(:options) { super().merge(device: nil) }

        it 'raises an error' do
          expect { described_class.new(options) }
            .to raise_error(Loga::ConfigurationError, 'Device cannot be blank')
        end
      end
    end

    describe 'hostname' do
      context 'when hostname cannot be resolved' do
        before do
          allow(Socket).to receive(:gethostname).and_raise(Exception)
        end

        it 'uses a default hostname' do
          expect(subject.host).to eq('unknown.host')
        end
      end
    end

    describe 'service_name' do
      context 'when service name is missing' do
        let(:options) do
          { service_: 'hello_world_app' }
        end

        it 'raises an error' do
          expect { subject }.to raise_error(Loga::ConfigurationError,
                                            'Service name cannot be blank')
        end
      end
    end

    describe 'format' do
      context 'when initialized via user options' do
        let(:options) { super().merge(format: :gelf) }

        it 'sets the format' do
          expect(subject.format).to eq(:gelf)
        end
      end

      context 'when initialized via ENV' do
        before do
          allow(ENV).to receive(:[]).with('LOGA_FORMAT').and_return('gelf')
        end

        it 'sets the format' do
          expect(subject.format).to eq(:gelf)
        end
      end

      context 'when initialized via framework options' do
        subject { described_class.new(options, framework_options) }
        let(:framework_options) { { format: :gelf } }

        it 'sets the format' do
          expect(subject.format).to eq(:gelf)
        end
      end

      context 'when initialized with user options and ENV' do
        let(:options) { super().merge(format: :gelf) }

        before do
          allow(ENV).to receive(:[]).with('LOGA_FORMAT').and_return('simple')
        end

        it 'prefers user option' do
          expect(subject.format).to eq(:gelf)
        end
      end

      context 'when initialized with ENV and framework options' do
        subject { described_class.new(options, framework_options) }
        let(:framework_options) { { format: :gelf } }

        before do
          allow(ENV).to receive(:[]).with('LOGA_FORMAT').and_return('simple')
        end

        it 'prefers env' do
          expect(subject.format).to eq(:simple)
        end
      end
    end

    describe 'formatter' do
      context 'when format is :gelf' do
        let(:options) do
          super().merge(
            format: :gelf,
            service_name: ' hello_world_app ',
            service_version: " 1.0\n",
          )
        end
        let(:formatter) { subject.logger.formatter }

        it 'uses the GELF formatter' do
          expect(subject.logger.formatter).to be_a(Loga::Formatter)
        end

        it 'strips the service name and version' do
          aggregate_failures do
            expect(formatter.instance_variable_get(:@service_name))
              .to eq('hello_world_app')

            expect(formatter.instance_variable_get(:@service_version))
              .to eq('1.0')
          end
        end
      end

      context 'when format is :simple' do
        let(:options) { super().merge(format: :simple) }

        it 'uses the SimpleFormatter' do
          expect(subject.logger.formatter).to be_a(ActiveSupport::Logger::SimpleFormatter)
        end
      end

      context 'when the ActiveSupport::VERSION is unsupported' do
        it 'raises an error' do
          stub_const('ActiveSupport::VERSION::MAJOR', 1)
          expect { described_class.new(options) }
            .to raise_error(Loga::ConfigurationError, 'ActiveSupport 1 is unsupported')
        end
      end
    end

    describe 'logger' do
      let(:logdev) { subject.logger.instance_variable_get(:@logdev) }

      {
        debug:   0,
        info:    1,
        warn:    2,
        error:   3,
        fatal:   4,
        unknown: 5,
      }.each do |sym, level|
        context "when log level is #{sym}" do
          let(:options) { super().merge(level: sym) }

          it "uses log level #{sym}" do
            expect(subject.logger.level).to eq(level)
          end
        end
      end

      context 'when sync is false' do
        let(:options) { super().merge(sync: false) }

        it 'uses warn log level' do
          expect(logdev.dev.sync).to eq(false)
        end
      end
    end

    describe '#structured?' do
      context 'when format is :simple' do
        let(:options) { super().merge(format: :simple) }

        specify { expect(subject.structured?).to eql(false) }
      end

      context 'when format is :gelf' do
        let(:options) { super().merge(format: :gelf) }

        specify { expect(subject.structured?).to eql(true) }
      end
    end
  end
end
