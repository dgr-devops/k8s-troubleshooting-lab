#!/usr/bin/env bash
# Funciones comunes de lab.sh, verify-all.sh y los check.sh de cada escenario.
# Se carga con `source`; no ejecutar directamente.

CLUSTER_NAME="${CLUSTER_NAME:-troubleshooting-lab}"
CTX="kind-${CLUSTER_NAME}"
# shellcheck disable=SC2034  # ROOT lo usan los scripts que cargan esta librería
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CURL_IMAGE="${CURL_IMAGE:-curlimages/curl:8.10.1}"

# kubectl siempre contra el cluster del laboratorio
k() { kubectl --context "$CTX" "$@"; }

log() { printf '%s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

# wait_for "descripción" segundos comando [args...]
# Reintenta el comando cada 2 s hasta que devuelve 0 o se agota el tiempo.
wait_for() {
  local desc=$1 timeout=$2
  shift 2
  local end=$((SECONDS + timeout))
  while ((SECONDS < end)); do
    if "$@" >/dev/null 2>&1; then
      log "  ok: $desc"
      return 0
    fi
    sleep 2
  done
  log "  FALLO: $desc (timeout de ${timeout}s)"
  return 1
}

# Razón de espera (waiting.reason) de los contenedores de un namespace
waiting_reasons() {
  k -n "$1" get pods -o jsonpath='{.items[*].status.containerStatuses[*].state.waiting.reason}'
}

# Razón de la última terminación (lastState.terminated.reason)
last_terminated_reasons() {
  k -n "$1" get pods -o jsonpath='{.items[*].status.containerStatuses[*].lastState.terminated.reason}'
}

# Suma de reinicios de los pods de un namespace
restart_count() {
  k -n "$1" get pods -o jsonpath='{.items[*].status.containerStatuses[*].restartCount}' |
    tr ' ' '\n' | awk '{s+=$1} END {print s+0}'
}

# Número de direcciones listas en los Endpoints de un Service
ready_endpoints() {
  k -n "$1" get endpoints "$2" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w
}

# Eventos de un namespace en una sola cadena (para grep)
events_text() {
  k -n "$1" get events -o jsonpath='{range .items[*]}{.reason}: {.message}{"\n"}{end}'
}

# Código HTTP devuelto por una URL, consultada desde un pod efímero del cluster.
# Uso: http_code namespace url [cabecera-Host]. Devuelve 000 si no hay conexión.
http_code() {
  local ns=$1 url=$2 host=${3:-}
  local args=(-s -o /dev/null -w '%{http_code}' -m 5)
  [[ -n $host ]] && args+=(-H "Host: $host")
  k -n "$ns" run "probe-$RANDOM" --rm -i --restart=Never --quiet \
    --image="$CURL_IMAGE" --command -- curl "${args[@]}" "$url" 2>/dev/null || true
}

rollout_ok() { k -n "$1" rollout status "deploy/$2" --timeout=150s; }
