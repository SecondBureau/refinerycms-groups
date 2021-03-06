require 'rubygems'
require 'spork'

def setup_environment
  puts "==>> setup the environment"

  # Configure Rails Environment
  ENV["RAILS_ENV"] ||= 'test'

  if File.exist?(dummy_path = File.expand_path('../dummy/config/environment.rb', __FILE__))
    require dummy_path
  elsif File.dirname(__FILE__) =~ %r{vendor/extensions}
    # Require the path to the refinerycms application this is vendored inside.
    require File.expand_path('../../../../../config/environment', __FILE__)
  else
    puts "Could not find a config/environment.rb file to require. Please specify this in #{File.expand_path(__FILE__)}"
  end

  require 'rspec/rails'
  require 'capybara/rspec'
  require 'factory_girl'

  Rails.backtrace_cleaner.remove_silencers!

  RSpec.configure do |config|
    config.mock_with :rspec
    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.run_all_when_everything_filtered = true
    config.include FactoryGirl::Syntax::Methods
  end
end

def reload_the_app_and_route
  Dir["app/controllers/*/*/*.rb"].each do |controller|
    load controller
    puts "====>>>> loading #{controller}"
  end
  Dir["app/controllers/*/*/*/*.rb"].each do |controller|
    load controller
    puts "====>>>> loading #{controller}"
  end
  Dir["app/models/*/*/*.rb"].each do |model|
    load model
    puts "====>>>> loading #{model}"
  end
  Dir["config/*.rb"].each do |file|
    load file
    puts "====>>>> loading #{file}"
  end
end

def each_run
  puts "==>> reloading files"
  Rails.cache.clear
  ActiveSupport::Dependencies.clear
  FactoryGirl.reload
  # Requires supporting files with custom matchers and macros, etc,
  # in ./support/ and its subdirectories including factories.
  ([Rails.root.to_s] | ::Refinery::Plugins.registered.pathnames).map{|p|
    Dir[File.join(p, 'spec', 'support', '**', '*.rb').to_s]
  }.flatten.sort.each do |support_file|
    require support_file
  end
  # Reload all model files when run each spec
  # otherwise there might be out-of-date testing
  reload_the_app_and_route
  # create Guest Group
  puts "==>> reloading Guests Group"
  Refinery::Groups::Group.guest_group
  # create roles
  puts "==>> reloading Roles"
  Refinery::Role[Refinery::Groups.admin_role]
  Refinery::Role[Refinery::Groups.superadmin_role]
end

# If spork is available in the Gemfile it'll be used but we don't force it.
Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.
  setup_environment
end

Spork.each_run do
  # This code will be run each time you run your specs.
  each_run
end
