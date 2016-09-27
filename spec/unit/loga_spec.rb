require 'spec_helper'

describe Loga do
  before { described_class.reset }

  let(:config_missing_class) { described_class::ConfigurationError }
  let(:config_missing_msg) do
    'Loga has not been configured. Configure with Loga.configure(options)'
  end
  let(:options) { { service_name: 'hello_world_app' } }

  describe '.configure' do
    it 'configures Loga' do
      expect(Loga::Configuration).to receive(:new).with(options).and_call_original
      subject.configure(options)
    end

    context 'when configure twice' do
      before { subject.configure(options) }

      it 'raises an error' do
        expect { subject.configure(options) }
          .to raise_error(config_missing_class, 'Loga has already been configured')
      end
    end
  end

  describe '.configuration' do
    context 'when Loga is not configured' do
      it 'raises an error' do
        expect { subject.configuration }
          .to raise_error(config_missing_class, config_missing_msg)
      end
    end

    context 'when Loga is configured' do
      before { subject.configure(options) }

      it 'returns the configuration' do
        expect(subject.configuration.service_name).to eql(options[:service_name])
      end
    end
  end

  describe '.logger' do
    context 'when Loga is not configured' do
      it 'raises an error' do
        expect { subject.logger }
          .to raise_error(config_missing_class, config_missing_msg)
      end
    end

    context 'when Loga is configured' do
      before { subject.configure(options) }
      specify { expect(subject.logger).to be_kind_of(Logger) }
    end
  end

  describe '.reset' do
    before { subject.configure(options) }

    it 'resets the configuration' do
      expect do
        subject.reset
        subject.configure(options)
      end.to change { subject.configuration.object_id }
    end
  end
end
