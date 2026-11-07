# Hamrash handbook

A handoff site for anyone joining Hamrash. For every data operation in Hamrash Admin and Hamrash Platform Admin, it covers:

- the database tables and functions it touches
- who can do it
- what happens on insert, update and delete
- why it can be refused

**Open it:** open `index.html` in a browser. It needs no build step and no server.

| File | What it is |
|------|------------|
| `data.js` | **All the content.** Edit this. |
| `app.js` | Renders the pages from `data.js`. |
| `styles.css` | Hamrash design system colours and type. The design is in the Paper file "Hamrash", page "Handoff docs (web)". |
| `drawer.js` | The side panel that opens when you click a table or function name. |
| `snippets.js` | **Generated.** The SQL shown in the panel, copied from the migrations. Don't edit; run `extract_sql.py`. |
| `extract_sql.py` | Rebuilds `snippets.js` from `supabase/migrations/`. |
| `lightbox.js` | Thumbnails and the click-to-enlarge screen viewer. |
| `screens/` | App screens exported from Paper (page “Hmarash Admin”) at 2x. Listed in `data.js` `screens`; re-export when a design changes. Hamrash Admin only. |
| `check.py` | Fails if a table, RPC or edge function used by the apps or migrations isn't mentioned in `data.js`. |

## Keep it up to date

Update `data.js` **in the same change** whenever you do any of these:

- add or edit a migration
- add or change a service method that calls `.from()`, `.rpc()` or `functions.invoke()` in either app
- change who can see an action, or change a message the user sees

Then run:

```bash
python3 docs/handbook/extract_sql.py   # rebuilds the SQL snippets from the migrations
python3 docs/handbook/check.py         # fails if anything is missing or stale
```

When a migration is applied to the live project, bump `meta.migrationsLive` in `data.js`.
