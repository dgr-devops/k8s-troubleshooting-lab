#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
NS=lab-11

config_error() { [[ $(waiting_reasons "$NS") == *CreateContainerConfigError* ]]; }
event() { events_text "$NS" | grep -q "Failed.*couldn't find key password in Secret lab-11/db-credentials"; }
logged() { [[ $(k -n "$NS" logs deploy/app 2>/dev/null) == *credenciales-recibidas* ]]; }

case ${1:-} in
  broken) wait_for "CreateContainerConfigError" 60 config_error &&
    wait_for "evento: couldn't find key password in Secret" 30 event ;;
  fixed) rollout_ok "$NS" app && wait_for "la app recibe la credencial" 60 logged ;;
  *) die "uso: check.sh broken|fixed" ;;
esac
