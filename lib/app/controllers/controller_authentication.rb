# This module is included in your application controller which makes
# several methods available to all controllers and views. Here's a
# common example you might add to your application layout file.
#
#   <% if logged_in? %>
#     Welcome <%= current_user.username %>.
#     <%= link_to "Edit profile", edit_current_user_path %> or
#     <%= link_to "Log out", logout_path %>
#   <% else %>
#     <%= link_to "Sign up", signup_path %> or
#     <%= link_to "log in", login_path %>.
#   <% end %>
#
# You can also restrict unregistered users from accessing a controller using
# a before filter. For example.
#
#   before_filter :login_required, :except => [:index, :show]
#   before_filter :admin_required
#
#to include
# class ApplicationController < ActionController::Base
#  include ControllerAuthentication
module ControllerAuthentication
  
  def self.included(controller)
    controller.send :helper_method, :current_user, :logged_in?, :redirect_to_target_or_default, :login_required, :admin_required
  end

  def current_user
    @current_user ||= User.find_by_auth_token!(cookies[:auth_token]) unless cookies[:auth_token].blank? 
  end

  def logged_in?
    current_user
  end

  def login_required
    unless logged_in?
      flash[:error] = "You must first log in or sign up before accessing this page."
      store_target_location
      redirect_to login_url
    end
  end  

  def admin_required
    unless current_user && current_user.admin?
      flash[:error] = "Sorry, you don't have access to that."
      redirect_to root_url and return false
    end
  end

  def redirect_to_target_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def store_target_location
    session[:return_to] = request.url
  end
end

