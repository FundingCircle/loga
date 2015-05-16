require 'spec_helper'

describe Loga::Logging do
  before { described_class.reset }

  describe '.initialize_logger' do
    let(:logger) { described_class.initialize_logger }

    specify { expect(logger).to be_instance_of(Logger) }

    it 'sets log level to INFO' do
      expect(logger.level).to eq(Logger::INFO)
    end

    it 'sets formatter to GELFFormatter' do
      expect(logger.formatter).to be_instance_of(Loga::GELFFormatter)
    end
  end

  describe '.logger' do
    let(:logger) { described_class.logger }

    specify { expect(logger).to be_instance_of(Logger) }

    it 'memoizes the result' do
      expect(logger).to equal(logger)
    end

    it 'initializes the logger' do
      expect(described_class).to receive(:initialize_logger).with(no_args).once
      logger
    end
  end

  describe '.reset' do
    subject { described_class }

    it 'resets the logger instance' do
      expect { subject.reset }.to change { subject.logger.object_id }
    end
  end
end
