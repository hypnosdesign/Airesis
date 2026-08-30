import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["section", "status"]
  static values = { toolbarLabel: String }

  connect() {
    this.toolbars = new Set()
    this.initializeToolbar = this.initializeToolbar.bind(this)
    this.element.addEventListener("trix-initialize", this.initializeToolbar)
    requestAnimationFrame(() => {
      this.element.querySelectorAll("trix-editor").forEach((editor) => this.setupToolbar(editor))
    })
  }

  disconnect() {
    this.element.removeEventListener("trix-initialize", this.initializeToolbar)
    this.toolbars.forEach((toolbar) => {
      toolbar.removeEventListener("keydown", this.handleToolbarKeydown)
      toolbar.removeEventListener("focusin", this.handleToolbarFocus)
    })
  }

  expandAll() {
    this.sectionTargets.forEach((section) => { section.open = true })
    this.announce("All proposal sections are expanded.")
  }

  collapseAll() {
    this.sectionTargets.forEach((section) => { section.open = false })
    this.announce("All proposal sections are collapsed.")
  }

  initializeToolbar(event) {
    this.setupToolbar(event.target)
  }

  setupToolbar(editor) {
    const toolbar = editor.toolbarElement || document.getElementById(editor.getAttribute("toolbar"))
    if (!toolbar || this.toolbars.has(toolbar)) return

    const fieldLabel = this.editorLabel(editor)
    const labelTemplate = this.hasToolbarLabelValue ? this.toolbarLabelValue : "Formatting options for %{field}"
    toolbar.setAttribute("role", "toolbar")
    toolbar.setAttribute("aria-label", labelTemplate.replace("%{field}", fieldLabel))

    const row = toolbar.querySelector(".trix-button-row")
    if (row) {
      row.setAttribute("role", "presentation")
      row.setAttribute("tabindex", "-1")
    }

    const buttons = this.toolbarButtons(toolbar)
    buttons.forEach((button, index) => {
      button.tabIndex = index === 0 ? 0 : -1
      if (!button.getAttribute("aria-label") && button.title) button.setAttribute("aria-label", button.title)
    })

    toolbar.addEventListener("keydown", this.handleToolbarKeydown)
    toolbar.addEventListener("focusin", this.handleToolbarFocus)
    this.toolbars.add(toolbar)
  }

  handleToolbarKeydown = (event) => {
    const current = event.target.closest(".trix-button")
    if (!current) return

    const buttons = this.toolbarButtons(event.currentTarget).filter((button) => !button.disabled)
    const currentIndex = buttons.indexOf(current)
    if (currentIndex < 0) return

    let nextIndex
    if (["ArrowRight", "ArrowDown"].includes(event.key)) nextIndex = (currentIndex + 1) % buttons.length
    if (["ArrowLeft", "ArrowUp"].includes(event.key)) nextIndex = (currentIndex - 1 + buttons.length) % buttons.length
    if (event.key === "Home") nextIndex = 0
    if (event.key === "End") nextIndex = buttons.length - 1
    if (nextIndex === undefined) return

    event.preventDefault()
    this.activateButton(buttons, buttons[nextIndex])
  }

  handleToolbarFocus = (event) => {
    const button = event.target.closest(".trix-button")
    if (!button) return

    this.activateButton(this.toolbarButtons(event.currentTarget), button, false)
  }

  activateButton(buttons, activeButton, moveFocus = true) {
    buttons.forEach((button) => { button.tabIndex = button === activeButton ? 0 : -1 })
    if (moveFocus) {
      activeButton.focus({ preventScroll: true })
      activeButton.scrollIntoView({ block: "nearest", inline: "nearest" })
    }
  }

  toolbarButtons(toolbar) {
    return Array.from(toolbar.querySelectorAll(".trix-button-row .trix-button"))
  }

  editorLabel(editor) {
    const labelIds = editor.getAttribute("aria-labelledby")?.split(/\s+/) || []
    const label = labelIds.map((id) => document.getElementById(id)?.textContent?.trim()).filter(Boolean).join(" ")
    return label || editor.getAttribute("aria-label") || "editor"
  }

  announce(message) {
    if (this.hasStatusTarget) this.statusTarget.textContent = message
  }
}
