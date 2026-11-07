// Reference drawer for the Hamrash handbook: click a table or function name
// anywhere and a panel slides in from the right with its details and SQL.
// Content comes from data.js (descriptions, who-can-do-what) and snippets.js
// (the SQL, generated from the migrations by extract_sql.py).
//
// Exposes window.HB with the helpers app.js shares (esc, md, refFor, ...) and
// HB.drawer.sync(spec) which opens, updates or closes the panel.
(function () {
  const H = window.HANDBOOK;
  const S = window.SNIPPETS || { functions: {}, tables: {} };

  const esc = (s) =>
    String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);
  const slug = (s) => String(s).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
  const KIND_LABEL = { create: 'Create', read: 'Read', update: 'Update', delete: 'Delete' };

  // ── Which names are links ───────────────────────────────────────────
  const namesOf = (entry) => entry.name.split(' · ').map((n) => n.replace('private.', '').trim());
  const fnEntry = (name) => H.functions.find((f) => namesOf(f).includes(name));
  const tblEntry = (name) => H.tables.find((t) => namesOf(t).includes(name));
  const isFn = (n) => Object.prototype.hasOwnProperty.call(S.functions, n);
  const isTbl = (n) => Object.prototype.hasOwnProperty.call(S.tables, n);

  // `name` (or `name()`) in a content string becomes a link when it's a known
  // table or function.
  function linkCode(name) {
    const bare = name.replace(/\(\)$/, '');
    if (isFn(bare)) return `<code><a class="ref-link" data-d="fn:${bare}" href="#">${name}</a></code>`;
    if (isTbl(bare)) return `<code><a class="ref-link" data-d="tbl:${bare}" href="#">${name}</a></code>`;
    return `<code>${name}</code>`;
  }
  // Content strings may use `code`, **bold** and “quotes”; everything else is escaped.
  const md = (s) =>
    esc(s)
      .replace(/`([^`]+)`/g, (_, c) => linkCode(c))
      .replace(/\*\*([^*]+)\*\*/g, '<b>$1</b>')
      .replace(/“([^”]+)”/g, '<span class="quote">“$1”</span>');

  // A "touches" chip such as "delete class_arms" or "rpc close_session":
  // returns a drawer spec, an edge-function page link, or null.
  function refFor(text) {
    const words = text.match(/[a-z_-]{4,}/g) || [];
    for (const w of words) {
      if (isTbl(w)) return { d: `tbl:${w}` };
      if (isFn(w)) return { d: `fn:${w}` };
      const e = H.edge.find((e) => e.name === w);
      if (e) return { href: `/edge?at=e-${slug(e.name)}` };
    }
    return null;
  }

  // Which operations touch a table or function.
  let usedIndex = null;
  function usedBy(key) {
    if (!usedIndex) {
      usedIndex = {};
      H.features.forEach((f) =>
        f.ops.forEach((op) =>
          (op.touches || []).forEach((t) => {
            const r = refFor(t.replace(/^~/, ''));
            if (r && r.d) {
              (usedIndex[r.d] = usedIndex[r.d] || []).some((x) => x.op.id === op.id) ||
                usedIndex[r.d].push({ op, feature: f });
            }
          })
        )
      );
    }
    return usedIndex[key] || [];
  }

  // ── SQL highlighting ────────────────────────────────────────────────
  const KW = new RegExp(
    '\\b(' +
      [
        'create', 'or', 'replace', 'function', 'returns', 'language', 'security', 'definer', 'invoker', 'as', 'begin', 'end',
        'if', 'then', 'else', 'elsif', 'not', 'found', 'raise', 'exception', 'using', 'errcode', 'select', 'from', 'where',
        'into', 'insert', 'update', 'delete', 'set', 'values', 'for', 'to', 'on', 'in', 'and', 'or', 'is', 'null', 'return',
        'query', 'declare', 'table', 'policy', 'trigger', 'before', 'after', 'each', 'row', 'execute', 'using', 'check',
        'with', 'primary', 'key', 'references', 'unique', 'default', 'constraint', 'cascade', 'restrict', 'join', 'left',
        'exists', 'loop', 'perform', 'returning', 'order', 'by', 'limit', 'case', 'when', 'stable', 'volatile', 'immutable',
        'alter', 'add', 'column', 'drop', 'grant', 'revoke', 'true', 'false', 'distinct', 'group', 'having', 'union', 'all',
        'any', 'array', 'only', 'of', 'begin', 'commit', 'authenticated', 'anon', 'public',
      ].join('|') +
      ')\\b',
    'gi'
  );
  const TYPES = /\b(uuid|text|int|integer|boolean|bool|date|timestamptz|timestamp|numeric|bigint|jsonb|json|void|record|bytea)\b/gi;
  function highlight(sql) {
    const out = [];
    const re = /(--[^\n]*)|('(?:[^']|'')*')|(\$[A-Za-z_]*\$)|([^'$\-]+|[\s\S])/g;
    let m;
    while ((m = re.exec(sql))) {
      if (m[1]) out.push(`<span class="tok-c">${esc(m[1])}</span>`);
      else if (m[2]) out.push(`<span class="tok-s">${esc(m[2])}</span>`);
      else if (m[3]) out.push(esc(m[3]));
      else {
        out.push(
          esc(m[4])
            .replace(TYPES, '<span class="tok-t">$1</span>')
            .replace(KW, (k) => `<span class="tok-k">${k}</span>`)
        );
      }
    }
    return out.join('');
  }

  const migLabel = (n) => String(n).padStart(2, '0');
  const isLive = (n) => n <= H.meta.migrationsLive;
  const livePill = (n) =>
    `<span class="pill ${isLive(n) ? 'ok' : 'warn'}">${isLive(n) ? 'Live' : 'Not live yet'} · migration ${migLabel(n)}</span>`;

  function snippet(title, meta, sql, opts = {}) {
    const id = 'sn' + Math.random().toString(36).slice(2, 8);
    return `<div class="snip"><div class="snip-head"><b>${esc(title)}</b><span class="meta">${esc(meta)}</span>
      <button class="copy-btn" data-copy="${id}"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="11" height="11" rx="2"/><path d="M5 15V6a2 2 0 012-2h9"/></svg><span>Copy</span></button></div>
      <pre id="${id}" class="${opts.clip ? 'clip' : ''}" data-raw="${esc(sql)}">${highlight(sql)}</pre>${opts.foot ? `<div class="snip-foot">${opts.foot}</div>` : ''}</div>`;
  }
  const where = (x) => `migration ${migLabel(x.migration)} · lines ${x.lines[0]}–${x.lines[1]}`;

  // ── Function drawer ─────────────────────────────────────────────────
  function dartValue(p) {
    const t = p.type.toLowerCase();
    if (/bool/.test(t)) return 'true';
    if (/^(int|integer|numeric|bigint)/.test(t)) return '0';
    if (/uuid/.test(t)) return "'<uuid>'";
    if (/date/.test(t) || /timestamp/.test(t)) return "'2026-09-07'";
    if (/member_role/.test(t)) return "'teacher'";
    return "'…'";
  }
  function sqlValue(p) {
    const v = dartValue(p);
    if (v === 'true' || v === '0') return v;
    return `${v}${/uuid/.test(p.type) ? '::uuid' : ''}`;
  }
  function callIt(name, f) {
    const params = f.params || [];
    const dart = params.length
      ? `final result = await supabase.rpc(\n  '${name}',\n  params: {\n${params.map((p) => `    '${p.name}': ${dartValue(p)},${p.default != null ? `  // optional, default ${p.default}` : ''}`).join('\n')}\n  },\n);`
      : `final result = await supabase.rpc('${name}');`;
    const sql = `select * from public.${name}(${params.map((p) => sqlValue(p)).join(', ')});`;
    return `<div class="stack">
      <p class="dr-note">From the apps, call it with <code>rpc()</code>. The call runs as the signed-in user: Supabase gets their Clerk token, and <code>auth.jwt() ->> 'sub'</code> inside the function is their id.</p>
      ${snippet('Dart', 'supabase_flutter', dart)}
      ${snippet('SQL', 'for reading a result, not for testing permissions', sql)}
      <div class="callout info">In the Supabase SQL editor there is no signed-in user, so functions that check who is calling will refuse (for example “Not authenticated”). To test permissions, use the access tests in <code>supabase/tests/</code>, which act as fake users.</div>
    </div>`;
  }

  function fnView(name, tab, ctx) {
    const f = S.functions[name];
    const e = fnEntry(name) || {};
    const used = usedBy(`fn:${name}`);
    const sig = `public.${name}(${(f.params || []).map((p) => `${p.name} ${p.type}`).join(', ')}) → ${(f.returns || '').replace(/^public\./, '')}`;
    const siblings = namesOf(e).filter((n) => n !== name);
    const tabs = [['overview', 'Overview'], ['sql', 'SQL'], ['call', 'Call it'], ['used', `Used by${used.length ? ` <b>${used.length}</b>` : ''}`]];
    let body;
    if (tab === 'sql') {
      body = snippet('Latest definition', where(f), f.sql) +
        `<p class="dr-note">This is the definition after every migration. Earlier versions were replaced with <code>create or replace function</code> or dropped and recreated; see <a class="dr-link" href="#/migrations">Migrations</a>.</p>`;
    } else if (tab === 'call') {
      body = callIt(name, f);
    } else if (tab === 'used') {
      body = usedList(used);
    } else {
      const errs = e.errors || [];
      const showAll = ctx.expanded || errs.length <= 4;
      const shown = showAll ? errs : errs.slice(0, 3);
      body = `
        ${e.who ? `<div class="dr-sec"><div class="dr-label">Who can call</div><div class="dr-note">${md(e.who)}</div></div>` : ''}
        ${e.does ? `<div class="dr-sec"><div class="dr-label">What it does</div><div class="dr-note">${md(e.does)}</div></div>` : ''}
        ${errs.length ? `<div class="dr-sec"><div class="dr-label">Refuses with</div><div class="dr-box">${shown
          .map((x) => `<div class="dr-row"><span class="code ${x[0] === 'P0001' || x[0].startsWith('RLS') ? 'warn' : 'err'}">${esc(x[0])}</span><span class="grow">${md(x[1])}</span></div>`)
          .join('')}</div>${showAll ? '' : `<span class="dr-note" style="font-size:13px">+ ${errs.length - 3} more · <button class="dr-link" data-act="expand">see all</button></span>`}</div>` : ''}
        ${snippet('SQL', where(f), f.sql, { clip: true, foot: '<button class="dr-link" data-tab="sql">Show full function ↓</button>' })}
        ${e.from ? `<div class="dr-sec"><div class="dr-label">Called from</div><div class="dr-note">${md(e.from)}</div></div>` : ''}
        ${siblings.length ? `<div class="dr-sec"><div class="dr-label">Documented together with</div><div class="dr-note">${siblings.map((n) => linkCode(n)).join(' · ')}</div></div>` : ''}`;
    }
    return {
      kind: 'fn',
      head: `<span class="dr-kind fn">Function</span><span class="pill off">security ${f.security}</span>${livePill(f.migration)}`,
      title: name,
      sub: sig,
      subClass: '',
      tabs,
      body,
    };
  }

  // ── Table drawer ────────────────────────────────────────────────────
  const COL_STOP = /\b(not\s+null|null|default|references|primary\s+key|unique|check|generated|constraint)\b/i;
  function splitColumn(c) {
    const m = c.type.match(COL_STOP);
    const type = (m ? c.type.slice(0, m.index) : c.type).trim();
    return { type, rest: m ? c.type.slice(m.index).trim() : '' };
  }
  function linkRefs(rest) {
    return esc(rest).replace(/references\s+(?:public|private)\.([a-z_]+)/gi, (_, t) =>
      isTbl(t) ? `→ <a class="ref-link" data-d="tbl:${t}" href="#">${t}</a>` : `→ ${t}`
    ).replace(/\bnot null\b/gi, 'not null');
  }
  function columnRows(cols) {
    return cols
      .map((c) => {
        const { type, rest } = splitColumn(c);
        return `<div class="dr-col"><span class="n">${esc(c.name)}</span><span class="t">${esc(type)}</span><span class="r">${linkRefs(rest)}${c.added ? ` <span class="pill off">added in ${migLabel(c.added)}</span>` : ''}</span></div>`;
      })
      .join('');
  }

  // One line per trigger: when it fires and which function it runs.
  function triggerRow(x) {
    return `<div class="dr-row"><span class="grow"><b style="font-family:var(--mono);font-size:12.5px;color:var(--ink)">${esc(x.name)}</b><br><span style="font-size:12px;color:var(--muted)">${esc(x.timing)}${x.each_row ? ' · each row' : ''}${x.function ? ` · runs <code>${esc(x.function)}()</code>` : ''}</span></span></div>`;
  }

  function triggersTab(t, trg) {
    if (!trg.length) return '<p class="dr-empty">No triggers on this table.</p>';
    const fnOf = (x) => (x.function_schema === 'private' ? (S.privateFunctions || {})[x.function] : S.functions[x.function]);
    return `<p class="dr-note">Triggers run inside the database whenever a row is inserted, updated or deleted, whoever does it. Triggers for the same event fire in the order listed (alphabetical by name). Each is shown with the full function it runs.</p>
      ${trg
        .map((x, i) => {
          const f = fnOf(x);
          return `<div class="trg">
            <div class="trg-head"><span class="trg-n">${i + 1}</span><div class="grow"><b class="mono">${esc(x.name)}</b><div class="trg-when">${esc(x.timing)}${x.each_row ? ' · for each row' : ''}${x.when ? ` · when (${esc(x.when.trim())})` : ''}</div></div></div>
            ${snippet('Trigger', `${x.table} · ${where(x)}`, x.sql)}
            ${f
              ? snippet(`Function ${x.function_schema}.${x.function}()`, `security ${f.security} · ${where(f)}`, f.sql)
              : `<p class="dr-note">The function <code>${esc(x.function_schema || '')}.${esc(x.function || '?')}()</code> isn’t in the migrations the extractor reads.</p>`}
          </div>`;
        })
        .join('')}`;
  }

  function tblView(name, tab, ctx) {
    const t = S.tables[name];
    const e = tblEntry(name) || {};
    const used = usedBy(`tbl:${name}`);
    const cols = t.columns || [];
    const pol = t.policies || [];
    const trg = t.triggers || [];
    const tabs = [['overview', 'Overview'], ['columns', `Columns <b>${cols.length}</b>`], ['policies', `Policies <b>${pol.length}</b>`], ['triggers', `Triggers <b>${trg.length}</b>`], ['sql', 'SQL'], ['used', `Used by${used.length ? ` <b>${used.length}</b>` : ''}`]];
    const siblings = namesOf(e).filter((n) => n !== name);
    let body;
    if (tab === 'columns') {
      body = `<div class="dr-box">${columnRows(cols)}</div>${
        t.constraints.length
          ? `<div class="dr-sec"><div class="dr-label">Constraints</div><div class="dr-box">${t.constraints
              .map((c) => `<div class="dr-row"><span class="grow" style="font-family:var(--mono);font-size:12px;line-height:18px">${linkRefs(c)}</span></div>`)
              .join('')}</div></div>`
          : ''
      }`;
    } else if (tab === 'policies') {
      body = `<p class="dr-note">${t.schema === 'private' ? 'This table is in the <code>private</code> schema: the Data API never exposes it, so there are no policies. Only security-definer functions touch it.' : pol.length ? `Row-level security decides who sees or changes which rows. ${pol.length} polic${pol.length === 1 ? 'y' : 'ies'}, as they stand after every migration.` : 'No policies: clients can do nothing with this table directly.'}</p>
        ${pol.map((p) => snippet('Policy', `${p.name} · ${where(p)}`, p.sql)).join('')}`;
    } else if (tab === 'triggers') {
      body = triggersTab(t, trg);
    } else if (tab === 'sql') {
      const later = cols.filter((c) => c.added);
      body = snippet('create table', where(t.create), t.create.sql) +
        (later.length ? `<p class="dr-note">Columns added later with <code>alter table</code> aren’t in this statement: ${later.map((c) => `<code>${esc(c.name)}</code>`).join(', ')}. See the Columns tab.</p>` : '');
    } else if (tab === 'used') {
      body = usedList(used);
    } else {
      body = `
        <div class="dr-sec"><div class="dr-label">Who can do what</div><div class="dr-box">
          ${e.read ? `<div class="dr-row"><span class="k">read</span><span class="grow">${md(e.read)}</span></div>` : ''}
          ${e.write ? `<div class="dr-row"><span class="k">write</span><span class="grow">${md(e.write)}</span></div>` : ''}
          ${e.del ? `<div class="dr-row"><span class="k">delete</span><span class="grow">${md(e.del)}</span></div>` : ''}
          ${!e.read && !e.write && !e.del ? '<div class="dr-row"><span class="grow dr-empty">Not documented yet.</span></div>' : ''}
        </div></div>
        ${e.rules ? `<div class="dr-sec"><div class="dr-label">Rules</div><div class="dr-note">${md(e.rules)}</div></div>` : ''}
        <div class="dr-sec"><div class="dr-label">Columns <button class="dr-link" data-tab="columns">All ${cols.length} →</button></div><div class="dr-box">${columnRows(cols.slice(0, 4))}</div></div>
        ${pol.length ? snippet('Policy', `${pol[0].name} · ${where(pol[0])}`, pol[0].sql, { clip: true, foot: `<button class="dr-link" data-tab="policies">All ${pol.length} polic${pol.length === 1 ? 'y' : 'ies'} →</button>` }) : ''}
        ${trg.length ? `<div class="dr-sec"><div class="dr-label">Triggers <button class="dr-link" data-tab="triggers">All ${trg.length} with their functions →</button></div><div class="dr-box">${trg.slice(0, 4).map((x) => triggerRow(x)).join('')}</div></div>` : ''}
        ${siblings.length ? `<div class="dr-sec"><div class="dr-label">Documented together with</div><div class="dr-note">${siblings.map((n) => linkCode(n)).join(' · ')}</div></div>` : ''}`;
    }
    return {
      kind: 'tbl',
      head: `<span class="dr-kind tbl">Table</span><span class="pill off">${t.schema === 'private' ? 'private · not in the API' : 'RLS on'}</span>${livePill(t.create.migration)}`,
      title: t.schema === 'private' ? `private.${name}` : name,
      sub: e.purpose || '',
      subClass: ' sans',
      tabs,
      body,
    };
  }

  function usedList(list) {
    if (!list.length) return '<p class="dr-empty">No operation in the apps touches this directly yet.</p>';
    return `<div class="dr-box">${list
      .map(
        ({ op, feature }) =>
          `<a class="dr-row" style="text-decoration:none;color:inherit" href="#/f/${feature.id}?at=${op.id}" data-close="1"><span class="kind ${op.kind}">${KIND_LABEL[op.kind]}</span><span class="grow"><b style="color:var(--ink)">${esc(op.title)}</b><br><span style="font-size:12px;color:var(--muted)">${esc(feature.title)}</span></span><span style="color:var(--muted)">→</span></a>`
      )
      .join('')}</div>`;
  }

  // ── Panel ───────────────────────────────────────────────────────────
  const el = () => document.getElementById('drawer');
  const scrim = () => document.getElementById('scrim');
  let state = { d: null, tab: 'overview', expanded: false };
  let stack = []; // earlier drawer specs, for the back arrow
  let opener = null;

  function paint() {
    const [kind, name] = state.d.split(':');
    const ok = kind === 'fn' ? isFn(name) : isTbl(name);
    const v = ok
      ? kind === 'fn'
        ? fnView(name, state.tab, state)
        : tblView(name, state.tab, state)
      : { kind: 'fn', head: '<span class="dr-kind fn">Not found</span>', title: name, sub: 'No such table or function in the migrations.', tabs: [], body: '' };
    const root = el();
    root.innerHTML = `
      <div class="dr-head">
        <div class="dr-top">${stack.length ? '<button class="icon-btn" data-act="back" aria-label="Back">←</button>' : ''}${v.head}<span class="grow"></span>
          <button class="icon-btn" data-act="close" aria-label="Close"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg></button></div>
        <div><h2 class="dr-title">${esc(v.title)}</h2><div class="dr-sub${v.subClass || ''}">${esc(v.sub)}</div></div>
        ${v.tabs.length ? `<div class="dr-tabs">${v.tabs.map(([id, label]) => `<button class="dr-tab${state.tab === id ? ' active' : ''}" data-tab="${id}">${label}</button>`).join('')}</div>` : ''}
      </div>
      <div class="dr-body">${v.body}</div>`;
  }

  function show() {
    paint();
    const root = el();
    root.hidden = false;
    scrim().hidden = false;
    requestAnimationFrame(() => {
      root.classList.add('open');
      scrim().classList.add('open');
    });
    if (document.body.classList) document.body.classList.add('drawer-open');
    const close = root.querySelector('[data-act="close"]');
    if (close) close.focus({ preventScroll: true });
  }
  function hide() {
    const root = el();
    if (root.hidden) return;
    root.classList.remove('open');
    scrim().classList.remove('open');
    if (document.body.classList) document.body.classList.remove('drawer-open');
    setTimeout(() => {
      if (!state.d) {
        root.hidden = true;
        scrim().hidden = true;
      }
    }, 200);
    if (opener && opener.focus) opener.focus({ preventScroll: true });
  }

  // The page calls sync() whenever the address changes: d is "fn:name",
  // "tbl:name" or null.
  function sync(d) {
    if (!d) {
      state = { d: null, tab: 'overview', expanded: false };
      stack = [];
      hide();
      return;
    }
    if (state.d !== d) state = { d, tab: 'overview', expanded: false };
    show();
  }

  function pathOnly() {
    return location.hash.slice(1).split('?')[0] || '/';
  }
  function go(d, push) {
    if (push && state.d) stack.push(state.d);
    location.hash = d ? `#${pathOnly()}?d=${d}` : `#${pathOnly()}`;
  }

  document.addEventListener('click', (ev) => {
    const copy = ev.target.closest('[data-copy]');
    if (copy) {
      const text = document.getElementById(copy.dataset.copy).dataset.raw;
      const done = () => {
        copy.classList.add('done');
        copy.lastElementChild.textContent = 'Copied';
        setTimeout(() => {
          copy.classList.remove('done');
          copy.lastElementChild.textContent = 'Copy';
        }, 1400);
      };
      if (navigator.clipboard) navigator.clipboard.writeText(text).then(done, done);
      else {
        const ta = Object.assign(document.createElement('textarea'), { value: text });
        document.body.appendChild(ta);
        ta.select();
        document.execCommand('copy');
        ta.remove();
        done();
      }
      return;
    }
    const link = ev.target.closest('[data-d]');
    if (link) {
      ev.preventDefault();
      if (!state.d) opener = link;
      go(link.dataset.d, !!state.d);
      return;
    }
    const tab = ev.target.closest('[data-tab]');
    if (tab && el().contains(tab)) {
      state.tab = tab.dataset.tab;
      paint();
      el().querySelector('.dr-body').scrollTop = 0;
      return;
    }
    const act = ev.target.closest('[data-act]');
    if (act) {
      if (act.dataset.act === 'close') go(null);
      if (act.dataset.act === 'back') go(stack.pop() || null);
      if (act.dataset.act === 'expand') {
        state.expanded = true;
        paint();
      }
      return;
    }
    if (ev.target.closest('#scrim')) go(null);
    if (ev.target.closest('[data-close]') && el().contains(ev.target)) {
      stack = [];
      state = { d: null, tab: 'overview', expanded: false };
      hide();
    }
  });

  window.HB = { esc, md, slug, KIND_LABEL, refFor, linkCode, usedBy, drawer: { sync, isOpen: () => !!state.d, go } };
})();
