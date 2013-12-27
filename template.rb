# Cloudspace Rails 4 Template
# rails new app_name -m full_path_to_this_template_file.rb
# when generated this will create a rails project ready to serve as an API endpoint

# database setup - users are given a choice between postgres and mysql
data_store = ask("Which database would you like to use?\n1 Postgres (default)\n2 MySQL\nenter the number of your selection")
if data_store == 2
  puts "setting up MySQL"
  msu = ask("MySQL username?")
  msu = app_name if msu.blank?
  gsub_file "config/database.yml", /username: .*/, "username: #{msu}"
  msp = ask("Password for Postgre user #{msu}?")
  gsub_file "config/database.yml", /password:/, "password: #{msp}"
  gsub_file "config/database.yml", /database: myapp_development/, "database: #{app_name}_development"
  gsub_file "config/database.yml", /database: myapp_test/,        "database: #{app_name}_test"
  gsub_file "config/database.yml", /database: myapp_production/,  "database: #{app_name}_production"
  gem "mysql2"
else
  puts "setting up Postgres"
  pgu = ask("Postgres username?")
  pgu = app_name if pgu.blank?
  gsub_file "config/database.yml", /username: .*/, "username: #{pgu}"
  pgp = ask("Password for Postgre user #{pgu}?")
  gsub_file "config/database.yml", /password:/, "password: #{pgp}"
  gsub_file "config/database.yml", /database: myapp_development/, "database: #{app_name}_development"
  gsub_file "config/database.yml", /database: myapp_test/,        "database: #{app_name}_test"
  gsub_file "config/database.yml", /database: myapp_production/,  "database: #{app_name}_production"
  gem "pg"  
end

# make sure we've bundled before trying to drop, create, or migrate databases
run "bundle install"

# drop existing databases and then create the new one
if yes?("Drop any existing databases for #{app_name}?")
  run 'bundle exec rake db:drop'
end
run 'bundle exec rake db:create:all'

#setup cloudspace standard gems and associated needs

# use aws-sdk for s3
gem 'aws-sdk'

# use haml for views
gem 'haml'

# authentication gems - devise
gem "devise"
# scrub password confirmation from logged parameters
gsub_file 'config/application.rb', /:password/, ':password, :password_confirmation'
# generate devise install and user model
generate 'devise:install'
generate 'devise user'
# setup csrf protection - use null_session so that api calls work without a csrf token
gsub_file 'app/controllers/application_controller.rb', 'protect_from_forgery with: :exception', 'protect_from_forgery with: :null_session'
# setup the application to respond to json requests
inject_into_file 'app/controllers/application_controller.rb', before: "end" do <<-'RUBY'
 respond_to :json
RUBY
end

# authentication gems - cancan
gem "cancan"
# rescue cancan errors and direct to the home page
inject_into_file 'app/controllers/application_controller.rb', :before => "\nend" do <<-RUBY
\n
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, :alert => exception.message
  end
RUBY
end

# authentication gems - rolify
gem "rolify"

# automated testing gems
gem_group :test do
  gem "rspec"
  gem "rspec-rails"
  gem "shoulda"
  gem "database_cleaner"
  gem "factory_girl"
end

# documentation gems
gem_group :doc do
  gem "yard"
  gem "yard-activerecord"
  gem "redcarpet"
  gem "github-markup"
end

# debugging gems
gem_group :development do
  gem 'pry'
  gem 'debugger'
end

# code metric gems
gem_group :development do
  gem 'rails_best_practices'
  gem 'rubocop'
  gem 'metric_fu'
end

# development automation gems
gem_group :development do
  gem 'guard-bundler'
  gem 'guard-spring'
  gem 'guard-rails'
  gem 'guard-rspec'
end

# production webserver gem
gem_group :production do
  gem 'unicorn'
end

# create a home route, controller action, and view
route "root :to => 'home#index'"
create_file "app/controllers/home_controller.rb" do <<-'RUBY'
class HomeController < ApplicationController
  def index
  end
end
RUBY
end
create_file "app/views/home/index.html.haml" do <<-'RUBY'
%h1 Hello World
RUBY
end

# bundle and migrate to make sure everything has been applied
run "bundle install"
run 'bundle exec rake db:migrate'

# TODO: configure MongoDB or Redis

# initialize git project and commit progress
git :init
git add: "."
git commit: "-m 'initial project generation using the Cloudspace Rails 4 Template'"