# 01 · CrashLoopBackOff: el contenedor arranca y muere

> Namespace del escenario: `lab-01` · Directorio: `scenarios/01-crashloopbackoff/`

## Practicar

```bash
scripts/lab.sh break 1    # aplica broken.yaml
# ...diagnostica con kubectl, sin mirar solution.yaml...
scripts/lab.sh check 1    # ¿ya está resuelto?
scripts/lab.sh fix 1      # aplica la solución de referencia
scripts/lab.sh clean 1    # borra el namespace
```

## Síntomas

El pod aparece con `STATUS` alternando entre `Error` y `CrashLoopBackOff` y `RESTARTS` creciente. El contenedor arranca, termina con código 1 y kubelet lo reinicia con espera exponencial (10 s, 20 s, 40 s... hasta 5 min).

## Diagnóstico

`kubectl get pods` da la pista (reinicios), `kubectl logs` dice por qué muere el proceso y `describe` confirma el código de salida. En un crashloop real usa `kubectl logs --previous` para ver el log de la ejecución anterior.

Salida **real** capturada en un cluster kind al ejecutar este escenario:

```text
$ kubectl -n lab-01 get pods
NAME                   READY   STATUS   RESTARTS      AGE
api-5bb667d874-s7brf   0/1     Error    3 (58s ago)   70s

$ kubectl -n lab-01 logs deploy/api
FATAL: la variable DATABASE_URL no está definida

$ kubectl -n lab-01 describe pod -l app=api | sed -n '/State:/,/Ready:/p;/Events:/,$p'
    State:          Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Tue, 24 Nov 2026 20:32:55 +0100
      Finished:     Tue, 24 Nov 2026 20:32:55 +0100
    Last State:     Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Tue, 24 Nov 2026 20:32:33 +0100
      Finished:     Tue, 24 Nov 2026 20:32:33 +0100
    Ready:          False
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  70s                default-scheduler  Successfully assigned lab-01/api-5bb667d874-s7brf to troubleshooting-lab-worker
  Normal   Pulled     36s (x4 over 70s)  kubelet            spec.containers{api}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
  Normal   Created    36s (x4 over 70s)  kubelet            spec.containers{api}: Container created
  Normal   Started    36s (x4 over 69s)  kubelet            spec.containers{api}: Container started
  Warning  BackOff    35s (x3 over 68s)  kubelet            spec.containers{api}: Back-off restarting failed container api in pod api-5bb667d874-s7brf_lab-01(536a5884-8ac7-4270-bbdd-9dc9d45d9c4c)
```

## Causa raíz

La aplicación valida al arrancar que existe la variable `DATABASE_URL`, no la encuentra, imprime el error y sale con código 1. El Deployment no la define.

## Solución

Añadir la variable al contenedor (`solution.yaml`):

```yaml
env:
  - name: DATABASE_URL
    value: postgres://db.lab-01.svc:5432/app
```

En producción el valor vendría de un `ConfigMap` o `Secret` (ver escenarios 10 y 11).

## Prevención

- Documentar las variables obligatorias de cada servicio y validarlas en CI (por ejemplo con `kubeconform` más una política OPA/Kyverno).
- Falla rápido y con un mensaje claro, como hace esta app: el log es lo que te salva a las 3 de la madrugada.
- Usar `startupProbe` y alertar por `kube_pod_container_status_restarts_total`.
