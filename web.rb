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

post '/subscribe' do
  token = Stripe::Token.retrieve(params[:stripeToken])

  customer = Stripe::Customer.create(
    source: token,
    name: params['name'],
    email: params['email']
  )

  subscription = Stripe::Subscription.create(
    customer: customer.id,
    items: [{ plan: ENV['STRIPE_PLAN'] }],
    payment_behavior: 'allow_incomplete'
  )

  subscription.inspect
end
