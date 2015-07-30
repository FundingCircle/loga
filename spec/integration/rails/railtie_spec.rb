require 'ostruct'

describe Loga::Railtie do
  let(:app)         { Rails.application }
  let(:middlewares) { app.middleware.middlewares }

  let(:initializer) { Loga::Railtie.initializers.find { |i| i.name == name } }

  describe name = :loga_initialize_logger do
    let(:name) { name }

    let(:app)    { OpenStruct.new(config: config) }
    let(:config) { OpenStruct.new(loga: loga, log_level: :info) }

    before { initializer.run(app) }

    context 'when loga is disabled' do
      let(:loga) { Loga::Configuration.new.tap { |c| c.enable = false } }

      it 'is not initialized' do
        expect(config.logger).to be_nil
      end
    end

    context 'when loga is enabled' do
      let(:loga) { Loga::Configuration.new }

      it 'initializes the logger' do
        expect(config.logger).to be_a(Logger)
      end

      context 'when the log device is nil' do
        let(:loga) { Loga::Configuration.new.tap { |c| c.device = nil } }

        it 'is not initialized' do
          expect(config.logger).to be_nil
        end
      end
    end
  end

  it 'inserts Loga::Rack::Logger middleware after Rails::Rack::Logger' do
    expect(middlewares.index(Loga::Rack::Logger))
      .to eq(middlewares.index(Rails::Rack::Logger) + 1)
  end
end
