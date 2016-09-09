module ApiHelper
  include Rack::Test::Methods

  def app
    Rails.application
  end

  def create_authenticated_user
    @user = create(:user)
    @auth_params = { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Token.encode_credentials(@user.api_token) }
  end
end
