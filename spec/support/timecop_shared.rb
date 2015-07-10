shared_context 'timecop', timecop: true do
  # Allows fixed timestamps
  before(:all) { Timecop.freeze(time_anchor) }
  after(:all)  { Timecop.return }
end
