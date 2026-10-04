// app/javascript/controllers/browse_history_recorder_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    libraryId: Number,
    novelId: Number,
    novelSubtitle: String
  }

  // 💡 connect() での直接実行を廃止し、値の変更をトリガーにします
  connect() {
    // ページが初回読み込みされたとき、またはTurboでコンテンツが差し替わったときに実行
    this.recordHistory()
  }

  // 🆕 novelIdValue が変化した（別の話に切り替わった）ときにも自動実行
  novelIdValueDidChange() {
    this.recordHistory()
  }

  recordHistory() {
    // 1. 各Valueが正しく取得できているか確認（0やundefined、null、NaNを安全にスキップ）
    if (!this.libraryIdValue || !this.novelIdValue) return

    // 2. LocalStorageから現在の履歴（配列）を取得
    const history = JSON.parse(localStorage.getItem("library_history")) || []

    // 3. 組み立てる新規しおりデータ
    const newHistoryItem = {
      libraryId: this.libraryIdValue,
      lastNovelId: this.novelIdValue,
      lastNovelSubtitle: this.novelSubtitleValue || "無題"
    }

    // 4. 重複チェック：すでに同じ「作品(libraryId)」の履歴があるか探す
    const existingIndex = history.findIndex(item => Number(item.libraryId) === Number(this.libraryIdValue))

    if (existingIndex !== -1) {
      // 既存の履歴がある場合：一旦配列から削除（最新の閲覧順として先頭にするため）
      history.splice(existingIndex, 1)
    }

    // 5. 配列の「先頭」に最新の閲覧履歴を追加
    history.unshift(newHistoryItem)

    // 6. 最大件数を制限（例：最大20件）
    const MAX_HISTORY_COUNT = 20
    if (history.length > MAX_HISTORY_COUNT) {
      history.pop() // 一番古い履歴を削除
    }

    // 7. LocalStorageに保存
    localStorage.setItem("library_history", JSON.stringify(history))
    console.log("🔖 しおりを記録しました:", newHistoryItem)
  }
}
