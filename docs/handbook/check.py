#!/usr/bin/env python3
"""Checks that the Hamrash handbook (docs/handbook/data.js) mentions every
table, RPC and edge function the apps and migrations use.

Run from anywhere:  python3 docs/handbook/check.py
Exits 1 if something is missing, so it can run in CI.

It looks at:
  - hamrash-admin/lib and ../hamrash-platform-admin/lib: .from('x'), .rpc('x'),
    functions.invoke('x')
  - supabase/migrations: create table <schema>.<name>, create function public.<name>
It does not judge whether the description is right, only that it exists.
"""
import pathlib
import re
import sys

here = pathlib.Path(__file__).resolve().parent
repo = here.parent.parent  # hamrash-admin
apps = [repo / "lib", repo.parent / "hamrash-platform-admin" / "lib"]
migrations = sorted((repo / "supabase" / "migrations").glob("*.sql"))
data = (here / "data.js").read_text()

used = {}  # name -> where


def note(name, where):
    used.setdefault(name, where)


for app in apps:
    if not app.exists():
        continue
    for f in app.rglob("*.dart"):
        if not f.is_file():
            continue
        text = f.read_text(errors="ignore")
        for m in re.finditer(r"\.(from|rpc)\(\s*'([a-z_]+)'", text):
            note(m.group(2), f"{f.relative_to(repo.parent)} ({m.group(1)})")
        for m in re.finditer(r"functions\.invoke\(\s*'([a-z-]+)'", text):
            note(m.group(1), f"{f.relative_to(repo.parent)} (edge)")

# Objects that still exist after the last migration: replay create and drop
# statements in order, so a later drop removes and a later create brings back.
alive = {}
stmt = re.compile(
    r"(create|drop) (?:or replace )?(?:table|function) (?:if (?:not )?exists )?(public|private)\.([a-z_]+)"
)
for f in migrations:
    for m in stmt.finditer(f.read_text(errors="ignore").lower()):
        verb, schema, name = m.groups()
        is_fn = "function" in m.group(0)
        if is_fn and schema != "public":
            continue  # private helpers aren't documented one by one
        if verb == "create":
            alive[name] = f.name
        else:
            alive.pop(name, None)
for name, fname in alive.items():
    note(name, f"supabase/migrations/{fname}")

missing = sorted(n for n in used if not re.search(rf"\b{re.escape(n)}\b", data))

problems = []
if missing:
    problems.append("Not mentioned in docs/handbook/data.js:")
    problems += [f"  - {n:<34} {used[n]}" for n in missing]

highest = max(int(re.match(r"\d+_(\d+)_", f.name).group(1)) for f in migrations)
m = re.search(r"migrationsInRepo:\s*(\d+)", data)
if not m or int(m.group(1)) != highest:
    problems.append(f"meta.migrationsInRepo is {m.group(1) if m else '?'} but the newest migration is {highest:02d}.")

listed = {int(x) for x in re.findall(r"\{ n: (\d+),", data)}
unlisted = [f"{x:02d}" for x in range(1, highest + 1) if x not in listed]
if unlisted:
    problems.append("Migrations missing from the migrations list in data.js: " + ", ".join(unlisted))

import subprocess
stale = subprocess.run([sys.executable, str(here / "extract_sql.py"), "--check"], capture_output=True, text=True)
if stale.returncode != 0:
    problems.append(stale.stdout.strip() or "snippets.js is out of date. Run: python3 docs/handbook/extract_sql.py")

# every documented function and table needs SQL in snippets.js to show in the drawer
snips = (here / "snippets.js").read_text()
for kind, pat in (("function", r"name: '([a-z_ ·]+)', security"), ("table", r"\{ name: '((?:private\.)?[a-z_ ·.]+)', purpose")):
    for grp in re.findall(pat, data):
        for nm in grp.split(" · "):
            nm = nm.replace("private.", "").strip()
            if nm and not re.search(rf'"{re.escape(nm)}": \{{', snips):
                problems.append(f"No SQL snippet for {kind} {nm}: is it dropped, or misspelled in data.js?")

# screens: every listed file exists, every id used by an op or gallery is defined,
# and no PNG in screens/ is left unreferenced
defined = dict(re.findall(r"'([a-z0-9-]+)': \{ file: 'screens/([^']+)'", data))
shots_dir = here / "screens"
for sid, fname in defined.items():
    if not (shots_dir / fname).is_file():
        problems.append(f"Screen '{sid}' lists screens/{fname}, which doesn't exist.")
used_ids = set()
for arr in re.findall(r"(?:screens|gallery): \[([^\]]*)\]", data):
    used_ids |= set(re.findall(r"'([a-z0-9-]+)'", arr))
for sid in sorted(used_ids - set(defined)):
    problems.append(f"An operation or gallery uses screen '{sid}', which isn't defined in `screens`.")
for sid in sorted(set(defined) - used_ids):
    problems.append(f"Screen '{sid}' is defined but no operation or gallery shows it.")
if shots_dir.is_dir():
    listed = set(defined.values())
    for f in sorted(shots_dir.iterdir()):
        if f.is_file() and f.name not in listed:
            problems.append(f"screens/{f.name} isn't listed in data.js `screens`.")

if problems:
    print("\n".join(problems))
    sys.exit(1)
print(f"Handbook covers all {len(used)} tables, functions and edge functions and all {highest} migrations.")
