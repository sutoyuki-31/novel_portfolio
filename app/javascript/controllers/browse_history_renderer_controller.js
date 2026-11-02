// app/javascript/controllers/browse_history_renderer_controller.js
import { Controller } from "@hotwired/stimulus"

// 記録側(browse_history_recorder_controller.js)と同じキーを使うこと
const STORAGE_KEY = "library_history"

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
    // 【修正1】レイアウト適用は分岐ごとに呼ばず、ここで1回だけ行う
    this.applySafeLayout()

    const history = this.readHistory()

    if (history.length === 0) {
      this.listTarget.innerHTML = "<p>閲覧履歴はありません。</p>"
      return
    }

    const params = new URLSearchParams()
    history.forEach(item => params.append("ids[]", item.libraryId))

    // 前回のリクエストが残っていれば中断してから新しく開始
    this.cancelActiveRequest()
    this.abortController = new AbortController()

    try {
      const response = await fetch(`/libraries/history.json?${params.toString()}`, {
        signal: this.abortController.signal
      })

      if (!response.ok) throw new Error("ネットワークエラー")

      const libraries = await response.json()

      // 【修正2】並び替えは history(すでに新しい順)を基準にする
      // ID → 作品 の Map を作り、history の順に引くことで sort/indexOf が不要になる
      const libraryById = new Map(libraries.map(lib => [Number(lib.id), lib]))

      const fragment = document.createDocumentFragment()
      history.forEach(localInfo => {
        const lib = libraryById.get(Number(localInfo.libraryId))
        // DB に存在しない(削除された)作品はスキップ
        if (lib) fragment.appendChild(this.createHistoryItemElement(lib, localInfo))
      })

      // 【修正3】DB から消えた作品の履歴を localStorage から掃除する
      // (放置すると、存在しない ID を毎回リクエストし続けてしまう)
      this.pruneMissingHistory(history, libraryById)

      this.listTarget.innerHTML = ""
      if (fragment.childNodes.length === 0) {
        this.listTarget.innerHTML = "<p>該当する履歴データが見つかりませんでした。</p>"
      } else {
        this.listTarget.appendChild(fragment)
      }
    } catch (error) {
      // clear() や disconnect() による中断は正常動作なので何も表示しない
      if (error.name === "AbortError") return

      console.error("履歴の取得に失敗しました:", error)
      this.listTarget.innerHTML = "<p>履歴の読み込みに失敗しました。</p>"
    }
  }

  // 【修正4】固定ヘッダーに潜り込まないためのレイアウト調整
  // - style.cssText への代入は既存のインラインスタイルを全部消してしまうため、
  //   setProperty で必要なプロパティだけを上書きする
  // - 根本的には、固定ヘッダー分の余白は CSS 側(main / body の padding-top や
  //   .browse-history-list の定義)で解決するのが望ましい。
  //   CSS で対応できたら、この margin-top の行は削除してください。
  //   ヘッダーの高さが変わったりスマホ幅になったりすると、固定値の 140px はズレやすいです。
  applySafeLayout() {
    this.listTarget.className = "browse-history-list"
    const style = this.listTarget.style
    style.setProperty("display", "block", "important")
    style.setProperty("position", "relative", "important")
    style.setProperty("margin-top", "140px", "important") // 足りなければ数値を調整
    style.setProperty("padding", "1rem", "important")
    style.setProperty("clear", "both", "important")
  }

  createHistoryItemElement(lib, localInfo) {
    const itemDiv = document.createElement("div")
    itemDiv.className = "history-item"

    // 作品タイトル
    // textContent で組み立てているため、タイトルに HTML が含まれていても XSS にならない
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
    // 【修正5】第一話がない場合の行き先を、タイトルリンクと同じ一覧ページに統一
    // (以前は /libraries/:id で行き先がバラバラだった。意図的に分けていたなら戻してください)
       // 第一話リンク
    // 【修正7】URLの :id は NovelsController#set_novel が page_number で探すため、
    // 主キー(first_novel_id)ではなく第一話の page_number(first_page_number)を使う
    // (Library#first_page_number を history アクションの methods で返している前提)
    const firstEpisodeLink = document.createElement("a")
    const firstPage = lib.first_page_number
    firstEpisodeLink.href = firstPage
      ? `/libraries/${lib.id}/novels/${firstPage}`
      : `/libraries/${lib.id}/novels`
    firstEpisodeLink.textContent = "▶ 第一話から読む"
    firstEpisodeLink.className = "link-first-episode"
    navP.appendChild(firstEpisodeLink)

    // 続きから読む(しおり)リンク
    if (localInfo && localInfo.lastNovelId) {
      const separator = document.createElement("span")
      separator.className = "link-separator"
      separator.textContent = "｜"
      navP.appendChild(separator)

      const bookmarkLink = document.createElement("a")
      bookmarkLink.href = `/libraries/${lib.id}/novels/${localInfo.lastNovelId}`
      bookmarkLink.textContent = `🔖 続きから読む (${localInfo.lastNovelSubtitle || "タイトルなし"})`
      bookmarkLink.className = "link-bookmark"
      navP.appendChild(bookmarkLink)
    }

    itemDiv.appendChild(navP)

    // 作品のあらすじ
    const synopsisP = document.createElement("p")
    synopsisP.className = "history-synopsis"
    synopsisP.textContent = lib.synopsis || "あらすじはありません。"
    itemDiv.appendChild(synopsisP)

    return itemDiv
  }

  // 履歴を全消去(ボタンの data-action から呼ばれる)
  clear(event) {
    event.preventDefault()
    this.cancelActiveRequest()

    try {
      localStorage.removeItem(STORAGE_KEY)
    } catch (e) {
      // localStorage が使えない環境では何もしない
    }

    this.applySafeLayout()
    this.listTarget.innerHTML = "<p>閲覧履歴はありません。</p>"
  }

  cancelActiveRequest() {
    if (this.abortController) {
      this.abortController.abort()
      this.abortController = null
    }
  }

  // 【修正6】localStorage の読み込みを try/catch で保護
  // データが壊れていても例外で画面が真っ白にならず、空の履歴として扱う
  readHistory() {
    try {
      const data = JSON.parse(localStorage.getItem(STORAGE_KEY))
      return Array.isArray(data) ? data : []
    } catch (e) {
      return []
    }
  }

  // サーバーに存在しなかった作品を履歴から取り除く
  pruneMissingHistory(history, libraryById) {
    const pruned = history.filter(item => libraryById.has(Number(item.libraryId)))
    if (pruned.length === history.length) return // 変更がなければ書き込まない

    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(pruned))
    } catch (e) {
      // 保存できなくても表示には影響しないので無視
    }
  }
}