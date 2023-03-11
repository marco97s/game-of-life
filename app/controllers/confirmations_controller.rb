class ConfirmationsController < ApplicationController
  before_action :redirect_if_authenticated, only: [:create, :new]
  def create
    @user = User.find_by(email: params[:user][:email].downcase)

    if @user.present? && @user.unconfirmed_or_reconfirming?
      confirmation_token = @user.send_confirmation_email!
      if Rails.env.development?
        redirect_to root_path, notice: "[DEVELOPMENT ENV ONLY] Please follow this link to confirm your account http://loclhost:3000/confirmations/%s/edit [DEVELOPMENT ENV ONLY]" % confirmation_token
        return
      end
      redirect_to root_path, notice: "Check your email for confirmation instructions."
    elsif @user.save
      @user.send_confirmation_email!
    else
      redirect_to new_confirmation_path, alert: "We could not find a user with that email or that email has already been confirmed."
    end
  end

  def edit
    @user = User.find_signed(params[:confirmation_token], purpose: :confirm_email)

    if @user.present?
      if @user.confirm!
        login @user
        redirect_to root_path, notice: "Your account has been confirmed."
      else
        redirect_to new_confirmation_path, alert: "Something went wrong."
      end
    else
      redirect_to new_confirmation_path, alert: "Invalid token."
    end
  end

  def new
    @user = User.new
  end
end
