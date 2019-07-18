require 'dotenv'
require 'json'
require 'sinatra'
require 'stripe'

Dotenv.load
Stripe.api_key = ENV['STRIPE_SECRET_KEY']
Stripe.api_version = '2017-01-27'

get '/' do
  status 200
  erb :index
end
