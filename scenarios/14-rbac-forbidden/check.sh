#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
NS=lab-14
SA="system:serviceaccount:$NS:pod-reader"

recent_logs() { k -n "$NS" logs deploy/watcher --tail=2 2>/dev/null; }
forbidden() { [[ $(recent_logs) == *"HTTP 403"*"cannot list resource"* ]]; }
cannot() { [[ $(k auth can-i list pods -n "$NS" --as="$SA" 2>/dev/null) == no ]]; }
can() { [[ $(k auth can-i list pods -n "$NS" --as="$SA" 2>/dev/null) == yes ]]; }
ok_200() { [[ $(recent_logs) == *"HTTP 200"* && $(recent_logs) != *"HTTP 403"* ]]; }

case ${1:-} in
  broken) rollout_ok "$NS" watcher && wait_for "la API responde 403 forbidden" 60 forbidden &&
    wait_for "auth can-i list pods = no" 10 cannot ;;
  fixed) wait_for "auth can-i list pods = yes" 30 can && wait_for "el pod recibe HTTP 200" 60 ok_200 ;;
  *) die "uso: check.sh broken|fixed" ;;
esac
