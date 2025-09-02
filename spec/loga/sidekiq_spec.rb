# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Loga::Sidekiq do
  describe '.configure_logging' do
    context 'when sidekiq is defined' do
      it 'gets invoked on Loga.configure' do
        allow(described_class).to receive(:configure_logging)

        Loga.reset

        Loga.configure(
          service_name: 'hello_world_app',
          service_version: '1.0',
          device: StringIO.new,
          format: :gelf,
        )

        expect(described_class).to have_received(:configure_logging)
      end

      it 'assigns our custom sidekiq job logger depending on the sidekiq version' do
        Loga.reset

        Loga.configure(
          service_name: 'hello_world_app',
          service_version: '1.0',
          device: StringIO.new,
          format: :gelf,
        )

        m = ENV['BUNDLE_GEMFILE'].match(/sidekiq(?<version>\d+)/)

        job_logger =
          if Sidekiq.respond_to?(:options)
            Sidekiq.options[:job_logger]
          else
            sidekiq_config = Sidekiq.instance_variable_get(:@config)
            sidekiq_config && sidekiq_config[:job_logger]
          end

        case m['version']
        when '51'
          expect(job_logger).to eq(Loga::Sidekiq5::JobLogger)
        when '6', '60', '61', '62', '63', '64', '65'
          expect(job_logger).to eq(Loga::Sidekiq6::JobLogger)
        when '7', '70', '71', '72', '73'
          expect(job_logger).to eq(Loga::Sidekiq7::JobLogger)
        when '8', '80'
          expect(job_logger).to eq(Loga::Sidekiq8::JobLogger)
        end
      end
    end

    shared_examples 'a blank change' do
      it 'does nothing' do
        expect(described_class.configure_logging).to be_nil
      end
    end

    context 'when sidekiq is not defined' do
      before { hide_const('Sidekiq') }

      it_behaves_like 'a blank change'
    end

    context 'when sidekiq version is 4.2' do
      before { stub_const('::Sidekiq::VERSION', '4.2') }

      it_behaves_like 'a blank change'
    end
  end
end
