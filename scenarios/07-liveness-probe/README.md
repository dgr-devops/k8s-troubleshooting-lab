# 07 · Liveness probe fallando: reinicios en bucle

> Namespace del escenario: `lab-07` · Directorio: `scenarios/07-liveness-probe/`

## Practicar

```bash
scripts/lab.sh break 7    # aplica broken.yaml
# ...diagnostica con kubectl, sin mirar solution.yaml...
scripts/lab.sh check 7    # ¿ya está resuelto?
scripts/lab.sh fix 7      # aplica la solución de referencia
scripts/lab.sh clean 7    # borra el namespace
```

## Síntomas

El pod está `Running` pero `RESTARTS` crece sin parar, sin que la aplicación falle por sí misma.

## Diagnóstico

A diferencia del crashloop, aquí no hay errores en el log de la app: es kubelet quien mata el contenedor. Se ve en los eventos (`Killing ... failed liveness probe`).

Salida **real** capturada en un cluster kind al ejecutar este escenario:

```text
$ kubectl -n lab-07 get pods
NAME                   READY   STATUS             RESTARTS     AGE
web-86d44ddbbf-qdb59   0/1     CrashLoopBackOff   4 (5s ago)   50s

$ kubectl -n lab-07 describe pod -l app=web | sed -n '/Liveness:/p;/Events:/,$p'
    Liveness:     http-get http://:8080/ delay=2s timeout=1s period=3s successThreshold=1 failureThreshold=2
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  50s                default-scheduler  Successfully assigned lab-07/web-86d44ddbbf-qdb59 to troubleshooting-lab-worker
  Normal   Pulled     10s (x5 over 49s)  kubelet            spec.containers{web}: Container image "nginx:1.27-alpine" already present on machine and can be accessed by the pod
  Normal   Created    10s (x5 over 49s)  kubelet            spec.containers{web}: Container created
  Normal   Started    10s (x5 over 49s)  kubelet            spec.containers{web}: Container started
  Warning  Unhealthy  5s (x10 over 47s)  kubelet            spec.containers{web}: Liveness probe failed: Get "http://10.244.1.44:8080/": dial tcp 10.244.1.44:8080: connect: connection refused
  Normal   Killing    5s (x5 over 44s)   kubelet            spec.containers{web}: Container web failed liveness probe, will be restarted
  Warning  BackOff    4s (x4 over 32s)   kubelet            spec.containers{web}: Back-off restarting failed container web in pod web-86d44ddbbf-qdb59_lab-07(e535cf4d-a1af-4abc-b015-cc619d088413)
```

## Causa raíz

La liveness probe apunta al puerto 8080, pero nginx escucha en el 80. La conexión es rechazada, tras 2 fallos kubelet reinicia el contenedor, y vuelve a empezar.

## Solución

Corregir el puerto de la probe (`port: 80` en `solution.yaml`).

## Prevención

- Liveness solo para detectar bloqueos irrecuperables; usar readiness para el tráfico y `startupProbe` para arranques lentos.
- Evitar `failureThreshold` muy bajos.
- Comprobar `containerPort` y probes en la misma revisión.
