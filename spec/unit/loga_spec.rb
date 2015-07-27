require 'spec_helper'

describe Loga do
  before { described_class.reset }

  describe '.configuration' do
    specify { expect(subject.configuration).to be_instance_of(Loga::Configuration) }

    it 'memoizes the result' do
      expect(subject.configuration).to equal(subject.configuration)
    end
  end

  describe '.configure' do
    it 'configures Loga' do
      expect { |b| subject.configure(&b) }.to yield_with_args(subject.configuration)
    end
  end

  describe '.initialize!' do
    it 'initializes Loga' do
      expect { subject.initialize! }.to_not raise_error
    end
  end

  describe '.logger' do
    context 'when Loga is not initialized' do
      specify { expect(subject.logger).to be_nil }
    end
    context 'when Loga is initialized' do
      before { Loga.initialize! }
      specify { expect(subject.logger).to be_kind_of(Logger) }
    end
  end

  describe '.reset' do
    it 'resets the configuration' do
      expect { subject.reset }.to change { subject.configuration.object_id }
    end
  end
end
