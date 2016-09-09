class Api::BaseController < ApplicationController

  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate_user!

  rescue_from Exception do |exception|
    status = :internal_server_error
    error_hash = { error: I18n.t("api.errors.server_error"), details: {} }

    case exception.class.name
    when "Mongoid::Errors::Validations"
      status = :unprocessable_entity
      error_hash[:error] = exception.try(:record).try(:errors).try(:full_messages).first || I18n.t("api.errors.data.invalid")
      error_hash[:details] = (exception.try(:record).try(:errors) || {})
    when "Mongoid::Errors::DocumentNotFound"
      status = :not_found
      error_hash[:error] = I18n.t("api.errors.data.not_found")
    when "ActionController::ParameterMissing", "ApiError"
      status = :unprocessable_entity
      error_hash[:error] = exception.message
    when "StateMachine::InvalidTransition"
      status = :unprocessable_entity
      error_hash[:error] = I18n.t("api.errors.data.invalid_transition", state_attr_name: exception.machine.name, current_state_name: exception.from_name.to_s, event_name: exception.event.to_s)
    end

    render status: status, json: error_hash, layout: false
  end

  protected

    def current_user
      @current_user
    end

    def find_user_by_token
      authenticate_with_http_token do |token, options|
        @current_user = User.find_by(api_token: token)
      end
      @current_user
    end

    def authenticate_user!
      find_user_by_token || render_unauthorized
    end

    def render_unauthorized(realm = "Application")
      self.headers["WWW-Authenticate"] = %(Token realm="#{realm.gsub(/"/, "")}")
      render json: { error: I18n.t("api.errors.bad_credentials") }, status: :unauthorized
    end

end
