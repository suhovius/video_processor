class Api::V1::UsersController < ::Api::BaseController

  skip_before_action :authenticate_user!, only: :create

  def create
    @user = User.create!
    render json: @user, status: :created, serializer: ::Api::V1::UserSerializer
  end

end
