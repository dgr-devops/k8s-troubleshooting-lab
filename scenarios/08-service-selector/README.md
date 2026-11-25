# 08 · Service sin endpoints: el selector no coincide

> Namespace del escenario: `lab-08` · Directorio: `scenarios/08-service-selector/`

## Practicar

```bash
scripts/lab.sh break 8    # aplica broken.yaml
# ...diagnostica con kubectl, sin mirar solution.yaml...
scripts/lab.sh check 8    # ¿ya está resuelto?
scripts/lab.sh fix 8      # aplica la solución de referencia
scripts/lab.sh clean 8    # borra el namespace
```

## Síntomas

Los pods están `Running` y `Ready`, pero el Service no responde (conexión rechazada o timeout).

## Diagnóstico

Compara las etiquetas de los pods con el selector del Service. Un Service sin endpoints es casi siempre un selector erróneo (o pods no Ready, ver escenario 06).

Salida **real** capturada en un cluster kind al ejecutar este escenario:

```text
$ kubectl -n lab-08 get pods --show-labels
NAME                  READY   STATUS    RESTARTS   AGE   LABELS
web-59c45ddcc-8hznp   1/1     Running   0          30s   app=web,pod-template-hash=59c45ddcc
web-59c45ddcc-jhhg8   1/1     Running   0          30s   app=web,pod-template-hash=59c45ddcc

$ kubectl -n lab-08 get svc web -o wide
NAME   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE   SELECTOR
web    ClusterIP   10.96.126.153   <none>        80/TCP    30s   app=webapp

$ kubectl -n lab-08 get endpoints web
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME   ENDPOINTS   AGE
web    <none>      30s

$ kubectl -n lab-08 describe svc web | sed -n '/Selector:/p;/Endpoints:/p'
Selector:                 app=webapp
Endpoints:
```

## Causa raíz

El Service selecciona `app=webapp`, pero los pods llevan la etiqueta `app=web`. Ningún pod coincide, por lo que `endpoints` queda vacío.

## Solución

Corregir el selector del Service a `app: web` (`solution.yaml`).

## Prevención

- Usar `kubectl get endpoints` (o EndpointSlices) como paso fijo de todo despliegue.
- Plantillas Helm/Kustomize donde el selector y las etiquetas salen de la misma variable.
- Smoke test tras el despliegue que llame al Service.
