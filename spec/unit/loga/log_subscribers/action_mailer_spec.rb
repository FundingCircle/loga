# frozen_string_literal: true

require 'spec_helper'
require 'active_support'
require 'loga/log_subscribers/action_mailer'

RSpec.describe Loga::LogSubscribers::ActionMailer do
  subject(:mailer) { described_class.new }

  before { stub_loga }

  let(:event) do
    instance_double(
      ActiveSupport::Notifications::Event,
      payload: payload,
      duration: 0.0001,
      time: Time.now,
    )
  end

  describe '#deliver' do
    context 'when an email is sent' do
      let(:payload) do
        {
          mailer: 'FakeMailer',
          to: ['user@example.com'],
        }
      end
      let(:config) { instance_double Loga::Configuration, hide_pii: hide_pii }

      before do
        allow(Loga.logger).to receive(:info)
        allow(Loga).to receive(:configuration).and_return(config)
      end

      context 'when configuration hide_pii is true' do
        let(:hide_pii) { true }

        it 'logs an info message' do
          mailer.deliver(event)
          expect(Loga.logger).to have_received(:info).with(Loga::Event) do |event|
            expect(event.message).to include('FakeMailer: Sent mail')
            expect(event.message).not_to include('user@example.com')
          end
        end
      end

      context 'when configuration option hide_pii is false' do
        let(:hide_pii) { false }

        it 'logs an info message' do
          mailer.deliver(event)
          expect(Loga.logger).to have_received(:info).with(Loga::Event) do |event|
            expect(event.message).to include('FakeMailer: Sent mail to user@example.com')
          end
        end
      end
    end
  end

  describe '#process' do
    context 'when an email is sent' do
      let(:payload) do
        {
          mailer: 'FakeMailer',
          action: 'hello_world',
        }
      end

      it 'logs an info message' do
        allow(Loga.logger).to receive(:debug)
        mailer.process(event)
        expect(Loga.logger).to have_received(:debug)
          .with(kind_of(Loga::Event)) do |event|
            expect(event.message).to include(
              'FakeMailer#hello_world: Processed outbound mail',
            )
          end
      end
    end
  end

  describe '#receive' do
    context 'when an email is sent' do
      let(:payload) do
        {
          mailer: 'FakeMailer',
          from: 'loremipsum@example.com',
          subject: 'Lorem ipsum',
        }
      end
      let(:config) { instance_double Loga::Configuration, hide_pii: hide_pii }

      before do
        allow(Loga.logger).to receive(:info)
        allow(Loga).to receive(:configuration).and_return(config)
      end

      context 'when configuration hide_pii is true' do
        let(:hide_pii) { true }

        it 'logs an info message without email' do
          mailer.receive(event)
          expect(Loga.logger).to have_received(:info)
            .with(kind_of(Loga::Event)) do |event|
              expect(event.message).to include('Received mail')
              expect(event.message).not_to include('loremipsum@example.com')
            end
        end
      end

      context 'when configuration option hide_pii is false' do
        let(:hide_pii) { false }

        it 'logs an info message with email' do
          mailer.receive(event)
          expect(Loga.logger).to have_received(:info)
            .with(kind_of(Loga::Event)) do |event|
              expect(event.message).to include(
                'Received mail from loremipsum@example.com',
              )
            end
        end
      end
    end
  end
end
