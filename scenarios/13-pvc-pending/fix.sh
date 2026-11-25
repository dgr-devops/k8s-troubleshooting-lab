#!/usr/bin/env bash
# El campo storageClassName de un PVC es inmutable: hay que recrear el claim.
source "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib.sh"
D="$(dirname "${BASH_SOURCE[0]}")"
k -n lab-13 delete deploy/db pvc/data --ignore-not-found --wait=true
k apply -f "$D/solution.yaml"
