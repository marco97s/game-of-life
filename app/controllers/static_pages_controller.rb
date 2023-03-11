class StaticPagesController < ApplicationController
  before_action :redirect_if_authenticated

  def home
  end
end
