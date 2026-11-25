# 06 · Readiness probe fallando: Running pero 0/1 y sin tráfico

> Namespace del escenario: `lab-06` · Directorio: `scenarios/06-readiness-probe/`

## Practicar

```bash
scripts/lab.sh break 6    # aplica broken.yaml
# ...diagnostica con kubectl, sin mirar solution.yaml...
scripts/lab.sh check 6    # ¿ya está resuelto?
scripts/lab.sh fix 6      # aplica la solución de referencia
scripts/lab.sh clean 6    # borra el namespace
```

## Síntomas

El pod está `Running` pero `READY 0/1`. El Service no tiene endpoints, así que no recibe tráfico (para el usuario, la aplicación está caída aunque el pod parezca vivo).

## Diagnóstico

El contenedor está sano; lo que falla es la comprobación de readiness. Se ve en los eventos `Unhealthy` y en que `endpoints` está vacío.

Salida **real** capturada en un cluster kind al ejecutar este escenario:

```text
$ kubectl -n lab-06 get pods
NAME                  READY   STATUS    RESTARTS   AGE
web-c68cbc957-vv9x5   0/1     Running   0          30s

$ kubectl -n lab-06 get endpoints web
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME   ENDPOINTS   AGE
web                30s

$ kubectl -n lab-06 describe pod -l app=web | sed -n '/Readiness:/p;/Events:/,$p'
    Readiness:    http-get http://:80/healthz delay=0s timeout=1s period=3s successThreshold=1 failureThreshold=2
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  30s                default-scheduler  Successfully assigned lab-06/web-c68cbc957-vv9x5 to troubleshooting-lab-worker
  Normal   Pulled     30s                kubelet            spec.containers{web}: Container image "nginx:1.27-alpine" already present on machine and can be accessed by the pod
  Normal   Created    30s                kubelet            spec.containers{web}: Container created
  Normal   Started    30s                kubelet            spec.containers{web}: Container started
  Warning  Unhealthy  30s                kubelet            spec.containers{web}: Readiness probe failed: Get "http://10.244.1.43:80/healthz": dial tcp 10.244.1.43:80: connect: connection refused
  Warning  Unhealthy  2s (x10 over 29s)  kubelet            spec.containers{web}: Readiness probe failed: HTTP probe failed with statuscode: 404
```

## Causa raíz

La readiness probe consulta `/healthz`, que nginx no sirve (devuelve 404). Kubernetes marca el pod como no listo y lo saca de los endpoints del Service.

## Solución

Apuntar la probe a una ruta que exista (`path: /` en `solution.yaml`) o implementar el endpoint de salud en la aplicación.

## Prevención

- Probar en local la ruta de la probe antes de desplegarla.
- Una probe debe medir lo que importa (la app puede atender), no un fichero cualquiera.
- Alertar por pods que llevan más de N minutos `Running` y no `Ready`.
