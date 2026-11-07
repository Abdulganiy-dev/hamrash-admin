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

if problems:
    print("\n".join(problems))
    sys.exit(1)
print(f"Handbook covers all {len(used)} tables, functions and edge functions and all {highest} migrations.")
