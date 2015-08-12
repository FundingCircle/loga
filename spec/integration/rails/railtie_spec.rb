require 'ostruct'

RSpec.describe Loga::Railtie do
  let(:app)          { Rails.application }
  let(:middlewares)  { app.middleware.middlewares }
  let(:initializers) { described_class.initializers }

  describe 'loga_initialize_logger' do
    let(:initializer) { initializers.find { |i| i.name == :loga_initialize_logger } }

    let(:app)    { OpenStruct.new(config: config) }
    let(:config) { OpenStruct.new(loga: loga, log_level: :info) }

    before { initializer.run(app) }

    context 'when loga is disabled' do
      let(:loga) { Loga::Configuration.new.tap { |c| c.enabled = false } }

      it 'is not initialized' do
        expect(config.logger).to be_nil
      end
    end

    context 'when loga is enabled' do
      let(:loga) { Loga::Configuration.new }

      it 'initializes the logger' do
        expect(config.logger).to be_a(Logger)
      end
    end
  end

  it 'inserts Loga::Rack::Logger middleware after Rails::Rack::Logger' do
    expect(middlewares.index(Loga::Rack::Logger))
      .to eq(middlewares.index(Rails::Rack::Logger) + 1)
  end

  it 'disables colorized logging' do
    expect(app.config.colorize_logging).to eq(false)
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
  end
end
