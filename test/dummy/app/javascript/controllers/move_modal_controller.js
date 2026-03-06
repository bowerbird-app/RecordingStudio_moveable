import { Controller } from "@hotwired/stimulus"
import { application } from "controllers/application"

export default class extends Controller {
  static targets = ["body", "modal"]

  connect() {
    this.requestSequence = 0
  }

  async open(event) {
    event.preventDefault()

    const url = event.currentTarget.href
    if (!url) return

    const requestId = ++this.requestSequence
    this.renderLoading("Loading move options...")
    this.modalController?.open()

    await this.load(url, { requestId })
  }

  async submit(event) {
    if (!this.hasBodyTarget || !this.bodyTarget.contains(event.target)) return

    event.preventDefault()

    const form = event.target
    const method = (form.method || "get").toUpperCase()
    const formData = new FormData(form)
    const requestId = ++this.requestSequence

    this.renderLoading(method === "GET" ? "Updating destinations..." : "Moving item...")

    await this.load(form.action, {
      formData,
      method,
      requestId
    })
  }

  async load(url, { formData = null, method = "GET", requestId }) {
    try {
      const response = await fetch(this.requestUrl(url, method, formData), {
        method,
        body: method === "GET" ? null : formData,
        credentials: "same-origin",
        headers: this.headersFor(method)
      })

      if (requestId !== this.requestSequence) return

      if (response.redirected) {
        window.location.assign(response.url)
        return
      }

      const html = await response.text()

      if (!response.ok) {
        throw new Error(`Request failed with status ${response.status}`)
      }

      if (requestId !== this.requestSequence) return

      this.bodyTarget.innerHTML = html
    } catch (error) {
      if (requestId !== this.requestSequence) return

      this.renderError(error)
    }
  }

  renderLoading(message) {
    this.bodyTarget.innerHTML = `
      <div class="flex min-h-48 items-center justify-center rounded-2xl border border-dashed border-[var(--surface-border-color)] bg-[var(--surface-muted-background-color)] px-6 py-10 text-center">
        <p class="text-sm font-medium text-[var(--surface-muted-content-color)]">${message}</p>
      </div>
    `
  }

  renderError(error) {
    console.error("Failed to load move modal content", error)

    this.bodyTarget.innerHTML = `
      <div class="rounded-2xl border border-red-500/20 bg-red-500/10 px-5 py-4 text-sm text-red-700">
        Unable to load the move view right now. Please try again.
      </div>
    `
  }

  requestUrl(url, method, formData) {
    if (method !== "GET" || !formData) return url

    const requestUrl = new URL(url, window.location.origin)
    requestUrl.search = ""

    formData.forEach((value, key) => {
      requestUrl.searchParams.append(key, value)
    })

    return requestUrl.toString()
  }

  headersFor(method) {
    const headers = {
      Accept: "text/html, application/xhtml+xml"
    }

    if (method !== "GET") {
      const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

      if (csrfToken) {
        headers["X-CSRF-Token"] = csrfToken
      }
    }

    return headers
  }

  get modalController() {
    if (!this.hasModalTarget) return null

    return application.getControllerForElementAndIdentifier(this.modalTarget, "flat-pack--modal")
  }
}