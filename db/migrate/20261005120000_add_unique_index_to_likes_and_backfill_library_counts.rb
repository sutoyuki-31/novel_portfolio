class AddUniqueIndexToLikesAndBackfillLibraryCounts < ActiveRecord::Migration[7.2]
  def up
    # 既存の重複いいねを1件に整理する(残さないとユニークインデックスの作成が失敗する)
    execute <<~SQL
      DELETE FROM likes
      WHERE id NOT IN (
        SELECT MIN(id) FROM likes GROUP BY user_id, novel_id
      )
    SQL

    # 同じユーザーが同じ小説に複数回いいねできないよう、DB側でも保証する
    add_index :likes, [ :user_id, :novel_id ], unique: true

    # total_views_count が更新されていなかった分を含め、集計値を実データから再計算する
    execute <<~SQL
      UPDATE libraries
      SET total_views_count = COALESCE(
            (SELECT SUM(novels.view_counts_count)
             FROM novels
             WHERE novels.library_id = libraries.id), 0),
          total_likes_count = (
            SELECT COUNT(*)
            FROM likes
            INNER JOIN novels ON novels.id = likes.novel_id
            WHERE novels.library_id = libraries.id)
    SQL
  end

  def down
    # 削除した重複データと再計算前の集計値は元に戻せないため、インデックスだけ外す
    remove_index :likes, [ :user_id, :novel_id ]
  end
end
