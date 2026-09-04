import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "list", "hiddenContainer", "itemTemplate"];
  static values = {
    users: Array,
    selectedIds: Array,
  };

  connect() {
    this.usersByUsername = new Map();
    this.usersById = new Map();

    (this.usersValue || []).forEach((user) => {
      const usernameKey = String(user.username || "").toLowerCase();
      if (usernameKey.length === 0) return;

      this.usersByUsername.set(usernameKey, user);
      this.usersById.set(String(user.id), user);
    });

    this.selectedIds = new Set(
      (this.selectedIdsValue || []).map((id) => String(id)),
    );
    this.render();
  }

  addFromInput(event) {
    event.preventDefault();

    const username = this.inputTarget.value.trim().toLowerCase();
    if (username.length === 0) return;

    const user = this.usersByUsername.get(username);
    if (!user) return;

    this.selectedIds.add(String(user.id));
    this.inputTarget.value = "";
    this.render();
  }

  remove(event) {
    const id = event.currentTarget.dataset.collaboratorId;
    if (!id) return;

    this.selectedIds.delete(String(id));
    this.render();
  }

  render() {
    this.hiddenContainerTarget.innerHTML = "";
    this.listTarget.innerHTML = "";

    Array.from(this.selectedIds)
      .sort((a, b) => Number(a) - Number(b))
      .forEach((id) => {
        const user = this.usersById.get(String(id));
        if (!user) return;

        const hiddenInput = document.createElement("input");
        hiddenInput.type = "hidden";
        hiddenInput.name = "paste[collaborators][]";
        hiddenInput.value = String(user.id);
        this.hiddenContainerTarget.appendChild(hiddenInput);

        const fragment = this.itemTemplateTarget.content.cloneNode(true);
        const item = fragment.querySelector("li");
        const avatarSlot = fragment.querySelector('[data-role="avatar"]');
        const usernameSlot = fragment.querySelector('[data-role="username"]');
        const removeButton = fragment.querySelector('[data-role="remove"]');

        usernameSlot.textContent = user.username;
        removeButton.dataset.collaboratorId = String(user.id);
        removeButton.addEventListener("click", (e) => this.remove(e));

        if (user.avatar_url) {
          const image = document.createElement("img");
          image.src = user.avatar_url;
          image.alt = "";
          image.className = "h-6 w-6 object-cover";
          avatarSlot.appendChild(image);
        } else {
          avatarSlot.textContent =
            user.initial || user.username.slice(0, 1).toUpperCase();
        }

        this.listTarget.appendChild(item);
      });
  }
}
