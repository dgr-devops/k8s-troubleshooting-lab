#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
NS=lab-05

pending() { [[ $(k -n "$NS" get pods -o jsonpath='{.items[*].status.phase}') == *Pending* ]]; }
selector_event() { events_text "$NS" | grep -q "FailedScheduling.*didn't match Pod's node affinity/selector"; }

case ${1:-} in
  broken) wait_for "el pod queda Pending" 60 pending && wait_for "evento: no coincide el node selector" 60 selector_event ;;
  fixed) rollout_ok "$NS" cache ;;
  *) die "uso: check.sh broken|fixed" ;;
esac
