class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  rescue_from ActiveRecord::RecordNotFound, ActionController::RoutingError, with: :render404

  before_action :record_newrelic_custom_parameters

  def render404
    redirect_to "/404"
  end

  helper_method :current_setting, :markdown_processor

  def current_setting
    @current_setting ||= Setting.current
  end

  protected

  def authorize_admin
    redirect_to root_path, alert: "Access Denied" unless current_user&.admin?
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
