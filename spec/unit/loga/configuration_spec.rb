require 'spec_helper'

describe Loga::Configuration do
  let(:options) do
    { service_name: 'hello_world_app' }
  end

  subject { described_class.new(options) }

  describe 'initialize' do
    context 'defaults' do
      specify { expect(subject.host).to eq(hostname_anchor) }
      specify { expect(subject.level).to eq(:info) }
      specify { expect(subject.device).to eq(STDOUT) }
      specify { expect(subject.sync).to eq(true) }
      specify { expect(subject.filter_parameters).to eq([]) }
      specify { expect(subject.service_name).to eq('hello_world_app') }
      specify { expect(subject.service_version).to eq(:git) }
      specify { expect(subject.formatter).to eq(nil) }
    end

    context 'when hostname cannot be resolved' do
      before do
        allow(Socket).to receive(:gethostname).and_raise(Exception)
      end

      it 'uses a default hostname' do
        expect(subject.host).to eq('unknown.host')
      end
    end

    describe 'service_name' do
      context 'when service name is missing' do
        let(:options) do
          { service_: 'hello_world_app' }
        end

        it 'raises an error' do
          expect { subject }.to raise_error(described_class::ServiceNameMissingError)
        end
      end
    end

    describe 'formatter' do
      context 'when initialized with formatter' do
        let(:options) { super().merge(formatter: 'gelf') }

        it 'sets the formatter' do
          expect(subject.formatter).to eq('gelf')
        end
      end

      context 'when LOGA_FORMATTER is specified' do
        before do
          allow(ENV).to receive(:[]).with('LOGA_FORMATTER').and_return('gelf')
        end

        it 'sets the formatter' do
          expect(subject.formatter).to eq('gelf')
        end
      end

      context 'when initialized with options and LOGA_FORMATTER is specified' do
        let(:options) { super().merge(formatter: 'gelf') }

        before do
          allow(ENV).to receive(:[]).with('LOGA_FORMATTER').and_return('plain')
        end

        it 'prefers the options' do
          expect(subject.formatter).to eq('gelf')
        end
      end
    end
  end

  describe '#initialize!' do
    let(:options) do
      {
        service_name: ' hello_world_app ',
        service_version: " 1.0\n",
      }
    end

    it 'initializes the formatter with stripped service name and version' do
      expect(Loga::Formatter).to receive(:new)
        .with(service_name: 'hello_world_app',
              service_version: '1.0',
              host: hostname_anchor)
      subject.initialize!
    end

    describe 'logger' do
      let(:logdev) { subject.logger.instance_variable_get(:@logdev) }

      context 'when device is nil' do
        before do
          subject.device = nil
          allow(STDERR).to receive(:write)
        end
        let(:error_message) { /Loga could not be initialized/ }
        it 'uses STDERR' do
          subject.initialize!
          expect(logdev.dev).to eq(STDERR)
        end
        it 'logs an error to STDERR' do
          expect(STDERR).to receive(:write).with(error_message)
          subject.initialize!
        end
      end

      {
        debug:   0,
        info:    1,
        warn:    2,
        error:   3,
        fatal:   4,
        unknown: 5,
      }.each do |sym, level|
        context "when log level is #{sym}" do
          before { subject.level = sym }
          it "uses log level #{sym}" do
            subject.initialize!
            expect(subject.logger.level).to eq(level)
          end
        end
      end

      context 'when sync is false' do
        before { subject.sync = false }
        it 'uses warn log level' do
          subject.initialize!
          expect(logdev.dev.sync).to eq(false)
        end
      end
    end
  end

  describe '#logger' do
    context 'when initialized' do
      before { subject.initialize! }
      it 'returns a logger' do
        expect(subject.logger).to be_a(Logger)
      end

      it 'returns a tagged logger' do
        expect(subject.logger).to respond_to(:tagged)
      end
    end

    context 'when not initialized' do
      specify { expect(subject.logger).to be_nil }
    end
  end
end
