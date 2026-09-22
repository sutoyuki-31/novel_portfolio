class LibrariesController < ApplicationController
def writing
  @library = Library.new
end

def list
  @library = Library.all
end

def index
  @libraries = current_user.libraries
end

def novel
  #  @library = Library.find(params[:id])
  # @library = Library.all
  @library = Library.new
end

def create
  @library = current_user.libraries.build(library_params)
  if @library.save
      redirect_to libraries_path
  # redirect_to writing_path
  else
    # @novel = current_user.novels
    render :writing, status: :unprocessable_entity
  end
end

  private

  def library_params
    params.require(:library).permit(:title, :synopsis, :novel_id, :story, :subtitle)
  end
end
