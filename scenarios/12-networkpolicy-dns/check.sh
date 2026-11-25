#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
NS=lab-12

recent_logs() { k -n "$NS" logs deploy/client --tail=4 2>/dev/null; }
dns_fails() { [[ $(recent_logs) == *"bad address 'web'"* ]]; }
works() { [[ $(recent_logs) == *"OK: web responde"* && $(recent_logs) != *FAIL* ]]; }

case ${1:-} in
  broken) rollout_ok "$NS" web && rollout_ok "$NS" client &&
    wait_for "el cliente no resuelve 'web' (bad address)" 90 dns_fails ;;
  fixed) wait_for "el cliente vuelve a alcanzar web (solo OK en los logs)" 90 works ;;
  *) die "uso: check.sh broken|fixed" ;;
esac
