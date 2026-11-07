#!/usr/bin/env python3
"""Builds docs/handbook/snippets.js from supabase/migrations/*.sql.

The handbook's reference drawer shows real SQL: the latest definition of each
public function, and each table's columns, policies and triggers as they stand
after every migration has run. This script replays the migrations in order, so
a later `create or replace`, `drop policy` or `drop column` is respected.

  python3 docs/handbook/extract_sql.py           write snippets.js
  python3 docs/handbook/extract_sql.py --check   exit 1 if snippets.js is stale

check.py runs the --check mode. Run the write mode after any migration change.
It reads only plain statements, so SQL generated inside `do $$ ... $$` blocks
isn't seen; none of the current migrations rely on that for policies.
"""
import json
import pathlib
import re
import sys

here = pathlib.Path(__file__).resolve().parent
repo = here.parent.parent
migrations = sorted((repo / "supabase" / "migrations").glob("*.sql"))
OUT = here / "snippets.js"


KEYWORDS = {"before", "after", "instead", "of", "insert", "update", "delete", "or", "truncate"}


def line_of(text, offset):
    return text.count("\n", 0, offset) + 1


def split_top(s):
    """Split on commas that aren't inside parentheses or quotes."""
    parts, depth, cur, quote = [], 0, [], None
    for ch in s:
        if quote:
            cur.append(ch)
            if ch == quote:
                quote = None
            continue
        if ch in "'\"":
            quote = ch
            cur.append(ch)
        elif ch == "(":
            depth += 1
            cur.append(ch)
        elif ch == ")":
            depth -= 1
            cur.append(ch)
        elif ch == "," and depth == 0:
            parts.append("".join(cur).strip())
            cur = []
        else:
            cur.append(ch)
    tail = "".join(cur).strip()
    if tail:
        parts.append(tail)
    return parts


def matching_paren(text, open_idx):
    depth = 0
    for i in range(open_idx, len(text)):
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
            if depth == 0:
                return i
    return -1


def mig_no(path):
    return int(re.match(r"\d+_(\d+)_", path.name).group(1))


functions, private_functions, tables = {}, {}, {}
policies, triggers = {}, {}  # (table, name) -> entry
comment_strip = re.compile(r"--[^\n]*")

FN = re.compile(r"create\s+(?:or\s+replace\s+)?function\s+(public|private)\.([a-z_]+)\s*\(", re.I)
CT = re.compile(r"create\s+table\s+(?:if\s+not\s+exists\s+)?(public|private)\.([a-z_]+)\s*\(", re.I)
CP = re.compile(r"create\s+policy\s+\"([^\"]+)\"\s+on\s+(?:public|private)\.([a-z_]+)", re.I)
DP = re.compile(r"drop\s+policy\s+(?:if\s+exists\s+)?\"([^\"]+)\"\s+on\s+(?:public|private)\.([a-z_]+)", re.I)
CTR = re.compile(r"create\s+trigger\s+([a-z_]+)[\s\S]*?\bon\s+(?:public|private)\.([a-z_]+)", re.I)
DTR = re.compile(r"drop\s+trigger\s+(?:if\s+exists\s+)?([a-z_]+)\s+on\s+(?:public|private)\.([a-z_]+)", re.I)
ALTER = re.compile(r"alter\s+table\s+(?:only\s+)?(?:public|private)\.([a-z_]+)\s+", re.I)
DROPT = re.compile(r"drop\s+table\s+(?:if\s+exists\s+)?(?:public|private)\.([a-z_]+)", re.I)
DROPF = re.compile(r"drop\s+function\s+(?:if\s+exists\s+)?(public|private)\.([a-z_]+)", re.I)


def statement_end(text, start):
    """Index just after the `;` that ends the statement starting at `start`,
    skipping dollar-quoted bodies."""
    i, n = start, len(text)
    while i < n:
        if text[i] == "$":
            m = re.match(r"\$[A-Za-z_]*\$", text[i:])
            if m:
                tag = m.group(0)
                close = text.find(tag, i + len(tag))
                if close == -1:
                    return n
                i = close + len(tag)
                continue
        if text[i] == "'":
            j = i + 1
            while j < n:
                if text[j] == "'" and text[j + 1 : j + 2] == "'":
                    j += 2
                    continue
                if text[j] == "'":
                    break
                j += 1
            i = j + 1
            continue
        if text[i] == ";":
            return i + 1
        i += 1
    return n


for path in migrations:
    raw = path.read_text()
    text = raw  # keep comments in snippets; match against a comment-blanked copy
    blank = re.sub(r"--[^\n]*", lambda m: " " * len(m.group(0)), raw)
    n = mig_no(path)
    rel = f"supabase/migrations/{path.name}"

    for m in DROPF.finditer(blank):
        (functions if m.group(1) == "public" else private_functions).pop(m.group(2), None)
    for m in DROPT.finditer(blank):
        tables.pop(m.group(1), None)
        for k in [k for k in policies if k[0] == m.group(1)]:
            policies.pop(k)
        for k in [k for k in triggers if k[0] == m.group(1)]:
            triggers.pop(k)

    for m in FN.finditer(blank):
        schema, name = m.group(1), m.group(2)
        end = statement_end(blank, m.start())
        sql = text[m.start():end].strip()
        open_idx = m.end() - 1
        close_idx = matching_paren(blank, open_idx)
        params_src = blank[open_idx + 1 : close_idx]
        params = []
        for p in split_top(params_src):
            pm = re.match(r"([a-z_0-9]+)\s+(.+?)(?:\s+default\s+(.+))?$", p, re.I | re.S)
            if pm:
                params.append({"name": pm.group(1), "type": " ".join(pm.group(2).split()), "default": pm.group(3)})
        rest = blank[close_idx + 1 : end]
        rm = re.search(r"returns\s+(table\s*\(.*?\)|[a-z_.\[\] ]+?)(?=\s+(?:language|security|volatile|stable|immutable|set|as)\b)", rest, re.I | re.S)
        returns = " ".join(rm.group(1).split()) if rm else ""
        (functions if schema == "public" else private_functions)[name] = {
            "sql": sql,
            "file": rel,
            "migration": n,
            "lines": [line_of(text, m.start()), line_of(text, end - 1)],
            "params": params,
            "returns": returns,
            "security": "definer" if re.search(r"security\s+definer", rest, re.I) else "invoker",
        }

    for m in CT.finditer(blank):
        schema, name = m.groups()
        open_idx = m.end() - 1
        close_idx = matching_paren(blank, open_idx)
        body = blank[open_idx + 1 : close_idx]
        cols, constraints = [], []
        for part in split_top(body):
            if re.match(r"(constraint|primary\s+key|foreign\s+key|unique|check)\b", part, re.I):
                constraints.append(" ".join(part.split()))
            else:
                cm = re.match(r"([a-z_0-9]+)\s+(.+)$", part, re.I | re.S)
                if cm:
                    cols.append({"name": cm.group(1), "type": " ".join(cm.group(2).split())})
        end = statement_end(blank, m.start())
        tables[name] = {
            "schema": schema,
            "create": {"sql": text[m.start():end].strip(), "file": rel, "migration": n, "lines": [line_of(text, m.start()), line_of(text, end - 1)]},
            "columns": cols,
            "constraints": constraints,
            "alters": [],
        }

    # alter table ... add column a ..., add column b ..., drop column c
    for m in ALTER.finditer(blank):
        t = tables.get(m.group(1))
        if not t:
            continue
        end = statement_end(blank, m.start())
        for part in split_top(blank[m.end():end].rstrip(";")):
            am = re.match(r"add\s+column\s+(?:if\s+not\s+exists\s+)?([a-z_0-9]+)\s+(.+)$", part, re.I | re.S)
            if am:
                t["columns"].append({"name": am.group(1), "type": " ".join(am.group(2).split()), "added": n})
                continue
            dm = re.match(r"drop\s+column\s+(?:if\s+exists\s+)?([a-z_0-9]+)", part, re.I)
            if dm:
                t["columns"] = [c for c in t["columns"] if c["name"] != dm.group(1)]

    for m in DP.finditer(blank):
        policies.pop((m.group(2), m.group(1)), None)
    for m in CP.finditer(blank):
        end = statement_end(blank, m.start())
        policies[(m.group(2), m.group(1))] = {
            "name": m.group(1),
            "table": m.group(2),
            "sql": text[m.start():end].strip(),
            "file": rel,
            "migration": n,
            "lines": [line_of(text, m.start()), line_of(text, end - 1)],
        }

    for m in DTR.finditer(blank):
        triggers.pop((m.group(2), m.group(1)), None)
    for m in CTR.finditer(blank):
        end = statement_end(blank, m.start())
        body = text[m.start():end].strip()
        fm = re.search(r"execute\s+(?:function|procedure)\s+(public|private)\.([a-z_]+)", body, re.I)
        tm = re.search(r"trigger\s+[a-z_]+\s+(.+?)\s+on\s+(?:public|private)\.", body, re.I | re.S)
        triggers[(m.group(2), m.group(1))] = {
            "name": m.group(1),
            "table": m.group(2),
            "timing": " ".join(w.upper() if w.lower() in KEYWORDS else w for w in tm.group(1).split()) if tm else "",
            "each_row": bool(re.search(r"for\s+each\s+row", body, re.I)),
            "when": (re.search(r"\bwhen\s*\((.*?)\)\s*execute", body, re.I | re.S) or [None, None])[1],
            "function": fm.group(2) if fm else None,
            "function_schema": fm.group(1) if fm else None,
            "sql": body,
            "file": rel,
            "migration": n,
            "lines": [line_of(text, m.start()), line_of(text, end - 1)],
        }

for t in tables.values():
    t["alters"] = []
for (table, _), p in policies.items():
    if table in tables:
        tables[table].setdefault("policies", []).append(p)
for (table, _), t in triggers.items():
    if table in tables:
        tables[table].setdefault("triggers", []).append(t)
for t in tables.values():
    t.setdefault("policies", [])
    t.setdefault("triggers", [])
    t["policies"].sort(key=lambda p: (p["migration"], p["name"]))
    # Postgres fires triggers for the same event in alphabetical order by name
    t["triggers"].sort(key=lambda p: p["name"])

out = {"functions": functions, "privateFunctions": private_functions, "tables": tables}
js = (
    "// GENERATED by docs/handbook/extract_sql.py from supabase/migrations. Do not edit.\n"
    "// Regenerate with: python3 docs/handbook/extract_sql.py\n"
    "window.SNIPPETS = " + json.dumps(out, indent=1, sort_keys=True) + ";\n"
)

if "--check" in sys.argv:
    if not OUT.exists() or OUT.read_text() != js:
        print("snippets.js is out of date. Run: python3 docs/handbook/extract_sql.py")
        sys.exit(1)
    print(f"snippets.js is current ({len(functions)} functions, {len(private_functions)} private, {len(tables)} tables).")
else:
    OUT.write_text(js)
    print(f"wrote snippets.js: {len(functions)} functions, {len(private_functions)} private functions, {len(tables)} tables, "
          f"{sum(len(t['policies']) for t in tables.values())} policies, "
          f"{sum(len(t['triggers']) for t in tables.values())} triggers")
