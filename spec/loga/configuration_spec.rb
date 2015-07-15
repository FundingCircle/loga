require 'spec_helper'

describe Loga::Configuration do
  describe 'initialize' do
    context 'defaults' do
      specify { expect(subject.host).to eq(hostname_anchor) }
      specify { expect(subject.level).to eq(Logger::INFO) }
      specify { expect(subject.devices).to eq([{ type: :stdout }]) }
      specify { expect(subject.filter_parameters).to eq([]) }
      specify { expect(subject.service_name).to eq(nil) }
      specify { expect(subject.service_version).to eq(nil) }
    end
  end

  describe '#initialize!' do
    subject do
      described_class.new.tap do |config|
        config.service_name = ' hello_world_app '
        config.service_version =  " 1.0\n"
      end
    end

    it 'returns a logger' do
      expect(subject.initialize!).to be_a(Logger)
    end

    it 'initializes the formatter with stiped service name and version' do
      expect(Loga::Formatter).to receive(:new)
        .with(service_name: 'hello_world_app', service_version: '1.0', host: hostname_anchor)
      subject.initialize!
    end
  end
end
