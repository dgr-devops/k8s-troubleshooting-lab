#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
NS=lab-02

pull_error() { [[ $(waiting_reasons "$NS") =~ (ErrImagePull|ImagePullBackOff) ]]; }
pull_event() { events_text "$NS" | grep -qE 'Failed.*(manifest unknown|not found)'; }

case ${1:-} in
  broken) wait_for "el pod no puede bajar la imagen" 120 pull_error && wait_for "evento Failed con 'not found'" 60 pull_event ;;
  fixed) rollout_ok "$NS" web ;;
  *) die "uso: check.sh broken|fixed" ;;
esac
