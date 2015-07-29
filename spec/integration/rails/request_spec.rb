require 'spec_helper'

describe 'Integration with Rails', timecop: true do
  let(:app) { Rails.application }

  let(:json_entries) do
    [].tap do |entries|
      STREAM.tap do |s|
        s.rewind
        s.read.split("\n").each do |line|
          entries << JSON.parse(line)
        end
        s.close
        s.reopen
      end
    end
  end

  let(:json) { json_entries.last }

  include_examples 'request logger'
end
