import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["title", "body", "tags", "collaborators"];

  connect() {
    this.initialValues = {
      title: this.titleTarget.value,
      body: this.bodyTarget.value,
      tags: this.tagsTarget.value,
      collaborators: this.collaboratorsSnapshot(),
    };

    this.beforeUnloadHandler = this.onBeforeUnload.bind(this);
    this.turboBeforeVisitHandler = this.onTurboBeforeVisit.bind(this);
    this.submitHandler = this.onSubmit.bind(this);

    window.addEventListener("beforeunload", this.beforeUnloadHandler);
    document.addEventListener(
      "turbo:before-visit",
      this.turboBeforeVisitHandler,
    );
    this.element.addEventListener("submit", this.submitHandler);
  }

  disconnect() {
    window.removeEventListener("beforeunload", this.beforeUnloadHandler);
    document.removeEventListener(
      "turbo:before-visit",
      this.turboBeforeVisitHandler,
    );
    this.element.removeEventListener("submit", this.submitHandler);
  }

  onSubmit() {
    this.initialValues = {
      title: this.titleTarget.value,
      body: this.bodyTarget.value,
      tags: this.tagsTarget.value,
      collaborators: this.collaboratorsSnapshot(),
    };
  }

  collaboratorsSnapshot() {
    if (!this.hasCollaboratorsTarget) return "";

    const values = Array.from(
      this.collaboratorsTarget.querySelectorAll('input[name="paste[collaborators][]"]'),
    )
      .map((input) => input.value)
      .sort();

    return values.join(",");
  }

  onBeforeUnload(event) {
    if (this.isDirty()) {
      event.preventDefault();
    }
  }

  onTurboBeforeVisit(event) {
    if (
      this.isDirty() &&
      !confirm(
        "You have unsaved changes. Are you sure you want to leave this page?",
      )
    ) {
      event.preventDefault();
    }
  }

  isDirty() {
    return (
      this.titleTarget.value !== this.initialValues.title ||
      this.bodyTarget.value !== this.initialValues.body ||
      this.tagsTarget.value !== this.initialValues.tags ||
      this.collaboratorsSnapshot() !== this.initialValues.collaborators
    );
  }
}
