# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Loga::ServiceVersionStrategies do
  describe '#call' do
    context 'when GIT is available' do
      before do
        allow(described_class::SCM_GIT).to receive(:call).and_return("2776b9c\n")
      end

      it 'returns the git sha' do
        expect(subject.call).to eql('2776b9c')
      end
    end

    context 'when REVISION file is available' do
      before do
        allow(described_class::SCM_GIT).to receive(:call).and_return(nil)
        allow(File).to receive(:read).with('REVISION').and_return("2776b9c\n")
      end

      it 'returns the file content' do
        expect(subject.call).to eql('2776b9c')
      end
    end

    context 'when both GIT and REVISION file are unavailable' do
      before do
        allow(described_class::SCM_GIT).to       receive(:call).and_return(nil)
        allow(described_class::REVISION_FILE).to receive(:call).and_return(nil)
      end

      it 'returns a default value' do
        expect(subject.call).to eql('unknown.sha')
      end
    end
  end
end
