# frozen_string_literal: true

require 'timecop'

shared_context 'timecop', :timecop do
  # Allows fixed timestamps
  before(:all) { Timecop.freeze(time_anchor) }

  after(:all)  { Timecop.return }
end
