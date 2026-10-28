// Theme toggle with localStorage
(function() {
  const html = document.documentElement;
  const toggleBtn = document.getElementById('themeToggle');
  const saved = localStorage.getItem('theme');
  if (saved) html.setAttribute('data-bs-theme', saved);
  if (toggleBtn) {
    toggleBtn.addEventListener('click', () => {
      const current = html.getAttribute('data-bs-theme') || 'light';
      const next = current === 'light' ? 'dark' : 'light';
      html.setAttribute('data-bs-theme', next);
      localStorage.setItem('theme', next);
    });
  }
  // Active nav link based on body[data-page]
  const page = document.body.getAttribute('data-page');
  if (page) {
    const id = 'nav-' + page;
    const link = document.getElementById(id);
    if (link) link.classList.add('active');
  }
  // Footer year
  const yearEl = document.getElementById('year');
  if (yearEl) yearEl.textContent = new Date().getFullYear();

  // Gallery modal handler
  const modal = document.getElementById('imgModal');
  if (modal) {
    modal.addEventListener('show.bs.modal', function (event) {
      const img = event.relatedTarget;
      const src = img.getAttribute('src');
      const cap = img.getAttribute('data-caption') || '';
      modal.querySelector('#modalImg').setAttribute('src', src);
      modal.querySelector('#modalCaption').textContent = cap;
    });
  }

  // Publications filter
  const filterSel = document.getElementById('pubFilter');
  if (filterSel) {
    filterSel.addEventListener('change', function() {
      const val = this.value;
      document.querySelectorAll('.pub-item').forEach(li => {
        li.style.display = (val === 'all' || li.getAttribute('data-year') === val) ? '' : 'none';
      });
    });
  }
})(); 
