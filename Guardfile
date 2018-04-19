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

group :unit do
  guard :rspec, cmd: 'bundle exec appraisal unit rspec' do
    watch(%r{^spec/unit/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$}) { |m| "spec/unit/#{m[1]}_spec.rb" }
  end
end
