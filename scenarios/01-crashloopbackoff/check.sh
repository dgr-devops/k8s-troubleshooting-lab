#!/usr/bin/env bash
# Uso: check.sh broken|fixed
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
NS=lab-01

# Según la versión de Kubernetes, entre reinicios el estado visible es "CrashLoopBackOff"
# (waiting) o simplemente "Error" (terminated). El síntoma real es el mismo: el contenedor
# muere con código 1 y kubelet lo reinicia una y otra vez.
crashloop() {
  [[ $(waiting_reasons "$NS") == *CrashLoopBackOff* ]] && return 0
  local restarts exit_code
  restarts=$(k -n "$NS" get pods -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}')
  exit_code=$(k -n "$NS" get pods -o jsonpath='{.items[0].status.containerStatuses[0].lastState.terminated.exitCode}')
  [[ ${restarts:-0} -ge 2 && $exit_code == 1 ]]
}

case ${1:-} in
  broken) wait_for "el contenedor muere con código 1 y se reinicia en bucle (CrashLoopBackOff)" 120 crashloop ;;
  fixed) rollout_ok "$NS" api && [[ $(waiting_reasons "$NS") != *CrashLoopBackOff* ]] ;;
  *) die "uso: check.sh broken|fixed" ;;
esac
