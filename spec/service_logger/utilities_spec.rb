require 'spec_helper'

describe ServiceLogger::Utilities do
  subject { Object.new.extend(ServiceLogger::Utilities) }

  describe '#unix_time_with_ms(time)' do
    subject { super().unix_time_with_ms(time_anchor) }

    it 'formats Time in seconds since unix epoch with decimal places for milliseconds' do
      expect(subject).to eq('1450171805.123')
    end
  end

  describe 'duration_in_ms#(started_at, ended_at)' do
    let(:start_time) { Time.new(2002, 10, 31, 2, 2, 2.0) }
    let(:end_time)   { Time.new(2002, 10, 31, 2, 2, 2.6789) }

    subject { super().duration_in_ms(start_time, end_time) }

    it 'calculates elapsed time rounding the nearest millisecond' do
      expect(subject).to eq(679)
    end
  end
end
