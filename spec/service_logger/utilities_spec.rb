require 'spec_helper'

describe ServiceLogger::Utilities do
  subject { Object.new.extend(ServiceLogger::Utilities) }

  describe '#unix_time_with_ms(time)' do
    subject { super().unix_time_with_ms(time_anchor) }

    it 'formats Time in seconds since unix epoch with decimal places for milliseconds' do
      expect(subject).to eq('1450171805.123')
    end
  end
end
