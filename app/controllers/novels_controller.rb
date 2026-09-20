class NovelsController < ApplicationController
before_action :authenticate_user!

def index
@novels = Novel.all
end

def piece
@novel = Novel.new
end

def myhome
  @user = User.all
end

def new
@novel = Novel.new
end

def writing
@novels = Novel.all
@novel = Novel.new
end

def create
  @novel = current_user.novels.build(novel_params)
  if @novel.save
      redirect_to writing_novels_path
  # redirect_to writing_path
  else
    # @novel = current_user.novels
    render :new, status: :unprocessable_entity
  end
end

  private

  def novel_params
    params.require(:novel).permit(:title, :synopsis, :novel_number)
  end
end
