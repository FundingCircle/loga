# frozen_string_literal: true

require 'spec_helper'

describe Loga do
  before { described_class.reset }

  let(:config_missing_class) { described_class::ConfigurationError }
  let(:config_missing_msg) do
    'Loga has not been configured. Configure with Loga.configure(options)'
  end
  let(:options)           { { service_name: 'hello_world_app' } }
  let(:framework_options) { { format: 'gelf' } }

  describe '.configure' do
    it 'configures Loga' do
      allow(Loga::Configuration).to receive(:new).and_call_original
      subject.configure(options)
      expect(Loga::Configuration).to have_received(:new).with(options, {})
    end

    context 'when framework options provided' do
      it 'configures Loga' do
        allow(Loga::Configuration).to receive(:new).and_call_original
        subject.configure(options, framework_options)
        expect(Loga::Configuration).to have_received(:new)
          .with(options, framework_options)
      end
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

      specify { expect(subject.logger).to be_a(Logger) }
    end
  end

  describe '.reset' do
    before { subject.configure(options) }

    it 'resets the configuration' do
      expect do
        subject.reset
        subject.configure(options)
      end.to(change { subject.configuration.object_id })
    end
  end
end
