import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "results"]

  static values = {
    delay: { type: Number, default: 250 }
  }

  connect() {
    this.requestSequence = 0
    this.lastQueuedQuery = this.currentQuery()
  }

  disconnect() {
    this.clearPendingSubmit()
    this.cancelPendingRequest()
  }

  queueSubmit(event) {
    if (event.target?.name !== "q") return

    const nextQuery = this.currentQuery()

    if (nextQuery !== this.lastQueuedQuery) {
      this.renderPendingResults()
      this.lastQueuedQuery = nextQuery
    }

    this.clearPendingSubmit()
    this.submitTimeout = window.setTimeout(() => {
      this.formTarget.requestSubmit()
    }, this.delayValue)
  }

  async submit(event) {
    if (event.target !== this.formTarget) return

    event.preventDefault()
    event.stopPropagation()

    const requestId = ++this.requestSequence
    const requestUrl = this.buildRequestUrl()
    const abortController = new AbortController()

    this.clearPendingSubmit()
    this.cancelPendingRequest()
    this.abortController = abortController
    this.resultsTarget.setAttribute("aria-busy", "true")

    try {
      const response = await fetch(requestUrl, {
        credentials: "same-origin",
        headers: { Accept: "text/html, application/xhtml+xml" },
        signal: abortController.signal
      })

      if (requestId !== this.requestSequence) return
      if (!response.ok) throw new Error(`Request failed with status ${response.status}`)

      const html = await response.text()
      if (requestId !== this.requestSequence) return

      const replacement = this.extractResults(html)
      this.resultsTarget.innerHTML = replacement.innerHTML
      this.resultsTarget.style.minHeight = ""
      this.lastQueuedQuery = this.currentQuery()

      if (!this.modalRequest()) {
        window.history.replaceState({}, "", requestUrl)
      }
    } catch (error) {
      if (error.name === "AbortError") return

      console.error("Failed to update move search results", error)
    } finally {
      if (this.abortController === abortController) {
        this.abortController = null
      }

      if (requestId === this.requestSequence) {
        this.resultsTarget.removeAttribute("aria-busy")
      }
    }
  }

  clearPendingSubmit() {
    if (!this.submitTimeout) return

    window.clearTimeout(this.submitTimeout)
    this.submitTimeout = null
  }

  cancelPendingRequest() {
    if (!this.abortController) return

    this.abortController.abort()
    this.abortController = null
  }

  buildRequestUrl() {
    const requestUrl = new URL(this.formTarget.action, window.location.origin)
    requestUrl.search = ""

    new FormData(this.formTarget).forEach((value, key) => {
      requestUrl.searchParams.append(key, value)
    })

    return requestUrl.toString()
  }

  extractResults(html) {
    const document = new DOMParser().parseFromString(html, "text/html")
    const replacement = document.querySelector('[data-move-search-target="results"]')

    if (!replacement) {
      throw new Error("Move search response missing results target")
    }

    return replacement
  }

  modalRequest() {
    return this.formTarget.querySelector('input[name="display"]')?.value === "modal"
  }

  currentQuery() {
    return this.formTarget.querySelector('input[name="q"]')?.value.toString() || ""
  }

  renderPendingResults() {
    this.resultsTarget.setAttribute("aria-busy", "true")
    this.resultsTarget.style.minHeight = ""
    this.resultsTarget.innerHTML = ""
  }
}