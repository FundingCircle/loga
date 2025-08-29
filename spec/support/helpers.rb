# frozen_string_literal: true

require 'bigdecimal'

module Helpers
  # Time used when testing timestamp
  def time_anchor
    Time.new(2015, 12, 15, 9, 30, 5.123, '+06:00')
  end

  def time_anchor_unix
    BigDecimal('1450150205.123')
  end

  def stub_loga
    loga = class_double(Loga).as_stubbed_const
    logger = instance_double(Logger)
    allow(loga).to receive(:logger).and_return(logger)
    loga
  end

  def with_new_ruby(**data)
    if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.4')
      data[:test]
    else
      data[:else]
    end
  end
end
