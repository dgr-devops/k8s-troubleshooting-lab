#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
NS=lab-07

restarting() { [[ $(restart_count "$NS") -ge 2 ]]; }
probe_event() { events_text "$NS" | grep -q 'Unhealthy.*Liveness probe failed.*connection refused'; }
killed_event() { events_text "$NS" | grep -q 'Killing.*failed liveness probe'; }
stable() { sleep 15; [[ $(restart_count "$NS") -eq 0 ]]; }

case ${1:-} in
  broken) wait_for "el contenedor se reinicia (>=2 restarts)" 120 restarting &&
    wait_for "evento: Liveness probe failed (connection refused)" 30 probe_event &&
    wait_for "evento: Killing por liveness" 30 killed_event ;;
  fixed) rollout_ok "$NS" web && wait_for "el pod nuevo no se reinicia en 15 s" 40 stable ;;
  *) die "uso: check.sh broken|fixed" ;;
esac
