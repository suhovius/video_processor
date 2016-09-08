class Api::V1::UsersController < Api::BaseController

  def create
    @user = User.create
  end

end
