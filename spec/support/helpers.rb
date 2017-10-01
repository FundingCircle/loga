require 'bigdecimal'

module Helpers
  # Time used when testing timestamp
  def time_anchor
    Time.new(2015, 12, 15, 9, 30, 5.123, '+06:00')
  end

  def time_anchor_unix
    BigDecimal.new('1450150205.123')
  end
end
