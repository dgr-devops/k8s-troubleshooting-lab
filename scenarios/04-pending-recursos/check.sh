#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
NS=lab-04

pending() { [[ $(k -n "$NS" get pods -o jsonpath='{.items[*].status.phase}') == *Pending* ]]; }
insufficient() { events_text "$NS" | grep -q 'FailedScheduling.*Insufficient cpu'; }

case ${1:-} in
  broken) wait_for "el pod queda Pending" 60 pending && wait_for "evento FailedScheduling: Insufficient cpu" 60 insufficient ;;
  fixed) rollout_ok "$NS" batch ;;
  *) die "uso: check.sh broken|fixed" ;;
esac
