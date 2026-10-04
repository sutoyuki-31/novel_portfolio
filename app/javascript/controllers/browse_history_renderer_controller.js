// app/javascript/controllers/browse_history_renderer_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list"]

  connect() {
    this.abortController = null
    this.loadViewingHistory()
  }

  disconnect() {
    this.cancelActiveRequest()
  }

  async loadViewingHistory() {
    const history = JSON.parse(localStorage.getItem("library_history")) || []

    if (history.length === 0) {
      this.applySafeLayout() // 💡 ヘッダー潜り込み防止を適用
      this.listTarget.innerHTML = "<p>閲覧履歴はありません。</p>"
      return
    }

    const libraryIds = history.map(item => item.libraryId)
    const params = new URLSearchParams()
    libraryIds.forEach(id => params.append('ids[]', id))

    this.cancelActiveRequest()
    this.abortController = new AbortController()

    try {
      const response = await fetch(`/libraries/history.json?${params.toString()}`, { 
        signal: this.abortController.signal 
      })
      
      if (!response.ok) throw new Error("ネットワークエラー")
      
      const libraries = await response.json()

      if (!libraries || libraries.length === 0) {
        this.applySafeLayout() // 💡 ヘッダー潜り込み防止を適用
        this.listTarget.innerHTML = "<p>該当する履歴データが見つかりませんでした。</p>"
        return
      }

      // localStorage の元の並び順に合わせてソート
      const sortedLibraries = libraries.sort((a, b) => {
        return libraryIds.indexOf(Number(a.id)) - libraryIds.indexOf(Number(b.id))
      })

      const fragment = document.createDocumentFragment()

      sortedLibraries.forEach(lib => {
        const localInfo = history.find(item => Number(item.libraryId) === Number(lib.id))
        const itemDiv = this.createHistoryItemElement(lib, localInfo)
        fragment.appendChild(itemDiv)
      })

      this.applySafeLayout() // 💡 ヘッダー潜り込み防止を適用
      this.listTarget.innerHTML = ""
      this.listTarget.appendChild(fragment)

    } catch (error) {
      if (error.name === 'AbortError') return
      
      console.error("履歴の取得に失敗しました:", error)
      this.applySafeLayout()
      this.listTarget.innerHTML = "<p>履歴の読み込みに失敗しました。</p>"
    }
  }

  // 💡 固定ヘッダーに潜り込まない独立したレイアウト空間を強制的に作成するメソッド
  applySafeLayout() {
    this.listTarget.className = "browse-history-list"
    
    // インラインスタイルを使い、親要素のいかなる制限（Flexbox等）も上書きして下に押し下げます
    // もしこれでも足りない場合は '140px' などの数値を増やしてください
    this.listTarget.style.cssText = `
      display: block !important;
      position: relative !important;
      margin-top: 140px !important;
      padding: 1rem !important;
      clear: both !important;
    `
  }

  createHistoryItemElement(lib, localInfo) {
    const itemDiv = document.createElement("div")
    itemDiv.className = "history-item"

    // 作品タイトル
    const h3 = document.createElement("h3")
    const titleLink = document.createElement("a")
    titleLink.href = `/libraries/${lib.id}/novels`
    titleLink.textContent = lib.title
    h3.appendChild(titleLink)
    itemDiv.appendChild(h3)

    // ナビゲーションリンク
    const navP = document.createElement("p")
    navP.className = "history-nav-links"
    
    // 第一話リンク
    const firstEpisodeLink = document.createElement("a")
    const firstNovelId = lib.first_novel_id || lib.firstNovelId 
    firstEpisodeLink.href = firstNovelId ? `/libraries/${lib.id}/novels/${firstNovelId}` : `/libraries/${lib.id}`
    firstEpisodeLink.textContent = "▶ 第一話から読む"
    firstEpisodeLink.className = "link-first-episode"
    navP.appendChild(firstEpisodeLink)

    // 続きから読む（しおり）リンク
    if (localInfo && localInfo.lastNovelId) {
      const separator = document.createElement("span")
      separator.className = "link-separator"
      separator.textContent = "｜"
      navP.appendChild(separator)

      const bookmarkLink = document.createElement("a")
      bookmarkLink.href = `/libraries/${lib.id}/novels/${localInfo.lastNovelId}`
      bookmarkLink.textContent = `🔖 続きから読む (${localInfo.lastNovelSubtitle || 'タイトルなし'})`
      bookmarkLink.className = "link-bookmark"
      navP.appendChild(bookmarkLink)
    }
    
    itemDiv.appendChild(navP)

    // 作品のあらすじ
    const synopsisP = document.createElement("p")
    synopsisP.className = "history-synopsis"
    synopsisP.textContent = lib.synopsis || 'あらすじはありません。'
    itemDiv.appendChild(synopsisP)

    return itemDiv
  }

  clear(event) {
    event.preventDefault()
    this.cancelActiveRequest()
    
    localStorage.removeItem("library_history")
    this.applySafeLayout()
    this.listTarget.innerHTML = "<p>閲覧履歴はありません。</p>"
  }

  cancelActiveRequest() {
    if (this.abortController) {
      this.abortController.abort()
      this.abortController = null
    }
  }
}
