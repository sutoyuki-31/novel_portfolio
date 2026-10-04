class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_novel

  def create
    # すでにお気に入り登録されている場合は作成しないように安全性を考慮
    @like = current_user.likes.new(novel: @novel)

    if @like.save
      redirect_to library_novel_path(@library, @novel), notice: "お気に入りに登録しました"
    else
      redirect_to library_novel_path(@library, @novel), alert: "お気に入りの登録に失敗しました"
    end
  end

  def destroy
    # current_user の持つ likes から、該当する小説のものを直接探して削除
    like = current_user.likes.find_by!(novel_id: @novel.id)
    like.destroy

    redirect_to library_novel_path(@library, @novel), notice: "お気に入りを解除しました"
  rescue ActiveRecord::RecordNotFound
    # すでに解除されていた場合などのエラーハンドリング
    redirect_to library_novel_path(@library, @novel), alert: "お気に入りの解除に失敗しました"
  end

  private

  def set_novel
    # ActiveRecord の `find` は見つからない場合に自動で 404 エラー（RecordNotFound）を出してくれます
    @library = Library.find(params[:library_id])
    @novel = @library.novels.find(params[:novel_id])
  end
end
