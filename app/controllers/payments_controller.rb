class PaymentsController < ApplicationController
  def new
    if session[:customer] && session[:bank_account]
      @customer = Stripe::Customer.retrieve(session[:customer])
      @bank_account = @customer.sources.retrieve(session[:bank_account])
    else
      flash[:alert] = 'Please add a bank account to make an ACH payment.'
      redirect_to root_path
    end
  end

  def create
    # Turn the amount into cents and strip dollar signs
    amount = (100 * params[:amount].tr('$', '').to_r).to_i
    
    # Check for a valid donation amount (the minimum charge allowed in USD is $.50)
    unless amount > 50
      flash[:alert] = 'Please enter a valid donation amount (minimum donation is $.50).'
      redirect_to new_payment_path and return
    end
    
    # Check for a customer and bank account ID
    if params[:customer] && params[:bank_account]
      # Create the charge on Stripe
      begin
        charge = Stripe::Charge.create(
          customer: params[:customer],
          source: params[:bank_account],
          amount: amount,
          currency: 'usd',
          description: 'Payment from ACH example app'
        )

        # Let the customer know the payment was successful
        flash[:success] = "Thanks for your donation! Your transaction ID is #{charge.id}."
        redirect_to payments_path
      rescue Stripe::RateLimitError => e
        # Too many requests made to the API too quickly
        flash[:alert] = e.message
        redirect_to new_payment_path
      rescue Stripe::InvalidRequestError => e
        # Invalid parameters were supplied to Stripe's API
        flash[:alert] = e.message
        redirect_to new_payment_path
      rescue Stripe::AuthenticationError => e
        # Authentication with Stripe's API failed
        # (maybe you changed API keys recently)
        flash[:alert] = e.message
        redirect_to new_payment_path
      rescue Stripe::APIConnectionError => e
        # Network communication with Stripe failed
        flash[:alert] = e.message
        redirect_to new_payment_path
      rescue Stripe::StripeError => e
        # Display a very generic error to the user, and maybe send
        # yourself an email
        flash[:alert] = e.message
        redirect_to new_payment_path
      rescue => e
        # Something else happened, completely unrelated to Stripe
        flash[:alert] = e.message
        redirect_to new_payment_path
      end
    else
      flash[:alert] = 'No customer or bank account provided'
      redirect_to root_path
    end
  end

  def index
    if session[:customer]
      # Retrieve all of this customer's payments from Stripe
      @payments = Stripe::Charge.list(limit: 100, customer: session[:customer])
    else
      flash[:notice] = 'Please add a bank account to make an ACH payment.'
      redirect_to root_path
    end
  end

  def show
    
  end
end
