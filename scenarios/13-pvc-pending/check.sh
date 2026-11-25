#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
NS=lab-13

pvc_phase() { [[ $(k -n "$NS" get pvc data -o jsonpath='{.status.phase}') == "$1" ]]; }
pod_pending() { [[ $(k -n "$NS" get pods -o jsonpath='{.items[*].status.phase}') == *Pending* ]]; }
class_event() { events_text "$NS" | grep -q 'storageclass.storage.k8s.io "fast-ssd" not found'; }
written() { [[ $(k -n "$NS" logs deploy/db 2>/dev/null) == *escritura-ok* ]]; }

case ${1:-} in
  broken) wait_for "el PVC queda Pending" 30 pvc_phase Pending &&
    wait_for "el pod queda Pending" 30 pod_pending &&
    wait_for "evento: storageclass \"fast-ssd\" not found" 60 class_event ;;
  fixed) rollout_ok "$NS" db && wait_for "el PVC está Bound" 60 pvc_phase Bound && wait_for "el pod escribe en el volumen" 60 written ;;
  *) die "uso: check.sh broken|fixed" ;;
esac
