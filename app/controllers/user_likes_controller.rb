class UserLikesController < ApplicationController
  before_action :authenticate_user!

  def create
    @user_like = UserLike.new(user_like_params)
    @user_like.user_id = current_user.id
    if @user_like.save
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def destroy
    @user_like = UserLike.find_by(likeable_id: params[:user_like][:likeable_id], likeable_type: params[:user_like][:likeable_type])
    @user_like.destroy
    head :ok
  end

  protected

  def user_like_params
    params.require(:user_like).permit(:likeable_id, :likeable_type)
  end
end
