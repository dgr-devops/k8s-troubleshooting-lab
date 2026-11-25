#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
NS=lab-03

oom() { [[ $(last_terminated_reasons "$NS") == *OOMKilled* ]]; }
stable() { [[ $(k -n "$NS" logs deploy/worker 2>/dev/null) == *"carga cargada"* ]]; }

case ${1:-} in
  broken) wait_for "el contenedor muere por OOMKilled" 120 oom ;;
  fixed) rollout_ok "$NS" worker && wait_for "la carga termina de cargar sin OOM" 60 stable ;;
  *) die "uso: check.sh broken|fixed" ;;
esac
