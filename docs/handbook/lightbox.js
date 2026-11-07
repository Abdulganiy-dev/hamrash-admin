// Screens for the Hamrash handbook: thumbnails under each operation and on each
// feature page, and a lightbox to look at one in full.
//
// Content: H.screens (data.js) and the PNGs in docs/handbook/screens/. Adds
// window.HB.shots(ids, opts) for app.js to render thumbnails, and handles
// clicks on them. Esc closes the lightbox before anything else (the reference
// drawer and search) sees it.
(function () {
  const H = window.HANDBOOK;
  const { esc, md } = window.HB;
  const $lb = () => document.getElementById('lightbox');

  // Which operations show a screen, for the "Used by" list in the lightbox.
  let index = null;
  function opsFor(id) {
    if (!index) {
      index = {};
      H.features.forEach((f) =>
        f.ops.forEach((op) => (op.screens || []).forEach((sid) => (index[sid] = index[sid] || []).push({ f, op })))
      );
    }
    return index[id] || [];
  }

  function thumb(id, group) {
    const s = H.screens[id];
    if (!s) return '';
    return `<button class="shot" type="button" data-shot="${esc(id)}" data-group="${esc(group.join(','))}" aria-label="Open screen: ${esc(s.title)}">
      <span class="shot-frame"><img src="${esc(s.file)}" alt="${esc(s.title)}" loading="lazy" width="150" height="324">${
        s.outdated ? '<span class="shot-flag" title="This design no longer matches the app">Design differs</span>' : ''
      }</span><span class="shot-title">${esc(s.title)}</span></button>`;
  }
  // A row of thumbnails; the lightbox steps through the same list.
  function shots(ids) {
    const list = (ids || []).filter((i) => H.screens[i]);
    return list.length ? `<div class="shots">${list.map((i) => thumb(i, list)).join('')}</div>` : '';
  }

  let state = null; // { group: [...ids], i }
  let opener = null;

  function paint() {
    const id = state.group[state.i];
    const s = H.screens[id];
    const used = opsFor(id);
    const many = state.group.length > 1;
    $lb().innerHTML = `
      <div class="lb-panel" role="dialog" aria-modal="true" aria-label="${esc(s.title)}">
        <div class="lb-img"><img src="${esc(s.file)}" alt="${esc(s.title)}"></div>
        <div class="lb-side">
          <div class="lb-top">
            <span class="lb-count">${many ? `${state.i + 1} of ${state.group.length}` : ''}</span>
            <span class="grow"></span>
            ${many ? '<button class="icon-btn" data-lb="prev" aria-label="Previous screen">←</button><button class="icon-btn" data-lb="next" aria-label="Next screen">→</button>' : ''}
            <button class="icon-btn" data-lb="close" aria-label="Close"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg></button>
          </div>
          <h2 class="lb-title">${esc(s.title)}</h2>
          <p class="lb-caption">${md(s.caption || '')}</p>
          ${s.outdated ? `<div class="callout"><b>This design is out of date.</b> ${esc(s.outdated)}</div>` : ''}
          ${used.length ? `<div class="dr-label" style="margin-top:6px">Shown in</div><div class="dr-box">${used
            .map(({ f, op }) => `<a class="dr-row" style="text-decoration:none;color:inherit" href="#/f/${f.id}?at=${op.id}" data-lb="close"><span class="kind ${op.kind}">${esc(({ create: 'Create', read: 'Read', update: 'Update', delete: 'Delete' })[op.kind])}</span><span class="grow"><b style="color:var(--ink)">${esc(op.title)}</b></span></a>`)
            .join('')}</div>` : ''}
        </div>
      </div>`;
  }

  function open(id, group, from) {
    state = { group: group.length ? group : [id], i: Math.max(0, group.indexOf(id)) };
    opener = from;
    paint();
    const el = $lb();
    el.hidden = false;
    requestAnimationFrame(() => el.classList.add('open'));
    if (document.body.classList) document.body.classList.add('lb-open');
    const btn = el.querySelector('[data-lb="close"]');
    if (btn) btn.focus({ preventScroll: true });
  }
  function close() {
    if (!state) return;
    state = null;
    const el = $lb();
    el.classList.remove('open');
    el.hidden = true;
    if (document.body.classList) document.body.classList.remove('lb-open');
    if (opener && opener.focus) opener.focus({ preventScroll: true });
  }
  function step(d) {
    if (!state || state.group.length < 2) return;
    state.i = (state.i + d + state.group.length) % state.group.length;
    paint();
    const img = $lb().querySelector('.lb-img');
    if (img) img.scrollTop = 0;
  }

  document.addEventListener('click', (e) => {
    const shot = e.target.closest && e.target.closest('[data-shot]');
    if (shot) {
      e.preventDefault();
      open(shot.dataset.shot, (shot.dataset.group || '').split(',').filter(Boolean), shot);
      return;
    }
    if (!state) return;
    const act = e.target.closest && e.target.closest('[data-lb]');
    if (act) {
      const a = act.dataset.lb;
      if (a === 'prev') step(-1);
      else if (a === 'next') step(1);
      else close();
      return;
    }
    // a click on the dimmed area (not the panel) closes it
    if (e.target.id === 'lightbox') close();
  });

  // Registered before app.js's own key handler, so when the lightbox is open
  // it takes Esc and the arrow keys and nothing else reacts.
  document.addEventListener('keydown', (e) => {
    if (!state) return;
    if (e.key === 'Escape') close();
    else if (e.key === 'ArrowLeft') step(-1);
    else if (e.key === 'ArrowRight') step(1);
    else return;
    e.preventDefault();
    e.stopImmediatePropagation();
  });

  Object.assign(window.HB, { shots, lightbox: { isOpen: () => !!state, close } });
})();
