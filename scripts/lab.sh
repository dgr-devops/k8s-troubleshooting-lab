#!/usr/bin/env bash
# lab.sh: gestiona el laboratorio de troubleshooting de Kubernetes sobre kind.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

INGRESS_VERSION="${INGRESS_VERSION:-controller-v1.12.1}"
INGRESS_MANIFEST="https://raw.githubusercontent.com/kubernetes/ingress-nginx/${INGRESS_VERSION}/deploy/static/provider/kind/deploy.yaml"

usage() {
  cat <<USO
Uso: scripts/lab.sh <comando> [N]

  up         Crea el cluster kind (si no existe) e instala ingress-nginx
  down       Elimina el cluster
  list       Lista los escenarios disponibles
  break N    Aplica el escenario N (rompe algo a propósito)
  fix N      Aplica la solución de referencia del escenario N
  check N    Comprueba si el escenario N está resuelto (exit 0 = resuelto)
  clean N    Borra el namespace del escenario N

N es el número del escenario (1, 01, 12...).
USO
}

scenario_dir() {
  local n
  n=$(printf '%02d' "$((10#${1:-x}))" 2>/dev/null) || die "número de escenario inválido: ${1:-}"
  local matches=("$ROOT"/scenarios/"$n"-*/)
  [[ -d ${matches[0]} ]] || die "no existe el escenario $n (usa: lab.sh list)"
  echo "${matches[0]%/}"
}

scenario_ns() { echo "lab-$(printf '%02d' "$((10#$1))")"; }

cmd_up() {
  if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
    log "El cluster $CLUSTER_NAME ya existe, se reutiliza."
  else
    kind create cluster --name "$CLUSTER_NAME" --config "$ROOT/kind/cluster.yaml" --wait 120s
  fi
  if ! k -n ingress-nginx get deploy ingress-nginx-controller >/dev/null 2>&1; then
    log "Instalando ingress-nginx ($INGRESS_VERSION)..."
    k apply -f "$INGRESS_MANIFEST" >/dev/null
  fi
  k -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=240s
  log "Laboratorio listo. Contexto: $CTX"
}

cmd_down() { kind delete cluster --name "$CLUSTER_NAME"; }

cmd_list() {
  local d title
  for d in "$ROOT"/scenarios/*/; do
    d=${d%/}
    title=$(head -n1 "$d/README.md" | sed 's/^# *//')
    printf '%s\n' "$title"
  done
}

cmd_break() {
  local d
  d=$(scenario_dir "$1")
  k apply -f "$d/broken.yaml"
  log "Escenario $(basename "$d") aplicado. Namespace: $(scenario_ns "$1"). Diagnostica con kubectl."
}

cmd_fix() {
  local d
  d=$(scenario_dir "$1")
  if [[ -x $d/fix.sh ]]; then
    "$d/fix.sh"
  else
    k apply -f "$d/solution.yaml"
  fi
}

cmd_check() {
  local d
  d=$(scenario_dir "$1")
  if "$d/check.sh" fixed; then
    echo "RESUELTO: $(basename "$d")"
  else
    echo "TODAVÍA ROTO: $(basename "$d")"
    return 1
  fi
}

cmd_clean() { k delete namespace "$(scenario_ns "$1")" --ignore-not-found --wait=true; }

main() {
  local cmd=${1:-}
  case "$cmd" in
    up) cmd_up ;;
    down) cmd_down ;;
    list) cmd_list ;;
    break | fix | check | clean)
      [[ $# -ge 2 ]] || die "falta el número de escenario"
      "cmd_$cmd" "$2"
      ;;
    -h | --help | help | "") usage ;;
    *) usage >&2; exit 2 ;;
  esac
}

main "$@"
