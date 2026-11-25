# 15 · Ingress: el backend apunta a un Service que no existe

> Namespace del escenario: `lab-15` · Directorio: `scenarios/15-ingress-backend/`

## Practicar

```bash
scripts/lab.sh break 15    # aplica broken.yaml
# ...diagnostica con kubectl, sin mirar solution.yaml...
scripts/lab.sh check 15    # ¿ya está resuelto?
scripts/lab.sh fix 15      # aplica la solución de referencia
scripts/lab.sh clean 15    # borra el namespace
```

## Síntomas

Una petición al host del Ingress devuelve `503 Service Temporarily Unavailable`, aunque el Deployment y el Service están perfectos.

## Diagnóstico

Recorre la cadena de fuera hacia dentro: Ingress, Service, endpoints. `describe ingress` muestra el backend con un error si el Service no existe.

Salida **real** capturada en un cluster kind al ejecutar este escenario:

```text
$ kubectl -n lab-15 get ingress,svc,endpoints
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                            CLASS   HOSTS           ADDRESS     PORTS   AGE
ingress.networking.k8s.io/web   nginx   app.lab.local   localhost   80      40s

NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/web   ClusterIP   10.96.228.131   <none>        80/TCP    40s

NAME            ENDPOINTS        AGE
endpoints/web   10.244.1.54:80   40s

$ kubectl -n lab-15 describe ingress web | sed -n '/Rules:/,/Annotations:/p'
Rules:
  Host           Path  Backends
  ----           ----  --------
  app.lab.local  
                 /   web-svc:80 (<error: services "web-svc" not found>)
Annotations:     <none>

$ kubectl -n lab-15 run probe --rm -i --restart=Never --quiet --image=curlimages/curl:8.10.1 --command -- curl -s -o /dev/null -w 'HTTP %{http_code}\n' -H 'Host: app.lab.local' http://ingress-nginx-controller.ingress-nginx.svc
HTTP 503
```

## Causa raíz

El Ingress dirige `/` al Service `web-svc`, pero el Service se llama `web`. ingress-nginx no tiene endpoints a los que enviar y responde 503.

## Solución

Corregir el nombre del backend a `web` (`solution.yaml`).

## Prevención

- Revisar `kubectl describe ingress`: aparece `<error: services "..." not found>` al instante.
- Validar referencias entre recursos en CI (por ejemplo con `kubeconform` más un test de humo).
- Un smoke test HTTP por host tras cada despliegue.
