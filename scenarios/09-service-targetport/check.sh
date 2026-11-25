#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
NS=lab-09
URL=http://web.lab-09.svc

has_endpoints() { [[ $(ready_endpoints "$NS" web) -eq 2 ]]; }
refused() { [[ $(http_code "$NS" "$URL") == 000 ]]; }
reachable() { [[ $(http_code "$NS" "$URL") == 200 ]]; }
target_port() { [[ $(k -n "$NS" get endpoints web -o jsonpath='{.subsets[0].ports[0].port}') == "$1" ]]; }

case ${1:-} in
  broken) rollout_ok "$NS" web && wait_for "el Service SÍ tiene endpoints" 30 has_endpoints &&
    wait_for "los endpoints apuntan al puerto 8080" 20 target_port 8080 &&
    wait_for "pero la conexión al Service falla" 60 refused ;;
  fixed) wait_for "los endpoints apuntan al puerto 80" 60 target_port 80 && wait_for "el Service responde HTTP 200" 60 reachable ;;
  *) die "uso: check.sh broken|fixed" ;;
esac
