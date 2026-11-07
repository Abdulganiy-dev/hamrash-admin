// Hamrash handbook renderer. All content lives in data.js (window.HANDBOOK);
// this file only turns it into pages. No build step, no dependencies:
// open index.html in a browser.
(function () {
  const H = window.HANDBOOK;
  const $ = (sel) => document.querySelector(sel);
  const { esc, md, slug, KIND_LABEL, refFor, linkCode, shots } = window.HB;
  const DR = window.HB.drawer;

  // ── Sidebar ─────────────────────────────────────────────────────────
  function renderNav(route) {
    const link = (href, label, count) =>
      `<a class="nav-link${route === href ? ' active' : ''}" href="#${href}">${esc(label)}${
        count ? `<span class="nav-count">${count}</span>` : ''
      }</a>`;
    const group = (label, items) =>
      `<div class="nav-group"><span class="nav-label">${esc(label)}</span>${items.join('')}</div>`;
    const feat = (app) =>
      H.features.filter((f) => f.app === app).map((f) => link(`/f/${f.id}`, f.title, f.ops.length));
    $('#nav').innerHTML = [
      group('Start here', [
        link('/', 'How Hamrash works'),
        link('/roles', 'Roles and who can do what'),
        link('/errors', 'Reading an error'),
        link('/maintaining', 'Keeping this up to date'),
      ]),
      group('Hamrash Admin app', feat('admin')),
      group('Platform Admin app', feat('platform')),
      group('Database reference', [
        link('/migrations', 'Migrations', H.migrations.length),
        link('/tables', 'Tables', H.tables.length),
        link('/functions', 'Functions', H.functions.reduce((n, f) => n + f.name.split(' · ').length, 0) + Object.keys(window.HB.privateFunctions).length),
        link('/edge', 'Edge functions', H.edge.length),
        link('/gaps', 'Known gaps', H.gaps.length),
      ]),
    ].join('');
    $('#brand-sub').textContent = `Up to migration ${H.meta.migrationsInRepo}`;
  }

  function setToc(items) {
    $('#toc').innerHTML = items.length
      ? `<span class="nav-label" style="padding:0 0 10px">On this page</span><div class="toc-list">${items
          .map((i) => `<a class="${i.sub ? 'sub' : ''}" href="#${location.hash.slice(1).split('?')[0]}?at=${i.id}">${esc(i.label)}</a>`)
          .join('')}</div>${liveCallout()}`
      : liveCallout();
  }
  function liveCallout() {
    const m = H.meta;
    if (m.migrationsLive >= m.migrationsInRepo) return '';
    return `<div class="callout" style="margin-top:20px"><b>Not live yet</b><br>Migrations ${
      m.migrationsLive + 1
    }–${m.migrationsInRepo} are in the repo but not applied to the live project.</div>`;
  }

  // ── Pieces ──────────────────────────────────────────────────────────
  function opBlock(op, open) {
    const who = op.who || {};
    const pills = [
      ...(who.yes || []).map((r) => `<span class="pill role ok">✓ ${esc(r)}</span>`),
      ...(who.some || []).map((r) => `<span class="pill role warn">◐ ${esc(r)}</span>`),
      ...(who.no || []).map((r) => `<span class="pill role off">✕ ${esc(r)}</span>`),
    ].join('');
    const touches = (op.touches || [])
      .map((t) => {
        const ghost = t.startsWith('~');
        const text = ghost ? t.slice(1) : t;
        const ref = refFor(text);
        const cls = `chip${ghost ? ' ghost' : ''}`;
        if (ref && ref.d) return `<a class="${cls}" data-d="${ref.d}" href="#">${esc(text)}</a>`;
        if (ref && ref.href) return `<a class="${cls}" href="#${ref.href}">${esc(text)}</a>`;
        return `<span class="${cls}">${esc(text)}</span>`;
      })
      .join('');
    const steps = (op.steps || [])
      .map((s, i) => `<div class="step"><span class="step-n">${i + 1}</span><span>${md(s)}</span></div>`)
      .join('');
    const refusals = (op.refusals || [])
      .map(
        (r) => `<div class="refusal"><div class="refusal-head"><b>${esc(r.when)}</b>${
          r.code ? `<span class="code ${r.code.startsWith('RLS') || r.code === 'app' ? 'warn' : 'err'}">${esc(r.code)}</span>` : ''
        }</div><p>${md(r.text)}</p></div>`
      )
      .join('');
    return `<details class="op" id="${op.id}"${open ? ' open' : ''}>
      <summary><span class="kind ${op.kind}">${KIND_LABEL[op.kind]}</span><span class="op-title">${esc(op.title)}</span><span class="op-target">${esc(op.target || '')}</span><span class="op-plus">+</span></summary>
      ${op.trigger ? `<div class="op-trigger">${md(op.trigger)}</div>` : ''}
      ${touches ? `<div class="op-row band"><span class="op-label">Touches</span><div class="op-body">${touches}</div></div>` : ''}
      ${op.screens && op.screens.length ? `<div class="op-row"><span class="op-label">Screens</span><div class="op-screens">${shots(op.screens)}</div></div>` : ''}
      ${pills ? `<div class="op-row"><span class="op-label">Who can</span><div class="op-body">${pills}${who.note ? `<p style="width:100%;font-size:14px;margin-top:4px">${md(who.note)}</p>` : ''}</div></div>` : ''}
      ${steps ? `<div class="op-row"><span class="op-label">What happens</span><div class="steps">${steps}</div></div>` : ''}
      ${refusals ? `<div class="op-row"><span class="op-label">Refused when</span><div class="refusals">${refusals}</div></div>` : ''}
      ${op.sources ? `<div class="op-foot">${op.sources.map(esc).join('<span>·</span>')}</div>` : '<div style="height:22px"></div>'}
    </details>`;
  }

  // ── Pages ───────────────────────────────────────────────────────────
  function pageHome() {
    const o = H.overview;
    const cards = H.features
      .map(
        (f) => `<a class="card" href="#/f/${f.id}"><span class="meta">${f.app === 'admin' ? 'HAMRASH ADMIN' : 'PLATFORM ADMIN'} · ${f.ops.length} OPERATIONS</span><h3>${esc(
          f.title
        )}</h3><p>${md(f.summary)}</p></a>`
      )
      .join('');
    setToc([
      { id: 'pieces', label: 'The pieces' },
      { id: 'rules', label: 'Ground rules' },
      { id: 'journey', label: 'From new school to Home' },
      { id: 'features', label: 'Features' },
    ]);
    return `<div class="page-head"><span class="eyebrow">Hamrash handbook</span><h1>How Hamrash works</h1><p class="lede">${md(o.lede)}</p></div>
      <section id="pieces"><h2>The pieces</h2><p class="section-sub">Three moving parts, one database.</p>
        <div class="cards">${o.pieces.map((p) => `<div class="card"><span class="meta">${esc(p.kind)}</span><h3>${esc(p.name)}</h3><p>${md(p.text)}</p></div>`).join('')}</div></section>
      <section id="rules"><h2>Ground rules</h2><p class="section-sub">True everywhere in the database.</p>
        <div class="prose"><ul>${o.rules.map((r) => `<li>${md(r)}</li>`).join('')}</ul></div></section>
      <section id="journey"><h2>From new school to Home</h2><p class="section-sub">What happens, in order, from the moment Hamrash adds a school.</p>
        <div class="flow">${o.journey.map((s, i) => `<div class="flow-step"><span class="n">${i + 1}</span><div><b>${esc(s.title)}</b><p>${md(s.text)}</p></div></div>`).join('')}</div></section>
      <section id="features"><h2>Features</h2><p class="section-sub">Every screen that reads or writes data. Open one to see each operation, who can do it, and why it can be refused.</p>
        <div class="cards">${cards}</div></section>`;
  }

  function pageFeature(id) {
    const f = H.features.find((x) => x.id === id);
    if (!f) return `<p class="empty">No such page.</p>`;
    const counts = ['create', 'read', 'update', 'delete']
      .map((k) => [k, f.ops.filter((o) => o.kind === k).length])
      .filter(([, n]) => n)
      .map(([k, n]) => `<span class="pill ${{ create: 'ok', read: 'off', update: 'warn', delete: 'err' }[k]}">${n} ${k}</span>`)
      .join('');
    const strip = f.strip
      ? `<div class="strip">${f.strip.map(([a, b, hl]) => `<div class="${hl ? 'hl' : ''}"><span>${esc(a)}</span><b>${md(b)}</b></div>`).join('')}</div>`
      : '';
    setToc([
      ...(f.gallery && f.gallery.length ? [{ id: 'screens', label: 'Screens' }] : []),
      ...(f.notes ? [{ id: 'notes', label: 'Good to know' }] : []),
      { id: 'operations', label: 'Operations' },
      ...f.ops.map((o) => ({ id: o.id, label: o.title, sub: true })),
    ]);
    const gallery = f.gallery && f.gallery.length
      ? `<section class="gallery" id="screens"><div class="dr-label" style="margin-bottom:12px">Screens · ${f.gallery.length}</div>${shots(f.gallery)}</section>` : '';
    return `<div class="page-head"><span class="eyebrow">${f.app === 'admin' ? 'Hamrash Admin app' : 'Platform Admin app'} · Feature</span><h1>${esc(
      f.title
    )}</h1><p class="lede">${md(f.summary)}</p></div>${gallery}${strip}
      ${f.notes ? `<section id="notes"><h2>Good to know</h2><div class="prose" style="margin-top:14px"><ul>${f.notes.map((n) => `<li>${md(n)}</li>`).join('')}</ul></div></section>` : ''}
      <section id="operations"><div class="ops-head"><div><h2 style="border:0;padding:0">Operations</h2><p class="section-sub" style="margin:6px 0 0">Everything a user can do here, and what it does to the database. Tap one to open it.</p></div><div class="ops-counts">${counts}</div></div>
      ${f.ops.map((o, i) => opBlock(o, i === 0)).join('')}</section>`;
  }

  function cell(c, note) {
    const t = note ? ` title="${esc(note)}"` : '';
    if (c === 'E') return `<span class="pill ok"${t}>Edit</span>`;
    if (c === 'V') return `<span class="pill off"${t}>View</span>`;
    if (c === 'S') return `<span class="pill warn"${t}>Some</span>`;
    return `<span class="none">—</span>`;
  }
  function pageRoles() {
    const R = H.roles;
    setToc([
      { id: 'matrix', label: 'Matrix' },
      { id: 'roles-list', label: 'The roles' },
      { id: 'leaders', label: 'Words we use' },
    ]);
    const head = `<tr><th>Action</th>${R.columns.map((c) => `<th class="c">${esc(c)}</th>`).join('')}</tr>`;
    const body = R.matrix
      .map(
        (g) =>
          `<tr class="group"><td colspan="${R.columns.length + 1}">${esc(g.group)}</td></tr>` +
          g.rows
            .map(
              (r) =>
                `<tr><td class="action"><b>${esc(r.action)}</b><code>${esc(r.target)}</code>${
                  r.note ? `<div style="font-size:13px;line-height:18px;margin-top:4px">${md(r.note)}</div>` : ''
                }</td>${r.cells
                  .split(' ')
                  .map((c, i) => `<td class="c">${cell(c, r.notes && r.notes[i])}</td>`)
                  .join('')}</tr>`
            )
            .join('')
      )
      .join('');
    return `<div class="page-head"><span class="eyebrow">Start here</span><h1>Roles and who can do what</h1><p class="lede">${md(R.lede)}</p></div>
      <section id="matrix"><div class="legend"><span><span class="pill ok">Edit</span>Can create, change, remove</span><span><span class="pill off">View</span>Read only</span><span><span class="pill warn">Some</span>Only some rows · hover for the rule</span><span><span class="none">—</span>No access</span></div>
      <table class="matrix"><thead>${head}</thead><tbody>${body}</tbody></table></section>
      <section id="roles-list"><h2>The roles</h2><table class="ref" style="margin-top:14px"><tbody>${R.list
        .map((r) => `<tr><td><b>${esc(r.name)}</b><br><code>${esc(r.value)}</code></td><td>${md(r.text)}</td></tr>`)
        .join('')}</tbody></table></section>
      <section id="leaders"><h2>Words we use</h2><div class="prose" style="margin-top:14px"><ul>${R.terms.map((t) => `<li>${md(t)}</li>`).join('')}</ul></div></section>`;
  }

  function pageErrors() {
    setToc([{ id: 'codes', label: 'Error codes' }, { id: 'how', label: 'How the apps show them' }]);
    return `<div class="page-head"><span class="eyebrow">Start here</span><h1>Reading an error</h1><p class="lede">${md(H.errors.lede)}</p></div>
      <section id="codes"><h2>Error codes</h2><table class="ref" style="margin-top:14px"><thead><tr><th>Code</th><th>What it means</th></tr></thead><tbody>${H.errors.codes
        .map((c) => `<tr><td><span class="code ${c.code.startsWith('RLS') ? 'warn' : 'err'}">${esc(c.code)}</span><br><b>${esc(c.name)}</b></td><td>${md(c.text)}</td></tr>`)
        .join('')}</tbody></table></section>
      <section id="how"><h2>How the apps show them</h2><div class="prose" style="margin-top:14px"><ul>${H.errors.apps.map((a) => `<li>${md(a)}</li>`).join('')}</ul></div></section>`;
  }

  function pageTables() {
    setToc(H.tables.map((t) => ({ id: 't-' + slug(t.name), label: t.name })));
    return `<div class="page-head"><span class="eyebrow">Database reference</span><h1>Tables</h1><p class="lede">Every table, who can read and write it, and what deleting a row does. Reading is filtered by row-level security: a role only ever sees its own school.</p></div>
      ${H.tables
        .map(
          (t) => `<section id="t-${slug(t.name)}"><h2 style="font-size:24px">${t.name.split(' · ').map((n) => linkCode(n.replace('private.', ''))).join(' · ')}</h2><p class="section-sub">${md(t.purpose)}</p>
          <table class="ref"><tbody>
            <tr><td><b>Read</b></td><td>${md(t.read)}</td></tr>
            <tr><td><b>Insert / update</b></td><td>${md(t.write)}</td></tr>
            <tr><td><b>Delete</b></td><td>${md(t.del)}</td></tr>
            ${t.rules ? `<tr><td><b>Rules</b></td><td>${md(t.rules)}</td></tr>` : ''}
            <tr><td><b>Migrations</b></td><td>${md(t.migrations)}</td></tr>
          </tbody></table></section>`
        )
        .join('')}`;
  }

  // First sentence of a private function's comment, for the list.
  function blurb(name) {
    const f = window.HB.privateFunctions[name];
    const text = f.doc || (H.privateNotes || {})[name] || '';
    const first = text.split(/(?<=[.!?])\s/)[0] || '';
    return first.length > 170 ? first.slice(0, 167) + '…' : first;
  }
  function privateGroups() {
    const PF = window.HB.privateFunctions;
    const g = { 'Access helpers': [], 'Trigger functions': [], 'Called by other functions': [] };
    Object.keys(PF).sort().forEach((n) => {
      const u = PF[n].usedBy;
      (u.triggers.length ? g['Trigger functions'] : u.policies.length ? g['Access helpers'] : g['Called by other functions']).push(n);
    });
    return g;
  }
  const GROUP_NOTE = {
    'Access helpers': 'Used inside row-level-security policies to decide who sees or changes a row. Almost every policy calls `my_org_ids()` or `is_platform_admin()`.',
    'Trigger functions': 'Run automatically when a row is inserted, updated or deleted. Each is shown on its table’s Triggers tab too.',
    'Called by other functions': 'Small helpers that the public functions use.',
  };

  function pageFunctions() {
    const groups = [...new Set(H.functions.map((f) => f.group))];
    const priv = privateGroups();
    const privCount = Object.values(priv).reduce((n, l) => n + l.length, 0);
    setToc([...groups.map((g) => ({ id: 'g-' + slug(g), label: g })), { id: 'private', label: `Private helpers · ${privCount}` }, ...Object.keys(priv).map((k) => ({ id: 'p-' + slug(k), label: k, sub: true }))]);
    const privTable = (list) =>
      `<table class="ref" style="margin-top:14px"><thead><tr><th>Function</th><th>What it is</th><th style="width:96px">Used by</th></tr></thead><tbody>${list
        .map((n) => {
          const u = window.HB.privateFunctions[n].usedBy;
          const count = u.policies.length + u.triggers.length + u.functions.length + u.private.length;
          return `<tr id="pfn-${slug(n)}"><td style="width:34%"><code><a class="ref-link" data-d="pfn:${esc(n)}" href="#">${esc(n)}()</a></code><br><span class="pill off" style="margin-top:4px">${window.HB.privateFunctions[n].security}</span></td><td>${md(blurb(n)) || '<span class="empty">No comment in the migration.</span>'}</td><td>${count}</td></tr>`;
        })
        .join('')}</tbody></table>`;
    return `<div class="page-head"><span class="eyebrow">Database reference</span><h1>Functions</h1><p class="lede">Postgres functions the apps call with <code>rpc()</code>, then the <b>private helpers</b> that policies, triggers and those functions use behind the scenes. <b>Definer</b> functions run with the owner's rights and check the caller themselves; <b>invoker</b> functions run as the caller, so row-level security still applies. Click any name for its SQL and everything that uses it.</p></div>
      ${groups
        .map(
          (g) => `<section id="g-${slug(g)}"><h2>${esc(g)}</h2>${H.functions
            .filter((f) => f.group === g)
            .map(
              (f) => `<table class="ref" id="fn-${slug(f.name)}" style="margin:14px 0"><thead><tr><th colspan="2">${f.name.split(' · ').map((n) => linkCode(n)).join(' · ')} <span class="pill off" style="margin-left:6px">${esc(f.security)}</span>${
                f.live === false ? ' <span class="pill warn">not live yet</span>' : ''
              }</th></tr></thead><tbody>
              <tr><td><b>Who can call</b></td><td>${md(f.who)}</td></tr>
              <tr><td><b>What it does</b></td><td>${md(f.does)}</td></tr>
              ${f.errors && f.errors.length ? `<tr><td><b>Refuses with</b></td><td>${f.errors.map((e) => `<div style="margin-bottom:4px"><span class="code err">${esc(e[0])}</span> ${md(e[1])}</div>`).join('')}</td></tr>` : ''}
              <tr><td><b>Called from</b></td><td>${md(f.from)}</td></tr>
              </tbody></table>`
            )
            .join('')}</section>`
        )
        .join('')}
      <section id="private"><h2>Private helpers <span style="font-size:16px;color:var(--muted);font-weight:600">${privCount}</span></h2>
        <p class="section-sub">In the <code>private</code> schema, which the Data API never exposes. The apps can't call these; the database does.</p>
        ${Object.entries(priv).map(([k, list]) => `<div id="p-${slug(k)}" style="margin-top:26px"><h3 style="font-size:20px">${esc(k)} <span style="font-size:14px;color:var(--muted);font-weight:600">${list.length}</span></h3><p class="section-sub" style="margin:4px 0 0">${md(GROUP_NOTE[k])}</p>${privTable(list)}</div>`).join('')}
      </section>`;
  }

  function pageEdge() {
    setToc(H.edge.map((e) => ({ id: 'e-' + slug(e.name), label: e.name })));
    return `<div class="page-head"><span class="eyebrow">Database reference</span><h1>Edge functions</h1><p class="lede">Server code in <code>supabase/functions/</code>. They check the caller's Clerk login themselves, because Supabase's gateway only trusts Supabase-signed tokens (deploy with <code>--no-verify-jwt</code>).</p></div>
      ${H.edge
        .map(
          (e) => `<section id="e-${slug(e.name)}"><h2><code style="font-size:24px">${esc(e.name)}</code></h2><p class="section-sub">${md(e.purpose)}</p>
          <div class="flow" style="margin-bottom:14px">${e.steps.map((s, i) => `<div class="flow-step"><span class="n">${i + 1}</span><div><p>${md(s)}</p></div></div>`).join('')}</div>
          <table class="ref"><tbody>${e.facts.map(([k, v]) => `<tr><td><b>${esc(k)}</b></td><td>${md(v)}</td></tr>`).join('')}</tbody></table></section>`
        )
        .join('')}`;
  }

  function pageGaps() {
    const kinds = [...new Set(H.gaps.map((g) => g.kind))];
    setToc(kinds.map((k) => ({ id: 'k-' + slug(k), label: k })));
    const tone = { 'Broken or risky': 'err', 'Inconsistent': 'warn', 'Not built yet': 'off', 'Out of date': 'warn' };
    return `<div class="page-head"><span class="eyebrow">Database reference</span><h1>Known gaps</h1><p class="lede">Things the audit found that are missing, inconsistent or risky. Fix them, then delete the entry here.</p></div>
      ${kinds
        .map(
          (k) => `<section id="k-${slug(k)}"><h2>${esc(k)}</h2><div style="margin-top:14px">${H.gaps
            .filter((g) => g.kind === k)
            .map((g) => `<div class="gap"><div class="gap-head"><b>${esc(g.title)}</b><span class="pill ${tone[k] || 'off'}">${esc(g.where)}</span></div><p>${md(g.text)}</p></div>`)
            .join('')}</div></section>`
        )
        .join('')}`;
  }

  function pageMigrations() {
    const m = H.meta;
    setToc([]);
    return `<div class="page-head"><span class="eyebrow">Database reference</span><h1>Migrations</h1><p class="lede">Every change to the database, in order. They live in <code>supabase/migrations/</code>; each has an access test in <code>supabase/tests/</code>. The live project has 01–${String(m.migrationsLive).padStart(2, '0')} applied.</p></div>
      <table class="ref"><thead><tr><th>#</th><th>What it changed</th></tr></thead><tbody>${H.migrations
        .map(
          (x) => `<tr id="m-${x.n}"><td style="width:120px"><b class="mono">${String(x.n).padStart(2, '0')}</b><br>${
            x.n <= m.migrationsLive ? '<span class="pill ok">live</span>' : '<span class="pill warn">not live yet</span>'
          }${x.drops ? ' <span class="pill off">has drop</span>' : ''}</td><td><b>${esc(x.title)}</b><br>${md(x.text)}</td></tr>`
        )
        .join('')}</tbody></table>`;
  }

  function pageMaintaining() {
    const m = H.maintaining;
    setToc([{ id: 'when', label: 'When to update' }, { id: 'how', label: 'How' }, { id: 'check', label: 'The check script' }]);
    return `<div class="page-head"><span class="eyebrow">Start here</span><h1>Keeping this up to date</h1><p class="lede">${md(m.lede)}</p></div>
      <section id="when"><h2>When to update</h2><div class="prose" style="margin-top:14px"><ul>${m.when.map((w) => `<li>${md(w)}</li>`).join('')}</ul></div></section>
      <section id="how"><h2>How</h2><div class="flow" style="margin-top:14px">${m.how.map((s, i) => `<div class="flow-step"><span class="n">${i + 1}</span><div><p>${md(s)}</p></div></div>`).join('')}</div></section>
      <section id="check"><h2>The check script</h2><div class="prose" style="margin-top:14px"><p>${md(m.check)}</p></div></section>`;
  }

  // ── Search ──────────────────────────────────────────────────────────
  function pageSearch(q) {
    const needle = q.toLowerCase();
    const hits = [];
    const has = (...xs) => xs.some((x) => JSON.stringify(x ?? '').toLowerCase().includes(needle));
    H.features.forEach((f) =>
      f.ops.forEach((o) => {
        if (has(o.title, o.touches, o.refusals, o.steps, o.target)) hits.push({ href: `/f/${f.id}?at=${o.id}`, kind: KIND_LABEL[o.kind], title: o.title, where: f.title });
      })
    );
    H.tables.forEach((t) => has(t.name, t.purpose, t.rules) && hits.push({ d: `tbl:${t.name.split(' · ')[0].replace('private.', '')}`, kind: 'Table', title: t.name, where: t.purpose }));
    Object.entries(window.HB.privateFunctions).forEach(([n, f]) => has(n, f.doc) && hits.push({ d: `pfn:${n}`, kind: 'Private function', title: `private.${n}`, where: blurb(n) }));
    H.functions.forEach((f) => has(f.name, f.does, f.errors) && hits.push({ d: `fn:${f.name.split(' · ')[0]}`, kind: 'Function', title: f.name, where: f.group }));
    H.errors.codes.forEach((c) => has(c.code, c.name, c.text) && hits.push({ href: '/errors', kind: 'Error', title: `${c.code} · ${c.name}`, where: 'Reading an error' }));
    H.migrations.forEach((x) => has(x.title, x.text) && hits.push({ href: `/migrations?at=m-${x.n}`, kind: `Migration ${String(x.n).padStart(2, '0')}`, title: x.title, where: x.text }));
    H.gaps.forEach((g) => has(g.title, g.text) && hits.push({ href: '/gaps', kind: 'Gap', title: g.title, where: g.where }));
    setToc([]);
    return `<div class="page-head"><span class="eyebrow">Search</span><h1>“${esc(q)}”</h1><p class="lede">${hits.length} result${hits.length === 1 ? '' : 's'}</p></div>
      ${hits.length ? hits.map((h) => `<a class="card" style="margin-bottom:10px" ${h.d ? `data-d="${h.d}" href="#"` : `href="#${h.href}"`}><span class="meta">${esc(h.kind.toUpperCase())}</span><h3>${esc(h.title)}</h3><p>${md(h.where || '')}</p></a>`).join('') : '<p class="empty">Nothing matches. Try a table name, an error message or a role.</p>'}`;
  }

  // ── Router ──────────────────────────────────────────────────────────
  let shownPath = null;
  function renderPage(path, at) {
    const q = $('#q').value.trim();
    renderNav(path);
    let html;
    if (q) html = pageSearch(q);
    else if (path === '/') html = pageHome();
    else if (path === '/roles') html = pageRoles();
    else if (path === '/errors') html = pageErrors();
    else if (path === '/maintaining') html = pageMaintaining();
    else if (path === '/tables') html = pageTables();
    else if (path === '/migrations') html = pageMigrations();
    else if (path === '/functions') html = pageFunctions();
    else if (path === '/edge') html = pageEdge();
    else if (path === '/gaps') html = pageGaps();
    else if (path.startsWith('/f/')) html = pageFeature(path.slice(3));
    else html = '<p class="empty">No such page.</p>';
    $('#content').innerHTML = html;
    shownPath = path;
    if (at) {
      const el = document.getElementById(at);
      if (el) {
        if (el.tagName === 'DETAILS') el.open = true;
        el.scrollIntoView({ block: 'start' });
      }
    } else if (!q) window.scrollTo(0, 0);
  }

  // Opening or closing the drawer changes only the "d" part of the address,
  // so the page behind it isn't redrawn and keeps its scroll position.
  function onHash() {
    const raw = location.hash.slice(1) || '/';
    const [path, query] = raw.split('?');
    const params = new URLSearchParams(query || '');
    const at = params.get('at');
    if (path !== shownPath) renderPage(path, at);
    else if (at && !params.get('d')) {
      const el = document.getElementById(at);
      if (el) {
        if (el.tagName === 'DETAILS') el.open = true;
        el.scrollIntoView({ block: 'start' });
      }
    }
    DR.sync(params.get('d'));
  }

  window.addEventListener('hashchange', onHash);
  $('#q').addEventListener('input', () => renderPage(shownPath || '/', null));
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      if (DR.isOpen()) return DR.go(null);
      $('#q').value = '';
      renderPage(shownPath || '/', null);
      return;
    }
    if (e.key === '/' && document.activeElement !== $('#q') && !DR.isOpen()) {
      e.preventDefault();
      $('#q').focus();
    }
  });
  onHash();
})();
