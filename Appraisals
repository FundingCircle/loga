if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.4.0')
  appraise 'rails32' do
    gem 'rails', '~> 3.2.0'
  end

  appraise 'rails40' do
    gem 'rails', '~> 4.0.0'
  end
end

if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.7.0')
  appraise 'rails42' do
    gem 'rails', '~> 4.2.0'
  end

  appraise 'rails50' do
    gem 'rails', '~> 5.0.0'
  end

  appraise 'rails52' do
    gem 'rails', '~> 5.2.0'
  end
end

appraise 'sinatra14' do
  gem 'sinatra', '~> 1.4.0'
end

if Gem::Version.new(RUBY_VERSION) > Gem::Version.new('2.5.0')
  appraise 'rails60' do
    gem 'rails', '~> 6.0.0'
  end

  appraise 'sidekiq6' do
    gem 'sidekiq', '~> 6.0'
  end
end

appraise 'sidekiq51' do
  gem 'sidekiq', '~> 5.1.0'
end

appraise 'unit' do
end
