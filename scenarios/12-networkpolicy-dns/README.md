# 12 · NetworkPolicy bloquea el DNS y el tráfico

> Namespace del escenario: `lab-12` · Directorio: `scenarios/12-networkpolicy-dns/`

## Practicar

```bash
scripts/lab.sh break 12    # aplica broken.yaml
# ...diagnostica con kubectl, sin mirar solution.yaml...
scripts/lab.sh check 12    # ¿ya está resuelto?
scripts/lab.sh fix 12      # aplica la solución de referencia
scripts/lab.sh clean 12    # borra el namespace
```

## Síntomas

Un cliente deja de poder llamar a `http://web`. El error del cliente es `bad address 'web'`: falla la resolución DNS, no la conexión.

## Diagnóstico

Un `bad address` indica DNS, no red. Mira si hay NetworkPolicies en el namespace y qué tráfico de salida permiten.

Salida **real** capturada en un cluster kind al ejecutar este escenario:

```text
$ kubectl -n lab-12 logs deploy/client --tail=3
FAIL: wget: download timed out
FAIL: wget: bad address 'web'
FAIL: wget: bad address 'web'

$ kubectl -n lab-12 get networkpolicy
NAME            POD-SELECTOR   AGE
client-egress   app=client     60s

$ kubectl -n lab-12 describe networkpolicy client-egress
Name:         client-egress
Namespace:    lab-12
Created on:   2026-11-24 20:40:58 +0100 CET
Labels:       <none>
Annotations:  <none>
Spec:
  PodSelector:     app=client
  Not affecting ingress traffic
  Allowing egress traffic:
    <none> (Selected pods are isolated for egress connectivity)
  Policy Types: Egress
```

## Causa raíz

La `NetworkPolicy` `client-egress` selecciona los pods cliente y no permite ninguna salida, ni siquiera a CoreDNS (puerto 53). Sin DNS no hay resolución, y sin regla hacia `web` tampoco habría tráfico.

## Solución

Permitir la salida hacia CoreDNS (UDP/TCP 53 en `kube-system`) y hacia los pods `web` en el puerto 80 (`solution.yaml`).

## Prevención

- Con *default deny* de egress, la regla de DNS es la primera que hay que añadir.
- Probar las políticas en un namespace de pruebas con pods efímeros.
- Herramientas como `netpol-analyzer` en CI.
