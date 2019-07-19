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

  redirect to("/sub/#{subscription.id}")
end

get '/sub/:id' do
  subscription = Stripe::Subscription.retrieve(
    params['id']
  )

  check_subscrition(subscription)
end

def check_subscrition(subscription)
  case subscription.status
  when 'incomplete'
    invoice = Stripe::Invoice.retrieve(subscription.latest_invoice)
    check_invoice(subscription, invoice)
  else
    "Subscription: #{subscription.status}"
  end
end

def check_invoice(subscription, invoice)
  case invoice.status
  when 'open'
    payment_intent = Stripe::PaymentIntent.retrieve(invoice.payment_intent)
    check_payment_intent(subscription, invoice, payment_intent)
  else
    "Invoice: #{invoice.status}"
  end
end

def check_payment_intent(subscription, invoice, payment_intent)
  # PaymentIntent#status values have been changes in newer API version:
  # See: https://stripe.com/docs/payments/payment-intents/migration#api-version
  case payment_intent.status
  when 'requires_source_action', 'require_action'
    payment_intent = payment_intent.confirm(
      return_url: "http://0.0.0.0:5000/sub/#{subscription.id}/callback"
    )
    # payment_intent.next_action.type should eq 'redirect_to_url' as we're not
    # confirming the payment_intent with Stripe.js
    redirect to(payment_intent.next_action.redirect_to_url.url)

  # when 'requires_source', 'requires_payment_method'
    # 1. Notify customer of failure and collect a new payment method
    # 2. Attach new payment method to the customer
    # 3. Reattempt payment
    # See: https://stripe.com/docs/billing/subscriptions/payment#failure-1

  else
    "PaymentIntent: #{payment_intent.status}"
  end
end

get '/sub/:id/callback' do
  subscription = Stripe::Subscription.retrieve(
    params['id']
  )

  # Verify callback authenticity, received params are:
  #   payment_intent, payment_intent_client_secret, source_type

  redirect to("/sub/#{subscription.id}")
end
