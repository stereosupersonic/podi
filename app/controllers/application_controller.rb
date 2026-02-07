class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  rescue_from ActiveRecord::RecordNotFound, ActionController::RoutingError, with: :render404

  before_action :record_newrelic_custom_parameters

  def render404
    respond_to do |format|
      format.html { render file: Rails.root.join("public/404.html"), layout: false, status: :not_found }
      format.xml { head :not_found }
      format.any { head :not_found }
    end
  end

  helper_method :current_setting, :markdown_processor, :current_user, :user_signed_in?

  def current_setting
    @current_setting ||= Setting.current
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def user_signed_in?
    current_user.present?
  end

  def authenticate_user!
    redirect_to login_path, alert: "Please sign in to continue" unless user_signed_in?
  end

  protected

  def authorize_admin
    redirect_to "/", alert: "Access Denied" unless current_user&.admin?
  end

  def record_newrelic_custom_parameters
    custom_parameters = {
      request_uuid: request.uuid,
      params: request.filtered_parameters
    }
    ::NewRelic::Agent.add_custom_attributes(custom_parameters)
  end

  def markdown_processor
    @markdown_processor ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
  end
end
