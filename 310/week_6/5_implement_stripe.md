### install `gem 'figaro'` 
~> `bundle exec figaro install`   
~> will look for key in `application.yml` and return the value base on environment  
```ruby
#config/application.yml
#test key
development:
  STRIPE_PUBLISHABLE_KEY: "abcde"
  STRIPE_SECRET_KEY: "abcde"
test:
  STRIPE_PUBLISHABLE_KEY: "abcde"
  STRIPE_SECRET_KEY: "abcde"
#live key
production:
  STRIPE_PUBLISHABLE_KEY: "abcde"
  STRIPE_SECRET_KEY: "abcde"
```

## Charge credit card with stripe  
* install `gem 'stripe'`  

* integrate stripe script in the form  
~> replace `data-key` with `#{ENV['STRIPE_PUBLISHABLE_KEY']}`  
```ruby
#views/user/new.html.haml
#...
#replace submit button with stripe checkout script
  %script ...
```
* stripe will process payment and card info through stripe server  
~> stripe token will only be send to our server  
~> charge new charge with stripe token  
```ruby
  #obtain from stripe API
  #users controller create action
  Stripe.api_key = ENV['STRIPE_SECRET_KEY'] #from stripe account
  Stripe::Charge.create(
    amount: 999,
    currency: "usd",
    card: params[:stripe_token], #from stripe js token
    description: "Charge for myflix for #{@user.email}"
  )
```

## Stripe with custom form  
* integrate custom payment form from ui mockups  

* indicate the payment by adding data-stripe attributes into the custom form  
~> DO NOT include name in custom payment form
~> customer's info will not be send to server, our server only need stripe token for charging.   
~> eg: `data-strip="number"`
~> use rails form helper for `data: {stripe: "exp_month"}` and `data: {stripe: "exp_year"}`

* add stripe javascript v2 to the form page  
~> include in page head  
~> set stripe key
```ruby
%script(type="text/javascript" src="https://js.stripe.com/v2/")
:javascript
  Stripe.setPublishableKey("#{ENV['STRIPE_PUBLISHABLE_KEY']}");
```

* create `javascripts/payment.js` file  
~> js example can be found on stripe docs  
~> implment the Jquery id to the form  
eg: for bootstrap_form to match the javascript submit event  
`bootstrap_form_for(@user, ..., html: { id: "payment-form" })`  
~> implement class in the form for display error message with Jquery event  
~> will create token for the form, append stripe token and then submit with the form  
~> our web server will get `stripeToken` params  

* include `payment.js` in the page  
~> at head of the page 
```ruby
= javascript_include_tag 'payment'
```

* create/implement in `config/initializers/assets.rb`  
~> add js file for precompile  
~> Js file not include in tree in application.js  
```ruby
Rails.application.config.assets.precompile += ['payment.js']
```