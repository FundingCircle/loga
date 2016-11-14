require 'ostruct'

RSpec.describe Loga::Railtie do
  let(:app)          { Rails.application }
  let(:middlewares)  { app.middleware.middlewares }

  context 'development', if: Rails.env.development? do
    describe 'loga_initialize_logger' do
      let(:formatter) do
        if ActiveSupport::VERSION::MAJOR == 3
          Logger::SimpleFormatter
        else
          ActiveSupport::Logger::SimpleFormatter
        end
      end

      it 'assign Loga logger to Rails logger' do
        expect(Loga.logger).to equal(Rails.logger)
      end

      it 'configures Loga with a simple formatter' do
        expect(Loga.configuration.logger.formatter).to be_a(formatter)
      end
    end
  end

  context 'production', if: Rails.env.production? do
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

      context 'ActionView' do
        [
          'render_collection.action_view',
          'render_partial.action_view',
          'render_template.action_view',
        ].each do |notification|
          let(:notification) { notification }

          it 'removes ActionView::LogSubscriber' do
            expect(subscribers).to_not include(ActionView::LogSubscriber)
          end
        end
      end

      context 'ActionController' do
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
            expect(subscribers).to_not include(ActionController::LogSubscriber)
          end
        end
      end
    end
  end
end
