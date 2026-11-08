#!/usr/bin/env bash
# One command for the checks every change needs.
#   tool/check.sh                 analyze + all tests + handbook check
#   tool/check.sh test/views/team analyze + only those tests + handbook check
set -uo pipefail
cd "$(dirname "$0")/.."

status=0

echo "== analyze"
fvm flutter analyze || status=1

echo "== test ${1:-(all)}"
if [ $# -gt 0 ]; then
  fvm flutter test "$@" || status=1
else
  fvm flutter test || status=1
fi

echo "== handbook"
python3 docs/handbook/check.py || status=1

if [ $status -eq 0 ]; then echo "ALL CHECKS PASSED"; else echo "CHECKS FAILED"; fi
exit $status
