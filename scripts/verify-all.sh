#!/usr/bin/env bash
# verify-all.sh: para CADA escenario aplica broken.yaml, comprueba que el síntoma
# se observa de verdad, aplica la solución y comprueba la recuperación.
# Uso: scripts/verify-all.sh [N ...]   (sin argumentos, todos los escenarios)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
LAB="$ROOT/scripts/lab.sh"

if (($# > 0)); then
  nums=("$@")
else
  nums=()
  for d in "$ROOT"/scenarios/*/; do
    n=$(basename "$d")
    nums+=("${n%%-*}")
  done
fi

results=()
failed=0

verify_one() {
  local n=$1 d name
  d=$(ls -d "$ROOT"/scenarios/"$(printf '%02d' "$((10#$n))")"-*/)
  d=${d%/}
  name=$(basename "$d")
  log "=== $name ==="
  "$LAB" clean "$n" >/dev/null 2>&1
  "$LAB" break "$n" >/dev/null || { log "  no se pudo aplicar broken.yaml"; return 1; }
  log " - síntoma esperado:"
  "$d/check.sh" broken || return 1
  log " - aplicando la solución:"
  "$LAB" fix "$n" >/dev/null || { log "  fallo al aplicar la solución"; return 1; }
  log " - recuperación esperada:"
  "$d/check.sh" fixed || return 1
}

for n in "${nums[@]}"; do
  start=$SECONDS
  if verify_one "$n"; then
    status=PASS
  else
    status=FAIL
    failed=$((failed + 1))
  fi
  "$LAB" clean "$n" >/dev/null 2>&1
  results+=("$(printf '%-6s %-3s %4ss' "$status" "$n" "$((SECONDS - start))")")
done

echo
echo "RESULTADO   escenario  tiempo"
printf '%s\n' "${results[@]}"
echo
if ((failed > 0)); then
  echo "$failed escenario(s) con fallo"
  exit 1
fi
echo "Todos los escenarios verificados: síntoma observado y recuperación confirmada"
