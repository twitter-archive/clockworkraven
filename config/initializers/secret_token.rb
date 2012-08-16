# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

token = YAML.load_file(File.expand_path('../../secret.yml',  __FILE__))['secret']
ClockworkRaven::Application.config.secret_token = token