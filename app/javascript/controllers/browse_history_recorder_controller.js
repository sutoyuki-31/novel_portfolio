// app/javascript/controllers/browse_history_recorder_controller.js
import { Controller } from "@hotwired/stimulus"

// localStorage のキーと最大保存件数(レンダラー側と必ず同じキーにすること)
const STORAGE_KEY = "library_history"
const MAX_HISTORY_COUNT = 20

export default class extends Controller {
  static values = {
    libraryId: Number,
    novelId: Number,
    novelSubtitle: String
  }

  // 【修正1】connect() を削除しました。
  // Stimulus は Value の初期化時にも ○○ValueDidChange を呼ぶため、
  // connect() と併用すると初回表示で recordHistory() が2回走っていました。
  // Turbo で要素が差し替わる場合は要素ごと再接続され、初期化時に呼ばれるので
  // これだけで「初回表示」と「別の話への切り替え」の両方をカバーできます。
  // ※もし初回に記録されない場合は、ここに connect() { this.recordHistory() } を戻し、
  //   novelIdValueDidChange の方を削除してください(両方残すのは二重実行になります)。
  novelIdValueDidChange() {
    this.recordHistory()
  }

  recordHistory() {
    // Value が未設定(0 / NaN)の場合は何もしない
    if (!this.libraryIdValue || !this.novelIdValue) return

    const newItem = {
      libraryId: this.libraryIdValue,
      lastNovelId: this.novelIdValue,
      lastNovelSubtitle: this.novelSubtitleValue || "無題"
    }

    // 同じ作品(libraryId)の古い履歴を除外し、最新を先頭に追加する
    let history = this.readHistory()
    history = history.filter(item => Number(item.libraryId) !== this.libraryIdValue)
    history.unshift(newItem)

    // 【修正2】pop() ではなく slice() で上限に切り詰める
    // (上限を下げた場合や、すでに上限超過のデータがあっても安全)
    history = history.slice(0, MAX_HISTORY_COUNT)

    this.writeHistory(history)
  }

  // 【修正3】localStorage の読み書きを try/catch で保護
  // プライベートモード等で localStorage が使えない場合や、保存データが壊れていて
  // JSON.parse が例外を投げる場合でも、ページ全体の動作を止めないようにする
  readHistory() {
    try {
      const data = JSON.parse(localStorage.getItem(STORAGE_KEY))
      // 配列以外(null や壊れた形式)は空配列として扱う
      return Array.isArray(data) ? data : []
    } catch (e) {
      return []
    }
  }

  writeHistory(history) {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(history))
    } catch (e) {
      // 容量超過・保存不可の環境では、履歴を諦めて何もしない
    }
  }
}