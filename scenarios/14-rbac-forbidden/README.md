# 14 · RBAC: 403 forbidden para una ServiceAccount

> Namespace del escenario: `lab-14` · Directorio: `scenarios/14-rbac-forbidden/`

## Practicar

```bash
scripts/lab.sh break 14    # aplica broken.yaml
# ...diagnostica con kubectl, sin mirar solution.yaml...
scripts/lab.sh check 14    # ¿ya está resuelto?
scripts/lab.sh fix 14      # aplica la solución de referencia
scripts/lab.sh clean 14    # borra el namespace
```

## Síntomas

Una aplicación del cluster que llama a la API de Kubernetes recibe `HTTP 403` con `pods is forbidden`.

## Diagnóstico

`kubectl auth can-i --as=` responde «no» y es la forma más rápida de comprobar permisos de una ServiceAccount. El mensaje de la API ya indica usuario, verbo y recurso.

Salida **real** capturada en un cluster kind al ejecutar este escenario:

```text
$ kubectl -n lab-14 logs deploy/watcher --tail=1 | cut -c1-230
HTTP 403 { "kind": "Status", "apiVersion": "v1", "metadata": {}, "status": "Failure", "message": "pods is forbidden: User \"system:serviceaccount:lab-14:pod-reader\" cannot list resource \"pods\" in 

$ kubectl auth can-i list pods -n lab-14 --as=system:serviceaccount:lab-14:pod-reader
no

$ kubectl -n lab-14 get role,rolebinding
No resources found in lab-14 namespace.
```

## Causa raíz

La ServiceAccount `pod-reader` existe, pero no tiene ningún `Role` que permita listar pods en el namespace.

## Solución

Crear un `Role` con `get/list/watch` sobre `pods` y un `RoleBinding` a la ServiceAccount (`solution.yaml`). Los permisos aplican sin reiniciar el pod.

## Prevención

- Mínimo privilegio: Roles por namespace y verbos concretos, no `cluster-admin`.
- Probar con `kubectl auth can-i --as=system:serviceaccount:<ns>:<sa>` en CI.
- Revisar RBAC con `kubectl-who-can` o `rakkess`.
