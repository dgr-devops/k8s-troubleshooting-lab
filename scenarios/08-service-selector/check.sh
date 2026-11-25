#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
NS=lab-08
URL=http://web.lab-08.svc

pods_ready() { rollout_ok "$NS" web; }
no_endpoints() { [[ $(ready_endpoints "$NS" web) -eq 0 ]]; }
has_endpoints() { [[ $(ready_endpoints "$NS" web) -eq 2 ]]; }
unreachable() { [[ $(http_code "$NS" "$URL") != 200 ]]; }
reachable() { [[ $(http_code "$NS" "$URL") == 200 ]]; }

case ${1:-} in
  broken) pods_ready && wait_for "los pods están Ready pero el Service no tiene endpoints" 30 no_endpoints &&
    wait_for "el Service no responde" 60 unreachable ;;
  fixed) wait_for "el Service ya tiene 2 endpoints" 60 has_endpoints && wait_for "el Service responde HTTP 200" 60 reachable ;;
  *) die "uso: check.sh broken|fixed" ;;
esac
