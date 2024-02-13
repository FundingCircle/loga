# frozen_string_literal: true

require 'spec_helper'

describe Loga::Configuration do
  subject { described_class.new(options) }

  let(:options) do
    { service_name: 'hello_world_app' }
  end

  describe 'initialize' do
    let(:framework_exceptions) do
      %w[
        ActionController::RoutingError
        ActiveRecord::RecordNotFound
        Sinatra::NotFound
      ]
    end

    before do
      allow(Loga::ServiceVersionStrategies).to receive(:call).and_return('unknown.sha')
    end

    context 'defaults', :with_hostname do
      specify { expect(subject.device).to eq($stdout) }
      specify { expect(subject.filter_exceptions).to eq(framework_exceptions) }
      specify { expect(subject.filter_parameters).to eq([]) }
      specify { expect(subject.format).to eq(:simple) }
      specify { expect(subject.host).to eq(hostname) }
      specify { expect(subject.level).to eq(:info) }
      specify { expect(subject.service_name).to eq('hello_world_app') }
      specify { expect(subject.service_version).to eq('unknown.sha') }
      specify { expect(subject.sync).to be(true) }
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
          allow(Socket).to receive(:gethostname).and_raise(SystemCallError, 'Something')
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

    describe 'service_version' do
      context 'when service version is missing' do
        it 'uses a service version strategy' do
          expect(subject.service_version).to eq('unknown.sha')
        end
      end

      context 'when initialized via user options' do
        let(:options) { super().merge(service_version: 'v3.0.1') }

        it 'sets the service version' do
          expect(subject.service_version).to eq('v3.0.1')
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
            service_version_strategies: ['1.0'],
          )
        end
        let(:formatter) { subject.logger.formatter }

        it 'uses the GELF formatter' do
          expect(subject.logger.formatter).to be_a(Loga::Formatters::GELFFormatter)
        end

        it 'strips the service name' do
          expect(formatter.instance_variable_get(:@service_name)).to eq('hello_world_app')
        end
      end

      context 'when format is :simple' do
        let(:options) { super().merge(format: :simple) }

        it 'uses the SimpleFormatter' do
          expect(subject.logger.formatter).to be_a(Loga::Formatters::SimpleFormatter)
        end
      end
    end

    describe 'logger' do
      let(:logdev) { subject.logger.instance_variable_get(:@logdev) }

      {
        debug: 0,
        info: 1,
        warn: 2,
        error: 3,
        fatal: 4,
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
          expect(logdev.dev.sync).to be(false)
        end
      end
    end

    describe '#structured?' do
      context 'when format is :simple' do
        let(:options) { super().merge(format: :simple) }

        specify { expect(subject.structured?).to be(false) }
      end

      context 'when format is :gelf' do
        let(:options) { super().merge(format: :gelf) }

        specify { expect(subject.structured?).to be(true) }
      end
    end
  end
end
