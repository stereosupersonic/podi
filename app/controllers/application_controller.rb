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

  helper_method :current_setting, :markdown_processor

  def current_setting
    @current_setting ||= Setting.current
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
