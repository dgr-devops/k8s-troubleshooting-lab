# 10 · ConfigMap inexistente: CreateContainerConfigError

> Namespace del escenario: `lab-10` · Directorio: `scenarios/10-configmap-inexistente/`

## Practicar

```bash
scripts/lab.sh break 10    # aplica broken.yaml
# ...diagnostica con kubectl, sin mirar solution.yaml...
scripts/lab.sh check 10    # ¿ya está resuelto?
scripts/lab.sh fix 10      # aplica la solución de referencia
scripts/lab.sh clean 10    # borra el namespace
```

## Síntomas

El pod se queda en `CreateContainerConfigError`. El contenedor ni siquiera llega a crearse.

## Diagnóstico

El error se detecta antes de arrancar el contenedor, así que no hay logs. Hay que leer los eventos.

Salida **real** capturada en un cluster kind al ejecutar este escenario:

```text
$ kubectl -n lab-10 get pods
NAME                READY   STATUS                       RESTARTS   AGE
app-5fbdb6d-k7tp6   0/1     CreateContainerConfigError   0          30s

$ kubectl -n lab-10 describe pod -l app=app | sed -n '/Events:/,$p'
Events:
  Type     Reason     Age               From               Message
  ----     ------     ----              ----               -------
  Normal   Scheduled  30s               default-scheduler  Successfully assigned lab-10/app-5fbdb6d-k7tp6 to troubleshooting-lab-worker
  Normal   Pulled     4s (x4 over 30s)  kubelet            spec.containers{app}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
  Warning  Failed     4s (x4 over 30s)  kubelet            spec.containers{app}: Error: configmap "app-config" not found

$ kubectl -n lab-10 get configmap
NAME               DATA   AGE
kube-root-ca.crt   1      30s
```

## Causa raíz

El Deployment lee `LOG_LEVEL` de la clave `log_level` del ConfigMap `app-config`, que no existe en el namespace.

## Solución

Crear el ConfigMap (`solution.yaml`). Los pods atascados se recuperan solos: kubelet reintenta la creación.

## Prevención

- Desplegar ConfigMaps y Secrets en el mismo paquete (Helm/Kustomize) que quien los usa.
- Marcar `optional: true` solo si la aplicación realmente tolera su ausencia.
- Validar referencias en CI.
