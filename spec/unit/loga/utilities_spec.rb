require 'spec_helper'

describe Loga::Utilities do
  subject { Object.new.extend(described_class) }

  describe 'duration_in_ms#(started_at, ended_at)' do
    subject { super().duration_in_ms(start_time, end_time) }

    let(:start_time) { Time.new(2002, 10, 31, 2, 2, 2.0) }
    let(:end_time)   { Time.new(2002, 10, 31, 2, 2, 2.6789) }

    it 'calculates elapsed time rounding the nearest millisecond' do
      expect(subject).to eq(679)
    end
  end
end
