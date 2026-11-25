# 09 · Service con targetPort equivocado

> Namespace del escenario: `lab-09` · Directorio: `scenarios/09-service-targetport/`

## Practicar

```bash
scripts/lab.sh break 9    # aplica broken.yaml
# ...diagnostica con kubectl, sin mirar solution.yaml...
scripts/lab.sh check 9    # ¿ya está resuelto?
scripts/lab.sh fix 9      # aplica la solución de referencia
scripts/lab.sh clean 9    # borra el namespace
```

## Síntomas

Hay endpoints, los pods están `Ready`, pero las conexiones al Service fallan con `Connection refused`.

## Diagnóstico

Aquí `get endpoints` NO está vacío: la diferencia con el escenario 08 es que los endpoints existen pero apuntan a un puerto donde nadie escucha.

Salida **real** capturada en un cluster kind al ejecutar este escenario:

```text
$ kubectl -n lab-09 get svc,endpoints
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME          TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
service/web   ClusterIP   10.96.30.87   <none>        80/TCP    31s

NAME            ENDPOINTS                           AGE
endpoints/web   10.244.1.47:8080,10.244.1.48:8080   31s

$ kubectl -n lab-09 describe svc web | sed -n '/Port:/p;/TargetPort:/p;/Endpoints:/p'
Port:                     <unset>  80/TCP
TargetPort:               8080/TCP
TargetPort:               8080/TCP
Endpoints:                10.244.1.48:8080,10.244.1.47:8080

$ kubectl -n lab-09 get pods -o wide
NAME                  READY   STATUS    RESTARTS   AGE   IP            NODE                         NOMINATED NODE   READINESS GATES
web-59c45ddcc-8nnvc   1/1     Running   0          31s   10.244.1.47   troubleshooting-lab-worker   <none>           <none>
web-59c45ddcc-kvhg4   1/1     Running   0          31s   10.244.1.48   troubleshooting-lab-worker   <none>           <none>
```

## Causa raíz

El Service reenvía a `targetPort: 8080`, pero nginx escucha en el 80.

## Solución

Corregir `targetPort` a 80 (o hacer que el contenedor escuche en 8080). Ver `solution.yaml`. Truco: nombrar el puerto del contenedor (`name: http`) y usar el nombre en `targetPort`.

## Prevención

- Usar puertos con nombre para no repetir números.
- Probar el Service con un pod efímero (`kubectl run curl --rm -it --image=curlimages/curl -- curl http://web`).
- Un smoke test en el pipeline.
