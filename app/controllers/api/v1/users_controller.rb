class Api::V1::UsersController < ::Api::BaseController

  skip_before_action :authenticate_user!, only: :create

  def create
    @user = User.create!
    render_json_with(@user, status: :created)
  end

end
