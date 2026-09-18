(() => {
  "use strict";

  const themeButton = document.getElementById("themeButton");
  const savedTheme = localStorage.getItem("docs-theme");
  const prefersDark = window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches;
  if (savedTheme === "dark" || (!savedTheme && prefersDark)) document.documentElement.dataset.theme = "dark";

  themeButton?.addEventListener("click", () => {
    const next = document.documentElement.dataset.theme === "dark" ? "light" : "dark";
    document.documentElement.dataset.theme = next;
    localStorage.setItem("docs-theme", next);
  });

  const form = document.querySelector("[data-search-form]");
  const input = document.querySelector("#site-search");
  const cards = [...document.querySelectorAll("[data-search-card]")];
  const categories = [...document.querySelectorAll("[data-category]")];
  const empty = document.querySelector("[data-search-empty]");
  if (!form || !input || cards.length === 0) return;

  const params = new URLSearchParams(window.location.search);
  input.value = params.get("q") || "";
  const filter = () => {
    const query = input.value.trim().toLowerCase();
    let visible = 0;
    cards.forEach(card => {
      const matches = !query || card.textContent.toLowerCase().includes(query);
      card.hidden = !matches;
      if (matches) visible += 1;
    });
    categories.forEach(category => {
      const links = [...category.querySelectorAll("[data-search-card]")];
      category.hidden = Boolean(query) && links.every(link => link.hidden);
    });
    if (empty) empty.hidden = visible !== 0;
  };

  input.addEventListener("input", filter);
  form.addEventListener("submit", event => event.preventDefault());
  filter();
})();
