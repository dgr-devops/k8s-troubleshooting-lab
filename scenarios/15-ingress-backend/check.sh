#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
NS=lab-15
CONTROLLER=http://ingress-nginx-controller.ingress-nginx.svc
HOST=app.lab.local

code_is() { [[ $(http_code "$NS" "$CONTROLLER" "$HOST") == "$1" ]]; }
backend_error() { k -n "$NS" describe ingress web | grep -q 'services "web-svc" not found'; }

case ${1:-} in
  broken) rollout_ok "$NS" web && wait_for "el Ingress devuelve 503" 90 code_is 503 &&
    wait_for "describe ingress muestra services \"web-svc\" not found" 20 backend_error ;;
  fixed) wait_for "el Ingress devuelve 200" 90 code_is 200 ;;
  *) die "uso: check.sh broken|fixed" ;;
esac
