# A sample Guardfile
# More info at https://github.com/guard/guard#readme

## Uncomment and set this to only include directories you want to watch
# directories %w(app lib config test spec features) \
#  .select{|d| Dir.exists?(d) ? d : UI.warning("Directory #{d} does not exist")}

## Note: if you are using the `directories` clause above and you are not
## watching the project directory ('.'), then you will want to move
## the Guardfile to a watched dir and symlink it back, e.g.
#
#  $ mkdir config
#  $ mv Guardfile config/
#  $ ln -s config/Guardfile .
#
# and, you'll have to watch "config/Guardfile" instead of "Guardfile"

guard :rubocop do
  watch(%r{^lib/.+\.rb$})
  watch(%r{^spec/.+\.rb$})
end

group :sinatra do
  %w(production development).each do |env|
    guard :rspec,
          all_on_start: true,
          cmd: "RACK_ENV=#{env} bundle exec appraisal sinatra14 rspec" do
      watch(%r{^spec/integration/sinatra_spec.rb$})
    end
  end
end

group :rails do
  %w(production development).each do |env|
    %w(rails32 rails40 rails50).each do |appraisal|
      guard :rspec,
            all_on_start: true,
            cmd: "RACK_ENV=#{env} bundle exec appraisal #{appraisal} rspec" do
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
