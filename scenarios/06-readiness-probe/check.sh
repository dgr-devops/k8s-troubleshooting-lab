#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
NS=lab-06

running_not_ready() {
  [[ $(k -n "$NS" get pods -o jsonpath='{.items[*].status.phase}') == Running ]] &&
    [[ $(k -n "$NS" get pods -o jsonpath='{.items[*].status.containerStatuses[*].ready}') == false ]]
}
probe_event() { events_text "$NS" | grep -q 'Unhealthy.*Readiness probe failed: HTTP probe failed with statuscode: 404'; }
no_endpoints() { [[ $(ready_endpoints "$NS" web) -eq 0 ]]; }
has_endpoints() { [[ $(ready_endpoints "$NS" web) -ge 1 ]]; }

case ${1:-} in
  broken) wait_for "pod Running pero no Ready" 90 running_not_ready &&
    wait_for "evento: Readiness probe failed (404)" 60 probe_event &&
    wait_for "el Service no tiene endpoints" 20 no_endpoints ;;
  fixed) rollout_ok "$NS" web && wait_for "el Service ya tiene endpoints" 60 has_endpoints ;;
  *) die "uso: check.sh broken|fixed" ;;
esac
