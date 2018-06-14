require 'ostruct'

RSpec.describe Loga::Railtie do
  let(:app)          { Rails.application }
  let(:middlewares)  { app.middleware.middlewares }

  describe 'Tempfile' do
    let(:tempfile) { Tempfile.new('README.md') }

    it 'monkey patches #as_json' do
      expect(tempfile.as_json).to eql(tempfile.to_s)
    end
  end

  context 'when development', if: Rails.env.development? do
    describe 'loga_initialize_logger' do
      let(:formatter) { Loga::Formatters::SimpleFormatter }

      it 'assign Loga logger to Rails logger' do
        expect(Loga.logger).to equal(Rails.logger)
      end

      it 'configures Loga with a simple formatter' do
        expect(Loga.configuration.logger.formatter).to be_a(formatter)
      end
    end
  end

  context 'when production', if: Rails.env.production? do
    describe 'loga_initialize_logger' do
      it 'assign Loga logger to Rails logger' do
        expect(Loga.logger).to equal(Rails.logger)
      end

      it 'configures Loga with a structured formatter' do
        expect(Loga.configuration.logger.formatter)
          .to be_a(Loga::Formatters::GELFFormatter)
      end

      it 'disables colorized logging' do
        expect(app.config.colorize_logging).to eq(false)
      end
    end

    describe 'loga_initialize_middleware' do
      it 'inserts Loga::Rack::Logger middleware after Rails::Rack::Logger' do
        expect(middlewares.index(Loga::Rack::Logger))
          .to eq(middlewares.index(Rails::Rack::Logger) + 1)
      end
    end

    describe 'instrumentation' do
      let(:listeners)   do
        ActiveSupport::Notifications.notifier.listeners_for(notification)
      end

      let(:subscribers) do
        listeners.map { |l| l.instance_variable_get(:@delegate).class }
      end

      describe 'ActionView' do
        [
          'render_collection.action_view',
          'render_partial.action_view',
          'render_template.action_view',
        ].each do |notification|
          let(:notification) { notification }

          it 'removes ActionView::LogSubscriber' do
            expect(subscribers).not_to include(ActionView::LogSubscriber)
          end
        end
      end

      describe 'ActionController' do
        [
          'exist_fragment?.action_controller',
          'expire_fragment.action_controller',
          'expire_page.action_controller',
          'halted_callback.action_controller',
          'logger.action_controller',
          'process_action.action_controller',
          'read_fragment.action_controller',
          'redirect_to.action_controller',
          'send_data.action_controller',
          'send_file.action_controller',
          'start_processing.action_controller',
          'unpermitted_parameters.action_controller',
          'write_fragment.action_controller',
          'write_page.action_controller',
        ].each do |notification|
          let(:notification) { notification }

          it 'removes ActionController::LogSubscriber' do
            expect(subscribers).not_to include(ActionController::LogSubscriber)
          end
        end
      end

      describe 'ActionMailer' do
        [
          'receive.action_mailer',
          'deliver.action_mailer',
          'process.action_mailer',
        ].each do |notification|
          let(:notification) { notification }

          it 'removes ActionMailer::LogSubscriber' do
            expect(subscribers).not_to include(ActionMailer::LogSubscriber)
          end
        end
      end
    end
  end
end
