source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.0', '>= 5.0.0.1'

# Data Storage
gem 'mongoid', git: 'https://github.com/mongodb/mongoid.git'
gem 'carrierwave-mongoid', :require => 'carrierwave/mongoid'
gem 'aasm'
gem 'kaminari-mongoid', '~> 0.1.0'

# Background jobs
gem 'sidekiq'

# Video Processing
gem 'streamio-ffmpeg'

# APIs
gem 'active_model_serializers', '~> 0.10.0'

# Settings
gem 'dotenv'

# Use Puma as the app server
# gem 'puma', '~> 3.0'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem 'rack-cors'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri

  # Use RSpec for specs
  gem 'rspec-rails', '3.1.0'

  gem 'rspec-activejob'

  # Use Factory Girl for generating random test data
  gem "factory_girl_rails", "~> 4.0"

  gem 'pry-rails'
  gem 'pry-doc'
end

group :test do
  gem 'shoulda-matchers', '~> 3.1'
  gem 'simplecov'
  gem 'mongoid-rspec' # Unfortunately there is no any this gem versions for mongoid 6. Currently it will install here old version that would return depreaction warnings
end

group :development do
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end


require 'rbconfig'
if RbConfig::CONFIG['target_os'] =~ /darwin(1[0-3])/i
  gem 'rb-fsevent', '<= 0.9.4'
end
