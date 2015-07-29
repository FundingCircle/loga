describe 'Railtie' do
  let(:app)         { Rails.application }
  let(:middlewares) { app.middleware.middlewares }

  it 'inserts Loga::Rack::Logger middleware after Rails::Rack::Logger' do
    expect(middlewares.index(Loga::Rack::Logger))
      .to eq(middlewares.index(Rails::Rack::Logger) + 1)
  end
end
