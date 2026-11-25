#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
NS=lab-10

config_error() { [[ $(waiting_reasons "$NS") == *CreateContainerConfigError* ]]; }
event() { events_text "$NS" | grep -q 'Failed.*configmap "app-config" not found'; }
logged() { [[ $(k -n "$NS" logs deploy/app 2>/dev/null) == *LOG_LEVEL=info* ]]; }

case ${1:-} in
  broken) wait_for "el contenedor no se crea: CreateContainerConfigError" 60 config_error &&
    wait_for "evento: configmap \"app-config\" not found" 30 event ;;
  fixed) wait_for "el pod arranca y lee LOG_LEVEL=info" 120 logged ;;
  *) die "uso: check.sh broken|fixed" ;;
esac
