require 'spec_helper'

describe Loga::RevisionStrategy do
  describe '.call' do
    it 'uses :git as default argument' do
      expect(Loga::RevisionStrategy.call).to match(/\h+/)
    end

    it "returns 'unknown.sha' when argument is empty string" do
      expect(Loga::RevisionStrategy.call('')).to eq('unknown.sha')
    end

    context 'called with :git argument' do
      it 'fetches the service version from git' do
        expect(Loga::RevisionStrategy.call(:git)).to match(/\h+/)
      end

      it 'reads the REVISION file when no git repo' do
        allow(Loga::RevisionStrategy).to receive(:fetch_from_git) { false }
        expect(File).to receive(:read).with('REVISION').and_return('sha1_hash')
        expect(Loga::RevisionStrategy.call(:git)).to eq('sha1_hash')
      end

      it "returns 'unknown.sha' otherwise" do
        allow(Loga::RevisionStrategy).to receive(:fetch_from_git) { false }
        allow(Loga::RevisionStrategy).to receive(:read_from_file) { false }
        expect(Loga::RevisionStrategy.call(:git)).to eq('unknown.sha')
      end
    end

    context 'called with anything else' do
      it 'returns the argument called with' do
        expect(Loga::RevisionStrategy.call('foobar')).to eq('foobar')
      end

      it 'strips any leading and trailing whitespace' do
        expect(Loga::RevisionStrategy.call("\t foobar\r\n ")).to eq('foobar')
      end
    end
  end
end
