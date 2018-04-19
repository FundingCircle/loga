require 'spec_helper'

RSpec.describe Loga::LogSubscribers::ActionMailer, if: Rails.env.production? do
  let(:log_entries) do
    entries = []
    STREAM.tap do |s|
      s.rewind
      entries = s.read.split("\n").map { |line| JSON.parse(line) }
      s.close
      s.reopen
    end
    entries
  end

  let(:last_log_entry) { log_entries.last }

  context 'when an email is being sent' do
    it 'delivers an email' do
      send_mail = -> { FakeMailer.send_email }

      expect(&send_mail).to change { FakeMailer.deliveries.size }.by(1)
    end

    if Gem::Version.new(Rails.version) >= Gem::Version.new('5.0.0')
      it 'has the proper payload for message processing' do
        configuration = Loga::Configuration.new(
          format: :gelf,
          service_name: 'loga_test',
          device: STREAM,
          level: :debug,
        )

        allow(Loga).to receive(:logger).and_return(configuration.logger)

        FakeMailer.send_email

        message_pattern = /^FakeMailer#basic_mail: Processed outbound mail in\(*/
        short_message   = log_entries.last(2).first['short_message']

        expect(short_message).to match message_pattern
      end
    end

    it 'has the proper payload for message delivery' do
      FakeMailer.send_email

      message_pattern = /^FakeMailer: Sent mail to user@example.com in \(*/
      expect(last_log_entry['short_message']).to match(message_pattern)
    end

    it 'has the additional key "_mailer"' do
      FakeMailer.send_email

      expect(last_log_entry).to have_key('_mailer')
    end

    it 'has the additional key "_unique_id"' do
      FakeMailer.send_email

      expect(last_log_entry).to have_key('_unique_id')
    end
  end
end
