guard :rubocop do
  watch(%r{^lib/.+\.rb$})
  watch(%r{^spec/.+\.rb$})
end

group :sinatra do
  %w[production development].each do |env|
    guard :rspec,
          all_on_start: true,
          cmd: "RACK_ENV=#{env} bundle exec appraisal sinatra14 rspec" do
      watch(%r{^spec/integration/sinatra_spec.rb$})
    end
  end
end

group :rails do
  %w[production development].each do |env|
    %w[rails32 rails40 rails50 rails52].each do |appraisal|
      cmd = "RACK_ENV=#{env} bundle exec appraisal #{appraisal} rspec"

      guard :rspec, all_on_start: true, cmd: cmd do
        watch('lib/loga/railtie.rb') do
          [
            'spec/integration/rails/request_spec.rb',
            'spec/integration/rails/railtie_spec.rb',
          ]
        end

        watch(%r{^spec/fixtures/rails\d{2}/.+\.rb$}) do
          [
            'spec/integration/rails/request_spec.rb',
            'spec/integration/rails/railtie_spec.rb',
          ]
        end

        watch(%r{^spec/integration/rails/.+_spec\.rb$})
      end
    end
  end
end

group :sidekiq do
  cmd = 'bundle exec appraisal sidekiq51 rspec'

  guard :rspec, all_on_start: true, cmd: cmd do
    watch('lib/loga/sidekiq/job_logger.rb') do
      [
        'spec/integration/sidekiq_spec.rb',
        'spec/loga/sidekiq/job_logger_spec.rb',
        'spec/loga/sidekiq_spec.rb',
      ]
    end
  end
end

group :unit do
  guard :rspec, cmd: 'bundle exec appraisal unit rspec' do
    watch(%r{^spec/unit/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$}) { |m| "spec/unit/#{m[1]}_spec.rb" }
    watch('spec/loga/context_manager_spec.rb')
  end
end
