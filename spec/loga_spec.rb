describe Loga do
  describe '.configuration' do
    subject { described_class.configuration }
    specify { expect(subject).to be_instance_of(Loga::Configuration) }

    it 'memoizes the result' do
      expect(subject).to equal(subject)
    end
  end

  pending '.configure'

  describe '.logger' do
    subject { described_class.logger }
    specify { expect(subject).to be_kind_of(Logger) }
  end
end
