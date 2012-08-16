namespace :raven do
  desc "Perform setup for Travis CI"
  task :travis_setup do
    `cp config/auth.example_password.yml config/auth.yml`
    `cp config/database.example.yml config/database.yml`
    `cp config/mturk.example.yml config/mturk.yml`
    `cp config/secret.example.yml config/secret.yml`
    `rake db:create`
    `rake db:structure:load`
  end
end
