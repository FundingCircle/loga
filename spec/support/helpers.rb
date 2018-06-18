require 'bigdecimal'

module Helpers
  # Time used when testing timestamp
  def time_anchor
    Time.new(2015, 12, 15, 9, 30, 5.123, '+06:00')
  end

  def time_anchor_unix
    BigDecimal('1450150205.123')
  end

  # Creates a Loga module mock with corresponding logger mock.
  # Both mocks are verifiable.
  #
  # logger, loga = loga_mock
  def loga_mock
    loga = class_double(Loga).as_stubbed_const
    logger = instance_double(Logger)
    allow(loga).to receive(:logger).and_return(logger)
    [logger, loga]
  end
end
