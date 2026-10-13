#!/usr/bin/env bash
# Runs every database test against the LOCAL Supabase database.
#
#   supabase start                      # once per session (needs Docker running)
#   supabase/tests/run_local.sh         # rebuild the local db from migrations, run all tests
#   supabase/tests/run_local.sh --no-reset   # run the tests on the db as it is
#
# Prints one line per test, then every FAIL/ERROR line, and exits 1 if
# anything failed. Each test rolls itself back, so nothing is kept.
# Never touches the hosted project: it refuses any database that isn't local.

set -euo pipefail

cd "$(dirname "$0")/../.."   # project root, where supabase/config.toml lives

DB_URL="${DB_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
case "$DB_URL" in
  *@127.0.0.1:*|*@localhost:*) ;;
  *) echo "Refusing to run: DB_URL must point at a local database (127.0.0.1 or localhost)." >&2; exit 2 ;;
esac

if ! supabase status >/dev/null 2>&1; then
  echo "The local Supabase stack isn't running. Start Docker, then run: supabase start" >&2
  exit 2
fi

if [[ "${1:-}" != "--no-reset" ]]; then
  echo "Rebuilding the local database from supabase/migrations…"
  supabase db reset --local >/dev/null
fi

python3 supabase/tests/build_run_all.py >/dev/null

# run_all.sql fills a temp table with one report per test; the summary below
# reads it in the same session.
output="$(psql "$DB_URL" -X -q -t -A -v ON_ERROR_STOP=1 <<'SQL'
\o /dev/null
\i supabase/tests/run_all.sql
\o
with counted as (
  select test,
         report,
         (length(report) - length(replace(report, 'PASS ', ''))) / 5 as passed,
         (length(report) - length(replace(report, 'FAIL ', ''))) / 5
           + (length(report) - length(replace(report, 'ERROR ', ''))) / 6 as failed
  from test_reports
)
select format('%s  %-28s %3s passed  %s failed', case when failed = 0 then 'ok  ' else 'FAIL' end, test, passed, failed)
       || coalesce((select string_agg(E'\n        ' || l, '')
                    from regexp_split_to_table(report, E'\n') l
                    where l like 'FAIL %' or l like 'ERROR %'), '')
from counted
union all
select 'TOTAL_FAILED=' || coalesce(sum(failed), 0) from counted;
SQL
)"

echo "$output" | grep -v '^TOTAL_FAILED='
total_failed="$(echo "$output" | sed -n 's/^TOTAL_FAILED=//p')"

if [[ "$total_failed" != "0" ]]; then
  echo; echo "$total_failed check(s) failed."
  exit 1
fi
echo; echo "All tests passed."
