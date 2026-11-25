# 13 · PVC Pending: la StorageClass no existe

> Namespace del escenario: `lab-13` · Directorio: `scenarios/13-pvc-pending/`

## Practicar

```bash
scripts/lab.sh break 13    # aplica broken.yaml
# ...diagnostica con kubectl, sin mirar solution.yaml...
scripts/lab.sh check 13    # ¿ya está resuelto?
scripts/lab.sh fix 13      # aplica la solución de referencia
scripts/lab.sh clean 13    # borra el namespace
```

## Síntomas

El PVC queda en `Pending` y el pod que lo usa también, con `STATUS Pending`.

## Diagnóstico

Si el PVC no se enlaza (Bound), el pod no puede arrancar. Los eventos del PVC cuentan el motivo.

Salida **real** capturada en un cluster kind al ejecutar este escenario:

```text
$ kubectl -n lab-13 get pods,pvc
NAME                      READY   STATUS    RESTARTS   AGE
pod/db-7c69bd5bfb-pwzpx   0/1     Pending   0          30s

NAME                         STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/data   Pending                                      fast-ssd       <unset>                 30s

$ kubectl -n lab-13 describe pvc data | sed -n '/Events:/,$p'
Events:
  Type     Reason              Age               From                         Message
  ----     ------              ----              ----                         -------
  Warning  ProvisioningFailed  7s (x3 over 30s)  persistentvolume-controller  storageclass.storage.k8s.io "fast-ssd" not found

$ kubectl get storageclass
NAME                 PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
standard (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  26m
```

## Causa raíz

El PVC pide `storageClassName: fast-ssd`, que no existe en el cluster (kind solo trae `standard`).

## Solución

El campo `storageClassName` de un PVC es inmutable, así que se recrea el claim sin esa clase (usa la `standard` por defecto): `fix.sh` borra el Deployment y el PVC y aplica `solution.yaml`.

## Prevención

- Listar `kubectl get storageclass` antes de escribir manifiestos.
- No fijar clases de almacenamiento en manifiestos genéricos; dejar la por defecto.
- Alerta sobre PVC `Pending` más de unos minutos.
