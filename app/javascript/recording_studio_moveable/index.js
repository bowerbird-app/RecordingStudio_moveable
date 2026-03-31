const TRIGGER_SELECTOR = "a[data-recording-studio-moveable-modal='true']"
const ROOT_SELECTOR = "[data-recording-studio-moveable-modal-root='true']"
const BODY_SELECTOR = "[data-recording-studio-moveable-modal-body='true']"
const MODAL_SELECTOR = "[data-recording-studio-moveable-modal-element='true']"

class MoveModalLauncher {
  constructor() {
    this.requestSequence = 0
    this.observer = null
  }

  start() {
    document.addEventListener("click", this.handleClick)
    document.addEventListener("submit", this.handleSubmit)
  }

  handleClick = async (event) => {
    const trigger = event.target.closest(TRIGGER_SELECTOR)
    if (!trigger || !this.shouldHandleClick(event, trigger)) return

    event.preventDefault()

    try {
      await this.open(trigger.href)
    } catch (error) {
      console.error("Failed to open move modal", error)
      window.location.assign(trigger.href)
    }
  }

  handleSubmit = async (event) => {
    const form = event.target
    if (!(form instanceof HTMLFormElement) || !form.closest(ROOT_SELECTOR)) return

    event.preventDefault()

    const method = (form.method || "get").toUpperCase()
    const formData = new FormData(form)
    const requestId = ++this.requestSequence

    this.renderLoading(method === "GET" ? "Updating destinations..." : "Moving item...")

    await this.load(form.action, {
      method,
      formData,
      requestId
    })
  }

  async open(url) {
    const requestId = ++this.requestSequence
    const response = await fetch(this.modalUrl(url).toString(), {
      credentials: "same-origin",
      headers: { Accept: "text/html, application/xhtml+xml" }
    })

    if (!response.ok) {
      throw new Error(`Request failed with status ${response.status}`)
    }

    if (requestId !== this.requestSequence) return

    this.replaceRoot(await response.text())

    const controller = await this.waitForModalController()
    controller?.open()
  }

  async load(url, { method = "GET", formData = null, requestId }) {
    try {
      const response = await fetch(this.requestUrl(url, method, formData), {
        method,
        body: method === "GET" ? null : formData,
        credentials: "same-origin",
        headers: this.headersFor(method)
      })

      if (requestId !== this.requestSequence) return

      if (response.redirected) {
        this.removeRoot()
        window.location.assign(response.url)
        return
      }

      const html = await response.text()

      if (!response.ok) {
        throw new Error(`Request failed with status ${response.status}`)
      }

      if (requestId !== this.requestSequence) return

      this.bodyElement().innerHTML = html
    } catch (error) {
      if (requestId !== this.requestSequence) return

      this.renderError(error)
    }
  }

  replaceRoot(html) {
    this.removeRoot()

    const fragment = document.createRange().createContextualFragment(html)
    const root = fragment.querySelector(ROOT_SELECTOR)

    if (!root) {
      throw new Error("Move modal root not found in response")
    }

    document.body.appendChild(root)
    this.observeModal(root)
  }

  observeModal(root) {
    this.observer?.disconnect()

    const modal = root.querySelector(MODAL_SELECTOR)
    if (!modal) return

    this.observer = new MutationObserver(() => {
      if (modal.classList.contains("hidden") || modal.getAttribute("aria-hidden") == "true") {
        this.removeRoot()
      }
    })

    this.observer.observe(modal, {
      attributes: true,
      attributeFilter: ["class", "aria-hidden"]
    })
  }

  removeRoot() {
    this.observer?.disconnect()
    this.observer = null
    this.rootElement()?.remove()
  }

  renderLoading(message) {
    const body = this.bodyElement()
    if (!body) return

    body.innerHTML = `
      <div class="flex min-h-48 items-center justify-center rounded-2xl border border-dashed border-(--surface-border-color) bg-(--surface-muted-background-color) px-6 py-10 text-center">
        <p class="text-sm font-medium text-(--surface-muted-content-color)">${message}</p>
      </div>
    `
  }

  renderError(error) {
    console.error("Failed to load move modal content", error)

    const body = this.bodyElement()
    if (!body) return

    body.innerHTML = `
      <div class="rounded-2xl border border-red-500/20 bg-red-500/10 px-5 py-4 text-sm text-red-700">
        Unable to load the move view right now. Please try again.
      </div>
    `
  }

  modalUrl(url) {
    const modalUrl = new URL(url, window.location.origin)
    modalUrl.pathname = `${modalUrl.pathname.replace(/\/$/, "")}/modal`
    return modalUrl
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

  shouldHandleClick(event, trigger) {
    if (event.defaultPrevented) return false
    if (event.button !== 0) return false
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return false
    if (trigger.target && trigger.target !== "_self") return false
    if (trigger.hasAttribute("download")) return false

    return true
  }

  rootElement() {
    return document.querySelector(ROOT_SELECTOR)
  }

  bodyElement() {
    return this.rootElement()?.querySelector(BODY_SELECTOR)
  }

  modalController() {
    const modal = this.rootElement()?.querySelector(MODAL_SELECTOR)
    if (!modal || !window.Stimulus?.getControllerForElementAndIdentifier) return null

    return window.Stimulus.getControllerForElementAndIdentifier(modal, "flat-pack--modal")
  }

  async waitForModalController(maxFrames = 10) {
    for (let frame = 0; frame < maxFrames; frame += 1) {
      const controller = this.modalController()
      if (controller) return controller

      await new Promise((resolve) => window.requestAnimationFrame(resolve))
    }

    return null
  }
}

if (!window.__recordingStudioMoveableModalLauncher) {
  window.__recordingStudioMoveableModalLauncher = new MoveModalLauncher()
  window.__recordingStudioMoveableModalLauncher.start()
}