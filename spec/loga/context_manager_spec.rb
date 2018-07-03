require 'spec_helper'

RSpec.describe Loga::ContextManager do
  subject(:manager) { described_class.new }

  describe '.current' do
    it 'returns an instance of context manager' do
      expect(described_class.current).to be_an_instance_of(described_class)
    end
  end

  describe '#clear' do
    it 'sets the value of @context to nil' do
      manager.clear

      expect(manager.instance_variable_get(:@context)).to eq({})
    end
  end

  describe '#attach_context' do
    it 'adds the given custom attributes to @context' do
      attach_action = -> { manager.attach_context(uuid: 'lorem-ipsum') }

      expect(&attach_action).to change { manager.instance_variable_get(:@context) }
        .from({})
        .to(uuid: 'lorem-ipsum')
    end
  end

  describe '#retrieve_context' do
    it 'can retrieve context' do
      manager.attach_context(fruit: 'banana')

      expect(manager.retrieve_context).to eq(fruit: 'banana')
    end
  end
end
