class Api::BaseController < ApplicationController

  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate_user!

  rescue_from Exception do |exception|
    status = :internal_server_error
    error_hash = { error: I18n.t("api.errors.server_error"), details: {} }

    case exception.class.name
    when "ActiveRecord::RecordInvalid"
      status = :unprocessable_entity
      error_hash[:error] = exception.try(:record).try(:errors).try(:full_messages).first || I18n.t("api.errors.activerecord.invalid")
      error_hash[:details] = (exception.try(:record).try(:errors) || {})
    when "ActiveRecord::RecordNotFound"
      status = :not_found
      error_hash[:error] = I18n.t("api.errors.activerecord.not_found")
    when "ActionController::ParameterMissing", "ApiError"
      status = :unprocessable_entity
      error_hash[:error] = exception.message
    end

    render status: status, json: error_hash, layout: false
  end

  protected

    def current_user
      authenticate_token || render_unauthorized
    end

    def authenticate_token
      authenticate_with_http_token do |token, options|
        @current_user = User.find_by(api_token: token)
      end
    end

    def render_unauthorized(realm = "Application")
      self.headers["WWW-Authenticate"] = %(Token realm="#{realm.gsub(/"/, "")}")
      render json: { error: 'Bad credentials' }, status: :unauthorized
    end

end
