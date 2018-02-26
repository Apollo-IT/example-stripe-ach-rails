class PlaidController < ApplicationController
  def new

  end

  def create
    # If a plaid token is submitted, request a bank token
    if params[:public_token] && params[:account_id]
      public_token = params[:public_token]
      account_id = params[:account_id]

      # Get the Stripe bank token from Plaid
      token = Plaid::User.exchange_token(public_token, account_id)

      # Create Stripe customer with token
      begin
        customer = Stripe::Customer.create(
          source: token.stripe_bank_account_token,
          description: 'Plaid example customer',
          metadata: { 'plaid_account' => account_id }
        )

        # Create sessions for the customer and bank account
        # For the purpose of this demo, we're just storing a customer ID in a session.
        # In a production application, you'll want to store the customer in your database
        session[:customer] = customer.id
        session[:bank_account] = customer.sources.data.first.id

        # Direct the customer to pay
        flash[:success] = 'Your bank account has been connected.'
        redirect_to new_payment_path
      rescue Stripe::StripeError => e
        # Display a very generic error to the user, and maybe send
        # yourself an email
        flash[:alert] = e.message
        render 'create'
      rescue => e
        # Something else happened, completely unrelated to Stripe
        flash[:alert] = e.message
        render 'create'
      end
    else
      flash[:alert] = 'No Plaid token provided'
      render 'create'
    end

  end
end
